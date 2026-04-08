// test/unit/features/tasks/dashboard_grouping_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';

TaskPreview _makeTask({
  required String taskId,
  required String recurrenceType,
  required DateTime nextDueAt,
  bool isOverdue = false,
  String title = 'Task',
}) =>
    TaskPreview(
      taskId: taskId,
      title: title,
      visualKind: 'emoji',
      visualValue: '',
      recurrenceType: recurrenceType,
      currentAssigneeUid: null,
      currentAssigneeName: null,
      currentAssigneePhoto: null,
      nextDueAt: nextDueAt,
      isOverdue: isOverdue,
      status: 'active',
    );

DoneTaskPreview _makeDone({
  required String taskId,
  required String recurrenceType,
  String title = 'Done Task',
}) =>
    DoneTaskPreview(
      taskId: taskId,
      title: title,
      visualKind: 'emoji',
      visualValue: '',
      recurrenceType: recurrenceType,
      completedByUid: 'uid1',
      completedByName: 'Ana',
      completedByPhoto: null,
      completedAt: DateTime(2026, 4, 6, 9, 0),
    );

void main() {
  final base = DateTime(2026, 4, 6, 10, 0);

  group('groupByRecurrence', () {
    test('listas vacías retornan mapa vacío', () {
      final result = groupByRecurrence([], []);
      expect(result, isEmpty);
    });

    test('agrupa tareas activas por recurrenceType', () {
      final tasks = [
        _makeTask(taskId: 't1', recurrenceType: 'daily', nextDueAt: base),
        _makeTask(taskId: 't2', recurrenceType: 'weekly', nextDueAt: base),
        _makeTask(taskId: 't3', recurrenceType: 'daily', nextDueAt: base.add(const Duration(hours: 1))),
      ];
      final result = groupByRecurrence(tasks, []);
      expect(result.keys, containsAll(['daily', 'weekly']));
      expect(result['daily']!.todos.length, 2);
      expect(result['weekly']!.todos.length, 1);
    });

    test('agrupa tareas completadas por recurrenceType', () {
      final dones = [
        _makeDone(taskId: 'd1', recurrenceType: 'daily'),
        _makeDone(taskId: 'd2', recurrenceType: 'daily'),
        _makeDone(taskId: 'd3', recurrenceType: 'monthly'),
      ];
      final result = groupByRecurrence([], dones);
      expect(result['daily']!.dones.length, 2);
      expect(result['monthly']!.dones.length, 1);
      expect(result['daily']!.todos, isEmpty);
    });

    test('ordena tareas: vencidas primero, luego por fecha, luego alfabético', () {
      final tasks = [
        _makeTask(taskId: 't1', recurrenceType: 'daily', nextDueAt: base, title: 'B'),
        _makeTask(taskId: 't2', recurrenceType: 'daily', nextDueAt: base, title: 'A', isOverdue: true),
        _makeTask(taskId: 't3', recurrenceType: 'daily', nextDueAt: base.subtract(const Duration(hours: 1)), title: 'C'),
      ];
      final result = groupByRecurrence(tasks, []);
      final sorted = result['daily']!.todos;
      // t2 (overdue) must be first
      expect(sorted.first.taskId, 't2');
      // Then t3 (earlier date), then t1 (same date as t2 but after, title B > -)
      expect(sorted[1].taskId, 't3');
      expect(sorted[2].taskId, 't1');
    });

    test('combina activas y completadas en el mismo grupo de recurrencia', () {
      final tasks = [
        _makeTask(taskId: 't1', recurrenceType: 'weekly', nextDueAt: base),
      ];
      final dones = [
        _makeDone(taskId: 'd1', recurrenceType: 'weekly'),
      ];
      final result = groupByRecurrence(tasks, dones);
      expect(result['weekly']!.todos.length, 1);
      expect(result['weekly']!.dones.length, 1);
    });

    test('solo alfabético cuando fechas y overdue son iguales', () {
      final tasks = [
        _makeTask(taskId: 't1', recurrenceType: 'monthly', nextDueAt: base, title: 'Lavar'),
        _makeTask(taskId: 't2', recurrenceType: 'monthly', nextDueAt: base, title: 'Barrer'),
        _makeTask(taskId: 't3', recurrenceType: 'monthly', nextDueAt: base, title: 'Fregar'),
      ];
      final result = groupByRecurrence(tasks, []);
      final sorted = result['monthly']!.todos.map((t) => t.title).toList();
      expect(sorted, ['Barrer', 'Fregar', 'Lavar']);
    });
  });
}
