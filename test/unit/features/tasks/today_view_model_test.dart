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
