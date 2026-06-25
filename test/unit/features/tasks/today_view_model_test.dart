// test/unit/features/tasks/today_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

void main() {
  group('groupByRecurrence', () {
    test('empty lists produce empty map', () {
      expect(groupByRecurrence([], []), isEmpty);
    });

    test('active tasks grouped by recurrenceType', () {
      final task = TaskPreview(
        taskId: 't1',
        title: 'Limpiar',
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'weekly',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 10),
        isOverdue: false,
        status: 'active',
      );
      final result = groupByRecurrence([task], []);
      expect(result['weekly']!.todos, hasLength(1));
      expect(result['weekly']!.dones, isEmpty);
    });

    test('done tasks grouped by recurrenceType', () {
      final done = DoneTaskPreview(
        taskId: 'd1',
        title: 'Barrer',
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'daily',
        completedByUid: 'uid1',
        completedByName: 'Ana',
        completedByPhoto: null,
        completedAt: DateTime(2026, 4, 7),
      );
      final result = groupByRecurrence([], [done]);
      expect(result['daily']!.dones, hasLength(1));
      expect(result['daily']!.todos, isEmpty);
    });

    test('overdue tasks sorted first within group', () {
      final overdue = TaskPreview(
        taskId: 't_overdue',
        title: 'Barrer',
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 5),
        isOverdue: true,
        status: 'active',
      );
      final onTime = TaskPreview(
        taskId: 't_ok',
        title: 'Fregar',
        visualKind: 'emoji',
        visualValue: '🍽️',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 7),
        isOverdue: false,
        status: 'active',
      );
      final result = groupByRecurrence([onTime, overdue], []);
      expect(result['daily']!.todos.first.taskId, 't_overdue');
    });

    test('tasks with same overdue status sorted by nextDueAt ascending', () {
      final later = TaskPreview(
        taskId: 't_later',
        title: 'Cocinar',
        visualKind: 'emoji',
        visualValue: '🍳',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 9),
        isOverdue: false,
        status: 'active',
      );
      final earlier = TaskPreview(
        taskId: 't_earlier',
        title: 'Desayuno',
        visualKind: 'emoji',
        visualValue: '☕',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 7),
        isOverdue: false,
        status: 'active',
      );
      final result = groupByRecurrence([later, earlier], []);
      expect(result['daily']!.todos.first.taskId, 't_earlier');
    });

    test('tasks with same date sorted alphabetically by title', () {
      final sameDate = DateTime(2026, 4, 7);
      final taskB = TaskPreview(
        taskId: 'tb',
        title: 'Barrer',
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: sameDate,
        isOverdue: false,
        status: 'active',
      );
      final taskA = TaskPreview(
        taskId: 'ta',
        title: 'Aspirar',
        visualKind: 'emoji',
        visualValue: '🌀',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: sameDate,
        isOverdue: false,
        status: 'active',
      );
      final result = groupByRecurrence([taskB, taskA], []);
      expect(result['daily']!.todos.first.taskId, 'ta');
    });

    test('parte activas en todos (accionables hoy) y upcoming (futuras)', () {
      final now = DateTime(2026, 6, 24, 12);
      final actionable = TaskPreview(
        taskId: 't_hoy',
        title: 'Fregar',
        visualKind: 'emoji',
        visualValue: '🍽️',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 6, 24, 18), // hoy, más tarde → accionable
        isOverdue: false,
        status: 'active',
      );
      final upcoming = TaskPreview(
        taskId: 't_manana',
        title: 'Barrer',
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'daily',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 6, 25, 9), // mañana → NO accionable hoy
        isOverdue: false,
        status: 'active',
      );
      final result = groupByRecurrence([upcoming, actionable], [], now: now);
      expect(result['daily']!.todos.map((t) => t.taskId), ['t_hoy']);
      expect(result['daily']!.upcoming.map((t) => t.taskId), ['t_manana']);
      expect(result['daily']!.dones, isEmpty);
    });

    test('upcoming se ordena por nextDueAt ascendente', () {
      final now = DateTime(2026, 6, 24, 12);
      TaskPreview upc(String id, DateTime due) => TaskPreview(
            taskId: id,
            title: id,
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: null,
            currentAssigneeName: null,
            currentAssigneePhoto: null,
            nextDueAt: due,
            isOverdue: false,
            status: 'active',
          );
      final later = upc('later', DateTime(2026, 6, 27, 9));
      final sooner = upc('sooner', DateTime(2026, 6, 25, 9));
      final result = groupByRecurrence([later, sooner], [], now: now);
      expect(result['daily']!.upcoming.map((t) => t.taskId),
          ['sooner', 'later']);
    });

    test('tasks from different recurrence types go to separate groups', () {
      final weekly = TaskPreview(
        taskId: 'tw',
        title: 'Limpiar',
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceType: 'weekly',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 10),
        isOverdue: false,
        status: 'active',
      );
      final monthly = TaskPreview(
        taskId: 'tm',
        title: 'Factura',
        visualKind: 'emoji',
        visualValue: '📄',
        recurrenceType: 'monthly',
        currentAssigneeUid: null,
        currentAssigneeName: null,
        currentAssigneePhoto: null,
        nextDueAt: DateTime(2026, 4, 30),
        isOverdue: false,
        status: 'active',
      );
      final result = groupByRecurrence([weekly, monthly], []);
      expect(result.keys, containsAll(['weekly', 'monthly']));
      expect(result['weekly']!.todos, hasLength(1));
      expect(result['monthly']!.todos, hasLength(1));
    });
  });

  group('excludePendingCompletions', () {
    TaskPreview task(String id) => TaskPreview(
          taskId: id,
          title: 'T $id',
          visualKind: 'emoji',
          visualValue: '🧹',
          recurrenceType: 'daily',
          currentAssigneeUid: 'u1',
          currentAssigneeName: null,
          currentAssigneePhoto: null,
          nextDueAt: DateTime(2026, 4, 7),
          isOverdue: false,
          status: 'active',
        );

    test('sin pendientes devuelve la lista intacta', () {
      final tasks = [task('a'), task('b')];
      expect(excludePendingCompletions(tasks, const {}), tasks);
    });

    test('oculta las tareas con completación pendiente (optimista)', () {
      final result =
          excludePendingCompletions([task('a'), task('b')], const {'a'});
      expect(result.map((t) => t.taskId), ['b']);
    });

    test('un taskId pendiente que no está en la lista no afecta', () {
      final tasks = [task('a')];
      expect(excludePendingCompletions(tasks, const {'zzz'}), tasks);
    });
  });

  group('TodayViewModel.homes — HomeDropdownItem', () {
    test('hasPendingToday true cuando membresía lo indica', () {
      final membership = HomeMembership(
        homeId: 'h1',
        homeNameSnapshot: 'Casa de Ana',
        role: MemberRole.owner,
        billingState: BillingState.none,
        status: MemberStatus.active,
        joinedAt: DateTime(2024),
        hasPendingToday: true,
      );
      final item = HomeDropdownItem.fromMembership(
        membership,
        emoji: '🏠',
        isSelected: true,
      );
      expect(item.hasPendingToday, isTrue);
      expect(item.isSelected, isTrue);
      expect(item.homeId, 'h1');
    });

    test('hasPendingToday false cuando membresía tiene false', () {
      final membership = HomeMembership(
        homeId: 'h2',
        homeNameSnapshot: 'Piso',
        role: MemberRole.member,
        billingState: BillingState.none,
        status: MemberStatus.active,
        joinedAt: DateTime(2024),
        hasPendingToday: false,
      );
      final item = HomeDropdownItem.fromMembership(
        membership,
        emoji: '🏡',
        isSelected: false,
      );
      expect(item.hasPendingToday, isFalse);
    });
  });
}
