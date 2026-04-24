// functions/src/tasks/pass_turn_helpers.ts

/**
 * Calcula el siguiente miembro elegible para el callable `passTaskTurn`.
 *
 * IMPORTANTE — BUG-06:
 * Este helper SIEMPRE avanza en `assignmentOrder` (saltando miembros frozen /
 * absent). No consulta `onMissAssign`: esa configuración solo aplica al
 * cron de expiración (`processExpiredTasks` → `computeNextAssignee`), que
 * decide qué ocurre cuando una tarea vence sin acción del usuario.
 *
 * Al pasar turno explícitamente el usuario siempre quiere rotar, aunque la
 * política de miss sea `sameAssignee`.
 *
 * Contrato:
 * - `order` vacío → devuelve `currentUid` (nada que rotar).
 * - `order.length === 1` → devuelve `currentUid` (solo un miembro activo,
 *   no hay candidato; el llamante marca `noCandidate = true`).
 * - `order.length === 2` sin frozen → alterna A ↔ B correctamente.
 * - Si todos los demás están frozen → devuelve `currentUid`.
 */
export function getNextEligibleMember(
  order: string[],
  currentUid: string,
  frozenUids: string[]
): string {
  if (!order.length) return currentUid;
  const currentIdx = order.indexOf(currentUid);
  for (let i = 1; i < order.length; i++) {
    const candidate = order[(currentIdx + i) % order.length];
    if (!frozenUids.includes(candidate)) return candidate;
  }
  return currentUid;
}
