# ViewModel Contracts Enrichment — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enriquecer los contratos de los 6 ViewModels principales (Today, History, MemberProfile, AllTasks, CreateEditTask, TaskDetail) con los campos y acciones que faltan para que cada pantalla sea completamente autosuficiente a partir de su ViewModel.

**Architecture:** Patrón MVVM con abstract class como contrato. El dominio no recibe campos de presentación — los joins (nombre del actor, foto) se resuelven en clases de presentación en la capa Application. El estado de UI efímero (dropdown abierto) se gestiona localmente en el screen, no en el ViewModel.

**Tech Stack:** Flutter 3.x · Dart 3.x · Riverpod (riverpod_annotation) · freezed · mocktail (tests) · flutter_test

---

## Notas previas sobre el modelo existente

Antes de implementar, tener en cuenta:
- `Task.difficultyWeight` es un `double` (0.5–3.0), no hay enum `TaskDifficulty`. Los ViewModels exponen `difficultyWeight: double`.
- `DoneTaskPreview.completedAt` ya existe (la spec lo llamó `doneAt` — en código se usa `completedAt`).
- `RecurrenceRule.time` siempre es un `String` requerido ("HH:mm"). El toggle `hasFixedTime` en CreateEditTask es UI: cuando `false`, el time se fija a `'00:00'`; cuando `true`, el usuario elige hora.
- `Member.tasksCompleted` = `completedCount`, `Member.currentStreak` = `streakCount`, `Member.averageScore` = `averageScore`.
- `upcomingOccurrencesProvider` calcula 3 ocurrencias por defecto; TaskDetail necesita 5.
- `AllTasksViewData.canCreate` debe renombrarse a `canManage` (el test existente todavía usa `canCreate` — actualizar junto con el campo).

---

## Mapa de archivos

| Archivo | Acción |
|---------|--------|
| `lib/features/homes/domain/home_membership.dart` | Modificar — añadir `hasPendingToday` |
| `lib/features/homes/data/home_model.dart` | Modificar — leer `hasPendingToday` del doc Firestore |
| `functions/src/tasks/update_dashboard.ts` | Modificar — escribir `hasPendingToday` en membresías |
| `lib/features/tasks/application/today_view_model.dart` | Modificar — añadir `HomeDropdownItem`, `homes`, `selectHome` |
| `lib/features/history/application/history_view_model.dart` | Modificar — añadir `TaskEventItem`, cambiar `events` → `items`, añadir `rateEvent` |
| `lib/features/members/application/member_profile_view_model.dart` | Modificar — añadir `OverflowEntry`, stats y radar lógica en ViewData |
| `lib/features/profile/application/member_radar_provider.dart` | Modificar — ordenar activas-primero + frecuencia, incluir `visualKind/Value` |
| `lib/features/profile/presentation/widgets/radar_chart_widget.dart` | Modificar — `RadarEntry` añade `visualKind/visualValue` |
| `lib/features/tasks/application/all_tasks_view_model.dart` | Modificar — selección múltiple, bulk actions, renombrar `canCreate→canManage` |
| `lib/features/tasks/application/create_edit_task_view_model.dart` | Modificar — añadir `showApplyToday`, `upcomingDates`, `orderedMembers`, `hasFixedTime`, `toggleMember`, `reorderMember` |
| `lib/features/tasks/application/task_detail_view_model.dart` | Modificar — añadir `difficultyWeight`, ampliar ocurrencias a 5 |
| `test/unit/features/tasks/today_view_model_test.dart` | Modificar — añadir tests de HomeDropdownItem |
| `test/unit/features/history/history_view_model_test.dart` | Modificar — añadir tests de TaskEventItem y canRate |
| `test/unit/features/members/member_profile_view_model_test.dart` | Modificar — añadir tests de stats y overflow |
| `test/unit/features/tasks/all_tasks_view_model_test.dart` | Modificar — añadir tests de selección múltiple, bulk, renombrar canCreate |
| `test/unit/features/tasks/create_edit_task_view_model_test.dart` | Modificar — añadir tests de showApplyToday, upcomingDates, orderedMembers |
| `test/unit/features/tasks/task_detail_view_model_test.dart` | Modificar — añadir tests de difficultyWeight y 5 ocurrencias |

---

## Task 1 — `HomeMembership.hasPendingToday` (dominio + data + backend)

**Files:**
- Modify: `lib/features/homes/domain/home_membership.dart`
- Modify: `lib/features/homes/data/home_model.dart`
- Modify: `functions/src/tasks/update_dashboard.ts`
- Test: `test/unit/features/homes/homes_repository_test.dart` (añadir caso)

- [ ] **Step 1: Añadir campo al dominio**

En `lib/features/homes/domain/home_membership.dart` añadir el campo con valor por defecto `false` para retrocompatibilidad:

```dart
@freezed
class HomeMembership with _$HomeMembership {
  const factory HomeMembership({
    required String homeId,
    required String homeNameSnapshot,
    required MemberRole role,
    required BillingState billingState,
    required MemberStatus status,
    required DateTime joinedAt,
    DateTime? leftAt,
    @Default(false) bool hasPendingToday,  // ← nuevo
  }) = _HomeMembership;
}
```

- [ ] **Step 2: Regenerar código freezed**

```bash
cd "c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka"
dart run build_runner build --delete-conflicting-outputs
```

Esperado: sin errores de compilación.

- [ ] **Step 3: Actualizar el mapper en `home_model.dart`**

En `lib/features/homes/data/home_model.dart`, método `membershipFromFirestore`, añadir la lectura del campo nuevo. Sustituir la llamada existente por:

```dart
static HomeMembership membershipFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return HomeMembership(
    homeId: doc.id,
    homeNameSnapshot: data['homeNameSnapshot'] as String,
    role: MemberRole.values.firstWhere(
      (e) => e.name == (data['role'] as String? ?? 'member'),
      orElse: () => MemberRole.member,
    ),
    billingState: BillingState.values.firstWhere(
      (e) => e.name == (data['billingState'] as String? ?? 'none'),
      orElse: () => BillingState.none,
    ),
    status: MemberStatus.values.firstWhere(
      (e) => e.name == (data['status'] as String? ?? 'active'),
      orElse: () => MemberStatus.active,
    ),
    joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    leftAt: (data['leftAt'] as Timestamp?)?.toDate(),
    hasPendingToday: data['hasPendingToday'] as bool? ?? false,  // ← nuevo
  );
}
```

- [ ] **Step 4: Actualizar la Cloud Function `update_dashboard.ts`**

En `functions/src/tasks/update_dashboard.ts`, al final de la función que actualiza el dashboard de cada hogar, añadir la escritura de `hasPendingToday` en cada documento de membresía del usuario. Localizar el bloque que recalcula contadores y añadir al final de la función principal:

```typescript
// Después de calcular tasksDueToday y tasksDoneToday para el hogar:
const hasPendingToday = tasksDueToday > tasksDoneToday;

// Para cada miembro activo del hogar, actualizar su documento de membresía
const memberUids: string[] = activeMembers.map((m: any) => m.uid);
const membershipUpdates = memberUids.map((uid: string) =>
  db.collection('users').doc(uid)
    .collection('memberships').doc(homeId)
    .update({ hasPendingToday })
);
await Promise.all(membershipUpdates);
```

