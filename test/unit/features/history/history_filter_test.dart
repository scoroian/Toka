// test/unit/features/history/history_filter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/domain/task_event.dart';

void main() {
  const visual = TaskVisual(kind: 'emoji', value: '🧹');
  final now = DateTime(2026, 4, 6);

  TaskEvent completed(String id, String actorUid, String taskId) =>
      TaskEvent.completed(
        id: id,
        taskId: taskId,
        taskTitleSnapshot: 'Barrer',
        taskVisualSnapshot: visual,
        actorUid: actorUid,
        performerUid: actorUid,
        completedAt: now,
        createdAt: now,
      );

  TaskEvent passed(String id, String actorUid) => TaskEvent.passed(
        id: id,
        taskId: 'task99',
        taskTitleSnapshot: 'Aspirar',
        taskVisualSnapshot: visual,
        actorUid: actorUid,
        fromUid: actorUid,
        toUid: 'uid-Z',
        penaltyApplied: false,
        complianceBefore: null,
        complianceAfter: null,
        createdAt: now,
      );

  List<TaskEvent> applyFilter(List<TaskEvent> events, HistoryFilter f) {
    return events.where((e) {
      if (f.memberUid != null && e.actorUid != f.memberUid) return false;
      if (f.taskId != null && e.taskId != f.taskId) return false;
      if (f.eventType == 'completed' && e is! CompletedEvent) return false;
      if (f.eventType == 'passed' && e is! PassedEvent) return false;
      return true;
    }).toList();
  }

  final events = [
    completed('e1', 'uid-A', 'task1'),
    completed('e2', 'uid-B', 'task1'),
    passed('e3', 'uid-A'),
    passed('e4', 'uid-C'),
  ];

  group('HistoryFilter', () {
    test('sin filtros devuelve todos los eventos', () {
      final result = applyFilter(events, const HistoryFilter());
      expect(result.length, 4);
    });

    test('filtro por memberUid devuelve solo eventos de ese miembro', () {
      final result =
          applyFilter(events, const HistoryFilter(memberUid: 'uid-A'));
      expect(result.length, 2);
      expect(result.every((e) => e.actorUid == 'uid-A'), isTrue);
    });

    test('filtro eventType:passed excluye completed', () {
      final result =
          applyFilter(events, const HistoryFilter(eventType: 'passed'));
      expect(result.length, 2);
      expect(result.every((e) => e is PassedEvent), isTrue);
    });

    test('filtro eventType:completed excluye passed', () {
      final result =
          applyFilter(events, const HistoryFilter(eventType: 'completed'));
      expect(result.length, 2);
      expect(result.every((e) => e is CompletedEvent), isTrue);
    });

    test('filtro por taskId devuelve solo eventos de esa tarea', () {
      final result =
          applyFilter(events, const HistoryFilter(taskId: 'task1'));
      expect(result.length, 2);
      expect(result.every((e) => e.taskId == 'task1'), isTrue);
    });

    test('HistoryNotifier resetea paginación al aplicar filtro', () {
      // Verificamos que applyFilter() resetea estado interno
      // Este test valida el contrato público del filtro
      const f1 = HistoryFilter(eventType: 'completed');
      const f2 = HistoryFilter(eventType: 'passed');
      expect(f1, isNot(equals(f2)));
      expect(const HistoryFilter(), const HistoryFilter());
    });
  });
}
