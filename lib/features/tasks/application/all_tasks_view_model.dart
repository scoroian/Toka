// lib/features/tasks/application/all_tasks_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import 'tasks_provider.dart';

part 'all_tasks_view_model.freezed.dart';
part 'all_tasks_view_model.g.dart';

@freezed
class AllTasksFilter with _$AllTasksFilter {
  const factory AllTasksFilter({
    @Default(TaskStatus.active) TaskStatus status,
    String? assigneeUid,
  }) = _AllTasksFilter;
}

@riverpod
class AllTasksFilterNotifier extends _$AllTasksFilterNotifier {
  @override
  AllTasksFilter build() => const AllTasksFilter();

  void setStatus(TaskStatus s) => state = state.copyWith(status: s);
  void setAssignee(String? uid) => state = state.copyWith(assigneeUid: uid);
}

@riverpod
class AllTasksSelectionNotifier extends _$AllTasksSelectionNotifier {
  @override
  Set<String> build() => {};

  void toggle(String taskId) {
    final current = Set<String>.from(state);
    if (current.contains(taskId)) {
      current.remove(taskId);
    } else {
      current.add(taskId);
    }
    state = current;
  }

  void clear() => state = {};
}

class AllTasksViewData {
  const AllTasksViewData({
    required this.tasks,
    required this.filter,
    required this.canManage,
    required this.uid,
    required this.homeId,
  });
  final List<Task>     tasks;
  final AllTasksFilter filter;
  final bool           canManage;
  final String         uid;
  final String         homeId;
}

abstract class AllTasksViewModel {
  AsyncValue<AllTasksViewData?> get viewData;
  Set<String> get selectedIds;
  bool get isSelectionMode;
  void setStatusFilter(TaskStatus s);
  void setAssigneeFilter(String? uid);
  void toggleSelection(String taskId);
  void clearSelection();
  Future<void> toggleFreeze(Task task);
  Future<void> deleteTask(Task task);
  Future<void> bulkDelete();
  Future<void> bulkFreeze();
}

class _AllTasksViewModelImpl implements AllTasksViewModel {
  const _AllTasksViewModelImpl({
    required this.viewData,
    required this.selectedIds,
    required this.ref,
  });

  @override
  final AsyncValue<AllTasksViewData?> viewData;
  @override
  final Set<String> selectedIds;
  final Ref ref;

  @override
  bool get isSelectionMode => selectedIds.isNotEmpty;

  @override
  void setStatusFilter(TaskStatus s) =>
      ref.read(allTasksFilterNotifierProvider.notifier).setStatus(s);

  @override
  void setAssigneeFilter(String? uid) =>
      ref.read(allTasksFilterNotifierProvider.notifier).setAssignee(uid);

  @override
  void toggleSelection(String taskId) =>
      ref.read(allTasksSelectionNotifierProvider.notifier).toggle(taskId);

  @override
  void clearSelection() =>
      ref.read(allTasksSelectionNotifierProvider.notifier).clear();

  @override
  Future<void> toggleFreeze(Task task) async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null) return;
    final repo = ref.read(tasksRepositoryProvider);
    if (task.status == TaskStatus.active) {
      await repo.freezeTask(homeId, task.id);
    } else {
      await repo.unfreezeTask(homeId, task.id);
    }
  }

  @override
  Future<void> deleteTask(Task task) async {
    final data = viewData.valueOrNull;
    if (data == null) return;
    await ref
        .read(tasksRepositoryProvider)
        .deleteTask(data.homeId, task.id, data.uid);
  }

  @override
  Future<void> bulkDelete() async {
    final data = viewData.valueOrNull;
    if (data == null || !data.canManage) return;
    final homeId = data.homeId;
    final uid    = data.uid;
    final repo   = ref.read(tasksRepositoryProvider);
    for (final taskId in List.of(selectedIds)) {
      await repo.deleteTask(homeId, taskId, uid);
    }
    clearSelection();
  }

  @override
  Future<void> bulkFreeze() async {
    final data = viewData.valueOrNull;
    if (data == null || !data.canManage) return;
    final homeId = data.homeId;
    final repo   = ref.read(tasksRepositoryProvider);
    for (final task in data.tasks.where((t) => selectedIds.contains(t.id))) {
      if (task.status == TaskStatus.active) {
        await repo.freezeTask(homeId, task.id);
      }
    }
    clearSelection();
  }
}

@riverpod
AllTasksViewModel allTasksViewModel(AllTasksViewModelRef ref) {
  final filter      = ref.watch(allTasksFilterNotifierProvider);
  final homeAsync   = ref.watch(currentHomeProvider);
  final authState   = ref.watch(authProvider);
  final uid         = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';
  final selectedIds = ref.watch(allTasksSelectionNotifierProvider);

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];
    final myMembership = memberships
        .where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final myRole = myMembership?.role;
    final canManage =
        myRole == MemberRole.owner || myRole == MemberRole.admin;

    final tasksAsync = ref.watch(homeTasksProvider(home.id));
    final allTasks   = tasksAsync.valueOrNull ?? [];

    var filtered = allTasks.where((t) => t.status == filter.status).toList();
    if (filter.assigneeUid != null) {
      filtered = filtered
          .where((t) => t.currentAssigneeUid == filter.assigneeUid)
          .toList();
    }
    filtered.sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));

    return AllTasksViewData(
      tasks: filtered,
      filter: filter,
      canManage: canManage,
      uid: uid,
      homeId: home.id,
    );
  });

  return _AllTasksViewModelImpl(
    viewData: viewData,
    selectedIds: selectedIds,
    ref: ref,
  );
}
