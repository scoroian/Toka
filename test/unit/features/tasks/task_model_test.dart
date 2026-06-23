import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/data/task_model.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';

void main() {
  TaskInput input({
    String title = 'Barrer',
    required List<String> order,
  }) =>
      TaskInput(
        title: title,
        visualKind: 'emoji',
        visualValue: '🧹',
        recurrenceRule: const RecurrenceRule.daily(
          every: 1,
          time: '09:00',
          timezone: 'Europe/Madrid',
        ),
        assignmentMode: 'basicRotation',
        assignmentOrder: order,
      );

  final nextDue = DateTime(2026, 6, 22, 9, 0);

  group('TaskModel.toUpdateMap — preservación del asignado (Hallazgo #11b)', () {
    test(
        'editar un campo no-asignación (mismo assignmentOrder) NO reescribe '
        'currentAssigneeUid', () {
      final map = TaskModel.toUpdateMap(
        input(title: 'Barrer el salón', order: ['A', 'B', 'C']),
        nextDue,
        previousOrder: ['A', 'B', 'C'],
        currentAssigneeUid: 'B', // turno a mitad de rotación
      );

      // El campo editado SÍ se actualiza.
      expect(map['title'], 'Barrer el salón');
      // Pero la rotación NO se toca: la clave ni siquiera está presente,
      // así que el documento conserva el currentAssigneeUid de Firestore.
      expect(map.containsKey('currentAssigneeUid'), isFalse);
    });

    test(
        'cambiar el orden preservando al asignado actual mantiene a ese '
        'asignado como responsable', () {
      final map = TaskModel.toUpdateMap(
        input(order: ['C', 'B', 'A']), // reordenado
        nextDue,
        previousOrder: ['A', 'B', 'C'],
        currentAssigneeUid: 'B', // sigue en el nuevo orden
      );

      expect(map.containsKey('currentAssigneeUid'), isTrue);
      expect(map['currentAssigneeUid'], 'B');
      expect(map['assignmentOrder'], ['C', 'B', 'A']);
    });

    test(
        'cambiar el orden quitando al asignado actual cae al primero del '
        'nuevo orden', () {
      final map = TaskModel.toUpdateMap(
        input(order: ['C', 'A']), // se eliminó B del orden
        nextDue,
        previousOrder: ['A', 'B', 'C'],
        currentAssigneeUid: 'B', // ya no está en el nuevo orden
      );

      expect(map['currentAssigneeUid'], 'C');
    });

    test('orden vacío → currentAssigneeUid null', () {
      final map = TaskModel.toUpdateMap(
        input(order: []),
        nextDue,
        previousOrder: ['A'],
        currentAssigneeUid: 'A',
      );

      expect(map.containsKey('currentAssigneeUid'), isTrue);
      expect(map['currentAssigneeUid'], isNull);
    });

    test(
        'sin currentAssigneeUid previo y orden cambiado → primero del nuevo '
        'orden', () {
      final map = TaskModel.toUpdateMap(
        input(order: ['A', 'B']),
        nextDue,
        previousOrder: ['B', 'A'],
        currentAssigneeUid: null,
      );

      expect(map['currentAssigneeUid'], 'A');
    });
  });

  group('TaskModel.toFirestore — alta (sin regresión)', () {
    test('crear una tarea asigna al primero del orden', () {
      final map = TaskModel.toFirestore(
        input(order: ['A', 'B', 'C']),
        'home1',
        'creator',
        nextDue,
      );

      expect(map['currentAssigneeUid'], 'A');
      expect(map['assignmentOrder'], ['A', 'B', 'C']);
    });
  });
}
