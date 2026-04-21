// functions/src/tasks/task_assignment_helpers.ts

export interface MemberLoadData {
  completionsRecent: number;
  difficultyWeight: number;
  daysSinceLastExecution: number;
}

export function scoreOf(data: MemberLoadData): number {
  return data.completionsRecent * data.difficultyWeight + data.daysSinceLastExecution * -0.1;
}

export function getNextAssigneeRoundRobin(
  order: string[],
  currentUid: string,
  excludedUids: string[]
): string | null {
  if (!order.length) return null;
  const eligible = order.filter((uid) => !excludedUids.includes(uid));
  if (!eligible.length) return currentUid;
  const idx = eligible.indexOf(currentUid);
  const nextIdx = (idx + 1) % eligible.length;
  return eligible[nextIdx];
}

export function getNextAssigneeSmart(
  order: string[],
  currentUid: string,
  excludedUids: string[],
  loadData: Map<string, MemberLoadData>
): string {
  const eligible = order.filter((uid) => !excludedUids.includes(uid));
  if (!eligible.length) return currentUid;
  return eligible.reduce((a, b) => {
    const aData = loadData.get(a) ?? { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 };
    const bData = loadData.get(b) ?? { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 };
    return scoreOf(aData) <= scoreOf(bData) ? a : b;
  });
}

export function addRecurrenceInterval(base: Date, recurrenceType: string): Date {
  const d = new Date(base);
  switch (recurrenceType) {
    case "hourly":  d.setUTCHours(d.getUTCHours() + 1); break;
    case "daily":   d.setUTCDate(d.getUTCDate() + 1); break;
    case "weekly":  d.setUTCDate(d.getUTCDate() + 7); break;
    case "monthly": d.setUTCMonth(d.getUTCMonth() + 1); break;
    case "yearly":  d.setUTCFullYear(d.getUTCFullYear() + 1); break;
    // oneTime: no hay siguiente ocurrencia. Devolvemos la base sin modificar;
    // los callers deben tratar oneTime como terminal antes de llamar aquí.
    case "oneTime": break;
  }
  return d;
}

/**
 * `true` si la recurrencia no produce más ocurrencias tras la primera
 * ejecución. Usado para decidir si una tarea pasa a `status=completedOneTime`
 * al completarla o pasar turno.
 */
export function isTerminalRecurrence(recurrenceType: string): boolean {
  return recurrenceType === "oneTime";
}