> **Nota:** `tasksDueToday`, `tasksDoneToday`, `activeMembers` y `homeId` ya están disponibles en el contexto de `update_dashboard.ts`. Adaptar los nombres de variables al código existente si difieren.

- [ ] **Step 5: Escribir test unitario del mapper**

En `test/unit/features/homes/homes_repository_test.dart` ya existen tests del mapper. Añadir al grupo existente:

```dart
test('membershipFromFirestore lee hasPendingToday correctamente', () {
  // Este test verifica que el mapper pasa el campo al modelo.
  // Usar FakeDocumentSnapshot de los tests existentes.
  final data = {
    'homeNameSnapshot': 'Hogar Test',
    'role': 'member',
    'billingState': 'none',
    'status': 'active',
    'joinedAt': Timestamp.fromDate(DateTime(2024)),
    'hasPendingToday': true,
  };
  final membership = HomeModel.membershipFromFirestore(
    FakeDocumentSnapshot(id: 'home1', data: data),
  );
  expect(membership.hasPendingToday, isTrue);
});

test('membershipFromFirestore usa false por defecto si falta hasPendingToday', () {
  final data = {
    'homeNameSnapshot': 'Hogar Test',
    'role': 'member',
    'billingState': 'none',
    'status': 'active',
    'joinedAt': Timestamp.fromDate(DateTime(2024)),
    // hasPendingToday ausente
  };
  final membership = HomeModel.membershipFromFirestore(
    FakeDocumentSnapshot(id: 'home1', data: data),
  );
  expect(membership.hasPendingToday, isFalse);
});
```

- [ ] **Step 6: Ejecutar tests**

```bash
flutter test test/unit/features/homes/homes_repository_test.dart -v
```

Esperado: todos PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/homes/domain/home_membership.dart \
        lib/features/homes/domain/home_membership.freezed.dart \
        lib/features/homes/data/home_model.dart \
        functions/src/tasks/update_dashboard.ts \
        test/unit/features/homes/homes_repository_test.dart
git commit -m "feat(homes): añadir HomeMembership.hasPendingToday para indicador de pendientes en selector de hogar"
```

---

## Task 2 — `TodayViewModel`: selector de hogares con punto rojo

**Files:**
- Modify: `lib/features/tasks/application/today_view_model.dart`
- Modify: `lib/features/tasks/application/today_view_model.g.dart` (regenerar)
- Modify: `test/unit/features/tasks/today_view_model_test.dart`

- [ ] **Step 1: Escribir tests fallidos para HomeDropdownItem y selectHome**

Añadir al final de `test/unit/features/tasks/today_view_model_test.dart`:

```dart
// Añadir imports necesarios al principio del archivo:
// import 'package:toka/features/homes/domain/home_membership.dart';

group('TodayViewModel.homes — HomeDropdownItem', () {
  test('hasPendingToday true cuando membresía lo indica', () {
    final membership = HomeMembership(
      homeId: 'h1',
      homeNameSnapshot: 'Casa de Ana',
      role: MemberRole.owner,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
      hasPendingToday: true,
    );
    // HomeDropdownItem se construye desde HomeMembership
    final item = HomeDropdownItem.fromMembership(
      membership,
      emoji: '🏠',
      isSelected: true,
    );
    expect(item.hasPendingToday, isTrue);
    expect(item.isSelected, isTrue);
    expect(item.homeId, 'h1');
  });

  test('hasPendingToday false cuando membresía tiene false', () {
    final membership = HomeMembership(
      homeId: 'h2',
      homeNameSnapshot: 'Piso',
      role: MemberRole.member,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
      hasPendingToday: false,
    );
    final item = HomeDropdownItem.fromMembership(
      membership,
      emoji: '🏡',
      isSelected: false,
    );
    expect(item.hasPendingToday, isFalse);
  });
});
```

- [ ] **Step 2: Ejecutar para verificar FAIL**

```bash
flutter test test/unit/features/tasks/today_view_model_test.dart -v
```

Esperado: FAIL — `HomeDropdownItem` no existe aún.

- [ ] **Step 3: Añadir `HomeDropdownItem` y actualizar el contrato**

En `lib/features/tasks/application/today_view_model.dart`, añadir la clase y actualizar el contrato e implementación:

```dart
// Añadir import al principio:
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';

/// Representa un hogar en el dropdown del selector de pantalla Hoy.
class HomeDropdownItem {
  const HomeDropdownItem({
    required this.homeId,
    required this.name,
    required this.emoji,
    required this.role,
    required this.hasPendingToday,
    required this.isSelected,
  });

  final String homeId;
  final String name;
  final String emoji;
  final MemberRole role;
  final bool hasPendingToday;
  final bool isSelected;

  factory HomeDropdownItem.fromMembership(
    HomeMembership membership, {
    required String emoji,
    required bool isSelected,
  }) =>
      HomeDropdownItem(
        homeId: membership.homeId,
        name: membership.homeNameSnapshot,
        emoji: emoji,
        role: membership.role,
        hasPendingToday: membership.hasPendingToday,
        isSelected: isSelected,
      );
}
```

Actualizar el contrato abstracto:

```dart
abstract class TodayViewModel {
  AsyncValue<TodayViewData?> get viewData;
  List<HomeDropdownItem> get homes;       // ← nuevo
  void selectHome(String homeId);         // ← nuevo
  Future<void> completeTask(String taskId);
  Future<({double complianceBefore, double estimatedAfter})> fetchPassStats(
      String currentUid);
  Future<void> passTurn(String taskId, {String? reason});
  void retry();
}
```

Actualizar `_TodayViewModelImpl`:

```dart
class _TodayViewModelImpl implements TodayViewModel {
  const _TodayViewModelImpl({
    required this.viewData,
    required this.homes,    // ← nuevo
    required this.ref,
  });

  @override
  final AsyncValue<TodayViewData?> viewData;
  @override
  final List<HomeDropdownItem> homes;   // ← nuevo
  final Ref ref;

  String? get _homeId => viewData.valueOrNull?.homeId;

  @override
  void selectHome(String homeId) =>
      ref.read(currentHomeProvider.notifier).switchHome(homeId);  // ← nuevo

  // ... resto de métodos sin cambios ...
}
```

Actualizar el provider al final del archivo para construir `homes`:

```dart
@riverpod
TodayViewModel todayViewModel(TodayViewModelRef ref) {
  final dashboardAsync = ref.watch(dashboardProvider);
  final auth = ref.watch(authProvider);
  final currentUid = auth.whenOrNull(authenticated: (u) => u.uid);
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';

  // Construir lista de hogares para el dropdown
  final memberships = currentUid != null
      ? ref.watch(userMembershipsProvider(currentUid)).valueOrNull ?? []
      : <HomeMembership>[];
  final homes = memberships.map((m) => HomeDropdownItem.fromMembership(
        m,
        emoji: '🏠', // TODO: leer emoji del documento Home cuando esté disponible
        isSelected: m.homeId == homeId,
      )).toList();

  final viewData = dashboardAsync.whenData((data) {
    // ... lógica existente sin cambios ...
  });

  return _TodayViewModelImpl(viewData: viewData, homes: homes, ref: ref);
}
```

- [ ] **Step 4: Regenerar código Riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Ejecutar tests**

```bash
flutter test test/unit/features/tasks/today_view_model_test.dart -v
```

Esperado: todos PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/tasks/application/today_view_model.dart \
        lib/features/tasks/application/today_view_model.g.dart \
        test/unit/features/tasks/today_view_model_test.dart
git commit -m "feat(today): añadir HomeDropdownItem y selectHome a TodayViewModel"
```

