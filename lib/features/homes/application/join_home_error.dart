import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/exceptions.dart';

/// Motivo canónico por el que falla unirse a un hogar. Es el eje común que
/// comparten las DOS entradas de unión (selector multi-hogar y onboarding):
/// clasificar a un `JoinHomeError` y resolver su mensaje con
/// `joinHomeErrorMessage` garantiza que el mismo motivo muestre el mismo texto
/// en ambas (Hallazgo #04, lote UX 2026-06-25).
enum JoinHomeError {
  /// Código de invitación inexistente (`not-found`).
  invalidCode,

  /// Código caducado o ya usado (`deadline-exceeded`).
  expiredCode,

  /// El hogar destino alcanzó el tope de miembros de su tier
  /// (`failed-precondition` + `free_limit_members`, `enforceMemberCapTx`).
  homeFull,

  /// La CUENTA del invitado no tiene plazas de hogar libres (Hallazgo #01:
  /// `resource-exhausted` + `no-account-slots`, `enforceAccountSlotsTx`).
  noAccountSlots,

  /// Rate-limit antifuerza bruta (`resource-exhausted` + `too-many-join-attempts`).
  tooManyAttempts,

  /// Sin permiso para unirse (`permission-denied`).
  permissionDenied,

  /// Sin conexión (SocketException).
  network,

  /// Motivo desconocido → mensaje genérico.
  unexpected,
}

/// Fuente de verdad ÚNICA del mapeo `FirebaseFunctionsException` → excepción de
/// dominio para `joinHomeByCode`. La usan AMBOS repos (`HomesRepositoryImpl` y
/// `HomeCreationRepositoryImpl`) para que selector y onboarding produzcan
/// EXACTAMENTE las mismas excepciones tipadas.
///
/// Mapea por el `code` ESPECÍFICO (no por la categoría genérica). Donde el
/// backend reusa un mismo `code` para dos motivos (`resource-exhausted`), los
/// distingue por el `message`.
///
/// Para un `code` desconocido devuelve el MISMO [e] (identidad preservada) para
/// que el caller pueda hacer `rethrow` sin perder el error original.
Exception mapJoinHomeException(FirebaseFunctionsException e) {
  switch (e.code) {
    case 'not-found':
      return const InvalidInviteCodeException();
    case 'deadline-exceeded':
      return const ExpiredInviteCodeException();
    case 'resource-exhausted':
      // Dos motivos comparten code: el cap de plazas de cuenta del invitado
      // (Hallazgo #01) y el rate-limit. Se distinguen por el mensaje.
      if ((e.message ?? '').contains('no-account-slots')) {
        return const NoAccountSlotsException();
      }
      return const TooManyAttemptsException();
    case 'failed-precondition':
      // El único `failed-precondition` que produce `joinHomeByCode` es el tope
      // de miembros del hogar (`enforceMemberCapTx` → `free_limit_members`). Lo
      // mapeamos por ese motivo concreto: si algún día el backend añade otro
      // `failed-precondition`, su mensaje NO contendrá `free_limit_members` y
      // caerá al genérico en vez de mentir con "hogar lleno".
      if ((e.message ?? '').contains('free_limit_members')) {
        return const MaxMembersReachedException();
      }
      return e;
    default:
      return e;
  }
}

/// Clasifica cualquier error de unión a un [JoinHomeError].
///
/// Acepta tanto las excepciones de dominio tipadas (lo que devuelven los repos
/// vía [mapJoinHomeException]) como un `FirebaseFunctionsException` crudo o una
/// `SocketException`. El FFE crudo se reclasifica delegando en
/// [mapJoinHomeException] (red de seguridad: nunca cae al genérico ante un
/// motivo conocido aunque el error no haya pasado por el repo).
JoinHomeError classifyJoinHomeError(Object error) {
  if (error is InvalidInviteCodeException) return JoinHomeError.invalidCode;
  if (error is ExpiredInviteCodeException) return JoinHomeError.expiredCode;
  if (error is MaxMembersReachedException) return JoinHomeError.homeFull;
  if (error is NoAccountSlotsException) return JoinHomeError.noAccountSlots;
  if (error is TooManyAttemptsException) return JoinHomeError.tooManyAttempts;
  if (error is SocketException) return JoinHomeError.network;
  if (error is FirebaseFunctionsException) {
    final mapped = mapJoinHomeException(error);
    // Si el code era conocido, `mapped` es una excepción de dominio: la
    // reclasificamos (no recursa con un FFE porque ya no lo es).
    if (!identical(mapped, error)) return classifyJoinHomeError(mapped);
    // `permission-denied` no tiene excepción de dominio (no es un error de
    // negocio del join): se clasifica aquí directamente.
    if (error.code == 'permission-denied') {
      return JoinHomeError.permissionDenied;
    }
  }
  return JoinHomeError.unexpected;
}
