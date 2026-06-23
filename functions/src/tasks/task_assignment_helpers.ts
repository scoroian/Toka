// functions/src/tasks/task_assignment_helpers.ts

export interface MemberLoadData {
  completionsRecent: number;
  difficultyWeight: number;
  daysSinceLastExecution: number;
}

export function scoreOf(data: MemberLoadData): number {
  return data.completionsRecent * data.difficultyWeight + data.daysSinceLastExecution * -0.1;
}

/** Un evento `taskEvents` de tipo `completed`, reducido a lo que necesita la
 * carga del reparto inteligente: quién completó y cuándo. */
export interface CompletedLoadEvent {
  performerUid: string;
  completedAtMs: number;
}

/**
 * Hallazgo #13: cuenta, por miembro, las tareas completadas dentro de una
 * ventana real de `windowDays` días — la carga del reparto inteligente. Sustituye
 * al contador `completions60d`, que solo se incrementaba y NUNCA decaía, de modo
 * que un miembro muy cumplidor en el pasado quedaba excluido del reparto para
 * siempre. El borde es inclusivo (`completedAtMs >= nowMs - windowDays`). Los
 * eventos sin `performerUid` se ignoran.
 */
export function countCompletionsInWindow(
  events: CompletedLoadEvent[],
  nowMs: number,
  windowDays: number
): Map<string, number> {
  const cutoffMs = nowMs - windowDays * 24 * 60 * 60 * 1000;
  const counts = new Map<string, number>();
  for (const ev of events) {
    if (!ev.performerUid) continue;
    if (ev.completedAtMs < cutoffMs) continue;
    counts.set(ev.performerUid, (counts.get(ev.performerUid) ?? 0) + 1);
  }
  return counts;
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

// `addRecurrenceInterval` (suma de intervalo en UTC) se eliminó en el Hallazgo
// #10: derivaba mal la 2ª ocurrencia (drift de DST + mensual/anual ignoraban la
// regla). La siguiente ocurrencia se calcula ahora con `computeNextDueAt` en
// `recurrence_calculator.ts` (tz-aware, paridad con el cliente).

/**
 * `true` si la recurrencia no produce más ocurrencias tras la primera
 * ejecución. Usado para decidir si una tarea pasa a `status=completedOneTime`
 * al completarla o pasar turno.
 */
export function isTerminalRecurrence(recurrenceType: string): boolean {
  return recurrenceType === "oneTime";
}
