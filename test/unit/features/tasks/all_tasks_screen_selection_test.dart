import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/all_tasks_view_model.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';

Task _makeTask(String id) => Task(
      id: id,
      homeId: 'home1',
      title: 'Task $id',
      description: null,
      visualKind: 'emoji',
      visualValue: '🧹',
      status: TaskStatus.active,
      recurrenceRule: const RecurrenceRule.daily(every: 1, time: '08:00', timezone: 'UTC'),
      assignmentMode: 'basicRotation',
      assignmentOrder: const [],
      currentAssigneeUid: null,
      nextDueAt: DateTime(2026, 4, 14),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: 'uid1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 4, 14),
    );

void main() {
  group('AllTasksViewData', () {
    test('canManage true se refleja en el ViewData', () {
      final data = AllTasksViewData(
        tasks: [_makeTask('t1')],
        filter: const AllTasksFilter(),
        canManage: true,
        uid: 'u1',
        homeId: 'home1',
      );
      expect(data.canManage, isTrue);
      expect(data.tasks.length, 1);
    });

    test('canManage false oculta acciones de gestión', () {
      final data = AllTasksViewData(
        tasks: [_makeTask('t1'), _makeTask('t2')],
        filter: const AllTasksFilter(),
        canManage: false,
        uid: 'u1',
        homeId: 'home1',
      );
      expect(data.canManage, isFalse);
    });
  });

  group('AllTasksSelectionNotifier', () {
    test('toggle añade taskId cuando no está en el set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(allTasksSelectionNotifierProvider.notifier);

      notifier.toggle('t1');
      expect(container.read(allTasksSelectionNotifierProvider), contains('t1'));
    });

    test('toggle elimina taskId cuando ya está en el set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(allTasksSelectionNotifierProvider.notifier);

      notifier.toggle('t1');
      notifier.toggle('t1');
      expect(container.read(allTasksSelectionNotifierProvider), isNot(contains('t1')));
    });

    test('clear vacía el set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(allTasksSelectionNotifierProvider.notifier);

      notifier.toggle('t1');
      notifier.toggle('t2');
      notifier.clear();
      expect(container.read(allTasksSelectionNotifierProvider), isEmpty);
    });
  });
}
