// Espejo en cliente de functions/src/tasks/pass_turn_helpers.ts.
//
// El diálogo de "Pasar turno" debe anticipar EXACTAMENTE lo que hará el
// backend (regla de negocio #7: la penalización y el siguiente responsable
// deben ser VISIBLES antes de confirmar). Mantener esta lógica idéntica al
// callable `passTaskTurn` evita desinformar al usuario.

/// Calcula el siguiente miembro elegible al pasar turno, replicando
/// `getNextEligibleMember` del backend.
///
/// Siempre avanza en [order] (el `assignmentOrder` de la tarea) saltando los
/// uids en [frozenUids] (miembros `frozen`/`absent`). No consulta
/// `onMissAssign`: pasar turno es una acción explícita que siempre rota.
///
/// Contrato:
/// - [order] vacío → [currentUid] (nada que rotar).
/// - un solo miembro activo → [currentUid] (sin candidato).
/// - 2 miembros sin frozen → alterna A ↔ B.
/// - todos los demás frozen → [currentUid].
String getNextEligibleMember(
  List<String> order,
  String currentUid,
  List<String> frozenUids,
) {
  if (order.isEmpty) return currentUid;
  final currentIdx = order.indexOf(currentUid);
  for (var i = 1; i < order.length; i++) {
    final candidate = order[(currentIdx + i) % order.length];
    if (!frozenUids.contains(candidate)) return candidate;
  }
  return currentUid;
}
