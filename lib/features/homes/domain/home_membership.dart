import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_membership.freezed.dart';

enum MemberRole { owner, admin, member, frozen }

enum BillingState { currentPayer, formerPayer, none }

enum MemberStatus { active, frozen, left }

@freezed
class HomeMembership with _$HomeMembership {
  const factory HomeMembership({
    required String homeId,
    required String homeNameSnapshot,
    required MemberRole role,
    required BillingState billingState,
    required MemberStatus status,
    required DateTime joinedAt,
    DateTime? leftAt,
    @Default(false) bool hasPendingToday,
    // Snapshot de la foto del hogar (`homes/{homeId}.photoUrl`) denormalizado
    // en la membership, igual que `homeNameSnapshot`. Lo escribe el backend al
    // unirse/crear y lo mantiene fresco el trigger `syncHomeSnapshotToMemberships`.
    // null cuando el hogar usa la inicial.
    String? homePhotoSnapshot,
  }) = _HomeMembership;
}
