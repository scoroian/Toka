// lib/features/tasks/application/today_view_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../domain/home_dashboard.dart';
import '../domain/recurrence_order.dart';
import '../presentation/widgets/pass_turn_dialog.dart';
import 'task_completion_provider.dart';
import 'task_pass_provider.dart';

part 'today_view_model.g.dart';

typedef RecurrenceGroup = ({
  List<TaskPreview> todos,
  List<DoneTaskPreview> dones,
});

@visibleForTesting
Map<String, RecurrenceGroup> groupByRecurrence(
  List<TaskPreview> activeTasks,
  List<DoneTaskPreview> doneTasks,
) {
  final result = <String, RecurrenceGroup>{};

  for (final task in activeTasks) {
    final key = task.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: [...(existing?.todos ?? []), task],
      dones: existing?.dones ?? [],
    );
  }

  for (final done in doneTasks) {
    final key = done.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: existing?.todos ?? [],
      dones: [...(existing?.dones ?? []), done],
    );
  }

  // Sort todos within each group
  for (final key in result.keys) {
    final group = result[key]!;
    final sorted = List<TaskPreview>.from(group.todos)
      ..sort((a, b) {
        // 1. Overdue first
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
        // 2. By nextDueAt ascending
        final dateCmp = a.nextDueAt.compareTo(b.nextDueAt);
        if (dateCmp != 0) return dateCmp;
        // 3. Alphabetically
        return a.title.compareTo(b.title);
      });
    result[key] = (todos: sorted, dones: group.dones);
  }

  return result;
}

class TodayViewData {
  const TodayViewData({
    required this.grouped,
    required this.counters,
    required this.showAdBanner,
    required this.adBannerUnit,
    required this.currentUid,
    required this.homeId,
    required this.recurrenceOrder,
  });

  final Map<String, RecurrenceGroup> grouped;
  final DashboardCounters counters;
  final bool showAdBanner;
  final String adBannerUnit;
  final String? currentUid;
  final String homeId;
  final List<String> recurrenceOrder;
}

abstract class TodayViewModel {
  AsyncValue<TodayViewData?> get viewData;
  Future<void> completeTask(String taskId);
  Future<({double complianceBefore, double estimatedAfter})> fetchPassStats(
      String currentUid);
  Future<void> passTurn(String taskId, {String? reason});
  void retry();
}

class _TodayViewModelImpl implements TodayViewModel {
  const _TodayViewModelImpl({
    required this.viewData,
    required this.ref,
  });

  @override
  final AsyncValue<TodayViewData?> viewData;
  final Ref ref;

  String? get _homeId => viewData.valueOrNull?.homeId;

  @override
  Future<void> completeTask(String taskId) async {
    final homeId = _homeId;
    if (homeId == null || homeId.isEmpty) return;
    await ref
        .read(taskCompletionProvider.notifier)
        .completeTask(homeId, taskId);
  }

  @override
  Future<({double complianceBefore, double estimatedAfter})> fetchPassStats(
      String currentUid) async {
    final homeId = _homeId;
    if (homeId == null || homeId.isEmpty) {
      return (complianceBefore: 1.0, estimatedAfter: 1.0);
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(currentUid)
          .get();
      final data = snap.data() ?? {};
      final completed = (data['completedCount'] as int?) ?? 0;
      final passed = (data['passedCount'] as int?) ?? 0;
      final before = (data['complianceRate'] as double?) ??
          completed / (completed + passed).clamp(1, double.maxFinite);
      final after = PassTurnDialog.calcEstimatedCompliance(
        completedCount: completed,
        passedCount: passed,
      );
      return (complianceBefore: before, estimatedAfter: after);
    } catch (_) {
      return (complianceBefore: 1.0, estimatedAfter: 1.0);
    }
  }

  @override
  Future<void> passTurn(String taskId, {String? reason}) async {
    final homeId = _homeId;
    if (homeId == null || homeId.isEmpty) return;
    await ref
        .read(taskPassProvider.notifier)
        .passTurn(homeId, taskId, reason: reason);
  }

  @override
  void retry() => ref.invalidate(dashboardProvider);
}

@riverpod
TodayViewModel todayViewModel(TodayViewModelRef ref) {
  final dashboardAsync = ref.watch(dashboardProvider);
  final auth = ref.watch(authProvider);
  final currentUid = auth.whenOrNull(authenticated: (u) => u.uid);
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';

  final viewData = dashboardAsync.whenData((data) {
    if (data == null) return null;
    return TodayViewData(
      grouped: groupByRecurrence(data.activeTasksPreview, data.doneTasksPreview),
      counters: data.counters,
      showAdBanner: data.adFlags.showBanner,
      adBannerUnit: data.adFlags.bannerUnit,
      currentUid: currentUid,
      homeId: homeId,
      recurrenceOrder: RecurrenceOrder.all,
    );
  });

  return _TodayViewModelImpl(viewData: viewData, ref: ref);
}