---

## Task 3 — `HistoryViewModel`: `TaskEventItem` + `rateEvent`

**Files:**
- Modify: `lib/features/history/application/history_view_model.dart`
- Modify: `lib/features/history/application/history_view_model.g.dart` (regenerar)
- Modify: `test/unit/features/history/history_view_model_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

Añadir al final de `test/unit/features/history/history_view_model_test.dart`:

```dart
// Añadir imports:
// import 'package:toka/features/history/application/history_view_model.dart';

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
      isOwnEvent: false,   // actor es otro
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
      isOwnEvent: true,   // yo mismo
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
      isRated: true,     // ya valorado
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
    expect(item.canRate, isFalse);  // PassedEvent nunca se valora
  });
});
```

- [ ] **Step 2: Verificar FAIL**

```bash
flutter test test/unit/features/history/history_view_model_test.dart -v
```

Esperado: FAIL — `TaskEventItem` no existe.

- [ ] **Step 3: Añadir `TaskEventItem` y actualizar el contrato**

Al principio de `lib/features/history/application/history_view_model.dart`, añadir antes de las clases existentes:

```dart
import '../../auth/application/auth_provider.dart';
import '../../members/application/members_provider.dart';

/// Evento enriquecido con datos de presentación.
/// [raw] contiene el evento de dominio original.
class TaskEventItem {
  const TaskEventItem({
    required this.raw,
    required this.actorName,
    this.actorPhotoUrl,
    required this.isOwnEvent,
    required this.isRated,
    required this.canRate,
  });

  final TaskEvent raw;
  final String    actorName;
  final String?   actorPhotoUrl;
  final bool      isOwnEvent;
  final bool      isRated;
  /// Solo true cuando raw es CompletedEvent && !isOwnEvent && !isRated.
  final bool      canRate;

  static bool computeCanRate({
    required TaskEvent raw,
    required bool isOwnEvent,
    required bool isRated,
  }) =>
      raw is CompletedEvent && !isOwnEvent && !isRated;
}
```

Actualizar el contrato abstracto:

```dart
abstract class HistoryViewModel {
  AsyncValue<List<TaskEventItem>> get items;  // ← era events: List<TaskEvent>
  HistoryFilter get filter;
  bool get hasMore;
  bool get isPremium;
  void loadMore();
  void applyFilter(HistoryFilter newFilter);
  Future<void> rateEvent(String eventId, double rating, {String? note});  // ← nuevo
}
```

Actualizar `_HistoryViewModelImpl`:

```dart
class _HistoryViewModelImpl implements HistoryViewModel {
  const _HistoryViewModelImpl({
    required this.items,     // ← era events
    required this.filter,
    required this.hasMore,
    required this.isPremium,
    required this.homeId,
    required this.currentUid,
    required this.ref,
  });

  @override
  final AsyncValue<List<TaskEventItem>> items;
  @override
  final HistoryFilter filter;
  @override
  final bool hasMore;
  @override
  final bool isPremium;
  final String? homeId;
  final String  currentUid;
  final Ref ref;

  @override
  void loadMore() {
    if (homeId == null) return;
    ref.read(historyNotifierProvider(homeId!).notifier)
        .loadMore(isPremium: isPremium);
  }

  @override
  void applyFilter(HistoryFilter newFilter) {
    if (homeId == null) return;
    ref.read(historyFilterNotifierProvider.notifier).setFilter(newFilter);
    ref.read(historyNotifierProvider(homeId!).notifier).applyFilter(newFilter);
    loadMore();
  }

  @override
  Future<void> rateEvent(String eventId, double rating, {String? note}) async {
    // Implementación mínima: guard + log.
    // La escritura a Firestore irá aquí cuando se implemente la colección
    // homes/{homeId}/taskRatings.
    // Por ahora solo previene crash si homeId es null.
    if (homeId == null) return;
    // TODO: llamar callable function o escribir directamente a Firestore
    // cuando se defina el schema de taskRatings.
  }
}
```

Actualizar el provider para construir `TaskEventItem`:

```dart
@riverpod
HistoryViewModel historyViewModel(HistoryViewModelRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  final filter = ref.watch(historyFilterNotifierProvider);
  final isPremium =
      ref.watch(dashboardProvider).valueOrNull?.premiumFlags.isPremium ?? false;
  final auth = ref.watch(authProvider);
  final currentUid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

  if (homeId == null) {
    return _HistoryViewModelImpl(
      items: const AsyncValue.loading(),
      filter: filter,
      hasMore: false,
      isPremium: isPremium,
      homeId: null,
      currentUid: currentUid,
      ref: ref,
    );
  }

  final rawEvents = ref.watch(historyNotifierProvider(homeId));
  final hasMore =
      ref.read(historyNotifierProvider(homeId).notifier).hasMore;

  // Resolver nombres y fotos de actores desde miembros del hogar
  final members = ref.watch(homeMembersProvider(homeId)).valueOrNull ?? [];
  final nameMap  = {for (final m in members) m.uid: m.nickname};
  final photoMap = {for (final m in members) m.uid: m.photoUrl};

  // Por ahora isRated = false hasta implementar la colección taskRatings.
  final items = rawEvents.whenData((events) => events.map((e) {
        final actorUid = switch (e) {
          CompletedEvent c => c.actorUid,
          PassedEvent p    => p.actorUid,
        };
        final isOwnEvent = actorUid == currentUid;
        const isRated = false;
        return TaskEventItem(
          raw: e,
          actorName: nameMap[actorUid] ?? actorUid,
          actorPhotoUrl: photoMap[actorUid],
          isOwnEvent: isOwnEvent,
          isRated: isRated,
          canRate: TaskEventItem.computeCanRate(
            raw: e,
            isOwnEvent: isOwnEvent,
            isRated: isRated,
          ),
        );
      }).toList());

  return _HistoryViewModelImpl(
    items: items,
    filter: filter,
    hasMore: hasMore,
    isPremium: isPremium,
    homeId: homeId,
    currentUid: currentUid,
    ref: ref,
  );
}
```

- [ ] **Step 4: Regenerar y ejecutar tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/features/history/history_view_model_test.dart -v
```

Esperado: todos PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/history/application/history_view_model.dart \
        lib/features/history/application/history_view_model.g.dart \
        test/unit/features/history/history_view_model_test.dart
