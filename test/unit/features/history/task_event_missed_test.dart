import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/domain/task_event.dart';

void main() {
  group('TaskEvent.fromMap — missed', () {
    test('deserializa un evento missed correctamente', () {
      const taskId = 'task-1';
      final now = DateTime(2026, 4, 15, 10, 0, 0);
      final data = <String, dynamic>{
        'eventType': 'missed',
        'taskId': taskId,
        'taskTitleSnapshot': 'Barrer',
        'taskVisualSnapshot': {'kind': 'emoji', 'value': '🧹'},
        'actorUid': 'uid-a',
        'toUid': 'uid-b',
        'penaltyApplied': true,
        'complianceBefore': 0.8,
        'complianceAfter': 0.75,
        'missedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      final event = TaskEvent.fromMap('event-1', data);

      expect(event, isA<MissedEvent>());
      final missed = event as MissedEvent;
      expect(missed.id, 'event-1');
      expect(missed.taskId, taskId);
      expect(missed.actorUid, 'uid-a');
      expect(missed.toUid, 'uid-b');
      expect(missed.penaltyApplied, isTrue);
      expect(missed.complianceBefore, 0.8);
      expect(missed.complianceAfter, 0.75);
    });

    test('campos opcionales nulos se manejan correctamente', () {
      final now = DateTime(2026, 4, 15, 10, 0, 0);
      final data = <String, dynamic>{
        'eventType': 'missed',
        'taskId': 'task-2',
        'taskTitleSnapshot': 'Fregar',
        'taskVisualSnapshot': {'kind': 'emoji', 'value': '🍽'},
        'actorUid': 'uid-a',
        'toUid': 'uid-a',
        'penaltyApplied': true,
        'complianceBefore': null,
        'complianceAfter': null,
        'missedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      final event = TaskEvent.fromMap('event-2', data);
      expect(event, isA<MissedEvent>());
      final missed = event as MissedEvent;
      expect(missed.complianceBefore, isNull);
      expect(missed.complianceAfter, isNull);
    });
  });
}
