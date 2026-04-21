// lib/features/members/application/members_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/free_limits.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/member.dart';
import 'members_provider.dart';

part 'members_view_model.g.dart';

class MembersViewData {
  const MembersViewData({
    required this.activeMembers,
    required this.frozenMembers,
    required this.canInvite,
    required this.homeId,
    required this.isPremium,
    required this.activeMembersCount,
    required this.maxMembersFree,
    required this.freeLimitReached,
  });
  final List<Member> activeMembers;
  final List<Member> frozenMembers;
  /// True cuando rol permite invitar Y no se ha alcanzado el límite Free.
  final bool canInvite;
  final String homeId;
  final bool isPremium;
  final int activeMembersCount;
  final int maxMembersFree;
  /// True cuando el hogar es Free y `activeMembersCount >= maxMembersFree`.
  final bool freeLimitReached;
}

abstract class MembersViewModel {
  AsyncValue<MembersViewData?> get viewData;
}

class _MembersViewModelImpl implements MembersViewModel {
  const _MembersViewModelImpl({required this.viewData});
  @override
  final AsyncValue<MembersViewData?> viewData;
}

@riverpod
MembersViewModel membersViewModel(MembersViewModelRef ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final auth = ref.watch(authProvider);
  final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final myMembership = membershipsAsync?.valueOrNull
        ?.where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final roleCanInvite = myMembership?.role == MemberRole.owner ||
        myMembership?.role == MemberRole.admin;

    final membersAsync = ref.watch(homeMembersProvider(home.id));
    final allMembers = membersAsync.valueOrNull ?? [];
    final activeMembers =
        allMembers.where((m) => m.status == MemberStatus.active).toList();
    final frozenMembers =
        allMembers.where((m) => m.status == MemberStatus.frozen).toList();

    // Free plan gating: obtenemos premium/counters del dashboard. Fallback
    // conservador: asumimos Premium hasta que llegue el dashboard (el backend
    // siempre es el backstop).
    final dashboard = ref.watch(dashboardProvider).valueOrNull;
    final isPremium = dashboard?.premiumFlags.isPremium ?? true;
    final activeMembersCount =
        dashboard?.planCounters.activeMembers ?? activeMembers.length;
    const maxMembersFree = FreeLimits.maxActiveMembers;
    final freeLimitReached =
        !isPremium && activeMembersCount >= maxMembersFree;

    return MembersViewData(
      activeMembers: activeMembers,
      frozenMembers: frozenMembers,
      canInvite: roleCanInvite && !freeLimitReached,
      homeId: home.id,
      isPremium: isPremium,
      activeMembersCount: activeMembersCount,
      maxMembersFree: maxMembersFree,
      freeLimitReached: freeLimitReached,
    );
  });

  return _MembersViewModelImpl(viewData: viewData);
}
