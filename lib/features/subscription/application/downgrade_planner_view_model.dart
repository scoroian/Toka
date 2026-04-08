// lib/features/subscription/application/downgrade_planner_view_model.dart
// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import 'paywall_provider.dart';

part 'downgrade_planner_view_model.freezed.dart';
part 'downgrade_planner_view_model.g.dart';

const _kMaxFreeMembers = 3;
const _kMaxFreeTasks = 4;

abstract class DowngradePlannerViewModel {
  Set<String> get selectedMemberIds;
  Set<String> get selectedTaskIds;
  bool get isLoading;
  bool get savedSuccessfully;
  void toggleMember(String uid, bool checked);
  void toggleTask(String id, bool checked);
  Future<void> savePlan();
}

class DowngradePlannerViewData {
  const DowngradePlannerViewData({
    required this.activeMembers,
    required this.tasks,
    required this.ownerUid,
  });
  final List<Member> activeMembers;
  final List<(String id, String title)> tasks;
  final String ownerUid;
}

@freezed
class _DowngradeVMState with _$DowngradeVMState {
  const factory _DowngradeVMState({
    @Default({}) Set<String> selectedMemberIds,
    @Default({}) Set<String> selectedTaskIds,
    @Default(false) bool initialized,
    @Default(false) bool isLoading,
    @Default(false) bool savedSuccessfully,
  }) = __DowngradeVMState;
}

@riverpod
class DowngradePlannerViewModelNotifier
    extends _$DowngradePlannerViewModelNotifier
    implements DowngradePlannerViewModel {
  @override
  _DowngradeVMState build() {
    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    if (homeId != null) {
      final membersAsync = ref.watch(homeMembersProvider(homeId));
      final dashAsync = ref.watch(dashboardProvider);
      membersAsync.whenData((members) {
        dashAsync.whenData((dash) {
          if (dash != null && !state.initialized) {
            Future.microtask(() => state = state.copyWith(
                  initialized: true,
                  selectedMemberIds: members
                      .where((m) => m.status == MemberStatus.active)
                      .map((m) => m.uid)
                      .toSet(),
                  selectedTaskIds: dash.activeTasksPreview
                      .map((t) => t.taskId)
                      .toSet(),
                ));
          }
        });
      });
    }
    return const _DowngradeVMState();
  }

  @override
  Set<String> get selectedMemberIds => state.selectedMemberIds;

  @override
  Set<String> get selectedTaskIds => state.selectedTaskIds;

  @override
  bool get isLoading => state.isLoading;

  @override
  bool get savedSuccessfully => state.savedSuccessfully;

  @override
  void toggleMember(String uid, bool checked) {
    final next = Set<String>.from(state.selectedMemberIds);
    if (checked) {
      if (next.length < _kMaxFreeMembers) next.add(uid);
    } else {
      next.remove(uid);
    }
    state = state.copyWith(selectedMemberIds: next);
  }

  @override
  void toggleTask(String id, bool checked) {
    final next = Set<String>.from(state.selectedTaskIds);
    if (checked) {
      if (next.length < _kMaxFreeTasks) next.add(id);
    } else {
      next.remove(id);
    }
    state = state.copyWith(selectedTaskIds: next);
  }

  @override
  Future<void> savePlan() async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    if (homeId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(paywallProvider.notifier).saveDowngradePlan(
            homeId: homeId,
            memberIds: state.selectedMemberIds.toList(),
            taskIds: state.selectedTaskIds.toList(),
          );
      state = state.copyWith(isLoading: false, savedSuccessfully: true);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

@riverpod
DowngradePlannerViewModel downgradePlannerViewModel(
    DowngradePlannerViewModelRef ref) {
  ref.watch(downgradePlannerViewModelNotifierProvider);
  return ref.read(downgradePlannerViewModelNotifierProvider.notifier);
}
