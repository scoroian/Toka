// functions/src/tasks/dashboard_delta.ts
//
// Hallazgo #16 (premortem): actualización INCREMENTAL del dashboard.
//
// `homes/{homeId}/views/dashboard` es un "hot document": antes se reconstruía
// ENTERO (lee todos los miembros + tareas activas + eventos de hoy y hace un
// `.set()` completo) en CADA completar/pasar turno, fuera de transacción. Esto
// daba (a) lecturas O(miembros+tareas+eventos) por acción, (b) una lost-update
// race entre reconstrucciones concurrentes (la que lee antes pero escribe
// después pisa el estado más nuevo → una tarea "reaparece") y (c) un fan-out
// ciego de escrituras a TODAS las memberships.
//
// Esta lógica PURA aplica el cambio de UNA acción (completar/pasar) sobre el
// documento del dashboard ya cargado, mutando solo la entrada de la tarea
// afectada y RECALCULANDO los agregados desde los arrays en memoria
// (`activeTasksPreview`/`doneTasksPreview`). No lee Firestore: el wrapper
// transaccional (`update_dashboard.ts`) lee el doc, llama aquí y reescribe en
// una transacción (serializable → sin lost-update), tocando las memberships
// SOLO cuando `hasPendingToday` cambia de valor.
//
// Es una aproximación inmediata "suficientemente buena": el rebuild completo
// (trigger `onTaskWriteUpdateDashboard` + cron diario) sigue siendo la fuente de
// verdad y reconcilia cualquier deriva. Si el dashboard no existe o la tarea no
// está en el preview (deriva), devuelve `needsFullRebuild` y el wrapper cae al
// rebuild completo.

/** Límites del día actual del hogar en milisegundos UTC (de `DayBounds`). */
export interface DayBoundsMs {
  startMs: number;
  endMs: number;
}

export interface DashboardTaskPreview {
  taskId: string;
  title: unknown;
  visualKind: unknown;
  visualValue: unknown;
  recurrenceType: string;
  currentAssigneeUid: string | null;
  currentAssigneeName: string | null;
  currentAssigneePhoto: unknown;
  nextDueAt: unknown;
  isOverdue: boolean;
  isDueToday: boolean;
  status: string;
  [key: string]: unknown;
}

export interface DashboardMemberPreview {
  uid: string;
  name: unknown;
  photoUrl: unknown;
  role: unknown;
  status: unknown;
  tasksDueCount: number;
  [key: string]: unknown;
}

export interface DashboardCounters {
  totalActiveTasks: number;
  totalMembers: number;
  tasksDueToday: number;
  tasksDoneToday: number;
}

export interface DashboardPlanCounters {
  activeMembers: number;
  activeTasks: number;
  automaticRecurringTasks: number;
  totalAdmins: number;
}

export interface DashboardData {
  activeTasksPreview: DashboardTaskPreview[];
  doneTasksPreview: Record<string, unknown>[];
  counters: DashboardCounters;
  planCounters: DashboardPlanCounters;
  memberPreview: DashboardMemberPreview[];
}

/** Cambio derivado de completar una tarea. */
export interface CompletionChange {
  kind: "completed";
  taskId: string;
  /** Quién la completó (asignado anterior). */
  performedByUid: string;
  /** True si era puntual (`oneTime`): deja de estar activa. */
  isOneTime: boolean;
  /** Próximo asignado (recurrente); `null` si era puntual. */
  newAssigneeUid: string | null;
  /** Valor opaco (Timestamp) a guardar como `nextDueAt` (recurrente). */
  newNextDueAt: unknown;
  /** Próximo vencimiento en ms para clasificar (recurrente); `null` si puntual. */
  newNextDueAtMillis: number | null;
  /** Valor opaco (Timestamp) del instante de completado, para el preview de hechos. */
  completedAt: unknown;
}

/** Cambio derivado de pasar turno. */
export interface PassChange {
  kind: "passed";
  taskId: string;
  newAssigneeUid: string;
}

export type DashboardChange = CompletionChange | PassChange;

export interface DashboardDeltaResult {
  /** Si true, el wrapper debe caer al rebuild completo (doc ausente o deriva). */
  needsFullRebuild: boolean;
  /** Campos del dashboard a reescribir (solo si `needsFullRebuild=false`). */
  patch?: {
    activeTasksPreview: DashboardTaskPreview[];
    doneTasksPreview: Record<string, unknown>[];
    counters: DashboardCounters;
    planCounters: DashboardPlanCounters;
    memberPreview: DashboardMemberPreview[];
  };
  /** Valor recomputado del flag home-level `hasPendingToday`. */
  hasPendingToday?: boolean;
}

