// lib/features/tasks/application/task_detail_view_model.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/task.dart';
import 'recurrence_provider.dart';
import 'tasks_provider.dart';

part 'task_detail_view_model.g.dart';

class TaskDetailViewData {
  const TaskDetailViewData({
    required this.task,
    required this.canEdit,
    required this.upcomingOccurrences,
  });
  final Task task;
  final bool canEdit;
  final List<DateTime> upcomingOccurrences;
}

abstract class TaskDetailViewModel {
  AsyncValue<TaskDetailViewData?> get viewData;
}

class _TaskDetailViewModelImpl implements TaskDetailViewModel {
  const _TaskDetailViewModelImpl({required this.viewData});

  @override
  final AsyncValue<TaskDetailViewData?> viewData;
}

@riverpod
TaskDetailViewModel taskDetailViewModel(
    TaskDetailViewModelRef ref, String taskId) {
  final homeAsync = ref.watch(currentHomeProvider);
  final authState = ref.watch(authProvider);
  final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final tasksAsync = ref.watch(homeTasksProvider(home.id));
    final tasks = tasksAsync.valueOrNull ?? [];
    final task = tasks.where((t) => t.id == taskId).cast<Task?>().firstOrNull;
    if (task == null) return null;

    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];
    final myMembership = memberships
        .where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final myRole = myMembership?.role;
    final canEdit =
        myRole == MemberRole.owner || myRole == MemberRole.admin;

    final upcoming =
        ref.watch(upcomingOccurrencesProvider(task.recurrenceRule));

    return TaskDetailViewData(
      task: task,
      canEdit: canEdit,
      upcomingOccurrences: upcoming.take(3).toList(),
    );
  });

  return _TaskDetailViewModelImpl(viewData: viewData);
}
