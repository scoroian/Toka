// functions/test/integration/large_home_batching.test.ts
//
// Hallazgo #16: operaciones que escribían un ÚNICO `db.batch()` sin trocear
// rompían en hogares grandes (>500 escrituras → "Cannot write more than 500
// entities in a single ... batch"). Premium no tiene tope de tareas, así que un
// hogar puede tener cientos/miles. Cubrimos contra el emulador que:
//  - `restorePremiumState` desheléa >500 entidades (members + tasks) sin romper,
//  - `reassignTasksFromDeletedUser` reasigna >500 tareas de un ex-miembro.

import * as admin from "firebase-admin";
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  getDb,
  makeCallableRequest,
} from "./helpers/setup";
import { restorePremiumState } from "../../src/jobs/restore_premium_state";
import { reassignTasksFromDeletedUser } from "../../src/users/cleanup_user";
import { applyDowngradeJob } from "../../src/entitlement/apply_downgrade_plan";

const callRestore = (req: any): Promise<any> => (restorePremiumState as any).run(req);
const runDowngrade = (data: any): Promise<any> => (applyDowngradeJob as any).run(data);

async function seedTasks(
  homeId: string,
  count: number,
  fields: (i: number) => Record<string, unknown>
): Promise<void> {
  const db = getDb();
  // Trocear el SEED en lotes de 450 (el seed también superaría el límite de 500).
  for (let start = 0; start < count; start += 450) {
    const batch = db.batch();
    for (let i = start; i < Math.min(start + 450, count); i++) {
      const ref = db.collection("homes").doc(homeId).collection("tasks").doc(`task-${i}`);
      batch.set(ref, {
        title: `Task ${i}`,
        visualKind: "emoji",
        visualValue: "🧹",
        recurrenceType: "weekly",
        nextDueAt: admin.firestore.Timestamp.fromDate(new Date()),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...fields(i),
      });
    }
    await batch.commit();
  }
}

describe("restorePremiumState — hogar grande (>500 entidades congeladas)", () => {
  const HOME = "home-restore-big";
  const OWNER = "owner-restore-big";
  const N_TASKS = 510; // > 500: rompía el batch único

  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createHome(HOME, OWNER, {
      premiumStatus: "restorable",
      restoreUntil: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 86400000)),
    });
    // El owner queda congelado (en un downgrade real se congela todo menos los
    // recursos del plan free).
    await getDb().collection("homes").doc(HOME).collection("members").doc(OWNER)
      .update({ status: "frozen", frozenAt: admin.firestore.FieldValue.serverTimestamp() });
    await seedTasks(HOME, N_TASKS, () => ({
      status: "frozen",
      currentAssigneeUid: OWNER,
      assignmentOrder: [OWNER],
      frozenAt: admin.firestore.FieldValue.serverTimestamp(),
    }));
  }, 90000);

  it("restaura sin romper el límite de 500: todas las tareas y el miembro vuelven a activo", async () => {
    const res = await callRestore(makeCallableRequest(OWNER, { homeId: HOME }));
    expect(res).toEqual({ success: true });

    const home = await getDb().collection("homes").doc(HOME).get();
    expect(home.data()!["premiumStatus"]).toBe("active");

    const stillFrozenTasks = await getDb()
      .collection("homes").doc(HOME).collection("tasks")
      .where("status", "==", "frozen").get();
    expect(stillFrozenTasks.size).toBe(0);

    const member = await getDb()
      .collection("homes").doc(HOME).collection("members").doc(OWNER).get();
    expect(member.data()!["status"]).toBe("active");
  }, 90000);
});

describe("reassignTasksFromDeletedUser — hogar grande (>500 tareas del ex-miembro)", () => {
  const HOME = "home-reassign-big";
  const OWNER = "owner-reassign-big";
  const GONE = "gone-reassign-big"; // cuenta borrada
  const HEIR = "heir-reassign-big"; // activo, hereda
  const N_TASKS = 510;

  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(GONE);
    await createUser(HEIR);
    await createHome(HOME, OWNER, { premiumStatus: "active" });
    await addMemberToHome(HOME, GONE, "member", "left"); // ya marcado left por el cleanup
    await addMemberToHome(HOME, HEIR, "member", "active");
    await seedTasks(HOME, N_TASKS, () => ({
      status: "active",
      currentAssigneeUid: GONE,
      assignmentOrder: [GONE, HEIR],
    }));
  }, 90000);

  it("reasigna >500 tareas sin romper el límite de 500: ninguna queda con el ex-miembro", async () => {
    await reassignTasksFromDeletedUser(GONE, HOME);

    const stillGone = await getDb()
      .collection("homes").doc(HOME).collection("tasks")
      .where("currentAssigneeUid", "==", GONE).get();
    expect(stillGone.size).toBe(0);

    // Muestreo: la primera tarea pasó al heredero y GONE salió de assignmentOrder.
    const t0 = await getDb().collection("homes").doc(HOME).collection("tasks").doc("task-0").get();
    expect(t0.data()!["currentAssigneeUid"]).toBe(HEIR);
    expect(t0.data()!["assignmentOrder"]).not.toContain(GONE);
  }, 90000);
});

describe("applyDowngradeJob — hogar grande (>500 entidades a congelar)", () => {
  const HOME = "home-downgrade-big";
  const OWNER = "owner-downgrade-big";
  const N_TASKS = 520; // > 500 incluso sin contar miembros: rompía el batch único

  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER);
    // Grupo expirado (elegible para downgrade a Free) con tope 10.
    await createHome(HOME, OWNER, {
      premiumStatus: "active",
      premiumTier: "grupo",
      premiumEndsAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 86400000)),
      limits: { maxMembers: 10, maxTasks: 999 },
    });
    // Varios miembros activos además del owner (se congelan todos menos owner+2).
    for (let i = 0; i < 8; i++) {
      await addMemberToHome(HOME, `${HOME}-m${i}`, "member", "active", { completions60d: 100 - i });
    }
    await seedTasks(HOME, N_TASKS, () => ({
      status: "active",
      currentAssigneeUid: OWNER,
      assignmentOrder: [OWNER],
    }));
  }, 90000);

  it("congela >500 entidades sin romper el límite de 500 y deja el hogar restorable", async () => {
    await runDowngrade({});

    const home = await getDb().collection("homes").doc(HOME).get();
    expect(home.data()!["premiumStatus"]).toBe("restorable");
    expect(home.data()!["limits"]["maxMembers"]).toBe(3); // Free

    // Free conserva 4 tareas activas; el resto congeladas.
    const activeTasks = await getDb()
      .collection("homes").doc(HOME).collection("tasks").where("status", "==", "active").get();
    expect(activeTasks.size).toBe(4);
    const frozenTasks = await getDb()
      .collection("homes").doc(HOME).collection("tasks").where("status", "==", "frozen").get();
    expect(frozenTasks.size).toBe(N_TASKS - 4);

    // Free conserva owner + 2 miembros activos; el resto congelados.
    const activeMembers = await getDb()
      .collection("homes").doc(HOME).collection("members").where("status", "==", "active").get();
    expect(activeMembers.size).toBe(3);
  }, 90000);
});
