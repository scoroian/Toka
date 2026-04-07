import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_validator.dart';

TaskInput _validInput({
  String title = 'Fregar',
  List<String> assignees = const ['uid1'],
  double weight = 1.0,
}) =>
    TaskInput(
      title: title,
      visualKind: 'emoji',
      visualValue: '🍽️',
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '20:00', timezone: 'Europe/Madrid'),
      assignmentMode: 'basicRotation',
      assignmentOrder: assignees,
      difficultyWeight: weight,
    );

void main() {
  group('TaskValidator', () {
    test('válido → ok', () {
      final result = TaskValidator.validate(_validInput());
      expect(result.isOk, isTrue);
    });

    test('título vacío → error', () {
      final result = TaskValidator.validate(_validInput(title: ''));
      expect(result.isOk, isFalse);
      expect(result.failure?.field, 'title');
      expect(result.failure?.code, 'tasks_validation_title_empty');
    });

    test('título con espacios → error vacío', () {
      final result = TaskValidator.validate(_validInput(title: '   '));
      expect(result.isOk, isFalse);
      expect(result.failure?.field, 'title');
    });

    test('título > 60 chars → error', () {
      final result = TaskValidator.validate(_validInput(title: 'A' * 61));
      expect(result.isOk, isFalse);
      expect(result.failure?.code, 'tasks_validation_title_too_long');
    });

    test('sin asignados → error', () {
      final result = TaskValidator.validate(_validInput(assignees: []));
      expect(result.isOk, isFalse);
      expect(result.failure?.field, 'assignees');
    });

    test('peso fuera de rango → error', () {
      final result = TaskValidator.validate(_validInput(weight: 0.4));
      expect(result.isOk, isFalse);
      expect(result.failure?.field, 'difficulty');
    });

    test('peso en límite inferior → ok', () {
      expect(TaskValidator.validate(_validInput(weight: 0.5)).isOk, isTrue);
    });

    test('peso en límite superior → ok', () {
      expect(TaskValidator.validate(_validInput(weight: 3.0)).isOk, isTrue);
    });
  });
}
