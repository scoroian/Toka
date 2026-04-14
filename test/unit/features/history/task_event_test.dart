// test/unit/features/history/task_event_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/domain/task_event.dart';

void main() {
  final now = DateTime(2026, 4, 6, 12, 0);
  final ts = Timestamp.fromDate(now);

  Map<String, dynamic> baseCompleted() => {
        'eventType': 'completed',
        'taskId': 'task1',
        'taskTitleSnapshot': 'Barrer',
        'taskVisualSnapshot': {'kind': 'emoji', 'value': '🧹'},
        'actorUid': 'uid-A',
        'performerUid': 'uid-A',
        'completedAt': ts,
        'createdAt': ts,
      };

  Map<String, dynamic> basePassed() => {
        'eventType': 'passed',
        'taskId': 'task2',
        'taskTitleSnapshot': 'Aspirar',
        'taskVisualSnapshot': {'kind': 'emoji', 'value': '🌀'},
        'actorUid': 'uid-B',
        'fromUid': 'uid-B',
        'toUid': 'uid-C',
        'reason': 'Me voy de viaje',
        'penaltyApplied': true,
        'complianceBefore': 0.8,
        'complianceAfter': 0.7,
        'createdAt': ts,
      };

  group('TaskEvent.fromMap', () {
    test('parsea evento completed correctamente', () {
      final event = TaskEvent.fromMap('e1', baseCompleted());
      expect(event, isA<CompletedEvent>());
      final c = event as CompletedEvent;
      expect(c.id, 'e1');
      expect(c.taskId, 'task1');
      expect(c.taskTitleSnapshot, 'Barrer');
      expect(c.taskVisualSnapshot.value, '🧹');
      expect(c.actorUid, 'uid-A');
      expect(c.completedAt, now);
    });

    test('parsea evento passed con motivo correctamente', () {
      final event = TaskEvent.fromMap('e2', basePassed());
      expect(event, isA<PassedEvent>());
      final p = event as PassedEvent;
      expect(p.fromUid, 'uid-B');
      expect(p.toUid, 'uid-C');
      expect(p.reason, 'Me voy de viaje');
      expect(p.penaltyApplied, isTrue);
      expect(p.complianceBefore, closeTo(0.8, 0.001));
      expect(p.complianceAfter, closeTo(0.7, 0.001));
    });

    test('fromMap sin eventType asume completed', () {
      final data = Map<String, dynamic>.from(baseCompleted())
        ..remove('eventType');
      final event = TaskEvent.fromMap('e3', data);
      expect(event, isA<CompletedEvent>());
    });

    test('passed sin reason tiene reason null', () {
      final data = Map<String, dynamic>.from(basePassed())
        ..remove('reason');
      final event = TaskEvent.fromMap('e4', data);
      final p = event as PassedEvent;
      expect(p.reason, isNull);
    });
  });

  group('TaskVisual.fromMap', () {
    test('parsea kind y value correctamente', () {
      final v = TaskVisual.fromMap({'kind': 'emoji', 'value': '🏠'});
      expect(v.kind, 'emoji');
      expect(v.value, '🏠');
    });

    test('usa defaults cuando faltan campos', () {
      final v = TaskVisual.fromMap({});
      expect(v.kind, 'emoji');
      expect(v.value, '');
    });

    test('igualdad funciona correctamente', () {
      const v1 = TaskVisual(kind: 'emoji', value: '🧹');
      const v2 = TaskVisual(kind: 'emoji', value: '🧹');
      expect(v1, v2);
    });
  });
}
