// test/integration/features/history/history_pagination_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/data/history_repository_impl.dart';
import 'package:toka/features/history/domain/task_event.dart';

Future<void> seedEvent(
  FakeFirebaseFirestore db,
  String homeId,
  String id,
  String eventType,
  String actorUid,
  String taskId,
  DateTime createdAt,
) async {
  final base = <String, dynamic>{
    'eventType': eventType,
    'taskId': taskId,
    'taskTitleSnapshot': 'Test',
    'taskVisualSnapshot': {'kind': 'emoji', 'value': '🧹'},
    'actorUid': actorUid,
    'createdAt': Timestamp.fromDate(createdAt),
  };
  if (eventType == 'completed') {
    base.addAll({
      'performerUid': actorUid,
      'completedAt': Timestamp.fromDate(createdAt),
    });
  } else {
    base.addAll({
      'fromUid': actorUid,
      'toUid': 'uid-Z',
      'penaltyApplied': false,
    });
  }
  await db
      .collection('homes')
      .doc(homeId)
      .collection('taskEvents')
      .doc(id)
      .set(base);
}

void main() {
  const homeId = 'home1';
  // Use recent timestamps so they pass the 30-day free cutoff
  final now = DateTime.now();

  late FakeFirebaseFirestore db;
  late HistoryRepositoryImpl repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = HistoryRepositoryImpl(firestore: db);
  });

  test('primera página devuelve primeros 20 eventos', () async {
    for (int i = 0; i < 25; i++) {
      await seedEvent(
        db, homeId, 'ev-$i', 'completed', 'uid-A', 'task1',
        now.subtract(Duration(minutes: i)),
      );
    }

    final (events, cursor) = await repo.fetchPage(
      homeId: homeId,
      isPremium: true,
    );

    expect(events.length, 20);
    expect(cursor, isNotNull);
    // Más reciente primero
    expect(events.first.createdAt.isAfter(events.last.createdAt), isTrue);
  });

  test('loadMore devuelve los 5 eventos restantes con cursor correcto',
      () async {
    for (int i = 0; i < 25; i++) {
      await seedEvent(
        db, homeId, 'ev-$i', 'completed', 'uid-A', 'task1',
        now.subtract(Duration(minutes: i)),
      );
    }

    final (page1, cursor1) = await repo.fetchPage(
      homeId: homeId,
      isPremium: true,
    );
    final (page2, cursor2) = await repo.fetchPage(
      homeId: homeId,
      startAfter: cursor1,
      isPremium: true,
    );

    expect(page1.length, 20);
    expect(page2.length, 5);
    // cursor2 null porque hay < 20 en página 2 → no hay más datos
    expect(cursor2, isNull);
    // Sin duplicados entre páginas
    final ids1 = page1.map((e) => e.id).toSet();
    final ids2 = page2.map((e) => e.id).toSet();
    expect(ids1.intersection(ids2), isEmpty);
  });

  test('menos de 20 eventos devuelve cursor null (no hay más)', () async {
    for (int i = 0; i < 5; i++) {
      await seedEvent(
        db, homeId, 'ev-$i', 'completed', 'uid-A', 'task1',
        now.subtract(Duration(minutes: i)),
      );
    }

    final (events, cursor) = await repo.fetchPage(
      homeId: homeId,
      isPremium: true,
    );
    expect(events.length, 5);
    expect(cursor, isNull);
  });

  test('filtro por memberUid devuelve solo eventos de ese miembro', () async {
    await seedEvent(db, homeId, 'ev-1', 'completed', 'uid-A', 'task1', now);
    await seedEvent(
      db, homeId, 'ev-2', 'completed', 'uid-B', 'task1',
      now.subtract(const Duration(minutes: 1)),
    );

    final (events, _) = await repo.fetchPage(
      homeId: homeId,
      filter: const HistoryFilter(memberUid: 'uid-A'),
      isPremium: true,
    );

    expect(events.length, 1);
    expect(events.first.actorUid, 'uid-A');
  });

  test('Free: eventos de más de 30 días no se devuelven', () async {
    // Evento de hace 40 días → excluido en Free (client-side filter)
    await seedEvent(
      db, homeId, 'ev-old', 'completed', 'uid-A', 'task1',
      now.subtract(const Duration(days: 40)),
    );
    // Evento de hace 10 días → incluido
    await seedEvent(
      db, homeId, 'ev-recent', 'completed', 'uid-A', 'task1',
      now.subtract(const Duration(days: 10)),
    );

    final (events, _) = await repo.fetchPage(
      homeId: homeId,
      isPremium: false,
    );

    expect(events.length, 1);
    expect(events.first.id, 'ev-recent');
  });

  test('filtro eventType:passed excluye completed', () async {
    await seedEvent(db, homeId, 'ev-c', 'completed', 'uid-A', 'task1', now);
    await seedEvent(
      db, homeId, 'ev-p', 'passed', 'uid-A', 'task1',
      now.subtract(const Duration(minutes: 1)),
    );

    final (events, _) = await repo.fetchPage(
      homeId: homeId,
      filter: const HistoryFilter(eventType: 'passed'),
      isPremium: true,
    );

    expect(events.length, 1);
    expect(events.first, isA<PassedEvent>());
  });
}
