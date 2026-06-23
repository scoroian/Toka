// functions/src/tasks/dashboard_dedup.ts
//
// Guarda PURA para el trigger `onTaskWriteUpdateDashboard` (Hallazgo #07).
// Vive en su propio módulo (sin `admin.firestore()` a nivel de módulo) para
// poder testearla en aislamiento, sin emulador ni inicialización de Admin SDK.

// Campos escalares de la tarea que el dashboard refleja directamente. Un cambio
// en cualquiera de ellos (o en `nextDueAt`) obliga a reconstruir el dashboard.
export const DASHBOARD_RELEVANT_TASK_FIELDS = [
  "status",
  "currentAssigneeUid",
  "title",
  "visualKind",
  "visualValue",
  "recurrenceType",
] as const;

// Detecta un Firestore Timestamp de forma estructural (sin importar admin) y
// devuelve su instante en milisegundos, o null si no es un Timestamp.
function taskTimestampMillis(value: unknown): number | null {
  if (
    value &&
    typeof (value as { toMillis?: () => number }).toMillis === "function"
  ) {
    return (value as { toMillis: () => number }).toMillis();
  }
  return null;
}

/**
 * True si, entre `before` y `after` de una EDICIÓN de tarea, cambió algún campo
 * que el dashboard muestra. Sirve para evitar reconstrucciones inútiles cuando
 * sólo cambian campos internos (p.ej. `updatedAt` o contadores de stats).
 * `nextDueAt` se compara por instante temporal (son Timestamp, no `===`).
 */
export function dashboardRelevantFieldsChanged(
  before: Record<string, unknown>,
  after: Record<string, unknown>
): boolean {
  for (const key of DASHBOARD_RELEVANT_TASK_FIELDS) {
    if (before[key] !== after[key]) return true;
  }
  if (
    taskTimestampMillis(before["nextDueAt"]) !==
    taskTimestampMillis(after["nextDueAt"])
  ) {
    return true;
  }
  return false;
}