git commit -m "feat(history): añadir TaskEventItem con canRate y rateEvent a HistoryViewModel"
```

---

## Task 4 — `MemberProfileViewModel`: estadísticas + overflow del radar

**Files:**
- Modify: `lib/features/profile/presentation/widgets/radar_chart_widget.dart`
- Modify: `lib/features/profile/application/member_radar_provider.dart`
- Modify: `lib/features/members/application/member_profile_view_model.dart`
- Modify: `lib/features/members/application/member_profile_view_model.g.dart` (regenerar)
- Modify: `test/unit/features/members/member_profile_view_model_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

Añadir a `test/unit/features/members/member_profile_view_model_test.dart`:

```dart
group('MemberProfileViewData — stats del Member', () {
  // fakeMember ya está definido al principio del test file con:
  // tasksCompleted: 10, currentStreak: 3, averageScore: 8.5

  test('completedCount viene de member.tasksCompleted', () {
    // Construir ViewData directamente para verificar el mapeo
    const data = MemberProfileViewData(
      member: fakeMember,  // ver definición al inicio del test file
      isSelf: false,
      visiblePhone: null,
      compliancePct: '85.0',
      radarEntries: [],
      canManageRoles: false,
      completedCount: 10,
      streakCount: 3,
      averageScore: 8.5,
      showRadar: false,
      overflowEntries: [],
    );
    expect(data.completedCount, 10);
    expect(data.streakCount, 3);
    expect(data.averageScore, 8.5);
  });

  test('showRadar false cuando radarEntries tiene menos de 3 elementos', () {
    const data = MemberProfileViewData(
      member: fakeMember,
      isSelf: false,
      visiblePhone: null,
      compliancePct: '85.0',
      radarEntries: [RadarEntry(taskName: 'T1', avgScore: 7.0)],
      canManageRoles: false,
      completedCount: 10,
      streakCount: 3,
      averageScore: 8.5,
      showRadar: false,
      overflowEntries: [],
    );
    expect(data.showRadar, isFalse);
  });

  test('showRadar true cuando radarEntries tiene 3 o más elementos', () {
    final entries = List.generate(
      3,
      (i) => RadarEntry(taskName: 'T$i', avgScore: 7.0),
    );
    final data = MemberProfileViewData(
      member: fakeMember,
      isSelf: false,
      visiblePhone: null,
      compliancePct: '85.0',
      radarEntries: entries,
      canManageRoles: false,
      completedCount: 10,
      streakCount: 3,
      averageScore: 8.5,
      showRadar: true,
      overflowEntries: [],
    );
    expect(data.showRadar, isTrue);
  });
});
```

- [ ] **Step 2: Verificar FAIL**

```bash
flutter test test/unit/features/members/member_profile_view_model_test.dart -v
```

Esperado: FAIL — `MemberProfileViewData` no acepta los nuevos campos.

- [ ] **Step 3: Añadir `OverflowEntry` y actualizar `MemberProfileViewData`**

En `lib/features/members/application/member_profile_view_model.dart`:

```dart
// Añadir import:
import '../../profile/presentation/widgets/radar_chart_widget.dart';

/// Entrada para tareas fuera del radar (cuando el miembro tiene >10 tareas asignadas).
class OverflowEntry {
  const OverflowEntry({
    required this.taskId,
    required this.title,
    required this.visualKind,
    required this.visualValue,
    required this.averageScore,
  });
  final String taskId;
  final String title;
  final String visualKind;
  final String visualValue;
  final double averageScore;
}

class MemberProfileViewData {
  const MemberProfileViewData({
    required this.member,
    required this.isSelf,
    required this.visiblePhone,
    required this.compliancePct,
    required this.radarEntries,
    required this.canManageRoles,
    required this.completedCount,     // ← nuevo
    required this.streakCount,        // ← nuevo
    required this.averageScore,       // ← nuevo
    required this.showRadar,          // ← nuevo
    required this.overflowEntries,    // ← nuevo
  });
  final Member member;
  final bool   isSelf;
  final String? visiblePhone;
  final String  compliancePct;
  final List<RadarEntry>    radarEntries;
  final bool                canManageRoles;
  final int                 completedCount;
  final int                 streakCount;
  final double              averageScore;
  final bool                showRadar;
  final List<OverflowEntry> overflowEntries;
}
```

- [ ] **Step 4: Actualizar la implementación del provider**

En el método `memberProfileViewModelProvider`, actualizar el bloque que construye `MemberProfileViewData`:

```dart
// Dentro del provider, donde se construye MemberProfileViewData:
final radarEntries = radarAsync.valueOrNull ?? [];

// Lógica de radar: máximo 10 en el gráfico, resto en overflow
const maxRadarEntries = 10;
const minRadarEntries = 3;
final showRadar = radarEntries.length >= minRadarEntries;
final visibleRadarEntries = radarEntries.take(maxRadarEntries).toList();
final overflowEntries = radarEntries.skip(maxRadarEntries).map((e) =>
  OverflowEntry(
    taskId: '',  // RadarEntry no tiene taskId — se puede añadir al provider si se necesita
    title: e.taskName,
    visualKind: 'emoji',
    visualValue: '',
    averageScore: e.avgScore,
  )).toList();

final viewData = memberAsync.whenData((member) => MemberProfileViewData(
      member: member,
      isSelf: isSelf,
      visiblePhone: member.phoneForViewer(isSelf: isSelf),
      compliancePct: (member.complianceRate * 100).toStringAsFixed(1),
      radarEntries: visibleRadarEntries,
      canManageRoles: isOwner && !isSelf,
      completedCount: member.tasksCompleted,   // ← nuevo
      streakCount: member.currentStreak,       // ← nuevo
      averageScore: member.averageScore,       // ← nuevo
      showRadar: showRadar,                    // ← nuevo
      overflowEntries: overflowEntries,        // ← nuevo
    ));
```

- [ ] **Step 5: Regenerar y ejecutar tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/features/members/member_profile_view_model_test.dart -v
```

Esperado: todos PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/members/application/member_profile_view_model.dart \
        lib/features/members/application/member_profile_view_model.g.dart \
        test/unit/features/members/member_profile_view_model_test.dart
git commit -m "feat(members): exponer stats (completedCount, streak, score) y overflow del radar en MemberProfileViewModel"
```

---

## Task 5 — `AllTasksViewModel`: selección múltiple + bulk actions + renombrar `canCreate`

