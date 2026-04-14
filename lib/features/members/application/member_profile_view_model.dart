// lib/features/members/application/member_profile_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  /// True si el usuario actual es owner del hogar y puede promover/degradar.
  final bool canManageRoles;
  final int completedCount;
  final int streakCount;
  final double averageScore;
  final bool showRadar;
  final List<OverflowEntry> overflowEntries;
}

abstract class MemberProfileViewModel {
  AsyncValue<MemberProfileViewData?> get viewData;
  Future<void> promoteToAdmin(String homeId, String uid);
  Future<void> demoteFromAdmin(String homeId, String uid);
}

class _MemberProfileViewModelImpl implements MemberProfileViewModel {
  const _MemberProfileViewModelImpl({
    required this.viewData,
    required this.ref,
  });

  @override
  final AsyncValue<MemberProfileViewData?> viewData;
  final Ref ref;

  @override
  Future<void> promoteToAdmin(String homeId, String uid) =>
      ref.read(membersRepositoryProvider).promoteToAdmin(homeId, uid);

  @override
  Future<void> demoteFromAdmin(String homeId, String uid) =>
      ref.read(membersRepositoryProvider).demoteFromAdmin(homeId, uid);
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

  // Rol del usuario actual en este hogar (para decidir si puede gestionar roles)
  final allMembers = ref.watch(homeMembersProvider(homeId)).valueOrNull ?? [];
  final myMember = allMembers.cast<Member?>().firstWhere(
        (m) => m?.uid == currentUid,
        orElse: () => null,
      );
  final isOwner = myMember?.role == MemberRole.owner;

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

  return _MemberProfileViewModelImpl(viewData: viewData, ref: ref);
}
