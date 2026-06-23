// lib/features/tasks/application/today_view_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../members/application/members_provider.dart';
import '../domain/home_dashboard.dart';
import '../domain/pass_turn_logic.dart';
import '../domain/recurrence_order.dart';
import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import '../presentation/widgets/pass_turn_dialog.dart';
import 'pending_completions_provider.dart';
import 'task_completion_provider.dart';
import 'task_pass_provider.dart';
import 'tasks_provider.dart';

part 'today_view_model.g.dart';

typedef RecurrenceGroup = ({
  List<TaskPreview> todos,
  List<DoneTaskPreview> dones,
});

/// Datos que necesita el diálogo de "Pasar turno": cumplimiento antes/después
/// y el nombre del siguiente responsable (null si no hay candidato).
typedef PassTurnInfo = ({
  double complianceBefore,
  double estimatedAfter,
  String? nextAssigneeName,
});

/// Calcula la información del diálogo de pasar turno tal como lo haría el
/// callable `passTaskTurn`: lee la tarea (para `assignmentOrder`) y la
/// colección de miembros (para detectar congelados/ausentes, resolver el
/// nombre del siguiente responsable y leer los contadores del propio usuario).
///
/// Espejo de getNextEligibleMember en
/// functions/src/tasks/pass_turn_helpers.ts. Función de nivel superior para
/// poder testearla con `FakeFirebaseFirestore`.
/// Réplica cliente de `isMemberCurrentlyAbsent` (functions/src/shared/vacation.ts):
/// true si el miembro tiene una vacación activa cuyo rango incluye HOY (fin de
/// día inclusivo). Mantener en sync con el backend.
bool _isOnVacationNow(dynamic vacationField, [DateTime? now]) {
  if (vacationField is! Map) return false;
  if (vacationField['isActive'] != true) return false;
  final n = now ?? DateTime.now();
  final start = (vacationField['startDate'] as Timestamp?)?.toDate();
  final end = (vacationField['endDate'] as Timestamp?)?.toDate();
  if (start != null && n.isBefore(start)) return false;
  if (end != null && n.isAfter(end.add(const Duration(days: 1)))) return false;
  return true;
}

@visibleForTesting
Future<PassTurnInfo> fetchPassTurnInfo(
  FirebaseFirestore db,
  String homeId,
  String taskId,
  String currentUid,
) async {
  final homeRef = db.collection('homes').doc(homeId);
  // Lanzamos ambas lecturas en paralelo.
  final taskFuture = homeRef.collection('tasks').doc(taskId).get();
  final membersFuture = homeRef.collection('members').get();
  final taskSnap = await taskFuture;
  final membersSnap = await membersFuture;

  final order =
      (taskSnap.data()?['assignmentOrder'] as List<dynamic>?)?.cast<String>() ??
          <String>[currentUid];

  final frozenUids = <String>[];
  final names = <String, String>{};
  var completed = 0;
  var passed = 0;
  for (final doc in membersSnap.docs) {
    final data = doc.data();
    final status = data['status'] as String?;
    // Espejo EXACTO de la exclusión del backend (passTaskTurn): se saltan los
    // ex-miembros ('left', Hallazgo #08), los congelados ('frozen') y quienes
    // tienen una vacación ACTIVA hoy (campo `vacation`, no `status` —
    // isMemberCurrentlyAbsent). Así el preview "siguiente responsable" coincide
    // con quien realmente recibirá el turno (regla de producto #7).
    if (status == 'left' ||
        status == 'frozen' ||
        _isOnVacationNow(data['vacation'])) {
      frozenUids.add(doc.id);
    }
    names[doc.id] = (data['nickname'] as String?) ?? '';
    if (doc.id == currentUid) {
      // El backend migró `completedCount` (legacy) → `tasksCompleted` y borra
      // el primero, así que preferimos `tasksCompleted` con fallback.
      final legacy = (data['completedCount'] as int?) ?? 0;
      completed = (data['tasksCompleted'] as int?) ?? legacy;
      passed = (data['passedCount'] as int?) ?? 0;
    }
  }

  final denom = (completed + passed) == 0 ? 1 : completed + passed;
  final before = completed / denom;
  final after = PassTurnDialog.calcEstimatedCompliance(
    completedCount: completed,
    passedCount: passed,
  );

  final nextUid = getNextEligibleMember(order, currentUid, frozenUids);
  final nextName = nextUid == currentUid ? null : names[nextUid];

  return (
    complianceBefore: before,
    estimatedAfter: after,
    nextAssigneeName:
        (nextName != null && nextName.isNotEmpty) ? nextName : null,
  );
}