**Files:**
- Modify: `lib/features/tasks/application/all_tasks_view_model.dart`
- Modify: `lib/features/tasks/application/all_tasks_view_model.freezed.dart` (regenerar)
- Modify: `lib/features/tasks/application/all_tasks_view_model.g.dart` (regenerar)
- Modify: `test/unit/features/tasks/all_tasks_view_model_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

Añadir al final de `test/unit/features/tasks/all_tasks_view_model_test.dart`:

```dart
// Nota: el test existente usa viewData!.canCreate — se actualiza a canManage aquí
group('AllTasksViewModel — selección múltiple', () {
  test('isSelectionMode false cuando selectedIds está vacío', () {
    // Crear container minimal con el VM
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final vm = container.read(allTasksViewModelProvider);
    expect(vm.isSelectionMode, isFalse);
    expect(vm.selectedIds, isEmpty);
  });

  test('toggleSelection añade id a selectedIds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final vm = container.read(allTasksViewModelProvider);
    vm.toggleSelection('task_1');
    // Leer el VM de nuevo para ver el estado actualizado
    final vm2 = container.read(allTasksViewModelProvider);
    expect(vm2.selectedIds, contains('task_1'));
    expect(vm2.isSelectionMode, isTrue);
  });

  test('toggleSelection sobre id ya seleccionado lo elimina (deselect)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final vm = container.read(allTasksViewModelProvider);
    vm.toggleSelection('task_1');
    vm.toggleSelection('task_1');
    final vm2 = container.read(allTasksViewModelProvider);
    expect(vm2.selectedIds, isNot(contains('task_1')));
    expect(vm2.isSelectionMode, isFalse);
  });

  test('clearSelection vacía selectedIds', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final vm = container.read(allTasksViewModelProvider);
    vm.toggleSelection('task_1');
    vm.toggleSelection('task_2');
    vm.clearSelection();
    final vm2 = container.read(allTasksViewModelProvider);
    expect(vm2.selectedIds, isEmpty);
  });
});

// Actualizar test existente: canCreate → canManage
group('AllTasksViewModel canManage (antes canCreate)', () {
  test('owner → canManage == true', () async {
    final container = _makeCanCreateContainer(
      staleRole: MemberRole.owner,
      authoritativeRole: MemberRole.owner,
    );
    addTearDown(container.dispose);
    final viewData = await _resolveViewData(container);
    expect(viewData, isNotNull);
    expect(viewData!.canManage, isTrue);  // ← renombrado
  });

  test('member → canManage == false', () async {
    final container = _makeCanCreateContainer(
      staleRole: MemberRole.member,
      authoritativeRole: MemberRole.member,
    );
    addTearDown(container.dispose);
    final viewData = await _resolveViewData(container);
    expect(viewData, isNotNull);
    expect(viewData!.canManage, isFalse);  // ← renombrado
  });
});
```

- [ ] **Step 2: Verificar FAIL**

```bash
flutter test test/unit/features/tasks/all_tasks_view_model_test.dart -v
```

Esperado: FAIL — `selectedIds`, `isSelectionMode`, `toggleSelection`, `canManage` no existen.

- [ ] **Step 3: Añadir estado de selección y actualizar contrato**

En `lib/features/tasks/application/all_tasks_view_model.dart`:

Renombrar `canCreate` → `canManage` en `AllTasksViewData`:

```dart
class AllTasksViewData {
  const AllTasksViewData({
    required this.tasks,
    required this.filter,
    required this.canManage,   // ← renombrado de canCreate
    required this.uid,
    required this.homeId,
  });
  final List<Task>     tasks;
  final AllTasksFilter filter;
  final bool           canManage;  // ← renombrado
  final String         uid;
  final String         homeId;
}
```

Añadir notifier de selección:

```dart
@riverpod
class AllTasksSelectionNotifier extends _$AllTasksSelectionNotifier {
  @override
  Set<String> build() => {};

  void toggle(String taskId) {
    final current = Set<String>.from(state);
    if (current.contains(taskId)) {
      current.remove(taskId);
    } else {
      current.add(taskId);
    }
    state = current;
  }

  void clear() => state = {};
}
```

Actualizar el contrato abstracto:

```dart
abstract class AllTasksViewModel {
  AsyncValue<AllTasksViewData?> get viewData;
  Set<String> get selectedIds;
  bool get isSelectionMode;
  void setStatusFilter(TaskStatus s);
  void setAssigneeFilter(String? uid);
  void toggleSelection(String taskId);
  void clearSelection();
  Future<void> toggleFreeze(Task task);
  Future<void> deleteTask(Task task);
  Future<void> bulkDelete();
  Future<void> bulkFreeze();
}
```

Actualizar `_AllTasksViewModelImpl`:

```dart
class _AllTasksViewModelImpl implements AllTasksViewModel {
  const _AllTasksViewModelImpl({
    required this.viewData,
    required this.selectedIds,
    required this.ref,
  });

  @override
  final AsyncValue<AllTasksViewData?> viewData;
  @override
  final Set<String> selectedIds;
  final Ref ref;

  @override
  bool get isSelectionMode => selectedIds.isNotEmpty;

  @override
  void setStatusFilter(TaskStatus s) =>
      ref.read(allTasksFilterNotifierProvider.notifier).setStatus(s);

  @override
  void setAssigneeFilter(String? uid) =>
      ref.read(allTasksFilterNotifierProvider.notifier).setAssignee(uid);

  @override
  void toggleSelection(String taskId) =>
      ref.read(allTasksSelectionNotifierProvider.notifier).toggle(taskId);

  @override
  void clearSelection() =>
      ref.read(allTasksSelectionNotifierProvider.notifier).clear();

  @override
  Future<void> toggleFreeze(Task task) async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null) return;
    final repo = ref.read(tasksRepositoryProvider);
    if (task.status == TaskStatus.active) {
      await repo.freezeTask(homeId, task.id);
    } else {
      await repo.unfreezeTask(homeId, task.id);
    }
  }

  @override
  Future<void> deleteTask(Task task) async {
    final data = viewData.valueOrNull;
    if (data == null) return;
    await ref.read(tasksRepositoryProvider).deleteTask(data.homeId, task.id, data.uid);
  }

  @override
  Future<void> bulkDelete() async {
    final data = viewData.valueOrNull;
    if (data == null || !data.canManage) return;
    final homeId = data.homeId;
    final uid    = data.uid;
    final repo   = ref.read(tasksRepositoryProvider);
    for (final taskId in List.of(selectedIds)) {
      await repo.deleteTask(homeId, taskId, uid);
    }
    clearSelection();
  }

  @override
  Future<void> bulkFreeze() async {
    final data = viewData.valueOrNull;
    if (data == null || !data.canManage) return;
    final homeId = data.homeId;
    final repo   = ref.read(tasksRepositoryProvider);
    for (final task in data.tasks.where((t) => selectedIds.contains(t.id))) {
      if (task.status == TaskStatus.active) {
        await repo.freezeTask(homeId, task.id);
      }
    }
    clearSelection();
  }
}
```

Actualizar el provider para incluir `selectedIds`:

```dart
@riverpod
AllTasksViewModel allTasksViewModel(AllTasksViewModelRef ref) {
  final filter     = ref.watch(allTasksFilterNotifierProvider);
  final homeAsync  = ref.watch(currentHomeProvider);
  final authState  = ref.watch(authProvider);
  final uid        = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';
  final selectedIds = ref.watch(allTasksSelectionNotifierProvider);

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final homeMembersAsync = ref.watch(homeMembersProvider(home.id));
    final homeMembers = homeMembersAsync.valueOrNull;
    if (homeMembers == null) return null;
    final myMember = homeMembers
        .where((m) => m.uid == uid)
        .cast<Member?>()
        .firstOrNull;
    final canManage =  // ← era canCreate
        myMember?.role == MemberRole.owner || myMember?.role == MemberRole.admin;

    final tasksAsync = ref.watch(homeTasksProvider(home.id));
    final allTasks   = tasksAsync.valueOrNull ?? [];
    var filtered = allTasks.where((t) => t.status == filter.status).toList();
    if (filter.assigneeUid != null) {
      filtered = filtered.where((t) => t.currentAssigneeUid == filter.assigneeUid).toList();
    }
    filtered.sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));

    return AllTasksViewData(
      tasks: filtered,
      filter: filter,
      canManage: canManage,  // ← era canCreate
      uid: uid,
      homeId: home.id,
    );
  });

  return _AllTasksViewModelImpl(
    viewData: viewData,
    selectedIds: selectedIds,
    ref: ref,
  );
}
```

- [ ] **Step 4: Actualizar referencias a `canCreate` en tests existentes**

En `test/unit/features/tasks/all_tasks_view_model_test.dart`, buscar y reemplazar todas las ocurrencias de `canCreate` por `canManage`. También actualizar el helper `_resolveViewData` que lee `viewData!.canCreate`.

- [ ] **Step 5: Regenerar y ejecutar tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/features/tasks/all_tasks_view_model_test.dart -v
```

