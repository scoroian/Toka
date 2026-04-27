// lib/features/homes/domain/invitation.dart
//
// Modelo de invitación pendiente del hogar. Representa un documento
// `homes/{homeId}/invitations/{inviteId}` creado por la callable
// `generateInviteCode` y consumido por la callable `joinHomeByCode`.

class Invitation {
  const Invitation({
    required this.id,
    required this.code,
    required this.createdBy,
    required this.expiresAt,
    required this.createdAt,
    required this.used,
  });

  /// Doc id en Firestore (por convención coincide con `code`).
  final String id;

  /// Código de 6 caracteres alfanuméricos.
  final String code;

  /// uid del miembro que generó el código.
  final String createdBy;

  /// Fecha hasta la cual el código sigue siendo válido.
  final DateTime expiresAt;

  /// Cuándo se creó (server timestamp).
  final DateTime createdAt;

  /// Marca cualquier invitación usada o revocada.
  final bool used;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Pendiente = no usada y no expirada.
  bool get isPending => !used && !isExpired;
}
