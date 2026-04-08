// test/unit/features/tasks/task_form_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/task_form_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';

class _MockTasksRepository extends Mock implements TasksRepository {}

const _dailyRule =
    RecurrenceRule.daily(every: 1, time: '09:00', timezone: 'UTC');

Task _makeTask() => Task(
      id: 't1',
      homeId: 'h1',
      title: 'Limpiar',
      description: null,
      visualKind: 'emoji',
      visualValue: '🧹',
      status: TaskStatus.active,
      recurrenceRule: _dailyRule,
      assignmentMode: 'basicRotation',
      assignmentOrder: const ['u1'],
      currentAssigneeUid: 'u1',
      nextDueAt: DateTime(2026, 4, 10),
      difficultyWeight: 1.0,
      completedCount90d: 5,
      createdByUid: 'u1',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

ProviderContainer _makeContainer([TasksRepository? repo]) {
  return ProviderContainer(overrides: [
    if (repo != null) tasksRepositoryProvider.overrideWithValue(repo),
  ]);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_dailyRule);
    registerFallbackValue(TaskFormMode.create);
    registerFallbackValue(
      const TaskInput(
        title: '',
        visualKind: 'emoji',
        visualValue: '🏠',
        recurrenceRule: RecurrenceRule.daily(every: 1, time: '09:00', timezone: 'UTC'),
        assignmentMode: 'basicRotation',
        assignmentOrder: [],
      ),
    );
  });

  group('TaskFormNotifier — estado inicial', () {
    test('estado inicial es create con campos vacíos', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final state = c.read(taskFormNotifierProvider);
      expect(state.mode, TaskFormMode.create);
      expect(state.title, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.fieldErrors, isEmpty);
    });
  });

  group('TaskFormNotifier — setters', () {
    test('setTitle actualiza el título', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setTitle('Nueva tarea');
      expect(c.read(taskFormNotifierProvider).title, 'Nueva tarea');
    });

    test('setTitle limpia el fieldError de title', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setTitle('X');
      expect(
          c.read(taskFormNotifierProvider).fieldErrors.containsKey('title'),
          isFalse);
    });

    test('setDescription actualiza la descripción', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setDescription('Desc');
      expect(c.read(taskFormNotifierProvider).description, 'Desc');
    });

    test('setVisual actualiza kind y value', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setVisual('icon', 'home');
      final state = c.read(taskFormNotifierProvider);
      expect(state.visualKind, 'icon');
      expect(state.visualValue, 'home');
    });

    test('setRecurrenceRule actualiza la regla', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setRecurrenceRule(_dailyRule);
      expect(c.read(taskFormNotifierProvider).recurrenceRule, equals(_dailyRule));
    });

    test('setAssignmentMode actualiza el modo', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c
          .read(taskFormNotifierProvider.notifier)
          .setAssignmentMode('smartDistribution');
      expect(c.read(taskFormNotifierProvider).assignmentMode,
          'smartDistribution');
    });

    test('setAssignmentOrder actualiza el orden', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c
          .read(taskFormNotifierProvider.notifier)
          .setAssignmentOrder(['u1', 'u2']);
      expect(
          c.read(taskFormNotifierProvider).assignmentOrder, ['u1', 'u2']);
    });

    test('setDifficultyWeight actualiza el peso', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).setDifficultyWeight(2.5);
      expect(c.read(taskFormNotifierProvider).difficultyWeight, 2.5);
    });
  });

  group('TaskFormNotifier — initEdit', () {
    test('initEdit rellena todos los campos con la tarea dada', () {
      final c = _makeContainer();
      addTearDown(c.dispose);
      c.read(taskFormNotifierProvider.notifier).initEdit(_makeTask());
      final state = c.read(taskFormNotifierProvider);
      expect(state.mode, TaskFormMode.edit);
      expect(state.editingTaskId, 't1');
      expect(state.title, 'Limpiar');
      expect(state.visualKind, 'emoji');
      expect(state.visualValue, '🧹');
      expect(state.assignmentMode, 'basicRotation');
      expect(state.assignmentOrder, ['u1']);
      expect(state.difficultyWeight, 1.0);
    });
  });

  group('TaskFormNotifier — save, validación', () {
    test('save devuelve null si no hay recurrenceRule', () async {
      final repo = _MockTasksRepository();
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.setTitle('Tarea');
      notifier.setAssignmentOrder(['u1']);
      // recurrenceRule no seteada
      final result = await notifier.save('h1', 'u1');
      expect(result, isNull);
      expect(
          c.read(taskFormNotifierProvider).fieldErrors.containsKey('recurrence'),
          isTrue);
    });

    test('save devuelve null si el título está vacío', () async {
      final repo = _MockTasksRepository();
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.setRecurrenceRule(_dailyRule);
      notifier.setAssignmentOrder(['u1']);
      // título vacío
      final result = await notifier.save('h1', 'u1');
      expect(result, isNull);
    });

    test('save crea tarea y devuelve ID en modo create', () async {
      final repo = _MockTasksRepository();
      when(() => repo.createTask(any(), any(), any()))
          .thenAnswer((_) async => 'new-task-id');
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.initCreate();
      notifier.setTitle('Fregar platos');
      notifier.setRecurrenceRule(_dailyRule);
      notifier.setAssignmentOrder(['u1']);
      final result = await notifier.save('h1', 'u1');
      expect(result, 'new-task-id');
      verify(() => repo.createTask('h1', any(), 'u1')).called(1);
    });

    test('save en modo edit llama updateTask', () async {
      final repo = _MockTasksRepository();
      when(() => repo.updateTask(any(), any(), any()))
          .thenAnswer((_) async {});
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.initEdit(_makeTask());
      notifier.setTitle('Tarea editada');
      final result = await notifier.save('h1', 'u1');
      expect(result, 't1');
      verify(() => repo.updateTask('h1', 't1', any())).called(1);
    });

    test(
        'save captura excepción del repositorio y devuelve null con globalError',
        () async {
      final repo = _MockTasksRepository();
      when(() => repo.createTask(any(), any(), any()))
          .thenThrow(Exception('Network error'));
      final c = _makeContainer(repo);
      addTearDown(c.dispose);
      final notifier = c.read(taskFormNotifierProvider.notifier);
      notifier.initCreate();
      notifier.setTitle('Tarea');
      notifier.setRecurrenceRule(_dailyRule);
      notifier.setAssignmentOrder(['u1']);
      final result = await notifier.save('h1', 'u1');
      expect(result, isNull);
      expect(c.read(taskFormNotifierProvider).globalError, 'tasks_save_error');
    });
  });
}
