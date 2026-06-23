// functions/src/tasks/dashboard_delta.test.ts
//
// Hallazgo #16 (premortem): el dashboard era un "hot document" que se
// reconstruía ENTERO (lee todos los miembros + tareas + eventos y hace .set())
// en cada completar/pasar turno, fuera de transacción (lost-update race) y con
// fan-out ciego a todas las memberships. La corrección añade una actualización
// INCREMENTAL (delta) en la ruta caliente: muta solo la entrada de la tarea
// afectada y recalcula los agregados desde los arrays en memoria, sin releer
// Firestore. El rebuild completo (trigger/cron) sigue como red de seguridad.
//
// Aquí cubrimos la lógica PURA `applyDashboardDelta` (sin emulador).

import { applyDashboardDelta, type DashboardData, type DayBoundsMs } from "./dashboard_delta";

// Día "hoy" = [1000, 2000) en ms (valores ficticios para clasificar).
const BOUNDS: DayBoundsMs = { startMs: 1000, endMs: 2000 };

// Timestamp-like opaco: el delta no lo interpreta, solo lo arrastra.
const ts = (millis: number) => ({ __ts: millis });

function baseDashboard(): DashboardData {
  return {
    activeTasksPreview: [
      {
        taskId: "t1",
        title: "Fregar",
        visualKind: "emoji",
        visualValue: "🧹",
        recurrenceType: "daily",
        currentAssigneeUid: "u1",
        currentAssigneeName: "Ana",
        currentAssigneePhoto: null,
        nextDueAt: ts(1500), // hoy
        isOverdue: false,
        isDueToday: true,
        status: "active",
      },
      {
        taskId: "t2",
        title: "Basura",
        visualKind: "emoji",
        visualValue: "🗑️",
        recurrenceType: "oneTime",
        currentAssigneeUid: "u2",
        currentAssigneeName: "Bob",
        currentAssigneePhoto: null,
        nextDueAt: ts(1600), // hoy
        isOverdue: false,
        isDueToday: true,
        status: "active",
      },
    ],
    doneTasksPreview: [],
    counters: {
      totalActiveTasks: 2,
      totalMembers: 2,
      tasksDueToday: 2,
      tasksDoneToday: 0,
    },
    planCounters: {
      activeMembers: 2,
      activeTasks: 2,
      automaticRecurringTasks: 1, // solo t1 (daily); t2 es oneTime
      totalAdmins: 1,
    },
    memberPreview: [
      { uid: "u1", name: "Ana", photoUrl: null, role: "owner", status: "active", tasksDueCount: 1 },
      { uid: "u2", name: "Bob", photoUrl: null, role: "member", status: "active", tasksDueCount: 1 },
    ],
  };
}