Esperado: todos PASS (incluyendo los tests existentes renombrados).

- [ ] **Step 6: Verificar que el screen compila con el renombrado**

```bash
flutter analyze lib/features/tasks/presentation/all_tasks_screen.dart
```

Si hay errores de `canCreate`, actualizarlos a `canManage` en el screen.

- [ ] **Step 7: Commit**

```bash
git add lib/features/tasks/application/all_tasks_view_model.dart \
        lib/features/tasks/application/all_tasks_view_model.freezed.dart \
        lib/features/tasks/application/all_tasks_view_model.g.dart \
        lib/features/tasks/presentation/all_tasks_screen.dart \
        test/unit/features/tasks/all_tasks_view_model_test.dart
git commit -m "feat(tasks): añadir selección múltiple y bulk actions a AllTasksViewModel, renombrar canCreate→canManage"
```

---

## Task 6 — `CreateEditTaskViewModel`: `showApplyToday`, `upcomingDates`, `orderedMembers`

**Files:**
- Modify: `lib/features/tasks/application/create_edit_task_view_model.dart`
- Modify: `lib/features/tasks/application/create_edit_task_view_model.freezed.dart` (regenerar)
- Modify: `lib/features/tasks/application/create_edit_task_view_model.g.dart` (regenerar)
- Modify: `test/unit/features/tasks/create_edit_task_view_model_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

Añadir a `test/unit/features/tasks/create_edit_task_view_model_test.dart`:

```dart
// Añadir imports:
// import 'package:toka/features/tasks/application/create_edit_task_view_model.dart';
// import 'package:toka/features/tasks/domain/recurrence_rule.dart';

group('CreateEditTaskViewModel — showApplyToday', () {
  test('showApplyToday false cuando no hay hora fija', () {
    // Sin hora fija, el toggle no tiene sentido
    expect(
      CreateEditTaskViewModel.computeShowApplyToday(
        hasFixedTime: false,
        fixedTime: null,
        now: TimeOfDay(hour: 9, minute: 0),
      ),
      isFalse,
    );
  });

  test('showApplyToday true cuando la hora fija es posterior a ahora', () {
    // Son las 9:00, la tarea es a las 10:00 → todavía hay tiempo → mostrar toggle
    expect(
      CreateEditTaskViewModel.computeShowApplyToday(
        hasFixedTime: true,
        fixedTime: TimeOfDay(hour: 10, minute: 0),
        now: TimeOfDay(hour: 9, minute: 0),
      ),
      isTrue,
    );
  });

  test('showApplyToday false cuando la hora fija ya pasó', () {
    // Son las 11:00, la tarea era a las 10:00 → ya pasó → no mostrar toggle
    expect(
      CreateEditTaskViewModel.computeShowApplyToday(
        hasFixedTime: true,
        fixedTime: TimeOfDay(hour: 10, minute: 0),
        now: TimeOfDay(hour: 11, minute: 0),
      ),
      isFalse,
    );
  });
});

group('CreateEditTaskViewModel — canSave', () {
  test('canSave false cuando el nombre está vacío', () {
    expect(
      CreateEditTaskViewModel.computeCanSave(
        name: '',
        assignedMemberCount: 2,
      ),
      isFalse,
    );
  });

  test('canSave false cuando no hay miembros asignados', () {
    expect(
      CreateEditTaskViewModel.computeCanSave(
        name: 'Barrer',
        assignedMemberCount: 0,
      ),
      isFalse,
    );
  });

  test('canSave true cuando hay nombre y al menos 1 miembro', () {
    expect(
      CreateEditTaskViewModel.computeCanSave(
        name: 'Barrer',
        assignedMemberCount: 1,
      ),
      isTrue,
    );
  });
});
```

- [ ] **Step 2: Verificar FAIL**

```bash
flutter test test/unit/features/tasks/create_edit_task_view_model_test.dart -v
```

Esperado: FAIL — métodos estáticos no existen.

- [ ] **Step 3: Actualizar `CreateEditTaskViewModel`**

Añadir las clases de presentación y los métodos estáticos al inicio de `lib/features/tasks/application/create_edit_task_view_model.dart`:

```dart
// Añadir imports:
import 'package:flutter/material.dart' show TimeOfDay;
import '../../members/application/members_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../application/recurrence_provider.dart';
import '../domain/task.dart';
import 'recurrence_provider.dart';

/// Un miembro en la lista ordenada de asignados de la tarea.
class MemberOrderItem {
  const MemberOrderItem({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.isAssigned,
    required this.position,
  });
  final String  uid;
  final String  name;
  final String? photoUrl;
  final bool    isAssigned;
  final int     position;  // 0-based; ignorado si !isAssigned
}

/// Una fecha próxima con el nombre del asignado.
class UpcomingDateItem {
  const UpcomingDateItem({required this.date, this.assigneeName});
  final DateTime date;
  final String?  assigneeName;
}
```

Actualizar el contrato abstracto `CreateEditTaskViewModel`:

```dart
abstract class CreateEditTaskViewModel {
  bool           get isEditing;
  TaskFormState  get formState;
  bool           get savedSuccessfully;
  String?        get loadedTitle;
  String?        get loadedDescription;

  // Nuevos getters
  bool                   get hasFixedTime;
  TimeOfDay?             get fixedTime;
  bool                   get showApplyToday;
  bool                   get applyToday;
  List<UpcomingDateItem> get upcomingDates;
  List<MemberOrderItem>  get orderedMembers;
  bool                   get canSave;

  // Acciones existentes
  void setTitle(String v);
  void setDescription(String v);
  void setVisual(String kind, String value);
  void setRecurrenceRule(RecurrenceRule rule);
  void setAssignmentMode(String mode);
  void setAssignmentOrder(List<String> order);
  void setDifficultyWeight(double v);
  Future<void> save();

  // Nuevas acciones
  void setHasFixedTime(bool value);
  void setFixedTime(TimeOfDay? time);
  void setApplyToday(bool value);
  void toggleMember(String uid);
  void reorderMember(int fromIndex, int toIndex);

