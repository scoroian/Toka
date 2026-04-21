// lib/features/tasks/application/task_detail_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../../profile/application/profile_provider.dart';
import '../domain/recurrence_rule.dart';
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
    required this.difficultyWeight,   // ← new
  });
  final Task task;
  final bool canManage;
  final String? currentAssigneeName;
  final List<UpcomingOccurrence> upcomingOccurrences;
  final double difficultyWeight;     // ← new

  bool get isFrozen => task.status == TaskStatus.frozen;
}

abstract class TaskDetailViewModel {
  AsyncValue<TaskDetailViewData?> get viewData;
  Future<void> toggleFreeze(Task task);
  Future<void> deleteTask(Task task);
}

class _TaskDetailViewModelImpl implements TaskDetailViewModel {
  const _TaskDetailViewModelImpl({required this.viewData, required this.ref});

  @override
  final AsyncValue<TaskDetailViewData?> viewData;
  final Ref ref;

  @override
  Future<void> toggleFreeze(Task task) async {
    final homeId = viewData.valueOrNull?.task.homeId;
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
    final uid =
        ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    await ref
        .read(tasksRepositoryProvider)
        .deleteTask(data.task.homeId, task.id, uid);
  }
}

// Calcula las próximas N ocurrencias con el asignado según rotación round-robin.
// Empieza por el siguiente después del currentAssigneeUid.
// nameMap: uid → nombre de display (ya resuelto con fallback a perfil).
List<UpcomingOccurrence> _computeUpcomingOccurrences(
    Task task, List<DateTime> dates, Map<String, String?> nameMap) {
  final order = task.assignmentOrder;
  final timezone = switch (task.recurrenceRule) {
    OneTimeRule r => r.timezone,
    HourlyRule r => r.timezone,
    DailyRule r => r.timezone,
    WeeklyRule r => r.timezone,
    MonthlyFixedRule r => r.timezone,
    MonthlyNthRule r => r.timezone,
    YearlyFixedRule r => r.timezone,
    YearlyNthRule r => r.timezone,
  };
  final location = tz.getLocation(timezone);

  if (order.isEmpty) {
    return dates
        .map((d) => UpcomingOccurrence(date: tz.TZDateTime.from(d, location)))
        .toList();
  }
  final currentUid = task.currentAssigneeUid;
  final currentIdx = currentUid != null ? order.indexOf(currentUid) : -1;
  return dates.asMap().entries.map((entry) {
    final i = entry.key;
    // La primera fecha upcoming es para currentAssigneeUid, las siguientes rotan.
    final nextIdx = currentIdx >= 0
        ? (currentIdx + i) % order.length
        : i % order.length;
    final uid = order[nextIdx];
    return UpcomingOccurrence(
        date: tz.TZDateTime.from(entry.value, location),
        assigneeName: nameMap[uid]);
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
        task, upcomingDates.take(5).toList(), nameMap);

    return TaskDetailViewData(
      task: task,
      canManage: canManage,
      currentAssigneeName: currentAssigneeName,
      upcomingOccurrences: upcomingOccurrences,
      difficultyWeight: task.difficultyWeight,          // ← new
    );
  });

  return _TaskDetailViewModelImpl(viewData: viewData, ref: ref);
}
