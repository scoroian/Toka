// functions/test/integration/dashboard_delta.test.ts
//
// Hallazgo #16: actualización incremental (delta) del dashboard + escritura
// transaccional. Cubre, contra el emulador Firestore:
//  - el delta aplicado por la callable de completar deja el dashboard correcto,
//  - CONCURRENCIA: dos miembros completando casi a la vez NO pierden ninguna
//    completación (la lost-update race que tenía el rebuild no-transaccional),
//  - el delta no deriva del rebuild completo (mismos campos),
//  - el trigger se SALTA el rebuild cuando la escritura llevaba `dashboardDeltaToken`
//    (el delta ya actualizó), y reduce el fan-out a memberships sin cambio.

import * as admin from "firebase-admin";
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
  makeCallableRequest,
} from "./helpers/setup";
import { applyTaskCompletion } from "../../src/tasks/apply_task_completion";
import {
  updateHomeDashboard,
  onTaskWriteUpdateDashboard,
} from "../../src/tasks/update_dashboard";

const complete = (req: any): Promise<any> => (applyTaskCompletion as any).run(req);
const runTrigger = (
  homeId: string,
  taskId: string,
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined
): Promise<unknown> =>
  (onTaskWriteUpdateDashboard as any).run({
    params: { homeId, taskId },
    data: { before: { data: () => before }, after: { data: () => after } },
  });

const todayTs = () => admin.firestore.Timestamp.fromDate(new Date());

async function readDashboard(homeId: string): Promise<Record<string, any>> {
  const doc = await getDb().collection("homes").doc(homeId).collection("views").doc("dashboard").get();
  return doc.data() ?? {};
}

const OWNER = "dd-owner";
const MEMBER = "dd-member";

describe("dashboard delta — completar aplica delta y deja el dashboard correcto", () => {
  const HOME = "home-dd-single";
  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER, { nickname: "Ana" });
    await createUser(MEMBER, { nickname: "Bob" });
    await createHome(HOME, OWNER, { name: "Casa", timezone: "Europe/Madrid", premiumStatus: "active" });
    await addMemberToHome(HOME, MEMBER, "member", "active", { nickname: "Bob" });
    // 2 tareas diarias que vencen hoy, una por miembro.
    await createTask(HOME, "t-owner", OWNER, { recurrenceType: "daily", assignmentOrder: [OWNER, MEMBER], nextDueAt: todayTs() });
    await createTask(HOME, "t-member", MEMBER, { recurrenceType: "daily", assignmentOrder: [MEMBER, OWNER], nextDueAt: todayTs() });
    await updateHomeDashboard(HOME);
  });

  it("estado de partida: 2 tareas activas, 2 vencen hoy, 0 hechas", async () => {
    const d = await readDashboard(HOME);
    expect(d["counters"]["totalActiveTasks"]).toBe(2);
    expect(d["counters"]["tasksDueToday"]).toBe(2);
    expect(d["counters"]["tasksDoneToday"]).toBe(0);
  });

  it("completar t-owner: aparece en hechos, baja tasksDueToday, sigue activa (diaria) pero ya no vence hoy", async () => {
    await complete(makeCallableRequest(OWNER, { homeId: HOME, taskId: "t-owner" }));
    const d = await readDashboard(HOME);
    expect(d["counters"]["tasksDoneToday"]).toBe(1);
    expect(d["counters"]["tasksDueToday"]).toBe(1);
    const done = d["doneTasksPreview"] as any[];
    expect(done.map((x) => x.taskId)).toContain("t-owner");
    expect(done.find((x) => x.taskId === "t-owner").completedByUid).toBe(OWNER);
    // sigue activa (recurrente) pero su preview ya no vence hoy
    const active = d["activeTasksPreview"] as any[];
    const tOwner = active.find((x) => x.taskId === "t-owner");
    expect(tOwner).toBeDefined();
    expect(tOwner.isDueToday).toBe(false);
  });

  it("el delta NO deriva del rebuild completo: tras un rebuild los campos clave coinciden", async () => {
    const before = await readDashboard(HOME);
    await updateHomeDashboard(HOME); // fuente de verdad
    const after = await readDashboard(HOME);
    expect(after["counters"]["totalActiveTasks"]).toBe(before["counters"]["totalActiveTasks"]);
    expect(after["counters"]["tasksDueToday"]).toBe(before["counters"]["tasksDueToday"]);
    expect(after["counters"]["tasksDoneToday"]).toBe(before["counters"]["tasksDoneToday"]);
    const activeIdsBefore = (before["activeTasksPreview"] as any[]).map((t) => t.taskId).sort();
    const activeIdsAfter = (after["activeTasksPreview"] as any[]).map((t) => t.taskId).sort();
    expect(activeIdsAfter).toEqual(activeIdsBefore);
  });
});

