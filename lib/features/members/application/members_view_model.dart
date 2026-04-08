// lib/features/members/application/members_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
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
  });
  final List<Member> activeMembers;
  final List<Member> frozenMembers;
  final bool canInvite;
  final String homeId;
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
    final canInvite = myMembership?.role == MemberRole.owner ||
        myMembership?.role == MemberRole.admin;

    final membersAsync = ref.watch(homeMembersProvider(home.id));
    final allMembers = membersAsync.valueOrNull ?? [];

    return MembersViewData(
      activeMembers:
          allMembers.where((m) => m.status == MemberStatus.active).toList(),
      frozenMembers:
          allMembers.where((m) => m.status == MemberStatus.frozen).toList(),
      canInvite: canInvite,
      homeId: home.id,
    );
  });

  return _MembersViewModelImpl(viewData: viewData);
}
