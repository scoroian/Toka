// test/unit/features/tasks/all_tasks_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/all_tasks_view_model.dart';
import 'package:toka/features/tasks/domain/task_status.dart';

void main() {
  group('AllTasksFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() => container.dispose());

    test('initial status is active', () {
      expect(
        container.read(allTasksFilterNotifierProvider).status,
        TaskStatus.active,
      );
    });

    test('setStatus updates status', () {
      container
          .read(allTasksFilterNotifierProvider.notifier)
          .setStatus(TaskStatus.frozen);
      expect(
        container.read(allTasksFilterNotifierProvider).status,
        TaskStatus.frozen,
      );
    });

    test('setAssignee updates assigneeUid', () {
      container
          .read(allTasksFilterNotifierProvider.notifier)
          .setAssignee('uid123');
      expect(
        container.read(allTasksFilterNotifierProvider).assigneeUid,
        'uid123',
      );
    });
  });

  group('AllTasksViewModel — selección múltiple', () {
    test('isSelectionMode false cuando selectedIds está vacío', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final vm = container.read(allTasksViewModelProvider);
      expect(vm.isSelectionMode, isFalse);
      expect(vm.selectedIds, isEmpty);
    });

    test('toggleSelection añade id a selectedIds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(allTasksViewModelProvider).toggleSelection('task_1');
      final vm = container.read(allTasksViewModelProvider);
      expect(vm.selectedIds, contains('task_1'));
      expect(vm.isSelectionMode, isTrue);
    });

    test('toggleSelection sobre id ya seleccionado lo elimina', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(allTasksViewModelProvider).toggleSelection('task_1');
      container.read(allTasksViewModelProvider).toggleSelection('task_1');
      final vm = container.read(allTasksViewModelProvider);
      expect(vm.selectedIds, isNot(contains('task_1')));
      expect(vm.isSelectionMode, isFalse);
    });

    test('clearSelection vacía selectedIds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(allTasksViewModelProvider).toggleSelection('task_1');
      container.read(allTasksViewModelProvider).toggleSelection('task_2');
      container.read(allTasksViewModelProvider).clearSelection();
      final vm = container.read(allTasksViewModelProvider);
      expect(vm.selectedIds, isEmpty);
    });
  });
}
