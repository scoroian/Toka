// test/unit/features/history/history_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/application/history_view_model.dart';
import 'package:toka/features/history/domain/task_event.dart';

void main() {
  group('HistoryFilter', () {
    test('default HistoryFilter has all null fields', () {
      const filter = HistoryFilter();
      expect(filter.memberUid, isNull);
      expect(filter.taskId, isNull);
      expect(filter.eventType, isNull);
    });

    test('HistoryFilter equality: two default instances are equal', () {
      const f1 = HistoryFilter();
      const f2 = HistoryFilter();
      expect(f1, equals(f2));
    });

    test('HistoryFilter copyWith changes only specified fields', () {
      const f = HistoryFilter();
      final f2 = f.copyWith(memberUid: 'u1', eventType: 'completed');
      expect(f2.memberUid, 'u1');
      expect(f2.eventType, 'completed');
      expect(f2.taskId, isNull);
    });

    test('HistoryFilter with memberUid differs from default', () {
      const base = HistoryFilter();
      final withMember = base.copyWith(memberUid: 'u2');
      expect(withMember, isNot(equals(base)));
    });
  });

  group('TaskEventItem.canRate', () {
    final completedEvent = TaskEvent.completed(
      id: 'e1',
      taskId: 't1',
      taskTitleSnapshot: 'Fregar',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🍽️'),
      actorUid: 'uid_actor',
      performerUid: 'uid_actor',
      completedAt: DateTime(2026, 4, 14, 10, 0),
      createdAt: DateTime(2026, 4, 14, 10, 0),
    );

    final passedEvent = TaskEvent.passed(
      id: 'e2',
      taskId: 't2',
      taskTitleSnapshot: 'Barrer',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
      actorUid: 'uid_actor',
      fromUid: 'uid_actor',
      toUid: 'uid_other',
      penaltyApplied: false,
      complianceBefore: null,
      complianceAfter: null,
      createdAt: DateTime(2026, 4, 14),
    );

    test('canRate true: completedEvent, otro actor, no valorado', () {
      final item = TaskEventItem(
        raw: completedEvent,
        actorName: 'Ana',
        actorPhotoUrl: null,
        isOwnEvent: false,
        isRated: false,
        canRate: TaskEventItem.computeCanRate(
          raw: completedEvent,
          isOwnEvent: false,
          isRated: false,
        ),
      );
      expect(item.canRate, isTrue);
    });

    test('canRate false: completedEvent, propio evento', () {
      final item = TaskEventItem(
        raw: completedEvent,
        actorName: 'Sebas',
        actorPhotoUrl: null,
        isOwnEvent: true,
        isRated: false,
        canRate: TaskEventItem.computeCanRate(
          raw: completedEvent,
          isOwnEvent: true,
          isRated: false,
        ),
      );
      expect(item.canRate, isFalse);
    });

    test('canRate false: completedEvent, otro actor, ya valorado', () {
      final item = TaskEventItem(
        raw: completedEvent,
        actorName: 'Ana',
        actorPhotoUrl: null,
        isOwnEvent: false,
        isRated: true,
        canRate: TaskEventItem.computeCanRate(
          raw: completedEvent,
          isOwnEvent: false,
          isRated: true,
        ),
      );
      expect(item.canRate, isFalse);
    });

    test('canRate false: passedEvent, aunque sea de otro', () {
      final item = TaskEventItem(
        raw: passedEvent,
        actorName: 'Ana',
        actorPhotoUrl: null,
        isOwnEvent: false,
        isRated: false,
        canRate: TaskEventItem.computeCanRate(
          raw: passedEvent,
          isOwnEvent: false,
          isRated: false,
        ),
      );
      expect(item.canRate, isFalse);
    });
  });
}
