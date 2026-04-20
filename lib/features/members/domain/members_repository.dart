import '../../../core/errors/exceptions.dart';
import 'member.dart';
import 'vacation.dart';

export '../../../core/errors/exceptions.dart'
    show
        MaxMembersReachedException,
        MaxAdminsReachedException,
        CannotRemoveOwnerException,
        PayerLockedException,
        AlreadyRatedException;

abstract interface class MembersRepository {
  /// Stream de todos los miembros (activos + congelados) del hogar.
  Stream<List<Member>> watchHomeMembers(String homeId);

  /// Obtiene un miembro concreto por su uid.
  Future<Member> fetchMember(String homeId, String uid);

  /// Invita un miembro por email (nullable = solo genera código).
  /// Lanza [MaxMembersReachedException] si el hogar está al límite.
  Future<void> inviteMember(String homeId, String? email);

  /// Genera código de invitación de 6 chars con TTL de 7 días.
  /// Revoca los códigos activos previos del hogar.
  /// Retorna el código y su fecha de expiración.
  Future<({String code, DateTime expiresAt})> generateInviteCode(String homeId);

  /// Observa el código de invitación activo y vigente del hogar.
  /// Emite null si no hay ninguno activo/vigente.
  Stream<({String code, DateTime expiresAt})?> watchActiveInviteCode(String homeId);

  /// Elimina a un miembro del hogar (vía CF).
  /// Lanza [CannotRemoveOwnerException] si el uid es el owner.
  Future<void> removeMember(String homeId, String uid);

  /// Promueve a un miembro a admin (vía CF).
  /// Lanza [MaxAdminsReachedException] en plan Free si ya hay 1 admin.
  Future<void> promoteToAdmin(String homeId, String uid);

  /// Degrada un admin a miembro (vía CF).
  Future<void> demoteFromAdmin(String homeId, String uid);

  /// Transfiere propiedad al nuevo uid (vía CF).
  /// El owner anterior pasa a ser admin.
  Future<void> transferOwnership(String homeId, String newOwnerUid);

  /// Guarda las vacaciones de un miembro.
  Future<void> saveVacation(String homeId, String uid, Vacation vacation);

  /// Observa las vacaciones de un miembro.
  Stream<Vacation?> watchVacation(String homeId, String uid);

  /// Envía una valoración de un evento completado (vía CF submitReview).
  /// Lanza [AlreadyRatedException] si el usuario ya valoró este evento.
  Future<void> submitReview({
    required String homeId,
    required String taskEventId,
    required double score,
    String? note,
  });
}
