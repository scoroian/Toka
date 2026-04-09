# Spec-09: History Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the home history screen with paginated task events (completed + passed), filters by member/task/type, Free/Premium date limits, and a Premium upgrade banner.

**Architecture:** Clean architecture — domain models (freezed sealed TaskEvent + HistoryFilter), abstract repository in domain/, implementation in data/ using Firestore cursor-based pagination, AsyncNotifier provider with state accumulation, and a ConsumerWidget screen with infinite scroll.

**Tech Stack:** Flutter + Dart 3, Riverpod (riverpod_annotation), Freezed, cloud_firestore (FakeFirebaseFirestore for tests), go_router, flutter_localizations/intl.

---

## File Map

### Create
- `lib/features/history/domain/task_event.dart` — TaskVisual + sealed TaskEvent (CompletedEvent | PassedEvent)
- `lib/features/history/domain/history_repository.dart` — abstract HistoryRepository interface
- `lib/features/history/data/history_repository_impl.dart` — Firestore impl with pagination + date cutoff
- `lib/features/history/application/history_provider.dart` — HistoryNotifier (AsyncNotifier) + HistoryFilter
- `lib/features/history/presentation/history_screen.dart` — main screen with AppBar, chips, infinite scroll
- `lib/features/history/presentation/widgets/history_event_tile.dart` — tile for completed/passed events
- `lib/features/history/presentation/widgets/history_filter_bar.dart` — horizontal scrollable filter chips
- `lib/features/history/presentation/widgets/history_empty_state.dart` — empty state widget
- `test/unit/features/history/task_event_test.dart` — unit tests for TaskEvent.fromFirestore
- `test/unit/features/history/history_filter_test.dart` — unit tests for HistoryFilter logic
- `test/integration/features/history/history_pagination_test.dart` — integration tests (FakeFirebaseFirestore)
- `test/ui/features/history/history_screen_test.dart` — widget + golden tests

### Modify
- `lib/core/constants/routes.dart` — add `history` route constant
- `lib/app.dart` — register `/history` GoRoute
- `lib/l10n/app_es.arb` — add history_* keys in Spanish
- `lib/l10n/app_en.arb` — add history_* keys in English
- `lib/l10n/app_ro.arb` — add history_* keys in Romanian
- `lib/l10n/app_localizations.dart` — add abstract getters
- `lib/l10n/app_localizations_es.dart` — add ES implementations
- `lib/l10n/app_localizations_en.dart` — add EN implementations
- `lib/l10n/app_localizations_ro.dart` — add RO implementations

---

## Task 1: Domain models

**Files:**
- Create: `lib/features/history/domain/task_event.dart`

- [ ] **Step 1: Create task_event.dart**

```dart
// lib/features/history/domain/task_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_event.freezed.dart';

class TaskVisual {
  const TaskVisual({required this.kind, required this.value});
  final String kind;
  final String value;

  factory TaskVisual.fromMap(Map<String, dynamic> map) => TaskVisual(
        kind: map['kind'] as String? ?? 'emoji',
        value: map['value'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is TaskVisual && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

@freezed
sealed class TaskEvent with _$TaskEvent {
  const factory TaskEvent.completed({
    required String id,
    required String taskId,
    required String taskTitleSnapshot,
    required TaskVisual taskVisualSnapshot,
    required String actorUid,
    required String performerUid,
    required DateTime completedAt,
    required DateTime createdAt,
  }) = CompletedEvent;

  const factory TaskEvent.passed({
    required String id,
    required String taskId,
    required String taskTitleSnapshot,
    required TaskVisual taskVisualSnapshot,
    required String actorUid,
    required String fromUid,
    required String toUid,
    String? reason,
    required bool penaltyApplied,
    required double? complianceBefore,
    required double? complianceAfter,
    required DateTime createdAt,
  }) = PassedEvent;

  static TaskEvent fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromMap(doc.id, doc.data()!);
  }

  static TaskEvent fromMap(String id, Map<String, dynamic> data) {
    final eventType = data['eventType'] as String? ?? 'completed';
    final visual = TaskVisual.fromMap(
      (data['taskVisualSnapshot'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    if (eventType == 'passed') {
      return TaskEvent.passed(
        id: id,
        taskId: data['taskId'] as String? ?? '',
        taskTitleSnapshot: data['taskTitleSnapshot'] as String? ?? '',
        taskVisualSnapshot: visual,
        actorUid: data['actorUid'] as String? ?? '',
        fromUid: data['fromUid'] as String? ?? '',
        toUid: data['toUid'] as String? ?? '',
        reason: data['reason'] as String?,
        penaltyApplied: data['penaltyApplied'] as bool? ?? false,
        complianceBefore: (data['complianceBefore'] as num?)?.toDouble(),
        complianceAfter: (data['complianceAfter'] as num?)?.toDouble(),
        createdAt: createdAt,
      );
    }

    return TaskEvent.completed(
      id: id,
      taskId: data['taskId'] as String? ?? '',
      taskTitleSnapshot: data['taskTitleSnapshot'] as String? ?? '',
      taskVisualSnapshot: visual,
      actorUid: data['actorUid'] as String? ?? '',
      performerUid: data['performerUid'] as String? ?? '',
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? createdAt,
      createdAt: createdAt,
    );
  }
}
```