/// Filtra las tareas cuya completación está "pendiente" (commit diferido tras
/// tocar Hecho, ver [PendingCompletions]): se ocultan de "Por hacer" de forma
/// optimista mientras dura la ventana de Deshacer. La animación de la tarjeta ya
/// dio el feedback de éxito; el backend aún no se ha tocado.
@visibleForTesting
List<TaskPreview> excludePendingCompletions(
  List<TaskPreview> tasks,
  Set<String> pendingTaskIds,
) {
  if (pendingTaskIds.isEmpty) return tasks;
  return tasks.where((t) => !pendingTaskIds.contains(t.taskId)).toList();
}

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

/// Representa un hogar en el dropdown del selector de pantalla Hoy.
class HomeDropdownItem {
  const HomeDropdownItem({
    required this.homeId,
    required this.name,
    required this.emoji,
    required this.role,
    required this.hasPendingToday,
    required this.isSelected,
  });

  final String homeId;
  final String name;
  final String emoji;
  final MemberRole role;
  final bool hasPendingToday;
  final bool isSelected;

  factory HomeDropdownItem.fromMembership(
    HomeMembership membership, {
    required String emoji,
    required bool isSelected,
  }) =>
      HomeDropdownItem(
        homeId: membership.homeId,
        name: membership.homeNameSnapshot,
        emoji: emoji,
        role: membership.role,
        hasPendingToday: membership.hasPendingToday,
        isSelected: isSelected,
      );
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
  List<HomeDropdownItem> get homes;
  void selectHome(String homeId);
  Future<void> completeTask(String taskId);
  Future<PassTurnInfo> fetchPassInfo(String taskId, String currentUid);
  Future<void> passTurn(String taskId, {String? reason});
  void retry();
}

class _TodayViewModelImpl implements TodayViewModel {
  const _TodayViewModelImpl({
    required this.viewData,
    required this.homes,
    required this.ref,
  });

  @override
  final AsyncValue<TodayViewData?> viewData;
  @override
  final List<HomeDropdownItem> homes;
  final Ref ref;

  String? get _homeId => viewData.valueOrNull?.homeId;

  @override
  void selectHome(String homeId) =>
      ref.read(currentHomeProvider.notifier).switchHome(homeId);

  @override
  Future<void> completeTask(String taskId) async {
    final homeId = _homeId;
    if (homeId == null || homeId.isEmpty) return;
    await ref
        .read(taskCompletionProvider.notifier)
        .completeTask(homeId, taskId);
  }

