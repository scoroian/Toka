// lib/features/members/application/member_profile_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../profile/application/member_radar_provider.dart';
import '../../profile/presentation/widgets/radar_chart_widget.dart';
import '../domain/member.dart';
import 'members_provider.dart';

part 'member_profile_view_model.g.dart';

class MemberProfileViewData {
  const MemberProfileViewData({
    required this.member,
    required this.isSelf,
    required this.visiblePhone,
    required this.compliancePct,
    required this.radarEntries,
  });
  final Member member;
  final bool isSelf;
  final String? visiblePhone;
  final String compliancePct;
  final List<RadarEntry> radarEntries;
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
  final radarEntries = radarAsync.valueOrNull ?? [];

  final viewData = memberAsync.whenData((member) => MemberProfileViewData(
        member: member,
        isSelf: isSelf,
        visiblePhone: member.phoneForViewer(isSelf: isSelf),
        compliancePct: (member.complianceRate * 100).toStringAsFixed(1),
        radarEntries: radarEntries,
      ));

  return _MemberProfileViewModelImpl(viewData: viewData);
}