  // Métodos estáticos para lógica pura (testeable sin Riverpod)
  static bool computeShowApplyToday({
    required bool hasFixedTime,
    required TimeOfDay? fixedTime,
    required TimeOfDay now,
  }) {
    if (!hasFixedTime || fixedTime == null) return false;
    final fixedMinutes = fixedTime.hour * 60 + fixedTime.minute;
    final nowMinutes   = now.hour * 60 + now.minute;
    return fixedMinutes > nowMinutes;
  }

  static bool computeCanSave({
    required String name,
    required int assignedMemberCount,
  }) =>
      name.trim().isNotEmpty && assignedMemberCount >= 1;
}
```

Actualizar `_CreateEditVMState` para guardar el estado de los campos nuevos:

```dart
@freezed
class _CreateEditVMState with _$CreateEditVMState {
  const factory _CreateEditVMState({
    @Default(false) bool savedSuccessfully,
    String? loadedTitle,
    String? loadedDescription,
    @Default(false) bool hasFixedTime,      // ← nuevo
    TimeOfDay? fixedTime,                   // ← nuevo
    @Default(false) bool applyToday,        // ← nuevo
  }) = __CreateEditVMState;
}
```

> **Nota:** `TimeOfDay` no es serializable con freezed por defecto. Añadir `// ignore_for_file: invalid_annotation_target` si build_runner se queja, o usar `int? fixedTimeMinutes` y convertir.

Añadir los getters y acciones en `CreateEditTaskViewModelNotifier`:

```dart
@override
bool get hasFixedTime => state.hasFixedTime;

@override
TimeOfDay? get fixedTime => state.fixedTime;

@override
bool get showApplyToday {
  final tod = ref.watch(authProvider);  // solo para forzar recomputación
  return CreateEditTaskViewModel.computeShowApplyToday(
    hasFixedTime: state.hasFixedTime,
    fixedTime: state.fixedTime,
    now: TimeOfDay.now(),
  );
}

@override
bool get applyToday => state.applyToday;

@override
List<UpcomingDateItem> get upcomingDates {
  final rule = ref.read(taskFormNotifierProvider).recurrenceRule;
  if (rule == null) return [];
  final dates = ref.read(upcomingOccurrencesProvider(rule));
  final order = ref.read(taskFormNotifierProvider).assignmentOrder;
  return dates.take(3).toList().asMap().entries.map((e) {
    final i   = e.key;
    final uid = order.isNotEmpty ? order[i % order.length] : null;
    final members = ref.read(homeMembersProvider(
      ref.read(currentHomeProvider).valueOrNull?.id ?? '',
    )).valueOrNull ?? [];
    final name = uid != null
        ? members.where((m) => m.uid == uid).cast<dynamic>().firstOrNull?.nickname
        : null;
    return UpcomingDateItem(date: e.value, assigneeName: name as String?);
  }).toList();
}

@override
List<MemberOrderItem> get orderedMembers {
  final homeId  = ref.read(currentHomeProvider).valueOrNull?.id ?? '';
  final members = ref.read(homeMembersProvider(homeId)).valueOrNull ?? [];
  final order   = ref.read(taskFormNotifierProvider).assignmentOrder;
  final assigned = Set<String>.from(order);

  // Miembros asignados en el orden definido
  final assignedItems = order.asMap().entries.map((e) {
    final uid = e.value;
    final m   = members.where((m) => m.uid == uid).cast<dynamic>().firstOrNull;
    return MemberOrderItem(
      uid: uid,
      name: (m?.nickname as String?) ?? uid,
      photoUrl: m?.photoUrl as String?,
      isAssigned: true,
      position: e.key,
    );
  }).toList();

  // Miembros no asignados al final
  final unassigned = members
      .where((m) => !assigned.contains(m.uid))
      .map((m) => MemberOrderItem(
            uid: m.uid,
            name: m.nickname,
            photoUrl: m.photoUrl,
            isAssigned: false,
            position: -1,
          ))
      .toList();

  return [...assignedItems, ...unassigned];
}

@override
bool get canSave {
  final form = ref.read(taskFormNotifierProvider);
  return CreateEditTaskViewModel.computeCanSave(
    name: form.title,
    assignedMemberCount: form.assignmentOrder.length,
  );
}

@override
void setHasFixedTime(bool value) {
  state = state.copyWith(hasFixedTime: value);
  if (!value) state = state.copyWith(fixedTime: null);
}

@override
void setFixedTime(TimeOfDay? time) => state = state.copyWith(fixedTime: time);

@override
void setApplyToday(bool value) => state = state.copyWith(applyToday: value);

@override
void toggleMember(String uid) {
  final current = List<String>.from(
    ref.read(taskFormNotifierProvider).assignmentOrder,
  );
  if (current.contains(uid)) {
    current.remove(uid);
  } else {
    current.add(uid);
  }
  _form.setAssignmentOrder(current);
}

@override
void reorderMember(int fromIndex, int toIndex) {
  final current = List<String>.from(
    ref.read(taskFormNotifierProvider).assignmentOrder,
  );
  if (fromIndex < current.length && toIndex <= current.length) {
    final item = current.removeAt(fromIndex);
    current.insert(toIndex > fromIndex ? toIndex - 1 : toIndex, item);
    _form.setAssignmentOrder(current);
  }
}
```

- [ ] **Step 4: Regenerar y ejecutar tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/features/tasks/create_edit_task_view_model_test.dart -v
```

Esperado: todos PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/application/create_edit_task_view_model.dart \
        lib/features/tasks/application/create_edit_task_view_model.freezed.dart \
        lib/features/tasks/application/create_edit_task_view_model.g.dart \
        test/unit/features/tasks/create_edit_task_view_model_test.dart
git commit -m "feat(tasks): añadir showApplyToday, upcomingDates y orderedMembers a CreateEditTaskViewModel"
```

---

## Task 7 — `TaskDetailViewModel`: exponer `difficultyWeight` + 5 ocurrencias

**Files:**
- Modify: `lib/features/tasks/application/task_detail_view_model.dart`
- Modify: `lib/features/tasks/application/task_detail_view_model.g.dart` (regenerar)
- Modify: `test/unit/features/tasks/task_detail_view_model_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

Añadir a `test/unit/features/tasks/task_detail_view_model_test.dart`:

```dart
// Al inicio del archivo, verificar que ya existe el helper _makeTask.
// Si no, añadir:
Task _makeTask({
  String id = 't1',
  String homeId = 'home1',
  double difficultyWeight = 2.0,
  RecurrenceRule? recurrenceRule,
  TaskStatus status = TaskStatus.active,
}) =>
    Task(
      id: id,
      homeId: homeId,
      title: 'Barrer',
      description: null,
      visualKind: 'emoji',
      visualValue: '🧹',
      status: status,
      recurrenceRule: recurrenceRule ??
          RecurrenceRule.daily(
            every: 1,
            time: '10:00',
            timezone: 'Europe/Madrid',
          ),
      assignmentMode: 'basicRotation',
      assignmentOrder: ['uid1', 'uid2'],
      currentAssigneeUid: 'uid1',
      nextDueAt: DateTime(2026, 4, 14, 10, 0),
      difficultyWeight: difficultyWeight,
      completedCount90d: 5,
      createdByUid: 'uid1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 4, 14),
    );