function classify(millis: number, bounds: DayBoundsMs): { isOverdue: boolean; isDueToday: boolean } {
  if (millis < bounds.startMs) return { isOverdue: true, isDueToday: false };
  if (millis < bounds.endMs) return { isOverdue: false, isDueToday: true };
  return { isOverdue: false, isDueToday: false };
}

/**
 * Aplica el cambio de UNA acción sobre el dashboard cargado y devuelve los
 * campos a reescribir + el `hasPendingToday` recomputado. Función pura.
 */
export function applyDashboardDelta(
  current: DashboardData,
  change: DashboardChange,
  bounds: DayBoundsMs
): DashboardDeltaResult {
  // Doc nunca construido (o sin los arrays que necesitamos) → rebuild completo.
  if (
    !current ||
    !Array.isArray(current.activeTasksPreview) ||
    !Array.isArray(current.memberPreview) ||
    !current.counters ||
    !current.planCounters
  ) {
    return { needsFullRebuild: true };
  }

  // Copias superficiales mutables.
  const active = current.activeTasksPreview.map((t) => ({ ...t }));
  const done = (current.doneTasksPreview ?? []).map((d) => ({ ...d }));
  const members = current.memberPreview.map((m) => ({ ...m }));

  const idx = active.findIndex((t) => t.taskId === change.taskId);
  if (idx === -1) {
    // La tarea no está en el preview (creada tras el último rebuild, o ya
    // completada por otra vía): no podemos aplicar un delta fiable.
    return { needsFullRebuild: true };
  }
  const task = active[idx];

  const memberName = (uid: string | null): string | null => {
    if (!uid) return null;
    const m = members.find((mm) => mm.uid === uid);
    return m ? ((m.name as string | null) ?? null) : null;
  };
  const memberPhoto = (uid: string | null): unknown => {
    if (!uid) return null;
    const m = members.find((mm) => mm.uid === uid);
    return m ? (m.photoUrl ?? null) : null;
  };

  if (change.kind === "completed") {
    // 1. Añadir entrada al preview de "hechos hoy".
    done.unshift({
      taskId: change.taskId,
      title: task.title ?? "",
      visualKind: task.visualKind ?? "emoji",
      visualValue: task.visualValue ?? "",
      recurrenceType: task.recurrenceType ?? "daily",
      completedByUid: change.performedByUid,
      completedByName: memberName(change.performedByUid) ?? "",
      completedByPhoto: memberPhoto(change.performedByUid),
      completedAt: change.completedAt,
    });

    if (change.isOneTime) {
      // 2a. Puntual: sale de activos.
      active.splice(idx, 1);
    } else {
      // 2b. Recurrente: sigue activa con el nuevo asignado y la próxima fecha.
      const cls = classify(change.newNextDueAtMillis ?? 0, bounds);
      active[idx] = {
        ...task,
        currentAssigneeUid: change.newAssigneeUid,
        currentAssigneeName: memberName(change.newAssigneeUid),
        currentAssigneePhoto: memberPhoto(change.newAssigneeUid),
        nextDueAt: change.newNextDueAt,
        isOverdue: cls.isOverdue,
        isDueToday: cls.isDueToday,
      };
    }
  } else {
    // Pasar turno: solo cambia el asignado. No toca vencimiento ni "hechos".
    active[idx] = {
      ...task,
      currentAssigneeUid: change.newAssigneeUid,
      currentAssigneeName: memberName(change.newAssigneeUid),
      currentAssigneePhoto: memberPhoto(change.newAssigneeUid),
    };
  }

  // --- Recalcular agregados desde los arrays mutados ---
  const totalActive = active.length;
  const dueToday = active.filter((t) => t.isDueToday).length;
  const automaticRecurring = active.filter((t) => t.recurrenceType !== "oneTime").length;
  const hasPendingToday = active.some((t) => t.isOverdue || t.isDueToday);

  for (const m of members) {
    m.tasksDueCount = active.filter((t) => t.currentAssigneeUid === m.uid).length;
  }

  const counters: DashboardCounters = {
    totalActiveTasks: totalActive,
    totalMembers: current.counters.totalMembers,
    tasksDueToday: dueToday,
    tasksDoneToday: done.length,
  };
  const planCounters: DashboardPlanCounters = {
    activeMembers: current.planCounters.activeMembers,
    activeTasks: totalActive,
    automaticRecurringTasks: automaticRecurring,
    totalAdmins: current.planCounters.totalAdmins,
  };

  return {
    needsFullRebuild: false,
    patch: {
      activeTasksPreview: active,
      doneTasksPreview: done,
      counters,
      planCounters,
      memberPreview: members,
    },
    hasPendingToday,
  };
}
