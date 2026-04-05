import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_membership.freezed.dart';

enum MemberRole { owner, admin, member, frozen }

enum BillingState { currentPayer, formerPayer, none }

enum MemberStatus { active, frozen }

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
  }) = _HomeMembership;
}