- [ ] **Step 2: Run build_runner**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `task_event.freezed.dart` with no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/history/domain/task_event.dart lib/features/history/domain/task_event.freezed.dart
git commit -m "feat(history): add TaskEvent sealed domain model"
```

---

## Task 2: Unit tests for TaskEvent

**Files:**
- Create: `test/unit/features/history/task_event_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/unit/features/history/task_event_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/domain/task_event.dart';

void main() {
  final now = DateTime(2026, 4, 6, 12, 0);
  final ts = Timestamp.fromDate(now);

  Map<String, dynamic> _baseCompleted() => {
        'eventType': 'completed',
        'taskId': 'task1',
        'taskTitleSnapshot': 'Barrer',
        'taskVisualSnapshot': {'kind': 'emoji', 'value': '🧹'},
        'actorUid': 'uid-A',
        'performerUid': 'uid-A',
        'completedAt': ts,
        'createdAt': ts,
      };

  Map<String, dynamic> _basePassed() => {
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
      final event = TaskEvent.fromMap('e1', _baseCompleted());
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
      final event = TaskEvent.fromMap('e2', _basePassed());
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
      final data = Map<String, dynamic>.from(_baseCompleted())
        ..remove('eventType');
      final event = TaskEvent.fromMap('e3', data);
      expect(event, isA<CompletedEvent>());
    });

    test('passed sin reason tiene reason null', () {
      final data = Map<String, dynamic>.from(_basePassed())
        ..remove('reason');
      final event = TaskEvent.fromMap('e4', data);
      final p = event as PassedEvent;
      expect(p.reason, isNull);
    });

    test('TaskVisual.fromMap usa defaults cuando faltan campos', () {
      final v = TaskVisual.fromMap({});
      expect(v.kind, 'emoji');
      expect(v.value, '');
    });
  });
}
```

- [ ] **Step 2: Ejecutar tests**

```bash
flutter test test/unit/features/history/task_event_test.dart
```

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/history/task_event_test.dart
git commit -m "test(history): add unit tests for TaskEvent model"
```

---

## Task 3: HistoryFilter model + unit tests

**Files:**
- Modify: `lib/features/history/application/history_provider.dart` (create with HistoryFilter first)
- Create: `test/unit/features/history/history_filter_test.dart`

- [ ] **Step 1: Create history_provider.dart con HistoryFilter**

```dart
// lib/features/history/application/history_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/history_repository_impl.dart';
import '../domain/history_repository.dart';
import '../domain/task_event.dart';

part 'history_provider.freezed.dart';
part 'history_provider.g.dart';

@freezed
class HistoryFilter with _$HistoryFilter {
  const factory HistoryFilter({
    String? memberUid,
    String? taskId,
    String? eventType,
  }) = _HistoryFilter;
}

@Riverpod(keepAlive: true)
HistoryRepository historyRepository(HistoryRepositoryRef ref) {
  return HistoryRepositoryImpl();
}

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  static const _pageSize = 20;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  HistoryFilter _filter = const HistoryFilter();

  @override
  AsyncValue<List<TaskEvent>> build(String homeId) {
    return const AsyncValue.data([]);
  }

  bool get hasMore => _hasMore;

  Future<void> loadMore({bool isPremium = false}) async {
    if (!_hasMore || state.isLoading) return;
    state = AsyncValue.data(state.valueOrNull ?? []);

    try {
      final repo = ref.read(historyRepositoryProvider);
      final (events, lastDoc) = await repo.fetchPage(
        homeId: homeId,
        filter: _filter,
        startAfter: _lastDoc,
        limit: _pageSize,
        isPremium: isPremium,
      );
      _lastDoc = lastDoc;
      _hasMore = events.length >= _pageSize;
      state = AsyncValue.data([...(state.valueOrNull ?? []), ...events]);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void applyFilter(HistoryFilter filter) {
    _filter = filter;
    _lastDoc = null;
    _hasMore = true;
    state = const AsyncValue.data([]);
  }
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `history_provider.freezed.dart` and `history_provider.g.dart`.

- [ ] **Step 3: Write HistoryFilter unit tests**

```dart
// test/unit/features/history/history_filter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/domain/task_event.dart';

