// functions/test/integration/dashboard_trigger.test.ts
//
// Hallazgo #07 (premortem): la pantalla "Hoy" (homes/{homeId}/views/dashboard)
// se quedaba STALE al crear/editar/borrar tareas porque la reconstrucción
// dependía de una llamada de cliente (`refreshDashboard`) con catch silencioso;
// si el cliente fallaba (sin red), el dashboard no reflejaba el cambio hasta el
// cron de medianoche. La corrección añade el trigger Firestore
// `onTaskWriteUpdateDashboard` que reconstruye el dashboard server-side ante
// cualquier escritura de tarea, SIN intervención del cliente.
//
// Aquí ejercitamos el trigger REAL contra el emulador de Firestore. El trigger
// sólo necesita `event.params.homeId`; `updateHomeDashboard` lee el estado real
// de Firestore (no el payload), así que escribir la tarea y disparar el trigger
// reproduce exactamente lo que hace Firestore en producción.

import * as admin from "firebase-admin";
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
} from "./helpers/setup";
import { onTaskWriteUpdateDashboard } from "../../src/tasks/update_dashboard";

// Construimos un evento mínimo (como sync_home_snapshot.test.ts): el handler
// sólo usa params.homeId y, para la guarda anti-coste, before/after.data().
const runTaskTrigger = (
  homeId: string,
  taskId: string,
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined
): Promise<unknown> =>
  (onTaskWriteUpdateDashboard as any).run({
    params: { homeId, taskId },
    data: {
      before: { data: () => before },
      after: { data: () => after },
    },
  });

async function readDashboard(homeId: string): Promise<Record<string, any>> {
  const doc = await getDb()
    .collection("homes")
    .doc(homeId)
    .collection("views")
    .doc("dashboard")
    .get();
  return doc.data() ?? {};
}

const todayTs = (): admin.firestore.Timestamp =>
  admin.firestore.Timestamp.fromDate(new Date());

const OWNER = "dash-owner";
const HOME = "home-dash-trigger";

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER, { nickname: "Owner" });
  await createHome(HOME, OWNER, { name: "Casa", timezone: "Europe/Madrid" });
  // Tarea inicial: el dashboard de partida tiene exactamente 1 tarea activa.
  await createTask(HOME, "t-base", OWNER, { nextDueAt: todayTs() });
  await runTaskTrigger(HOME, "t-base", undefined, { status: "active" });
});

describe("onTaskWriteUpdateDashboard — el dashboard refleja los cambios sin cliente", () => {
  it("estado de partida: el dashboard tiene la tarea base", async () => {
    const d = await readDashboard(HOME);
    expect(d["counters"]["totalActiveTasks"]).toBe(1);
    expect(d["activeTasksPreview"]).toHaveLength(1);
    expect(d["activeTasksPreview"][0]["taskId"]).toBe("t-base");
  });

  it("CREAR: una tarea nueva escrita en Firestore aparece en el dashboard tras el trigger", async () => {
    // El cliente escribe la tarea directamente (como TasksRepositoryImpl).
    await createTask(HOME, "t-new", OWNER, {
      title: "Sacar basura",
      nextDueAt: todayTs(),
    });
    // Firestore dispara el trigger (evento de creación: sin `before`).
    await runTaskTrigger(HOME, "t-new", undefined, { status: "active" });

    const d = await readDashboard(HOME);
    expect(d["counters"]["totalActiveTasks"]).toBe(2);
    const ids = (d["activeTasksPreview"] as any[]).map((t) => t["taskId"]);
    expect(ids).toContain("t-new");
  });

  it("EDITAR: cambiar el título se refleja en el preview tras el trigger", async () => {
    await getDb()
      .collection("homes").doc(HOME)
      .collection("tasks").doc("t-new")
      .update({ title: "Sacar la basura orgánica" });
    await runTaskTrigger(
      HOME,
      "t-new",
      { title: "Sacar basura", status: "active" },
      { title: "Sacar la basura orgánica", status: "active" }
    );

    const d = await readDashboard(HOME);
    const preview = (d["activeTasksPreview"] as any[]).find(
      (t) => t["taskId"] === "t-new"
    );
    expect(preview["title"]).toBe("Sacar la basura orgánica");
  });

  it("BORRAR (soft delete): la tarea sale del dashboard tras el trigger", async () => {
    await getDb()
      .collection("homes").doc(HOME)
      .collection("tasks").doc("t-new")
      .update({ status: "deleted", deletedAt: todayTs() });
    await runTaskTrigger(
      HOME,
      "t-new",
      { title: "Sacar la basura orgánica", status: "active" },
      { title: "Sacar la basura orgánica", status: "deleted" }
    );

    const d = await readDashboard(HOME);
    expect(d["counters"]["totalActiveTasks"]).toBe(1);
    const ids = (d["activeTasksPreview"] as any[]).map((t) => t["taskId"]);
    expect(ids).not.toContain("t-new");
  });

  it("EDGE — fallo de red del cliente: aunque el cliente NO llame a refreshDashboard, el trigger reconstruye y el dashboard NO queda stale", async () => {
    // Escenario: el cliente crea la tarea (se persiste en Firestore) pero la
    // llamada a `refreshDashboard` falla silenciosamente. NO invocamos ninguna
    // reconstrucción manual: sólo el trigger que Firestore dispararía solo.
    await createTask(HOME, "t-offline", OWNER, {
      title: "Tarea sin red",
      nextDueAt: todayTs(),
    });

    // Antes del trigger el dashboard sigue mostrando el estado viejo (stale).
    const before = await readDashboard(HOME);
    expect((before["activeTasksPreview"] as any[]).map((t) => t["taskId"]))
      .not.toContain("t-offline");

    // El trigger (única vía server-side) reconstruye.
    await runTaskTrigger(HOME, "t-offline", undefined, { status: "active" });

    const after = await readDashboard(HOME);
    expect(after["counters"]["totalActiveTasks"]).toBe(2);
    expect((after["activeTasksPreview"] as any[]).map((t) => t["taskId"]))
      .toContain("t-offline");
  });

  it("COSTE ACOTADO: una edición que no toca campos del dashboard NO reescribe el documento", async () => {
    const before = await readDashboard(HOME);
    const beforeMillis = (before["updatedAt"] as admin.firestore.Timestamp).toMillis();

    // Edición que sólo cambia `updatedAt` (campo interno, no mostrado).
    await runTaskTrigger(
      HOME,
      "t-base",
      { status: "active", title: "Task t-base", updatedAt: todayTs() },
      { status: "active", title: "Task t-base", updatedAt: todayTs() }
    );

    const after = await readDashboard(HOME);
    const afterMillis = (after["updatedAt"] as admin.firestore.Timestamp).toMillis();
    // Sin reconstrucción: el dashboard conserva exactamente el mismo updatedAt.
    expect(afterMillis).toBe(beforeMillis);
  });
});
