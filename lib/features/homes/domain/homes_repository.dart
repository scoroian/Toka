import 'home.dart';
import 'home_membership.dart';

export '../../../core/errors/exceptions.dart'
    show CannotLeaveAsOwnerException, NoAvailableSlotsException;

abstract interface class HomesRepository {
  /// Escucha en tiempo real las membresías del usuario en `users/{uid}/memberships`.
  Stream<List<HomeMembership>> watchUserMemberships(String uid);

  /// Obtiene un hogar por su ID desde `homes/{homeId}`.
  Future<Home> fetchHome(String homeId);

  /// Llama a la Cloud Function `createHome`. Retorna homeId.
  /// Lanza [NoAvailableSlotsException] si el usuario no tiene plazas.
  Future<String> createHome(String name);

  /// Llama a la Cloud Function `joinHome` con el código de invitación.
  Future<void> joinHome(String inviteCode);

  /// Elimina la membresía del usuario del hogar.
  /// Lanza [CannotLeaveAsOwnerException] si el usuario es owner.
  Future<void> leaveHome(String homeId, {required String uid});

  /// Elimina el hogar completo (solo owner). Llama a Cloud Function `closeHome`.
  Future<void> closeHome(String homeId);

  /// Actualiza el campo `lastSelectedHomeId` en `users/{uid}`.
  Future<void> updateLastSelectedHome(String uid, String homeId);

  /// Retorna `baseSlots + lifetimeUnlocked - currentMembershipCount`.
  Future<int> getAvailableSlots(String uid);

  /// Lee el lastSelectedHomeId del usuario desde Firestore.
  Future<String?> getLastSelectedHomeId(String uid);
}
