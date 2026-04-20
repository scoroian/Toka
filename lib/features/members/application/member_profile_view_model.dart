// lib/features/members/application/member_profile_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../profile/application/member_radar_provider.dart';
import '../../profile/application/profile_provider.dart';
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
    required this.canRemoveMember,
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
  /// True si el usuario actual es owner y puede expulsar a este miembro.
  final bool canRemoveMember;
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
  Future<void> removeMember(String homeId, String uid);
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

  @override
  Future<void> removeMember(String homeId, String uid) =>
      ref.read(membersRepositoryProvider).removeMember(homeId, uid);
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

  // Stream reactivo de todos los miembros del hogar (se actualiza al cambiar rol)
  final allMembersAsync = ref.watch(homeMembersProvider(homeId));
  final allMembers = allMembersAsync.valueOrNull ?? [];

  final myMember = allMembers.cast<Member?>().firstWhere(
        (m) => m?.uid == currentUid,
        orElse: () => null,
      );
  final isOwner = myMember?.role == MemberRole.owner;

  // Derivar el miembro objetivo desde el mismo stream reactivo (en lugar de FutureProvider)
  final memberAsync = allMembersAsync.whenData(
    (members) {
      final found = members.cast<Member?>().firstWhere(
            (m) => m?.uid == memberUid,
            orElse: () => null,
          );
      if (found == null) throw Exception('Member $memberUid not found');
      return found;
    },
  );

  // Fallback al perfil users/{uid} para photoUrl/nickname vacíos en el doc de miembro
  // (mismo enriquecimiento que MembersScreen.enrich para coherencia lista↔detalle)
  final profileFallback = ref.watch(userProfileProvider(memberUid)).valueOrNull;
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

  final viewData = memberAsync.whenData((member) {
    // Enriquecer con datos de users/{uid} si el doc de miembro tiene campos vacíos
    final enriched = member.copyWith(
      nickname: member.nickname.isEmpty &&
              (profileFallback?.nickname.isNotEmpty ?? false)
          ? profileFallback!.nickname
          : member.nickname,
      photoUrl: member.photoUrl ?? profileFallback?.photoUrl,
    );
    final canRemoveMember =
        isOwner && !isSelf && member.role != MemberRole.owner;
    return MemberProfileViewData(
        member: enriched,
        isSelf: isSelf,
        visiblePhone: member.phoneForViewer(isSelf: isSelf),
        compliancePct: (member.complianceRate * 100).toStringAsFixed(1),
        radarEntries: visibleRadarEntries,
        canManageRoles: canManageRoles,
        canRemoveMember: canRemoveMember,
        completedCount: member.tasksCompleted,
        streakCount: member.currentStreak,
        averageScore: member.averageScore,
        showRadar: showRadar,
        overflowEntries: overflowEntries,
      );
  });

  return _MemberProfileViewModelImpl(viewData: viewData, ref: ref);
}