describe("applyDashboardDelta — completar", () => {
  test("oneTime: la tarea sale de activos y entra en hechos; contadores y tasksDueCount se ajustan", () => {
    const res = applyDashboardDelta(
      baseDashboard(),
      {
        kind: "completed",
        taskId: "t2",
        performedByUid: "u2",
        isOneTime: true,
        newAssigneeUid: null,
        newNextDueAt: null,
        newNextDueAtMillis: null,
        completedAt: ts(1700),
      },
      BOUNDS
    );

    expect(res.needsFullRebuild).toBe(false);
    const p = res.patch!;
    // t2 ya no está en activos
    expect(p.activeTasksPreview.map((t) => t.taskId)).toEqual(["t1"]);
    // t2 aparece en hechos con el ejecutor
    expect(p.doneTasksPreview).toHaveLength(1);
    expect(p.doneTasksPreview[0]).toMatchObject({
      taskId: "t2",
      completedByUid: "u2",
      completedByName: "Bob",
    });
    // contadores
    expect(p.counters.totalActiveTasks).toBe(1);
    expect(p.counters.tasksDueToday).toBe(1); // solo t1 sigue venciendo hoy
    expect(p.counters.tasksDoneToday).toBe(1);
    expect(p.counters.totalMembers).toBe(2); // sin cambios
    expect(p.planCounters.activeTasks).toBe(1);
    expect(p.planCounters.automaticRecurringTasks).toBe(1); // t1 sigue
    // tasksDueCount: Bob baja a 0, Ana sigue en 1
    expect(p.memberPreview.find((m) => m.uid === "u2")!.tasksDueCount).toBe(0);
    expect(p.memberPreview.find((m) => m.uid === "u1")!.tasksDueCount).toBe(1);
    // sigue habiendo pendiente hoy (t1)
    expect(res.hasPendingToday).toBe(true);
  });

  test("recurrente con próxima ocurrencia MAÑANA: sigue activa con nuevo asignado e isDueToday=false", () => {
    const res = applyDashboardDelta(
      baseDashboard(),
      {
        kind: "completed",
        taskId: "t1",
        performedByUid: "u1",
        isOneTime: false,
        newAssigneeUid: "u2",
        newNextDueAt: ts(2500), // mañana (>= endMs)
        newNextDueAtMillis: 2500,
        completedAt: ts(1700),
      },
      BOUNDS
    );

    const p = res.patch!;
    const t1 = p.activeTasksPreview.find((t) => t.taskId === "t1")!;
    expect(t1.currentAssigneeUid).toBe("u2");
    expect(t1.currentAssigneeName).toBe("Bob");
    expect(t1.isDueToday).toBe(false);
    expect(t1.isOverdue).toBe(false);
    expect(p.counters.tasksDoneToday).toBe(1);
    // t1 ya no vence hoy → tasksDueToday baja a 1 (solo t2)
    expect(p.counters.tasksDueToday).toBe(1);
    // reasignación de carga: Ana 0, Bob 2 (t2 + t1)
    expect(p.memberPreview.find((m) => m.uid === "u1")!.tasksDueCount).toBe(0);
    expect(p.memberPreview.find((m) => m.uid === "u2")!.tasksDueCount).toBe(2);
  });

  test("recurrente HORARIA cuya próxima ocurrencia es HOY: sigue contando en tasksDueToday", () => {
    const res = applyDashboardDelta(
      baseDashboard(),
      {
        kind: "completed",
        taskId: "t1",
        performedByUid: "u1",
        isOneTime: false,
        newAssigneeUid: "u1",
        newNextDueAt: ts(1800), // misma jornada
        newNextDueAtMillis: 1800,
        completedAt: ts(1700),
      },
      BOUNDS
    );

    const p = res.patch!;
    const t1 = p.activeTasksPreview.find((t) => t.taskId === "t1")!;
    expect(t1.isDueToday).toBe(true);
    // t1 vuelve a vencer hoy + t2 → 2
    expect(p.counters.tasksDueToday).toBe(2);
    expect(p.counters.tasksDoneToday).toBe(1);
  });

  test("completar la última tarea pendiente de hoy → hasPendingToday=false", () => {
    // Hogar con una sola tarea oneTime que vence hoy.
    const d: DashboardData = {
      ...baseDashboard(),
      activeTasksPreview: [
        {
          taskId: "solo",
          title: "Única",
          visualKind: "emoji",
          visualValue: "✅",
          recurrenceType: "oneTime",
          currentAssigneeUid: "u1",
          currentAssigneeName: "Ana",
          currentAssigneePhoto: null,
          nextDueAt: ts(1500),
          isOverdue: false,
          isDueToday: true,
          status: "active",
        },
      ],
      counters: { totalActiveTasks: 1, totalMembers: 2, tasksDueToday: 1, tasksDoneToday: 0 },
      planCounters: { activeMembers: 2, activeTasks: 1, automaticRecurringTasks: 0, totalAdmins: 1 },
      memberPreview: [
        { uid: "u1", name: "Ana", photoUrl: null, role: "owner", status: "active", tasksDueCount: 1 },
        { uid: "u2", name: "Bob", photoUrl: null, role: "member", status: "active", tasksDueCount: 0 },
      ],
    };
    const res = applyDashboardDelta(
      d,
      {
        kind: "completed",
        taskId: "solo",
        performedByUid: "u1",
        isOneTime: true,
        newAssigneeUid: null,
        newNextDueAt: null,
        newNextDueAtMillis: null,
        completedAt: ts(1700),
      },
      BOUNDS
    );
    expect(res.hasPendingToday).toBe(false);
    expect(res.patch!.counters.tasksDueToday).toBe(0);
  });
});

describe("applyDashboardDelta — pasar turno", () => {
  test("solo cambia el asignado en activos y el reparto de tasksDueCount; hechos/contadores intactos", () => {
    const res = applyDashboardDelta(
      baseDashboard(),
      { kind: "passed", taskId: "t1", newAssigneeUid: "u2" },
      BOUNDS
    );

    const p = res.patch!;
    const t1 = p.activeTasksPreview.find((t) => t.taskId === "t1")!;
    expect(t1.currentAssigneeUid).toBe("u2");
    expect(t1.currentAssigneeName).toBe("Bob");
    expect(t1.isDueToday).toBe(true); // pasar NO cambia el vencimiento
    // hechos y contadores de día sin cambios
    expect(p.doneTasksPreview).toHaveLength(0);
    expect(p.counters.tasksDoneToday).toBe(0);
    expect(p.counters.tasksDueToday).toBe(2);
    expect(p.counters.totalActiveTasks).toBe(2);
    // reparto: Ana 0, Bob 2
    expect(p.memberPreview.find((m) => m.uid === "u1")!.tasksDueCount).toBe(0);
    expect(p.memberPreview.find((m) => m.uid === "u2")!.tasksDueCount).toBe(2);
    expect(res.hasPendingToday).toBe(true);
  });
});

describe("applyDashboardDelta — fallback a rebuild completo (drift)", () => {
  test("dashboard sin arrays (nunca construido) → needsFullRebuild", () => {
    const res = applyDashboardDelta(
      {} as unknown as DashboardData,
      { kind: "passed", taskId: "t1", newAssigneeUid: "u2" },
      BOUNDS
    );
    expect(res.needsFullRebuild).toBe(true);
    expect(res.patch).toBeUndefined();
  });

  test("la tarea no está en activos (creada tras el último rebuild) → needsFullRebuild", () => {
    const res = applyDashboardDelta(
      baseDashboard(),
      { kind: "passed", taskId: "desconocida", newAssigneeUid: "u2" },
      BOUNDS
    );
    expect(res.needsFullRebuild).toBe(true);
  });
});
