// lib/features/members/application/member_profile_view_model.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../profile/application/member_radar_provider.dart';
import '../../profile/presentation/widgets/radar_chart_widget.dart';
import '../domain/member.dart';
import 'members_provider.dart';

part 'member_profile_view_model.g.dart';

/// Entrada para tareas fuera del radar (cuando el miembro tiene >10 tareas).
class OverflowEntry {
  const OverflowEntry({
    required this.taskId,
    required this.title,
    required this.visualKind,
    required this.visualValue,
    required this.averageScore,
  });
  final String taskId;
  final String title;
  final String visualKind;
  final String visualValue;
  final double averageScore;
}

class MemberProfileViewData {
  const MemberProfileViewData({
    required this.member,
    required this.isSelf,
    required this.visiblePhone,
    required this.compliancePct,
    required this.radarEntries,
    required this.canManageRoles,
    required this.completedCount,
    required this.streakCount,
    required this.averageScore,
    required this.showRadar,
    required this.overflowEntries,
  });
  final Member member;
  final bool isSelf;
  final String? visiblePhone;
  final String compliancePct;
  final List<RadarEntry> radarEntries;
  final bool canManageRoles;
  final int completedCount;
  final int streakCount;
  final double averageScore;
  final bool showRadar;
  final List<OverflowEntry> overflowEntries;
}

abstract class MemberProfileViewModel {
  AsyncValue<MemberProfileViewData?> get viewData;
}

class _MemberProfileViewModelImpl implements MemberProfileViewModel {
  const _MemberProfileViewModelImpl({required this.viewData});
  @override
  final AsyncValue<MemberProfileViewData?> viewData;
}

// Moved from member_profile_screen.dart
@riverpod
Future<Member> memberDetail(
    MemberDetailRef ref, String homeId, String uid) async {
  return ref.watch(membersRepositoryProvider).fetchMember(homeId, uid);
}

@riverpod
MemberProfileViewModel memberProfileViewModel(
  MemberProfileViewModelRef ref, {
  required String homeId,
  required String memberUid,
}) {
  final auth = ref.watch(authProvider);
  final currentUid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
  final isSelf = currentUid == memberUid;

  final memberAsync = ref.watch(memberDetailProvider(homeId, memberUid));
  final radarAsync =
      ref.watch(memberRadarProvider(homeId: homeId, uid: memberUid));
  final allRadarEntries = radarAsync.valueOrNull ?? [];

  // Radar logic: min 3 to show, max 10 in chart, rest in overflow
  const minRadarEntries = 3;
  const maxRadarEntries = 10;
  final showRadar = allRadarEntries.length >= minRadarEntries;
  final visibleRadarEntries = allRadarEntries.take(maxRadarEntries).toList();
  final overflowEntries = allRadarEntries.skip(maxRadarEntries).map((e) =>
      OverflowEntry(
        taskId: e.taskId,
        title: e.taskName,
        visualKind: 'emoji',
        visualValue: '',
        averageScore: e.avgScore,
      )).toList();

  // Determine if current user can manage roles: must be owner, and not viewing self
  final members = ref.watch(homeMembersProvider(homeId)).valueOrNull ?? [];
  final myMember = members.where((m) => m.uid == currentUid).firstOrNull;
  final isOwner = myMember?.role == MemberRole.owner;
  final canManageRoles = isOwner && !isSelf;

  final viewData = memberAsync.whenData((member) => MemberProfileViewData(
        member: member,
        isSelf: isSelf,
        visiblePhone: member.phoneForViewer(isSelf: isSelf),
        compliancePct: (member.complianceRate * 100).toStringAsFixed(1),
        radarEntries: visibleRadarEntries,
        canManageRoles: canManageRoles,
        completedCount: member.tasksCompleted,
        streakCount: member.currentStreak,
        averageScore: member.averageScore,
        showRadar: showRadar,
        overflowEntries: overflowEntries,
      ));

  return _MemberProfileViewModelImpl(viewData: viewData);
}