  @override
  Future<PassTurnInfo> fetchPassInfo(String taskId, String currentUid) async {
    final homeId = _homeId;
    if (homeId == null || homeId.isEmpty) {
      return (
        complianceBefore: 1.0,
        estimatedAfter: 1.0,
        nextAssigneeName: null,
      );
    }
    try {
      return await fetchPassTurnInfo(
        FirebaseFirestore.instance,
        homeId,
        taskId,
        currentUid,
      );
    } catch (_) {
      return (
        complianceBefore: 1.0,
        estimatedAfter: 1.0,
        nextAssigneeName: null,
      );
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

/// Convierte una [Task] en [TaskPreview] usando los miembros para resolver el nombre y foto.
TaskPreview _taskToPreview(
  Task task,
  Map<String, String> memberNames,
  Map<String, String?> memberPhotos,
) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final isOverdue = task.nextDueAt.isBefore(todayStart);
  // Ruta de fallback (sin dashboard): clasificamos en la zona del dispositivo.
  // En la ruta normal manda `isDueToday` que calcula el backend en la zona del
  // hogar (ver TaskPreview).
  final isDueToday =
      !task.nextDueAt.isBefore(todayStart) && task.nextDueAt.isBefore(todayEnd);
  final recurrenceType = switch (task.recurrenceRule) {
    OneTimeRule _ => 'oneTime',
    HourlyRule _ => 'hourly',
    DailyRule _ => 'daily',
    WeeklyRule _ => 'weekly',
    MonthlyFixedRule _ || MonthlyNthRule _ => 'monthly',
    YearlyFixedRule _ || YearlyNthRule _ => 'yearly',
  };
  return TaskPreview(
    taskId: task.id,
    title: task.title,
    visualKind: task.visualKind,
    visualValue: task.visualValue,
    recurrenceType: recurrenceType,
    currentAssigneeUid: task.currentAssigneeUid,
    currentAssigneeName: task.currentAssigneeUid != null
        ? memberNames[task.currentAssigneeUid]
        : null,
    currentAssigneePhoto: task.currentAssigneeUid != null
        ? memberPhotos[task.currentAssigneeUid]
        : null,
    nextDueAt: task.nextDueAt,
    isOverdue: isOverdue,
    isDueToday: isDueToday,
    status: task.status.name,
  );
}

@riverpod
TodayViewModel todayViewModel(TodayViewModelRef ref) {
  final dashboardAsync = ref.watch(dashboardProvider);
  final auth = ref.watch(authProvider);
  final currentUid = auth.whenOrNull(authenticated: (u) => u.uid);
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
  // Completaciones "diferidas" en su ventana de Deshacer: se ocultan de la
  // lista de "Por hacer" hasta que el commit se confirma (o se deshace).
  final pending = ref.watch(pendingCompletionsProvider);

  // Build homes list for the dropdown
  final memberships = currentUid != null
      ? ref.watch(userMembershipsProvider(currentUid)).valueOrNull ?? []
      : <HomeMembership>[];
  final homes = memberships
      .map((m) => HomeDropdownItem.fromMembership(
            m,
            emoji: '🏠', // TODO: read emoji from Home document when available
            isSelected: m.homeId == homeId,
          ))
      .toList();

  final viewData = dashboardAsync.whenData((data) {
    // Dashboard disponible → usarlo directamente
    if (data != null) {
      return TodayViewData(
        grouped: groupByRecurrence(
            excludePendingCompletions(data.activeTasksPreview, pending),
            data.doneTasksPreview),
        counters: data.counters,
        showAdBanner: data.adFlags.showBanner,
        adBannerUnit: data.adFlags.bannerUnit,
        currentUid: currentUid,
        homeId: homeId,
        recurrenceOrder: RecurrenceOrder.all,
      );
    }

    // Dashboard null (no construido aún) → fallback a tareas de Firestore
    if (homeId.isEmpty) return null;

    final tasksAsync = ref.watch(homeTasksProvider(homeId));
    final tasks = tasksAsync.valueOrNull ?? [];
    final activeTasks = tasks
        .where((t) => t.status == TaskStatus.active)
        .toList();
    if (activeTasks.isEmpty) return null;

    final members = ref.watch(homeMembersProvider(homeId)).valueOrNull ?? [];
    final memberNames = {for (final m in members) m.uid: m.nickname};
    final memberPhotos = {for (final m in members) m.uid: m.photoUrl};

    final previews = excludePendingCompletions(
      activeTasks
          .map((t) => _taskToPreview(t, memberNames, memberPhotos))
          .toList(),
      pending,
    );

    return TodayViewData(
      grouped: groupByRecurrence(previews, []),
      counters: DashboardCounters(
        totalActiveTasks: activeTasks.length,
        totalMembers: members.length,
        // Estricto: solo las que vencen hoy (sin vencidas), igual que el backend.
        tasksDueToday: previews.where((t) => t.isDueToday).length,
        tasksDoneToday: 0,
      ),
      showAdBanner: false,
      adBannerUnit: '',
      currentUid: currentUid,
      homeId: homeId,
      recurrenceOrder: RecurrenceOrder.all,
    );
  });

  return _TodayViewModelImpl(viewData: viewData, homes: homes, ref: ref);
}