describe("dashboard delta — concurrencia (lost-update race)", () => {
  const HOME = "home-dd-concurrent";
  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER, { nickname: "Ana" });
    await createUser(MEMBER, { nickname: "Bob" });
    await createHome(HOME, OWNER, { name: "Casa", timezone: "Europe/Madrid", premiumStatus: "active" });
    await addMemberToHome(HOME, MEMBER, "member", "active", { nickname: "Bob" });
    await createTask(HOME, "c-owner", OWNER, { recurrenceType: "oneTime", assignmentOrder: [OWNER], nextDueAt: todayTs() });
    await createTask(HOME, "c-member", MEMBER, { recurrenceType: "oneTime", assignmentOrder: [MEMBER], nextDueAt: todayTs() });
    await updateHomeDashboard(HOME);
  });

  it("dos completaciones casi simultáneas: NINGUNA se pierde (ambas en hechos, 0 activas)", async () => {
    await Promise.all([
      complete(makeCallableRequest(OWNER, { homeId: HOME, taskId: "c-owner" })),
      complete(makeCallableRequest(MEMBER, { homeId: HOME, taskId: "c-member" })),
    ]);
    const d = await readDashboard(HOME);
    const doneIds = (d["doneTasksPreview"] as any[]).map((x) => x.taskId).sort();
    expect(doneIds).toEqual(["c-member", "c-owner"]);
    expect(d["counters"]["tasksDoneToday"]).toBe(2);
    expect(d["counters"]["totalActiveTasks"]).toBe(0);
    expect(d["counters"]["tasksDueToday"]).toBe(0);
  });
});

describe("dashboard delta — el trigger se salta el rebuild si la escritura llevaba dashboardDeltaToken", () => {
  const HOME = "home-dd-trigger";
  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER, { nickname: "Ana" });
    await createHome(HOME, OWNER, { name: "Casa", timezone: "Europe/Madrid", premiumStatus: "active" });
    await createTask(HOME, "tt", OWNER, { recurrenceType: "daily", nextDueAt: todayTs() });
    await updateHomeDashboard(HOME);
  });

  it("write con dashboardDeltaToken cambiado → NO reconstruye (rev intacto)", async () => {
    const revBefore = (await readDashboard(HOME))["rev"];
    await runTrigger(
      HOME,
      "tt",
      { status: "active", currentAssigneeUid: OWNER, dashboardDeltaToken: 1 },
      { status: "active", currentAssigneeUid: OWNER, dashboardDeltaToken: 2 }
    );
    const revAfter = (await readDashboard(HOME))["rev"];
    expect(revAfter).toBe(revBefore);
  });

  it("write sin cambio de token pero con campo relevante → SÍ reconstruye (rev +1)", async () => {
    const revBefore = (await readDashboard(HOME))["rev"];
    await runTrigger(
      HOME,
      "tt",
      { status: "active", title: "A", dashboardDeltaToken: 2 },
      { status: "active", title: "B", dashboardDeltaToken: 2 }
    );
    const revAfter = (await readDashboard(HOME))["rev"];
    expect(revAfter).toBe(revBefore + 1);
  });
});
