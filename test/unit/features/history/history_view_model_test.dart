// test/unit/features/history/history_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/domain/history_repository.dart';
import 'package:toka/features/history/application/history_view_model.dart';
import 'package:toka/features/history/domain/task_event.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HistoryFilter());
  });

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

  group('HistoryNotifier', () {
    late MockHistoryRepository mockRepo;

    setUp(() {
      mockRepo = MockHistoryRepository();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(overrides: [
        historyRepositoryProvider.overrideWithValue(mockRepo),
      ]);
    }

    test('estado inicial es data([])', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(historyNotifierProvider('home1'));
      expect(state.value, isEmpty);
    });

    test('loadMore appends eventos al estado', () async {
      final completedEvent = TaskEvent.completed(
        id: 'e1',
        taskId: 't1',
        taskTitleSnapshot: 'Fregar',
        taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
        actorUid: 'uid1',
        performerUid: 'uid1',
        completedAt: DateTime(2024),
        createdAt: DateTime(2024),
      );

      when(() => mockRepo.fetchPage(
            homeId: any(named: 'homeId'),
            filter: any(named: 'filter'),
            startAfter: any(named: 'startAfter'),
            limit: any(named: 'limit'),
            isPremium: any(named: 'isPremium'),
          )).thenAnswer((_) async => ([completedEvent], null));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(historyNotifierProvider('home1').notifier)
          .loadMore(isPremium: false);

      final state = container.read(historyNotifierProvider('home1'));
      expect(state.value, contains(completedEvent));
    });

    test('cuando cursor es null, hasMore pasa a false', () async {
      when(() => mockRepo.fetchPage(
            homeId: any(named: 'homeId'),
            filter: any(named: 'filter'),
            startAfter: any(named: 'startAfter'),
            limit: any(named: 'limit'),
            isPremium: any(named: 'isPremium'),
          )).thenAnswer((_) async => (<TaskEvent>[], null));

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(historyNotifierProvider('home1').notifier);
      await notifier.loadMore(isPremium: false);

      expect(notifier.hasMore, isFalse);
    });

    test(
        'segunda llamada a loadMore cuando hasMore=false no llama al repo',
        () async {
      when(() => mockRepo.fetchPage(
            homeId: any(named: 'homeId'),
            filter: any(named: 'filter'),
            startAfter: any(named: 'startAfter'),
            limit: any(named: 'limit'),
            isPremium: any(named: 'isPremium'),
          )).thenAnswer((_) async => (<TaskEvent>[], null));

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(historyNotifierProvider('home1').notifier);

      // Primera llamada — establece hasMore = false
      await notifier.loadMore(isPremium: false);
      // Segunda llamada — debe ignorarse porque hasMore es false
      await notifier.loadMore(isPremium: false);

      verify(() => mockRepo.fetchPage(
            homeId: any(named: 'homeId'),
            filter: any(named: 'filter'),
            startAfter: any(named: 'startAfter'),
            limit: any(named: 'limit'),
            isPremium: any(named: 'isPremium'),
          )).called(1);
    });

    test('applyFilter resetea estado y cursor', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(historyNotifierProvider('home1').notifier);

      notifier.applyFilter(const HistoryFilter(memberUid: 'u1'));

      final state = container.read(historyNotifierProvider('home1'));
      expect(state.value, isEmpty);
      expect(notifier.hasMore, isTrue);
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