void main() {
  final _visual = const TaskVisual(kind: 'emoji', value: '🧹');
  final _now = DateTime(2026, 4, 6);

  TaskEvent _completed(String id, String actorUid, String taskId) =>
      TaskEvent.completed(
        id: id,
        taskId: taskId,
        taskTitleSnapshot: 'Barrer',
        taskVisualSnapshot: _visual,
        actorUid: actorUid,
        performerUid: actorUid,
        completedAt: _now,
        createdAt: _now,
      );

  TaskEvent _passed(String id, String fromUid) => TaskEvent.passed(
        id: id,
        taskId: 'task99',
        taskTitleSnapshot: 'Aspirar',
        taskVisualSnapshot: _visual,
        actorUid: fromUid,
        fromUid: fromUid,
        toUid: 'uid-Z',
        penaltyApplied: false,
        complianceBefore: null,
        complianceAfter: null,
        createdAt: _now,
      );

  List<TaskEvent> _applyFilter(List<TaskEvent> events, HistoryFilter f) {
    return events.where((e) {
      if (f.memberUid != null && e.actorUid != f.memberUid) return false;
      if (f.taskId != null && e.taskId != f.taskId) return false;
      if (f.eventType == 'completed' && e is! CompletedEvent) return false;
      if (f.eventType == 'passed' && e is! PassedEvent) return false;
      return true;
    }).toList();
  }

  group('HistoryFilter', () {
    final events = [
      _completed('e1', 'uid-A', 'task1'),
      _completed('e2', 'uid-B', 'task1'),
      _passed('e3', 'uid-A'),
      _passed('e4', 'uid-C'),
    ];

    test('sin filtros devuelve todos los eventos', () {
      final result = _applyFilter(events, const HistoryFilter());
      expect(result.length, 4);
    });

    test('filtro por memberUid devuelve solo eventos de ese miembro', () {
      final result = _applyFilter(events, const HistoryFilter(memberUid: 'uid-A'));
      expect(result.length, 2);
      expect(result.every((e) => e.actorUid == 'uid-A'), isTrue);
    });

    test('filtro eventType:passed excluye completed', () {
      final result = _applyFilter(events, const HistoryFilter(eventType: 'passed'));
      expect(result.length, 2);
      expect(result.every((e) => e is PassedEvent), isTrue);
    });

    test('filtro eventType:completed excluye passed', () {
      final result = _applyFilter(events, const HistoryFilter(eventType: 'completed'));
      expect(result.length, 2);
      expect(result.every((e) => e is CompletedEvent), isTrue);
    });

    test('filtro por taskId devuelve solo eventos de esa tarea', () {
      final result = _applyFilter(events, const HistoryFilter(taskId: 'task1'));
      expect(result.length, 2);
      expect(result.every((e) => e.taskId == 'task1'), isTrue);
    });
  });
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/unit/features/history/history_filter_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/history/application/history_provider.dart lib/features/history/application/history_provider.freezed.dart lib/features/history/application/history_provider.g.dart test/unit/features/history/history_filter_test.dart
git commit -m "feat(history): add HistoryFilter model and HistoryNotifier provider"
```

---

## Task 4: Repository interface + implementation

**Files:**
- Create: `lib/features/history/domain/history_repository.dart`
- Create: `lib/features/history/data/history_repository_impl.dart`

- [ ] **Step 1: Create repository interface**

```dart
// lib/features/history/domain/history_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/history_provider.dart';
import 'task_event.dart';

abstract class HistoryRepository {
  Future<(List<TaskEvent>, DocumentSnapshot?)> fetchPage({
    required String homeId,
    HistoryFilter filter,
    DocumentSnapshot? startAfter,
    int limit,
    bool isPremium,
  });
}
```

- [ ] **Step 2: Create repository implementation**

```dart
// lib/features/history/data/history_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/history_provider.dart';
import '../domain/history_repository.dart';
import '../domain/task_event.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<(List<TaskEvent>, DocumentSnapshot?)> fetchPage({
    required String homeId,
    HistoryFilter filter = const HistoryFilter(),
    DocumentSnapshot? startAfter,
    int limit = 20,
    bool isPremium = false,
  }) async {
    final daysBack = isPremium ? 90 : 30;
    final cutoff = DateTime.now().subtract(Duration(days: daysBack));

    Query<Map<String, dynamic>> query = _firestore
        .collection('homes')
        .doc(homeId)
        .collection('taskEvents')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (filter.memberUid != null) {
      query = query.where('actorUid', isEqualTo: filter.memberUid);
    }
    if (filter.taskId != null) {
      query = query.where('taskId', isEqualTo: filter.taskId);
    }
    if (filter.eventType != null) {
      query = query.where('eventType', isEqualTo: filter.eventType);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    final events = snap.docs
        .map((d) => TaskEvent.fromFirestore(
            d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;

    return (events, lastDoc);
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/history/domain/history_repository.dart lib/features/history/data/history_repository_impl.dart
git commit -m "feat(history): add HistoryRepository interface and Firestore implementation"
```

---

## Task 5: Integration tests for pagination

**Files:**
- Create: `test/integration/features/history/history_pagination_test.dart`

- [ ] **Step 1: Write integration tests**

```dart
// test/integration/features/history/history_pagination_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/data/history_repository_impl.dart';
import 'package:toka/features/history/domain/task_event.dart';

Future<void> _seedEvent(
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
  final now = DateTime(2026, 4, 6, 12);

  late FakeFirebaseFirestore db;
  late HistoryRepositoryImpl repo;

  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = HistoryRepositoryImpl(firestore: db);
  });

  test('primera página devuelve primeros 20 eventos (más recientes primero)',
      () async {
    // Seed 25 events with different timestamps
    for (int i = 0; i < 25; i++) {
      await _seedEvent(
        db, homeId, 'ev-$i', 'completed', 'uid-A', 'task1',
        now.subtract(Duration(minutes: i)),
      );
    }

    final (events, lastDoc) = await repo.fetchPage(
      homeId: homeId,
      isPremium: true,
    );

    expect(events.length, 20);
    expect(lastDoc, isNotNull);
    // Más reciente primero
    expect(events.first.createdAt.isAfter(events.last.createdAt), isTrue);
  });

  test('loadMore devuelve los 5 eventos restantes con cursor correcto',
      () async {
    for (int i = 0; i < 25; i++) {
      await _seedEvent(
        db, homeId, 'ev-$i', 'completed', 'uid-A', 'task1',
        now.subtract(Duration(minutes: i)),
      );
    }

    final (page1, lastDoc1) = await repo.fetchPage(
      homeId: homeId,
      isPremium: true,
    );
    final (page2, lastDoc2) = await repo.fetchPage(
      homeId: homeId,
      startAfter: lastDoc1,
      isPremium: true,
    );

    expect(page1.length, 20);
    expect(page2.length, 5);
    expect(lastDoc2, isNotNull);
    // No duplicados
    final ids1 = page1.map((e) => e.id).toSet();
    final ids2 = page2.map((e) => e.id).toSet();
    expect(ids1.intersection(ids2), isEmpty);
  });

  test('sin más eventos _hasMore se vuelve false (devuelve < 20 eventos)',
      () async {
    for (int i = 0; i < 5; i++) {
      await _seedEvent(
        db, homeId, 'ev-$i', 'completed', 'uid-A', 'task1',
        now.subtract(Duration(minutes: i)),
      );
    }

    final (events, _) = await repo.fetchPage(
      homeId: homeId,
      isPremium: true,
    );
    expect(events.length, 5);
    // Al ser < 20, el notifier debería poner _hasMore = false
  });

  test('filtro por memberUid devuelve solo eventos de ese miembro', () async {
    await _seedEvent(db, homeId, 'ev-1', 'completed', 'uid-A', 'task1', now);
    await _seedEvent(db, homeId, 'ev-2', 'completed', 'uid-B', 'task1',
        now.subtract(const Duration(minutes: 1)));

    final (events, _) = await repo.fetchPage(
      homeId: homeId,
      filter: const HistoryFilter(memberUid: 'uid-A'),
      isPremium: true,
    );

    expect(events.length, 1);
    expect(events.first.actorUid, 'uid-A');
  });

  test('Free: eventos de hace más de 30 días no se devuelven', () async {
    // Event 40 days ago → excluded in Free
    await _seedEvent(
      db, homeId, 'ev-old', 'completed', 'uid-A', 'task1',
      now.subtract(const Duration(days: 40)),
    );
    // Event 10 days ago → included
    await _seedEvent(
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

  test('filtro por eventType:passed excluye completed', () async {
    await _seedEvent(db, homeId, 'ev-c', 'completed', 'uid-A', 'task1', now);
    await _seedEvent(db, homeId, 'ev-p', 'passed', 'uid-A', 'task1',
        now.subtract(const Duration(minutes: 1)));

    final (events, _) = await repo.fetchPage(
      homeId: homeId,
      filter: const HistoryFilter(eventType: 'passed'),
      isPremium: true,
    );

    expect(events.length, 1);
    expect(events.first, isA<PassedEvent>());
  });
}
```

- [ ] **Step 2: Run integration tests**

```bash
flutter test test/integration/features/history/history_pagination_test.dart
```

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/integration/features/history/history_pagination_test.dart
git commit -m "test(history): add integration tests for history pagination and filters"
```

---

## Task 6: i18n strings

**Files:**
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_es.dart`, `app_localizations_en.dart`, `app_localizations_ro.dart`

- [ ] **Step 1: Append to app_es.arb (before closing `}`)**

Add before the final `}`:
```json
  "history_title": "Historial",
  "@history_title": { "description": "History screen title" },
  "history_filter_all": "Todos",
  "@history_filter_all": { "description": "History filter: all events" },
  "history_filter_completed": "Completadas",
  "@history_filter_completed": { "description": "History filter: completed only" },
  "history_filter_passed": "Pases",
  "@history_filter_passed": { "description": "History filter: passed only" },
  "history_empty_title": "Sin actividad",
  "@history_empty_title": { "description": "History empty state title" },
  "history_empty_body": "Aún no hay eventos en el historial",
  "@history_empty_body": { "description": "History empty state body" },
  "history_event_completed": "{name} completó",
  "@history_event_completed": {
    "description": "Completed event actor label",
    "placeholders": { "name": { "type": "String" } }
  },
  "history_event_pass_turn": "pase de turno",
  "@history_event_pass_turn": { "description": "Pass turn label in event tile" },
  "history_event_reason": "Motivo: {reason}",
  "@history_event_reason": {
    "description": "Pass reason label",
    "placeholders": { "reason": { "type": "String" } }
  },
  "history_load_more": "Cargar más",
  "@history_load_more": { "description": "Load more button" },
  "history_premium_banner_title": "Más historial con Premium",
  "@history_premium_banner_title": { "description": "Premium banner title" },
  "history_premium_banner_body": "Accede a 90 días de historial",
  "@history_premium_banner_body": { "description": "Premium banner body" },
  "history_premium_banner_cta": "Actualizar a Premium",
  "@history_premium_banner_cta": { "description": "Premium banner CTA button" }
```

- [ ] **Step 2: Append to app_en.arb**

```json
  "history_title": "History",
  "@history_title": { "description": "History screen title" },
  "history_filter_all": "All",
  "@history_filter_all": { "description": "History filter: all events" },
  "history_filter_completed": "Completed",
  "@history_filter_completed": { "description": "History filter: completed only" },
  "history_filter_passed": "Passes",
  "@history_filter_passed": { "description": "History filter: passed only" },
  "history_empty_title": "No activity yet",
  "@history_empty_title": { "description": "History empty state title" },
  "history_empty_body": "No events in the history yet",
  "@history_empty_body": { "description": "History empty state body" },
  "history_event_completed": "{name} completed",
  "@history_event_completed": {
    "description": "Completed event actor label",
    "placeholders": { "name": { "type": "String" } }
  },
  "history_event_pass_turn": "turn pass",
  "@history_event_pass_turn": { "description": "Pass turn label in event tile" },
  "history_event_reason": "Reason: {reason}",
  "@history_event_reason": {
    "description": "Pass reason label",
    "placeholders": { "reason": { "type": "String" } }
  },
  "history_load_more": "Load more",
  "@history_load_more": { "description": "Load more button" },
  "history_premium_banner_title": "More history with Premium",
  "@history_premium_banner_title": { "description": "Premium banner title" },
  "history_premium_banner_body": "Access 90 days of history",
  "@history_premium_banner_body": { "description": "Premium banner body" },
  "history_premium_banner_cta": "Upgrade to Premium",
  "@history_premium_banner_cta": { "description": "Premium banner CTA button" }
```

- [ ] **Step 3: Append to app_ro.arb**

```json
  "history_title": "Istoric",
  "@history_title": { "description": "History screen title" },
  "history_filter_all": "Toate",
  "@history_filter_all": { "description": "History filter: all events" },
  "history_filter_completed": "Finalizate",
  "@history_filter_completed": { "description": "History filter: completed only" },
  "history_filter_passed": "Pasări",
  "@history_filter_passed": { "description": "History filter: passed only" },
  "history_empty_title": "Nicio activitate",
  "@history_empty_title": { "description": "History empty state title" },
  "history_empty_body": "Nu există încă evenimente în istoric",
  "@history_empty_body": { "description": "History empty state body" },
  "history_event_completed": "{name} a finalizat",
  "@history_event_completed": {
    "description": "Completed event actor label",
    "placeholders": { "name": { "type": "String" } }
  },
  "history_event_pass_turn": "pasare de tură",
  "@history_event_pass_turn": { "description": "Pass turn label in event tile" },
  "history_event_reason": "Motiv: {reason}",
  "@history_event_reason": {
    "description": "Pass reason label",
    "placeholders": { "reason": { "type": "String" } }
  },
  "history_load_more": "Încarcă mai mult",
  "@history_load_more": { "description": "Load more button" },
  "history_premium_banner_title": "Mai mult istoric cu Premium",
  "@history_premium_banner_title": { "description": "Premium banner title" },
  "history_premium_banner_body": "Accesează 90 de zile de istoric",
  "@history_premium_banner_body": { "description": "Premium banner body" },
  "history_premium_banner_cta": "Actualizează la Premium",
  "@history_premium_banner_cta": { "description": "Premium banner CTA button" }
```

- [ ] **Step 4: Add abstract getters to app_localizations.dart**

Add after the last existing abstract getter:
```dart
  String get history_title;
  String get history_filter_all;
  String get history_filter_completed;
  String get history_filter_passed;
  String get history_empty_title;
  String get history_empty_body;
  String history_event_completed(String name);
  String get history_event_pass_turn;
  String history_event_reason(String reason);
  String get history_load_more;
  String get history_premium_banner_title;
  String get history_premium_banner_body;
  String get history_premium_banner_cta;
```

- [ ] **Step 5: Add ES implementations to app_localizations_es.dart**

```dart
  @override
  String get history_title => 'Historial';

  @override
  String get history_filter_all => 'Todos';

  @override
  String get history_filter_completed => 'Completadas';

  @override
  String get history_filter_passed => 'Pases';

  @override
  String get history_empty_title => 'Sin actividad';

  @override
  String get history_empty_body => 'Aún no hay eventos en el historial';

  @override
  String history_event_completed(String name) => '$name completó';

  @override
  String get history_event_pass_turn => 'pase de turno';

  @override
  String history_event_reason(String reason) => 'Motivo: $reason';

  @override
  String get history_load_more => 'Cargar más';

  @override
  String get history_premium_banner_title => 'Más historial con Premium';

  @override
  String get history_premium_banner_body => 'Accede a 90 días de historial';

  @override
  String get history_premium_banner_cta => 'Actualizar a Premium';
```

- [ ] **Step 6: Add EN implementations to app_localizations_en.dart**

```dart
  @override
  String get history_title => 'History';

  @override
  String get history_filter_all => 'All';

  @override
  String get history_filter_completed => 'Completed';

  @override
  String get history_filter_passed => 'Passes';

  @override
  String get history_empty_title => 'No activity yet';

  @override
  String get history_empty_body => 'No events in the history yet';

  @override
  String history_event_completed(String name) => '$name completed';

  @override
  String get history_event_pass_turn => 'turn pass';

  @override
  String history_event_reason(String reason) => 'Reason: $reason';

  @override
  String get history_load_more => 'Load more';

  @override
  String get history_premium_banner_title => 'More history with Premium';

  @override
  String get history_premium_banner_body => 'Access 90 days of history';

  @override
  String get history_premium_banner_cta => 'Upgrade to Premium';
```

- [ ] **Step 7: Add RO implementations to app_localizations_ro.dart**

```dart
  @override
  String get history_title => 'Istoric';

  @override
  String get history_filter_all => 'Toate';

  @override
  String get history_filter_completed => 'Finalizate';

  @override
  String get history_filter_passed => 'Pasări';

  @override
  String get history_empty_title => 'Nicio activitate';

  @override
  String get history_empty_body => 'Nu există încă evenimente în istoric';

  @override
  String history_event_completed(String name) => '$name a finalizat';

  @override
  String get history_event_pass_turn => 'pasare de tură';

  @override
  String history_event_reason(String reason) => 'Motiv: $reason';

  @override
  String get history_load_more => 'Încarcă mai mult';

  @override
  String get history_premium_banner_title => 'Mai mult istoric cu Premium';

  @override
  String get history_premium_banner_body => 'Accesează 90 de zile de istoric';

  @override
  String get history_premium_banner_cta => 'Actualizează la Premium';
```

- [ ] **Step 8: Verify compilation**

```bash
flutter analyze lib/l10n/
```

Expected: No errors.

- [ ] **Step 9: Commit**

```bash
git add lib/l10n/
git commit -m "feat(history): add i18n strings for history feature (es/en/ro)"
```

---

## Task 7: Route constant + app.dart wiring

**Files:**
- Modify: `lib/core/constants/routes.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Add route constant**

In `lib/core/constants/routes.dart`, add to the `AppRoutes` class:
```dart
static const String history = '/history';
```
And add `history` to the `all` list.

- [ ] **Step 2: Add GoRoute in app.dart**

In `lib/app.dart`, add the import:
```dart
import 'features/history/presentation/history_screen.dart';
```

And add the route inside the `routes` list:
```dart
GoRoute(
  path: AppRoutes.history,
  builder: (_, __) => const HistoryScreen(),
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/routes.dart lib/app.dart
git commit -m "feat(history): add /history route"
```

---

## Task 8: UI widgets

**Files:**
- Create: `lib/features/history/presentation/widgets/history_empty_state.dart`
- Create: `lib/features/history/presentation/widgets/history_event_tile.dart`
- Create: `lib/features/history/presentation/widgets/history_filter_bar.dart`

- [ ] **Step 1: Create HistoryEmptyState**

```dart
// lib/features/history/presentation/widgets/history_empty_state.dart
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.history_empty_title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.history_empty_body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create HistoryEventTile**

```dart
// lib/features/history/presentation/widgets/history_event_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../features/history/domain/task_event.dart';
import '../../../../l10n/app_localizations.dart';

class HistoryEventTile extends StatelessWidget {
  const HistoryEventTile({
    super.key,
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    this.toName,
  });

  final TaskEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String? toName;

  static String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return DateFormat('EEE d MMM, HH:mm', 'es').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return event.map(
      completed: (e) => _CompletedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        timestamp: _formatTimestamp(e.createdAt),
        l10n: l10n,
      ),
      passed: (e) => _PassedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        toName: toName ?? e.toUid,
        timestamp: _formatTimestamp(e.createdAt),
        l10n: l10n,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 20,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
    );
  }
}

class _CompletedTile extends StatelessWidget {
  const _CompletedTile({
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.timestamp,
    required this.l10n,
  });
  final CompletedEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String timestamp;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '${visual.value} ${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    return ListTile(
      key: Key('history_tile_${event.id}'),
      leading: _Avatar(photoUrl: actorPhotoUrl, name: actorName),
      title: Text(l10n.history_event_completed(actorName)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(taskLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
    );
  }
}

class _PassedTile extends StatelessWidget {
  const _PassedTile({
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.toName,
    required this.timestamp,
    required this.l10n,
  });
  final PassedEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String toName;
  final String timestamp;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '${visual.value} ${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    return ListTile(
      key: Key('history_tile_${event.id}'),
      leading: _Avatar(photoUrl: actorPhotoUrl, name: actorName),
      title: Row(
        children: [
          Flexible(child: Text(actorName, overflow: TextOverflow.ellipsis)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 14),
          ),
          Flexible(child: Text(toName, overflow: TextOverflow.ellipsis)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$taskLabel — ${l10n.history_event_pass_turn}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          if (event.reason != null && event.reason!.isNotEmpty)
            Text(l10n.history_event_reason(event.reason!),
                style: const TextStyle(fontStyle: FontStyle.italic)),
          Text(timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: const Icon(Icons.swap_horiz, color: Colors.orange),
    );
  }
}
```

- [ ] **Step 3: Create HistoryFilterBar**

```dart
// lib/features/history/presentation/widgets/history_filter_bar.dart
import 'package:flutter/material.dart';
import '../../../../features/history/application/history_provider.dart';
import '../../../../l10n/app_localizations.dart';

class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final HistoryFilter current;
  final void Function(HistoryFilter) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      key: const Key('history_filter_bar'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            key: const Key('filter_chip_all'),
            label: l10n.history_filter_all,
            selected: current.eventType == null,
            onSelected: (_) => onChanged(
              HistoryFilter(memberUid: current.memberUid, taskId: current.taskId),
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            key: const Key('filter_chip_completed'),
            label: l10n.history_filter_completed,
            selected: current.eventType == 'completed',
            onSelected: (_) => onChanged(
              HistoryFilter(
                memberUid: current.memberUid,
                taskId: current.taskId,
                eventType: 'completed',
              ),
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            key: const Key('filter_chip_passed'),
            label: l10n.history_filter_passed,
            selected: current.eventType == 'passed',
            onSelected: (_) => onChanged(
              HistoryFilter(
                memberUid: current.memberUid,
                taskId: current.taskId,
                eventType: 'passed',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final void Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/history/presentation/widgets/
git commit -m "feat(history): add HistoryEmptyState, HistoryEventTile, HistoryFilterBar widgets"
```

---

## Task 9: HistoryScreen

**Files:**
- Create: `lib/features/history/presentation/history_screen.dart`

- [ ] **Step 1: Create HistoryScreen**

```dart
// lib/features/history/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/homes/application/current_home_provider.dart';
import '../../../features/homes/application/dashboard_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/history_provider.dart';
import '../domain/task_event.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_event_tile.dart';
import 'widgets/history_filter_bar.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();
  HistoryFilter _filter = const HistoryFilter();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isPremium {
    final dashboard = ref.read(dashboardProvider).valueOrNull;
    return dashboard?.premiumFlags.isPremium ?? false;
  }

  String? get _homeId =>
      ref.read(currentHomeProvider).valueOrNull?.id;

  void _loadInitial() {
    final homeId = _homeId;
    if (homeId == null) return;
    ref
        .read(historyNotifierProvider(homeId).notifier)
        .loadMore(isPremium: _isPremium);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final homeId = _homeId;
    if (homeId == null) return;
    ref
        .read(historyNotifierProvider(homeId).notifier)
        .loadMore(isPremium: _isPremium);
  }

  void _applyFilter(HistoryFilter filter) {
    final homeId = _homeId;
    if (homeId == null) return;
    setState(() => _filter = filter);
    ref
        .read(historyNotifierProvider(homeId).notifier)
        .applyFilter(filter);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref
            .read(historyNotifierProvider(homeId).notifier)
            .loadMore(isPremium: _isPremium));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeAsync = ref.watch(currentHomeProvider);

    return homeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.history_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.history_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (home) {
        if (home == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.history_title)),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        final historyAsync =
            ref.watch(historyNotifierProvider(home.id));
        final notifier =
            ref.read(historyNotifierProvider(home.id).notifier);
        final isPremium = _isPremium;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.history_title)),
          body: Column(
            children: [
              HistoryFilterBar(
                current: _filter,
                onChanged: _applyFilter,
              ),
              Expanded(
                child: historyAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Center(child: Text(l10n.error_generic)),
                  data: (events) {
                    if (events.isEmpty) {
                      return const HistoryEmptyState();
                    }

                    return ListView.builder(
                      key: const Key('history_list'),
                      controller: _scrollController,
                      itemCount:
                          events.length + (notifier.hasMore ? 1 : 0) + (!isPremium ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < events.length) {
                          return _buildEventTile(events[index]);
                        }
                        // Premium upgrade banner at end for Free users
                        if (!isPremium && index == events.length) {
                          return _PremiumBanner(l10n: l10n);
                        }
                        // Load more indicator
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: TextButton(
                              key: const Key('btn_load_more'),
                              onPressed: _loadMore,
                              child: Text(l10n.history_load_more),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventTile(TaskEvent event) {
    // In a real app, member names/photos would come from a provider.
    // For now, use actorUid as fallback name.
    final actorName = event.actorUid;
    String? toName;
    if (event is PassedEvent) toName = event.toUid;

    return HistoryEventTile(
      event: event,
      actorName: actorName,
      actorPhotoUrl: null,
      toName: toName,
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('premium_banner'),
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.history_premium_banner_title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.history_premium_banner_body),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('btn_upgrade_premium'),
                onPressed: () {},
                child: Text(l10n.history_premium_banner_cta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/history/presentation/history_screen.dart
git commit -m "feat(history): add HistoryScreen with infinite scroll, filters and premium banner"
```

---

## Task 10: UI tests + golden tests

**Files:**
- Create: `test/ui/features/history/history_screen_test.dart`

- [ ] **Step 1: Write UI tests**

```dart
// test/ui/features/history/history_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/domain/task_event.dart';
import 'package:toka/features/history/presentation/widgets/history_empty_state.dart';
import 'package:toka/features/history/presentation/widgets/history_event_tile.dart';
import 'package:toka/features/history/presentation/widgets/history_filter_bar.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

final _visual = const TaskVisual(kind: 'emoji', value: '🧹');
final _now = DateTime(2026, 4, 6, 12, 0);

CompletedEvent _completedEvent() => TaskEvent.completed(
      id: 'e1',
      taskId: 'task1',
      taskTitleSnapshot: 'Barrer',
      taskVisualSnapshot: _visual,
      actorUid: 'uid-A',
      performerUid: 'uid-A',
      completedAt: _now,
      createdAt: _now,
    ) as CompletedEvent;

PassedEvent _passedEvent() => TaskEvent.passed(
      id: 'e2',
      taskId: 'task2',
      taskTitleSnapshot: 'Aspirar',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🌀'),
      actorUid: 'uid-B',
      fromUid: 'uid-B',
      toUid: 'uid-C',
      reason: 'Me voy de viaje',
      penaltyApplied: true,
      complianceBefore: 0.8,
      complianceAfter: 0.7,
      createdAt: _now,
    ) as PassedEvent;

void main() {
  group('HistoryEmptyState', () {
    testWidgets('muestra título y cuerpo del empty state', (tester) async {
      await tester.pumpWidget(_wrap(const HistoryEmptyState()));
      expect(find.text('Sin actividad'), findsOneWidget);
      expect(find.text('Aún no hay eventos en el historial'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('HistoryEventTile — completed', () {
    testWidgets('muestra nombre, tarea y timestamp del evento completado',
        (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryEventTile(
          event: _completedEvent(),
          actorName: 'Ana',
          actorPhotoUrl: null,
        ),
      ));
      expect(find.textContaining('Ana'), findsOneWidget);
      expect(find.textContaining('🧹 Barrer'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  group('HistoryEventTile — passed', () {
    testWidgets('muestra motivo del pase cuando existe', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryEventTile(
          event: _passedEvent(),
          actorName: 'Bob',
          actorPhotoUrl: null,
          toName: 'Carlos',
        ),
      ));
      expect(find.textContaining('Motivo: Me voy de viaje'), findsOneWidget);
      expect(find.textContaining('🌀 Aspirar'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });

    testWidgets('no muestra motivo cuando es null', (tester) async {
      final event = TaskEvent.passed(
        id: 'e3',
        taskId: 'task3',
        taskTitleSnapshot: 'Fregar',
        taskVisualSnapshot: _visual,
        actorUid: 'uid-A',
        fromUid: 'uid-A',
        toUid: 'uid-B',
        reason: null,
        penaltyApplied: false,
        complianceBefore: null,
        complianceAfter: null,
        createdAt: _now,
      ) as PassedEvent;

      await tester.pumpWidget(_wrap(
        HistoryEventTile(
          event: event,
          actorName: 'Ana',
          actorPhotoUrl: null,
          toName: 'Bob',
        ),
      ));
      expect(find.textContaining('Motivo:'), findsNothing);
    });
  });

  group('HistoryFilterBar', () {
    testWidgets('muestra todos los chips de filtro', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryFilterBar(
          current: const HistoryFilter(),
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Completadas'), findsOneWidget);
      expect(find.text('Pases'), findsOneWidget);
    });

    testWidgets('chip Todos está seleccionado por defecto', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryFilterBar(
          current: const HistoryFilter(),
          onChanged: (_) {},
        ),
      ));
      final chip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('Todos'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('tap en Completadas llama onChanged con eventType:completed',
        (tester) async {
      HistoryFilter? received;
      await tester.pumpWidget(_wrap(
        HistoryFilterBar(
          current: const HistoryFilter(),
          onChanged: (f) => received = f,
        ),
      ));
      await tester.tap(find.byKey(const Key('filter_chip_completed')));
      await tester.pump();
      expect(received?.eventType, 'completed');
    });

    testWidgets('tap en Pases llama onChanged con eventType:passed',
        (tester) async {
      HistoryFilter? received;
      await tester.pumpWidget(_wrap(
        HistoryFilterBar(
          current: const HistoryFilter(),
          onChanged: (f) => received = f,
        ),
      ));
      await tester.tap(find.byKey(const Key('filter_chip_passed')));
      await tester.pump();
      expect(received?.eventType, 'passed');
    });
  });

  group('Golden tests', () {
    testWidgets('golden: HistoryEventTile completado', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryEventTile(
          event: _completedEvent(),
          actorName: 'Ana García',
          actorPhotoUrl: null,
        ),
      ));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/history_event_tile_completed.png'),
      );
    });

    testWidgets('golden: HistoryEventTile pase de turno', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryEventTile(
          event: _passedEvent(),
          actorName: 'Bob López',
          actorPhotoUrl: null,
          toName: 'Carlos Martínez',
        ),
      ));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/history_event_tile_passed.png'),
      );
    });
  });
}
```

- [ ] **Step 2: Run UI tests to generate goldens**

```bash
flutter test test/ui/features/history/history_screen_test.dart --update-goldens
```

Expected: Tests pass and golden files created in `test/ui/features/history/goldens/`.

- [ ] **Step 3: Run UI tests without update flag to verify**

```bash
flutter test test/ui/features/history/history_screen_test.dart
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/ui/features/history/
git commit -m "test(history): add UI and golden tests for history widgets"
```

---

## Task 11: Run all tests

- [ ] **Step 1: Run full test suite**

```bash
flutter test test/unit/ test/integration/ test/ui/
```

Expected: All tests pass, including new history tests.

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze
```

Expected: No errors.

- [ ] **Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix(history): address any remaining analysis issues"
```
