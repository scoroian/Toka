// lib/features/tasks/application/all_tasks_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
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

class AllTasksViewData {
  const AllTasksViewData({
    required this.tasks,
    required this.filter,
    required this.canCreate,
    required this.uid,
    required this.homeId,
  });
  final List<Task> tasks;
  final AllTasksFilter filter;
  final bool canCreate;
  final String uid;
  final String homeId;
}

abstract class AllTasksViewModel {
  AsyncValue<AllTasksViewData?> get viewData;
  void setStatusFilter(TaskStatus s);
  void setAssigneeFilter(String? uid);
  Future<void> toggleFreeze(Task task);
  Future<void> deleteTask(Task task);
}

class _AllTasksViewModelImpl implements AllTasksViewModel {
  const _AllTasksViewModelImpl({
    required this.viewData,
    required this.ref,
  });

  @override
  final AsyncValue<AllTasksViewData?> viewData;
  final Ref ref;

  @override
  void setStatusFilter(TaskStatus s) =>
      ref.read(allTasksFilterNotifierProvider.notifier).setStatus(s);

  @override
  void setAssigneeFilter(String? uid) =>
      ref.read(allTasksFilterNotifierProvider.notifier).setAssignee(uid);

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
}

@riverpod
AllTasksViewModel allTasksViewModel(AllTasksViewModelRef ref) {
  final filter = ref.watch(allTasksFilterNotifierProvider);
  final homeAsync = ref.watch(currentHomeProvider);
  final authState = ref.watch(authProvider);
  final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final homeMembersAsync = ref.watch(homeMembersProvider(home.id));
    final homeMembers = homeMembersAsync.valueOrNull;
    if (homeMembers == null) return null; // still loading
    final myMember = homeMembers
        .where((m) => m.uid == uid)
        .cast<Member?>()
        .firstOrNull;
    final canCreate =
        myMember?.role == MemberRole.owner || myMember?.role == MemberRole.admin;

    final tasksAsync = ref.watch(homeTasksProvider(home.id));
    final allTasks = tasksAsync.valueOrNull ?? [];

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
      canCreate: canCreate,
      uid: uid,
      homeId: home.id,
    );
  });

  return _AllTasksViewModelImpl(viewData: viewData, ref: ref);
}
