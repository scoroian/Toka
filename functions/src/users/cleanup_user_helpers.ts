// functions/src/users/cleanup_user_helpers.ts
//
// Helpers PUROS de la limpieza de cuentas borradas (sin dependencias de
// Firestore, testeables en aislamiento). La lógica con efectos vive en
// cleanup_user.ts.

export interface MemberSnapshot {
  uid: string;
  role: string; // owner | admin | member
  status: string; // active | frozen | absent | left
  joinedAtMillis: number;
}

/**
 * Elige el sustituto del owner cuando se borra la cuenta del owner actual.
 *
 * - Excluye al usuario borrado y a los que ya salieron (`status === "left"`).
 * - Prioriza: estado activo > congelado/ausente; a igualdad, rol admin > member;
 *   a igualdad, el miembro más antiguo (joinedAt menor).
 * - Devuelve `null` si no queda ningún candidato (el hogar queda huérfano).
 */
export function pickReplacementOwner(
  members: MemberSnapshot[],
  deletedUid: string
): string | null {
  const candidates = members.filter(
    (m) => m.uid !== deletedUid && m.status !== "left"
  );
  if (!candidates.length) return null;

  const statusRank = (m: MemberSnapshot) => (m.status === "active" ? 0 : 1);
  const roleRank = (m: MemberSnapshot) =>
    m.role === "admin" || m.role === "owner" ? 0 : 1;

  candidates.sort((a, b) => {
    if (statusRank(a) !== statusRank(b)) return statusRank(a) - statusRank(b);
    if (roleRank(a) !== roleRank(b)) return roleRank(a) - roleRank(b);
    return a.joinedAtMillis - b.joinedAtMillis;
  });
  return candidates[0].uid;
}

export interface ReassignResult {
  newOrder: string[];
  newAssignee: string | null;
  changed: boolean;
}

/**
 * Recalcula la asignación de una tarea tras eliminar a `deletedUid`.
 *
 * - Lo quita de `assignmentOrder`.
 * - Si era el responsable actual (`currentAssigneeUid`), elige el primer
 *   miembro elegible restante del orden (no excluido). Si no queda ninguno,
 *   el responsable pasa a `null` (tarea sin responsable, no rompe la UI).
 * - Si no era el responsable, conserva el responsable actual.
 *
 * `excludedUids` = miembros que NO deben recibir la tarea (left/frozen/absent
 * y el propio borrado).
 */
export function computeTaskReassignment(
  assignmentOrder: string[],
  currentAssigneeUid: string | null,
  deletedUid: string,
  excludedUids: string[]
): ReassignResult {
  const newOrder = assignmentOrder.filter((u) => u !== deletedUid);
  const orderChanged = newOrder.length !== assignmentOrder.length;

  if (currentAssigneeUid !== deletedUid) {
    return {
      newOrder,
      newAssignee: currentAssigneeUid,
      changed: orderChanged,
    };
  }

  const eligible = newOrder.filter((u) => !excludedUids.includes(u));
  return {
    newOrder,
    newAssignee: eligible.length ? eligible[0] : null,
    changed: true,
  };
}