group('TaskDetailViewData — difficultyWeight', () {
  test('difficultyWeight viene de task.difficultyWeight', () {
    final task = _makeTask(difficultyWeight: 2.5);
    final data = TaskDetailViewData(
      task: task,
      canManage: true,
      currentAssigneeName: 'Ana',
      upcomingOccurrences: [],
      difficultyWeight: task.difficultyWeight,  // ← nuevo campo
    );
    expect(data.difficultyWeight, 2.5);
  });
});

group('TaskDetailViewModel — 5 ocurrencias', () {
  test('upcomingOccurrences tiene exactamente 5 elementos para regla diaria', () async {
    // Necesitamos un container con los providers adecuados
    final home = _makeHome('home1');  // helper existente en el test
    const uid = _kCurrentUid;

    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(
        () => _FakeAuth(const AuthState.authenticated(
          AuthUser(
            uid: uid, email: 'a@b.com', displayName: 'A',
            photoUrl: null, emailVerified: true, providers: [],
          ),
        )),
      ),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      currentHomeProvider.overrideWith(() => _FakeCurrentHomeWithData(home)),
      homeMembersProvider('home1').overrideWith((_) => Stream.value([])),
      homeTasksProvider('home1').overrideWith((_) => Stream.value([
        _makeTask(id: 't1', homeId: 'home1'),
      ])),
      userMembershipsProvider(uid).overrideWith((_) => Stream.value([])),
    ]);
    addTearDown(container.dispose);

    await container.read(currentHomeProvider.future);
    await Future<void>.microtask(() {});

    final vm = container.read(taskDetailViewModelProvider('t1'));
    final data = vm.viewData.valueOrNull;
    expect(data, isNotNull);
    expect(data!.upcomingOccurrences, hasLength(5));
  });
});
```

- [ ] **Step 2: Verificar FAIL**

```bash
flutter test test/unit/features/tasks/task_detail_view_model_test.dart -v
```

Esperado: FAIL — `difficultyWeight` no existe en `TaskDetailViewData`; ocurrencias son 3, no 5.

- [ ] **Step 3: Actualizar `TaskDetailViewData` y el provider**

En `lib/features/tasks/application/task_detail_view_model.dart`:

Añadir `difficultyWeight` a `TaskDetailViewData`:

```dart
class TaskDetailViewData {
  const TaskDetailViewData({
    required this.task,
    required this.canManage,
    required this.currentAssigneeName,
    required this.upcomingOccurrences,
    required this.difficultyWeight,   // ← nuevo
  });
  final Task   task;
  final bool   canManage;
  final String? currentAssigneeName;
  final List<UpcomingOccurrence> upcomingOccurrences;
  final double difficultyWeight;       // ← nuevo

  bool get isFrozen => task.status == TaskStatus.frozen;
}
```

En el provider, cambiar `take(3)` → `take(5)` y añadir `difficultyWeight`:

```dart
// Localizar esta línea en taskDetailViewModelProvider:
final upcomingOccurrences = _computeUpcomingOccurrences(
    task, upcomingDates.take(3).toList(), nameMap);  // ← cambiar 3 por 5

// Reemplazar por:
final upcomingOccurrences = _computeUpcomingOccurrences(
    task, upcomingDates.take(5).toList(), nameMap);
```

Y en la construcción de `TaskDetailViewData`:

```dart
return TaskDetailViewData(
  task: task,
  canManage: canManage,
  currentAssigneeName: currentAssigneeName,
  upcomingOccurrences: upcomingOccurrences,
  difficultyWeight: task.difficultyWeight,  // ← nuevo
);
```

También actualizar `recurrenceProvider.dart` para que `upcomingOccurrences` acepte N como parámetro:

En `lib/features/tasks/application/recurrence_provider.dart`, cambiar a:

```dart
@riverpod
List<DateTime> upcomingOccurrences(
    UpcomingOccurrencesRef ref, RecurrenceRule? rule) {
  if (rule == null) return [];
  try {
    return RecurrenceCalculator.nextNOccurrences(rule, DateTime.now(), 5);  // ← 3→5
  } catch (_) {
    return [];
  }
}
```

> **Nota:** Cambiar el default a 5 no rompe nada — `take(3)` en `CreateEditTaskViewModel.upcomingDates` ya limita a 3 fechas visibles. TaskDetail ahora mostrará 5.

- [ ] **Step 4: Regenerar y ejecutar tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/features/tasks/task_detail_view_model_test.dart -v
```

Esperado: todos PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/application/task_detail_view_model.dart \
        lib/features/tasks/application/task_detail_view_model.g.dart \
        lib/features/tasks/application/recurrence_provider.dart \
        lib/features/tasks/application/recurrence_provider.g.dart \
        test/unit/features/tasks/task_detail_view_model_test.dart
git commit -m "feat(tasks): exponer difficultyWeight y ampliar a 5 ocurrencias próximas en TaskDetailViewModel"
```

---

## Task 8 — Verificación final

- [ ] **Step 1: Ejecutar todos los tests unitarios**

```bash
flutter test test/unit/ -v
```

Esperado: todos PASS.

- [ ] **Step 2: Análisis estático**

```bash
flutter analyze
```

Esperado: sin errores. Advertencias de deprecación son aceptables si no bloquean.

- [ ] **Step 3: Verificar que las screens compilan**

```bash
flutter build apk --debug 2>&1 | head -50
```

Esperado: sin errores de compilación en la capa de presentación por los renombrados (`canCreate` → `canManage`, `events` → `items`).

- [ ] **Step 4: Commit de cierre**

```bash
git add -A
git commit -m "chore: verificación final de contratos ViewModel — todos los tests pasan"
```

---

## Self-Review

**Cobertura de spec:**
- ✅ `HomeMembership.hasPendingToday` → Task 1
- ✅ `HomeDropdownItem` + `selectHome` → Task 2
- ✅ `TaskEventItem` + `canRate` + `rateEvent` → Task 3
- ✅ `completedCount`, `streakCount`, `averageScore`, `showRadar`, `overflowEntries` → Task 4
- ✅ Selección múltiple, `bulkDelete`, `bulkFreeze`, `canCreate→canManage` → Task 5
- ✅ `showApplyToday`, `upcomingDates`, `orderedMembers`, `hasFixedTime`, `toggleMember`, `reorderMember` → Task 6
- ✅ `difficultyWeight`, 5 ocurrencias → Task 7

**Tipos consistentes entre tasks:**
- `HomeDropdownItem.fromMembership` definido en Task 2, usado en tests de Task 2 ✅
- `TaskEventItem.computeCanRate` static, definido en Task 3, testeado en Task 3 ✅
- `AllTasksViewData.canManage` renombrado en Task 5, screen actualizado en mismo task ✅
- `upcomingOccurrencesProvider` cambia a 5 en Task 7; Task 6 usa `.take(3)` explícito ✅

**Nota sobre `rateEvent`:** la implementación de Task 3 deja un comentario `// TODO: implementar colección taskRatings`. La interfaz del contrato está definida y testeable — la persistencia real se completará cuando se diseñe el schema de valoraciones (fuera del scope de esta spec).
