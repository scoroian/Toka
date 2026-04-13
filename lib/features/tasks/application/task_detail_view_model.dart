// lib/features/tasks/application/task_detail_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../../profile/application/profile_provider.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import 'recurrence_provider.dart';
import 'tasks_provider.dart';

part 'task_detail_view_model.g.dart';

class UpcomingOccurrence {
  const UpcomingOccurrence({required this.date, this.assigneeName});
  final DateTime date;
  final String? assigneeName;
}

class TaskDetailViewData {
  const TaskDetailViewData({
    required this.task,
    required this.canManage,
    required this.currentAssigneeName,
    required this.upcomingOccurrences,
  });
  final Task task;
  final bool canManage;
  final String? currentAssigneeName;
  final List<UpcomingOccurrence> upcomingOccurrences;

  bool get isFrozen => task.status == TaskStatus.frozen;
}

abstract class TaskDetailViewModel {
  AsyncValue<TaskDetailViewData?> get viewData;
  Future<void> toggleFreeze();
  Future<void> deleteTask();
}

class _TaskDetailViewModelImpl implements TaskDetailViewModel {
  const _TaskDetailViewModelImpl({required this.viewData, required this.ref});

  @override
  final AsyncValue<TaskDetailViewData?> viewData;
  final Ref ref;

  @override
  Future<void> toggleFreeze() async {
    final data = viewData.valueOrNull;
    if (data == null) return;
    final homeId = data.task.homeId;
    final repo = ref.read(tasksRepositoryProvider);
    if (data.isFrozen) {
      await repo.unfreezeTask(homeId, data.task.id);
    } else {
      await repo.freezeTask(homeId, data.task.id);
    }
  }

  @override
  Future<void> deleteTask() async {
    final data = viewData.valueOrNull;
    if (data == null) return;
    final homeId = data.task.homeId;
    final uid = ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    await ref.read(tasksRepositoryProvider).deleteTask(homeId, data.task.id, uid);
  }
}

// Calcula las próximas N ocurrencias con el asignado según rotación round-robin.
// Empieza por el siguiente después del currentAssigneeUid.
// nameMap: uid → nombre de display (ya resuelto con fallback a perfil).
List<UpcomingOccurrence> _computeUpcomingOccurrences(
    Task task, List<DateTime> dates, Map<String, String?> nameMap) {
  final order = task.assignmentOrder;
  if (order.isEmpty) {
    return dates.map((d) => UpcomingOccurrence(date: d)).toList();
  }
  final currentUid = task.currentAssigneeUid;
  final currentIdx = currentUid != null ? order.indexOf(currentUid) : -1;
  return dates.asMap().entries.map((entry) {
    final i = entry.key;
    final nextIdx = currentIdx >= 0
        ? (currentIdx + 1 + i) % order.length
        : i % order.length;
    final uid = order[nextIdx];
    return UpcomingOccurrence(date: entry.value, assigneeName: nameMap[uid]);
  }).toList();
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

    final homeMembersAsync = ref.watch(homeMembersProvider(home.id));
    final homeMembers = homeMembersAsync.valueOrNull;
    if (homeMembers == null) return null; // still loading

    final myMember =
        homeMembers.where((m) => m.uid == uid).cast<Member?>().firstOrNull;
    final canManage = myMember?.role == MemberRole.owner ||
        myMember?.role == MemberRole.admin;

    // Construir mapa uid→nombre para currentAssignee y assignmentOrder.
    // Primero lee el nickname del documento de miembro (homes/{homeId}/members);
    // si está vacío, hace fallback al perfil del usuario (users/{uid}).
    final relevantUids = <String>{
      if (task.currentAssigneeUid != null) task.currentAssigneeUid!,
      ...task.assignmentOrder,
    };
    final nameMap = <String, String?>{};
    for (final ruid in relevantUids) {
      final m = homeMembers.where((m) => m.uid == ruid).cast<Member?>().firstOrNull;
      if (m != null && m.nickname.isNotEmpty) {
        nameMap[ruid] = m.nickname;
      } else {
        final profile = ref.watch(userProfileProvider(ruid)).valueOrNull;
        nameMap[ruid] = (profile != null && profile.nickname.isNotEmpty)
            ? profile.nickname
            : null;
      }
    }

    final currentAssigneeName = task.currentAssigneeUid != null
        ? nameMap[task.currentAssigneeUid]
        : null;

    final upcomingDates =
        ref.watch(upcomingOccurrencesProvider(task.recurrenceRule));
    final upcomingOccurrences = _computeUpcomingOccurrences(
        task, upcomingDates.take(3).toList(), nameMap);

    return TaskDetailViewData(
      task: task,
      canManage: canManage,
      currentAssigneeName: currentAssigneeName,
      upcomingOccurrences: upcomingOccurrences,
    );
  });

  return _TaskDetailViewModelImpl(viewData: viewData, ref: ref);
}
