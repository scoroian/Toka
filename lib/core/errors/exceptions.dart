class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  const AuthException([this.message = 'Auth error']);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No network connection']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class LanguagesFetchException implements Exception {
  const LanguagesFetchException([this.message = 'Failed to fetch languages']);
  final String message;
  @override
  String toString() => 'LanguagesFetchException: $message';
}

class InvalidInviteCodeException implements Exception {
  const InvalidInviteCodeException([this.message = 'Invalid invite code']);
  final String message;
  @override
  String toString() => 'InvalidInviteCodeException: $message';
}

class ExpiredInviteCodeException implements Exception {
  const ExpiredInviteCodeException([this.message = 'Invite code expired']);
  final String message;
  @override
  String toString() => 'ExpiredInviteCodeException: $message';
}

class NoAvailableSlotsException implements Exception {
  const NoAvailableSlotsException(
      [this.message = 'No available home slots']);
  final String message;
  @override
  String toString() => 'NoAvailableSlotsException: $message';
}

/// Alias for [NoAvailableSlotsException] kept for backwards compatibility.
typedef NoHomeSlotsException = NoAvailableSlotsException;

/// Hallazgo #01 (lote UX 2026-06-25): el usuario que intenta UNIRSE a un hogar
/// ya no tiene plazas de cuenta libres (su cap de hogares: 2 base + créditos
/// permanentes, máx 5). Es distinto de [NoAvailableSlotsException] (no poder
/// CREAR) y, sobre todo, de [MaxMembersReachedException] ("hogar lleno"): aquí
/// el límite es de la CUENTA del invitado, no del hogar destino.
class NoAccountSlotsException implements Exception {
  const NoAccountSlotsException(
      [this.message = 'No account home slots available to join']);
  final String message;
  @override
  String toString() => 'NoAccountSlotsException: $message';
}

/// Hallazgo #04 (lote UX 2026-06-25): rate-limit antifuerza bruta de
/// `joinHomeByCode` (>10 intentos/hora). El backend lo emite como
/// `resource-exhausted` con mensaje `too-many-join-attempts` — el MISMO code que
/// "sin plazas de cuenta" ([NoAccountSlotsException]), que se distingue por el
/// mensaje. Antes viajaba en crudo como `FirebaseFunctionsException` y cada UI lo
/// interceptaba a mano; ahora es una excepción tipada para unificar el mapeo.
class TooManyAttemptsException implements Exception {
  const TooManyAttemptsException(
      [this.message = 'Too many join attempts, try again later']);
  final String message;
  @override
  String toString() => 'TooManyAttemptsException: $message';
}

class CannotLeaveAsOwnerException implements Exception {
  const CannotLeaveAsOwnerException(
      [this.message = 'Owner must transfer ownership before leaving']);
  final String message;
  @override
  String toString() => 'CannotLeaveAsOwnerException: $message';
}

class MaxMembersReachedException implements Exception {
  const MaxMembersReachedException(
      [this.message = 'Maximum members limit reached']);
  final String message;
  @override
  String toString() => 'MaxMembersReachedException: $message';
}

class MaxAdminsReachedException implements Exception {
  const MaxAdminsReachedException(
      [this.message = 'Maximum admins limit reached (Free plan: 1 admin)']);
  final String message;
  @override
  String toString() => 'MaxAdminsReachedException: $message';
}

class CannotRemoveOwnerException implements Exception {
  const CannotRemoveOwnerException(
      [this.message = 'Cannot remove the home owner']);
  final String message;
  @override
  String toString() => 'CannotRemoveOwnerException: $message';
}

class PayerLockedException implements Exception {
  const PayerLockedException(
      [this.message =
          'Payer cannot leave or be removed while Premium is active']);
  final String message;
  @override
  String toString() => 'PayerLockedException: $message';
}

class AlreadyRatedException implements Exception {
  const AlreadyRatedException(
      [this.message = 'You already reviewed this event']);
  final String message;
  @override
  String toString() => 'AlreadyRatedException: $message';
}
