import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../data/plus_repository_impl.dart';
import '../domain/plus_entitlement.dart';
import '../domain/plus_repository.dart';
import 'toka_plus_enabled_provider.dart';

part 'plus_provider.g.dart';

/// Repositorio de SOLO LECTURA del entitlement Plus. Override en tests con un
/// fake vía `overrideWithValue`.
@Riverpod(keepAlive: true)
PlusRepository plusRepository(PlusRepositoryRef ref) {
  return PlusRepositoryImpl(FirebaseFirestore.instance);
}

/// Stream del entitlement Plus del USUARIO ACTUAL.
///
/// Se reabre automáticamente cuando cambia el uid autenticado (no mezcla el
/// estado de un usuario con el de otro). Emite `null` si no hay sesión o el doc
/// no existe (sin Plus).
@riverpod
Stream<PlusEntitlement?> plusEntitlement(PlusEntitlementRef ref) {
  final uid = ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
  if (uid == null) return Stream.value(null);
  return ref.watch(plusRepositoryProvider).watch(uid);
}

/// Activación EFECTIVA de Toka Plus para el usuario actual. ÚNICO punto de
/// gating de la UI y CONTRATO para la Fase 5 (cálculo de ads).
///
/// `true` solo si: el flag `toka_plus_enabled` está ON, el doc tiene
/// `active == true`, y no está vencido (`endsAt == null || endsAt > now`).
/// Fail-safe a `false` mientras carga, en error, o sin sesión. Espejo de
/// `isPlusEffectivelyActive` del backend.
@riverpod
bool plusActive(PlusActiveRef ref) {
  if (!ref.watch(tokaPlusEnabledProvider)) return false;
  final ent = ref.watch(plusEntitlementProvider).valueOrNull;
  if (ent == null || !ent.active) return false;
  final endsAt = ent.endsAt;
  if (endsAt != null && !endsAt.isAfter(DateTime.now())) return false;
  return true;
}
