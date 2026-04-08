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
}
