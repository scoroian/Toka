# Member Display & Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar siempre nombre e imagen/iniciales de perfil en lugar de UIDs o `?`, y cachear datos de miembros para minimizar lecturas a Firebase.

**Architecture:** `homeMembersProvider` pasa a `keepAlive: true` para mantener el stream activo durante toda la sesión. `HistoryScreen` resuelve UIDs a `Member` via ese provider. Los fallbacks de UID en el VM y el formulario se eliminan. Todos los avatares usan `CachedNetworkImageProvider` en lugar de `NetworkImage`.

**Tech Stack:** Flutter/Dart, Riverpod (`@Riverpod(keepAlive: true)`), `cached_network_image ^3.4.1`, `build_runner`

---

## Mapa de archivos

| Archivo | Acción |
|---|---|
| `lib/features/members/application/members_provider.dart` | Modificar: `@riverpod` → `@Riverpod(keepAlive: true)` en `homeMembers` |
| `lib/features/members/application/members_provider.g.dart` | Regenerar con build_runner |
| `lib/features/history/presentation/history_screen.dart` | Modificar: resolver UIDs → Member en `_buildEventTile` |
| `lib/features/tasks/application/task_detail_view_model.dart` | Modificar: fallback UID → `null` |
| `lib/features/tasks/presentation/widgets/assignment_form.dart` | Modificar: añadir avatar, quitar fallback UID |
| `lib/features/members/presentation/widgets/member_card.dart` | Modificar: `NetworkImage` → `CachedNetworkImageProvider` |
| `lib/features/members/presentation/member_profile_screen.dart` | Modificar: `NetworkImage` → `CachedNetworkImageProvider` |
| `lib/features/profile/presentation/own_profile_screen.dart` | Modificar: `NetworkImage` → `CachedNetworkImageProvider` |
| `lib/features/tasks/presentation/widgets/today_task_card_todo.dart` | Modificar: `NetworkImage` → `CachedNetworkImageProvider` en `_AssigneeAvatar` |
| `lib/features/history/presentation/widgets/history_event_tile.dart` | Modificar: `NetworkImage` → `CachedNetworkImageProvider` en `_Avatar` |
| `test/ui/features/history/history_screen_test.dart` | Añadir tests de resolución de UIDs en `HistoryScreen` |
| `test/ui/features/tasks/task_detail_screen_test.dart` | Corregir constructores rotos + añadir test de `currentAssigneeName: null` |
| `test/ui/features/tasks/create_task_screen_test.dart` | Añadir test: `AssignmentForm` muestra avatar e iniciales |

---

## Task 1: `homeMembersProvider` → keepAlive

**Files:**
- Modify: `lib/features/members/application/members_provider.dart`
- Regenerar: `lib/features/members/application/members_provider.g.dart`

- [ ] **Step 1: Cambiar la anotación**

Archivo: `lib/features/members/application/members_provider.dart`

```dart
// lib/features/members/application/members_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/members_repository_impl.dart';
import '../domain/member.dart';
import '../domain/members_repository.dart';

part 'members_provider.g.dart';

@Riverpod(keepAlive: true)
MembersRepository membersRepository(MembersRepositoryRef ref) {
  return MembersRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instance,
  );
}

@Riverpod(keepAlive: true)
Stream<List<Member>> homeMembers(HomeMembersRef ref, String homeId) {
  return ref.watch(membersRepositoryProvider).watchHomeMembers(homeId);
}
```

- [ ] **Step 2: Regenerar el código generado**

```bash
cd c:/Users/sebas/OneDrive/Escritorio/Proyectos/Toka
dart run build_runner build --delete-conflicting-outputs
```

Esperado: archivos `.g.dart` regenerados sin errores.

- [ ] **Step 3: Verificar que el proyecto compila**

```bash
flutter analyze lib/features/members/
```

Esperado: sin errores de análisis.

- [ ] **Step 4: Commit**

```bash
git add lib/features/members/application/members_provider.dart lib/features/members/application/members_provider.g.dart
git commit -m "perf: homeMembersProvider keepAlive para evitar re-lecturas en navegación"
```

---

## Task 2: `HistoryScreen` — resolver UIDs a nombres y fotos

**Files:**
- Modify: `lib/features/history/presentation/history_screen.dart`
- Test: `test/ui/features/history/history_screen_test.dart`

- [ ] **Step 1: Escribir el test que falla**

Añadir al final de `test/ui/features/history/history_screen_test.dart`, antes del `}` de cierre:

```dart
// --- Nuevos imports al inicio del archivo ---
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:toka/features/auth/application/auth_provider.dart';
// import 'package:toka/features/auth/application/auth_state.dart';
// import 'package:toka/features/homes/application/current_home_provider.dart';
// import 'package:toka/features/homes/domain/home.dart';
// import 'package:toka/features/homes/domain/home_limits.dart';
// import 'package:toka/features/homes/domain/home_membership.dart';
// import 'package:toka/features/members/application/members_provider.dart';
// import 'package:toka/features/members/domain/member.dart';
// import 'package:toka/features/history/application/history_provider.dart';
// import 'package:toka/features/history/application/history_view_model.dart';
// import 'package:toka/features/history/presentation/history_screen.dart';
```

Reemplazar **todo el contenido** del archivo por la versión completa con los nuevos tests:

```dart
// test/ui/features/history/history_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/application/history_view_model.dart';
import 'package:toka/features/history/domain/task_event.dart';
import 'package:toka/features/history/presentation/history_screen.dart';
import 'package:toka/features/history/presentation/widgets/history_empty_state.dart';
import 'package:toka/features/history/presentation/widgets/history_event_tile.dart';
import 'package:toka/features/history/presentation/widgets/history_filter_bar.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helpers globales
// ---------------------------------------------------------------------------

Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

const visual = TaskVisual(kind: 'emoji', value: '🧹');
final fixedDate = DateTime(2026, 4, 6, 12, 0);

CompletedEvent completedEvent() => TaskEvent.completed(
      id: 'e1',
      taskId: 'task1',
      taskTitleSnapshot: 'Barrer',
      taskVisualSnapshot: visual,
      actorUid: 'uid-A',
      performerUid: 'uid-A',
      completedAt: fixedDate,
      createdAt: fixedDate,
    ) as CompletedEvent;

PassedEvent passedEvent() => TaskEvent.passed(
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
      createdAt: fixedDate,
    ) as PassedEvent;

// ---------------------------------------------------------------------------
// Fakes para HistoryScreen
// ---------------------------------------------------------------------------

class _FakeHistoryViewModel implements HistoryViewModel {
  const _FakeHistoryViewModel({required this.events, this.isPremium = false});

  @override
  final AsyncValue<List<TaskEvent>> events;
  @override
  final bool isPremium;
  @override
  HistoryFilter get filter => const HistoryFilter();
  @override
  bool get hasMore => false;
  @override
  void loadMore() {}
  @override
  void applyFilter(HistoryFilter newFilter) {}
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
        id: 'h1',
        name: 'Casa Test',
        ownerUid: 'uid-A',
        currentPayerUid: null,
        lastPayerUid: null,
        premiumStatus: HomePremiumStatus.free,
        premiumPlan: null,
        premiumEndsAt: null,
        restoreUntil: null,
        autoRenewEnabled: false,
        limits: const HomeLimits(maxMembers: 5),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  @override
  Future<void> switchHome(String homeId) async {}
}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

Member _makeMember(String uid, String nickname) => Member(
      uid: uid,
      homeId: 'h1',
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: MemberRole.member,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0.0,
    );

Widget _wrapScreen({
  required List<TaskEvent> events,
  required List<Member> members,
}) =>
    ProviderScope(
      overrides: [
        historyViewModelProvider.overrideWith(
          (ref) => _FakeHistoryViewModel(events: AsyncData(events)),
        ),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        homeMembersProvider('h1').overrideWith(
          (ref) => Stream.value(members),
        ),
        authProvider.overrideWith(() => _FakeAuth()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        home: HistoryScreen(),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HistoryEmptyState', () {
    testWidgets('muestra título, body e icono', (tester) async {
      await tester.pumpWidget(wrap(const HistoryEmptyState()));
      expect(find.text('Sin actividad'), findsOneWidget);
      expect(
          find.text('Aún no hay eventos en el historial'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('HistoryEventTile — completed', () {
    testWidgets('muestra nombre del actor y tarea con emoji', (tester) async {
      await tester.pumpWidget(wrap(
        HistoryEventTile(
          event: completedEvent(),
          actorName: 'Ana',
          actorPhotoUrl: null,
        ),
      ));
      expect(find.textContaining('Ana completó'), findsOneWidget);
      expect(find.textContaining('🧹 Barrer'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  group('HistoryEventTile — passed', () {
    testWidgets('muestra motivo del pase cuando existe', (tester) async {
      await tester.pumpWidget(wrap(
        HistoryEventTile(
          event: passedEvent(),
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
        taskVisualSnapshot: visual,
        actorUid: 'uid-A',
        fromUid: 'uid-A',
        toUid: 'uid-B',
        reason: null,
        penaltyApplied: false,
        complianceBefore: null,
        complianceAfter: null,
        createdAt: fixedDate,
      ) as PassedEvent;

      await tester.pumpWidget(wrap(
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
    testWidgets('muestra los tres chips de filtro', (tester) async {
      await tester.pumpWidget(wrap(
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
      await tester.pumpWidget(wrap(
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
      await tester.pumpWidget(wrap(
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
      await tester.pumpWidget(wrap(
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

  // ---------------------------------------------------------------------------
  // Tests de resolución de UIDs → nombres en HistoryScreen
  // ---------------------------------------------------------------------------

  group('HistoryScreen — resolución de UIDs', () {
    testWidgets(
        'muestra nickname del actor en lugar del UID en evento completado',
        (tester) async {
      final member = _makeMember('uid-A', 'Ana García');
      await tester.pumpWidget(_wrapScreen(
        events: [completedEvent()],
        members: [member],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ana García'), findsWidgets);
      expect(find.text('uid-A'), findsNothing);
    });

    testWidgets(
        'muestra nicknames de fromUid y toUid en evento de pase de turno',
        (tester) async {
      final memberB = _makeMember('uid-B', 'Bob');
      final memberC = _makeMember('uid-C', 'Carlos');
      await tester.pumpWidget(_wrapScreen(
        events: [passedEvent()],
        members: [memberB, memberC],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bob'), findsWidgets);
      expect(find.textContaining('Carlos'), findsWidgets);
      expect(find.text('uid-B'), findsNothing);
      expect(find.text('uid-C'), findsNothing);
    });

    testWidgets('muestra ? cuando el UID no está en la lista de miembros',
        (tester) async {
      await tester.pumpWidget(_wrapScreen(
        events: [completedEvent()],
        members: [], // sin miembros → UID desconocido
      ));
      await tester.pumpAndSettle();

      // El tile se muestra con '?' como nombre
      expect(find.textContaining('?'), findsWidgets);
      expect(find.text('uid-A'), findsNothing);
    });
  });

  group('Golden tests', () {
    testWidgets('golden: HistoryEventTile completado', (tester) async {
      await tester.pumpWidget(wrap(
        HistoryEventTile(
          event: completedEvent(),
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
      await tester.pumpWidget(wrap(
        HistoryEventTile(
          event: passedEvent(),
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

- [ ] **Step 2: Ejecutar el test — debe fallar**

```bash
flutter test test/ui/features/history/history_screen_test.dart --name "resolución de UIDs" -v
```

Esperado: FAIL — la pantalla muestra `uid-A` en lugar de `Ana García`.

- [ ] **Step 3: Implementar el cambio en `history_screen.dart`**

Reemplazar todo el contenido del archivo:

```dart
// lib/features/history/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../application/history_provider.dart';
import '../application/history_view_model.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitial() {
    ref.read(historyViewModelProvider).loadMore();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyViewModelProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(historyViewModelProvider);

    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    final currentUid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);

    final members = homeId != null
        ? ref.watch(homeMembersProvider(homeId)).valueOrNull ?? <Member>[]
        : <Member>[];
    final membersByUid = {for (final m in members) m.uid: m};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history_title)),
      body: Column(
        children: [
          HistoryFilterBar(
            current: vm.filter,
            onChanged: (f) => vm.applyFilter(f),
          ),
          Expanded(
            child: vm.events.when(
              loading: () => const LoadingWidget(),
              error: (_, __) => Center(child: Text(l10n.error_generic)),
              data: (events) {
                if (events.isEmpty) {
                  return const HistoryEmptyState();
                }
                final isPremium = vm.isPremium;
                final showBanner = !isPremium;
                final showLoadMore = vm.hasMore;
                final extraItems =
                    (showBanner ? 1 : 0) + (showLoadMore ? 1 : 0);

                return ListView.builder(
                  key: const Key('history_list'),
                  controller: _scrollController,
                  itemCount: events.length + extraItems,
                  itemBuilder: (context, index) {
                    if (index < events.length) {
                      return _buildEventTile(
                        events[index],
                        membersByUid,
                        currentUid,
                        homeId,
                        isPremium,
                      );
                    }
                    final extra = index - events.length;
                    if (showBanner && extra == 0) {
                      return _PremiumBanner(l10n: l10n);
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: TextButton(
                          key: const Key('btn_load_more'),
                          onPressed: () =>
                              ref.read(historyViewModelProvider).loadMore(),
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
  }

  Widget _buildEventTile(
    TaskEvent event,
    Map<String, Member> membersByUid,
    String? currentUid,
    String? homeId,
    bool isPremium,
  ) {
    final actor = membersByUid[event.actorUid];
    final actorName =
        (actor?.nickname.isNotEmpty == true) ? actor!.nickname : '?';
    final actorPhotoUrl = actor?.photoUrl;

    String? toName;
    if (event is PassedEvent) {
      final toMember = membersByUid[event.toUid];
      toName =
          (toMember?.nickname.isNotEmpty == true) ? toMember!.nickname : '?';
    }

    return HistoryEventTile(
      event: event,
      actorName: actorName,
      actorPhotoUrl: actorPhotoUrl,
      toName: toName,
      homeId: homeId,
      currentUid: currentUid,
      isPremium: isPremium,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

- [ ] **Step 4: Ejecutar los tests — deben pasar**

```bash
flutter test test/ui/features/history/history_screen_test.dart -v
```

Esperado: PASS en todos los tests del grupo.

- [ ] **Step 5: Commit**

```bash
git add lib/features/history/presentation/history_screen.dart test/ui/features/history/history_screen_test.dart
git commit -m "fix(history): resolver UIDs a nicknames y fotos en HistoryScreen"
```

---

## Task 3: `TaskDetailViewModel` — eliminar fallback a UID

**Files:**
- Modify: `lib/features/tasks/application/task_detail_view_model.dart:98-106`
- Test: `test/ui/features/tasks/task_detail_screen_test.dart`

- [ ] **Step 1: Escribir tests que fallan / corregir constructores rotos**

Reemplazar todo el contenido de `test/ui/features/tasks/task_detail_screen_test.dart`:

```dart
// test/ui/features/tasks/task_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/task_detail_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _LoadingViewModel implements TaskDetailViewModel {
  @override
  AsyncValue<TaskDetailViewData?> get viewData => const AsyncLoading();
  @override
  Future<void> toggleFreeze() async {}
  @override
  Future<void> deleteTask() async {}
}

class _DataViewModel implements TaskDetailViewModel {
  _DataViewModel(this._data);
  final TaskDetailViewData? _data;

  @override
  AsyncValue<TaskDetailViewData?> get viewData => AsyncData(_data);
  @override
  Future<void> toggleFreeze() async {}
  @override
  Future<void> deleteTask() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kTaskId = 'task-1';

Task _makeTask({
  String title = 'Limpiar cocina',
  String visualKind = 'emoji',
  String visualValue = '🧹',
}) =>
    Task(
      id: _kTaskId,
      homeId: 'h1',
      title: title,
      visualKind: visualKind,
      visualValue: visualValue,
      status: TaskStatus.active,
      recurrenceRule: const RecurrenceRule.daily(
        every: 1,
        time: '20:00',
        timezone: 'Europe/Madrid',
      ),
      assignmentMode: 'basicRotation',
      assignmentOrder: const ['uid1'],
      currentAssigneeUid: 'uid1',
      nextDueAt: DateTime(2025, 6, 15, 20, 0),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: 'uid1',
      createdAt: DateTime(2025, 6, 1),
      updatedAt: DateTime(2025, 6, 1),
    );

Widget _wrap(TaskDetailViewModel fakeVm) {
  return ProviderScope(
    overrides: [
      taskDetailViewModelProvider(_kTaskId).overrideWith((_) => fakeVm),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es')],
      home: TaskDetailScreen(taskId: _kTaskId),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('muestra CircularProgressIndicator cuando viewData está cargando',
      (tester) async {
    await tester.pumpWidget(_wrap(_LoadingViewModel()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra el título de la tarea cuando los datos están disponibles',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: false,
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('Limpiar cocina'), findsWidgets);
  });

  testWidgets('muestra el emoji de la tarea cuando los datos están disponibles',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: false,
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('🧹'), findsOneWidget);
  });

  testWidgets('muestra el botón de edición cuando canEdit es true',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: true,
      canManage: true,
      currentAssigneeName: null,
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_task_button')), findsOneWidget);
  });

  testWidgets('NO muestra el botón de edición cuando canEdit es false',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: false,
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_task_button')), findsNothing);
  });

  testWidgets('no falla cuando viewData es null', (tester) async {
    final vm = _DataViewModel(null);
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.byType(Text), findsWidgets);
  });

  testWidgets(
      'muestra el nombre del asignado cuando currentAssigneeName no es null',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: false,
      canManage: false,
      currentAssigneeName: 'Ana García',
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('Ana García'), findsOneWidget);
  });

  testWidgets(
      'muestra guión cuando currentAssigneeName es null — nunca el UID',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: false,
      canManage: false,
      currentAssigneeName: null, // ← el VM ya no debe pasar el UID aquí
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    // El subtitle del tile muestra '—' cuando es null
    expect(find.text('—'), findsOneWidget);
    // Nunca el UID crudo
    expect(find.text('uid1'), findsNothing);
  });
}
```

- [ ] **Step 2: Ejecutar los tests — verificar estado inicial**

```bash
flutter test test/ui/features/tasks/task_detail_screen_test.dart -v
```

Esperado: Los tests nuevos del grupo pasan (porque la pantalla ya muestra `'—'` para null). Si algún test de los anteriores falla por constructor roto, ahora están corregidos.

- [ ] **Step 3: Aplicar el fix en el view model**

En `lib/features/tasks/application/task_detail_view_model.dart`, cambiar las líneas 98–106:

```dart
    // ANTES:
    final currentAssigneeName =
        assigneeMember != null && assigneeMember.nickname.isNotEmpty
            ? assigneeMember.nickname
            : task.currentAssigneeUid;

    // DESPUÉS:
    final currentAssigneeName =
        assigneeMember != null && assigneeMember.nickname.isNotEmpty
            ? assigneeMember.nickname
            : null;
```

- [ ] **Step 4: Ejecutar todos los tests de tasks**

```bash
flutter test test/ui/features/tasks/ test/unit/features/tasks/ -v
```

Esperado: PASS en todos los tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/application/task_detail_view_model.dart test/ui/features/tasks/task_detail_screen_test.dart
git commit -m "fix(tasks): currentAssigneeName fallback a null en lugar de UID"
```

---

## Task 4: `AssignmentForm` — avatar y eliminar fallback a UID

**Files:**
- Modify: `lib/features/tasks/presentation/widgets/assignment_form.dart`
- Test: `test/ui/features/tasks/create_task_screen_test.dart`

- [ ] **Step 1: Escribir el test que falla**

`AssignmentForm` es un `StatelessWidget` puro sin Riverpod — se puede testear directamente. Añadir al final de `test/ui/features/tasks/create_task_screen_test.dart`, dentro del `main()` antes del `}` de cierre:

```dart
  group('AssignmentForm — avatar e iniciales', () {
    testWidgets('muestra CircleAvatar con inicial del nickname', (tester) async {
      final member = Member(
        uid: 'uid1',
        homeId: 'h1',
        nickname: 'Ana García',
        photoUrl: null,
        bio: null,
        phone: null,
        phoneVisibility: 'hidden',
        role: MemberRole.owner,
        status: MemberStatus.active,
        joinedAt: DateTime(2024),
        tasksCompleted: 0,
        passedCount: 0,
        complianceRate: 1.0,
        currentStreak: 0,
        averageScore: 0.0,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: AssignmentForm(
            availableMembers: [member],
            selectedOrder: const [],
            onChanged: (_) {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Ana García'), findsOneWidget);
      expect(find.text('uid1'), findsNothing);
    });
  });
```

También añadir el import de `AssignmentForm` al inicio del archivo si no está:
```dart
import 'package:toka/features/tasks/presentation/widgets/assignment_form.dart';
```

- [ ] **Step 2: Ejecutar el test — debe fallar**

```bash
flutter test test/ui/features/tasks/create_task_screen_test.dart --name "avatar e iniciales" -v
```

Esperado: FAIL — no hay `CircleAvatar` en el `CheckboxListTile` actualmente.

- [ ] **Step 3: Implementar el cambio en `assignment_form.dart`**

Reemplazar todo el contenido del archivo:

```dart
// lib/features/tasks/presentation/widgets/assignment_form.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../features/members/domain/member.dart';
import '../../../../l10n/app_localizations.dart';

class AssignmentForm extends StatelessWidget {
  const AssignmentForm({
    super.key,
    required this.availableMembers,
    required this.selectedOrder,
    required this.onChanged,
  });

  final List<Member> availableMembers;
  final List<String> selectedOrder;
  final void Function(List<String> order) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tasks_assignment_members,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...availableMembers.map((member) {
          final selected = selectedOrder.contains(member.uid);
          return CheckboxListTile(
            key: Key('assignee_checkbox_${member.uid}'),
            secondary: CircleAvatar(
              radius: 18,
              backgroundImage: member.photoUrl != null
                  ? CachedNetworkImageProvider(member.photoUrl!)
                  : null,
              child: member.photoUrl == null
                  ? Text(
                      member.nickname.isNotEmpty
                          ? member.nickname[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            title: Text(member.nickname),
            value: selected,
            onChanged: (v) {
              final updated = v == true
                  ? [...selectedOrder, member.uid]
                  : selectedOrder.where((u) => u != member.uid).toList();
              onChanged(updated);
            },
          );
        }),
      ],
    );
  }
}
```

- [ ] **Step 4: Ejecutar los tests**

```bash
flutter test test/ui/features/tasks/create_task_screen_test.dart -v
```

Esperado: PASS en todos los tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/widgets/assignment_form.dart test/ui/features/tasks/create_task_screen_test.dart
git commit -m "fix(tasks): AssignmentForm muestra avatar con foto/iniciales, elimina fallback a UID"
```

---

## Task 5: `CachedNetworkImageProvider` en todos los avatares

**Files:**
- Modify: `lib/features/members/presentation/widgets/member_card.dart`
- Modify: `lib/features/members/presentation/member_profile_screen.dart`
- Modify: `lib/features/profile/presentation/own_profile_screen.dart`
- Modify: `lib/features/tasks/presentation/widgets/today_task_card_todo.dart`
- Modify: `lib/features/history/presentation/widgets/history_event_tile.dart`

Los tests existentes de estos widgets usan `photoUrl: null`, por lo que no intentan cargar imágenes reales. Solo hay que verificar que no se rompe nada.

- [ ] **Step 1: `member_card.dart`**

Añadir import al inicio:
```dart
import 'package:cached_network_image/cached_network_image.dart';
```

Cambiar el `CircleAvatar` (líneas ~28–37):

```dart
CircleAvatar(
  backgroundImage: member.photoUrl != null
      ? CachedNetworkImageProvider(member.photoUrl!)
      : null,
  child: member.photoUrl == null
      ? Text(member.nickname.isNotEmpty
          ? member.nickname[0].toUpperCase()
          : '?')
      : null,
),
```

- [ ] **Step 2: `member_profile_screen.dart`**

Añadir import:
```dart
import 'package:cached_network_image/cached_network_image.dart';
```

Cambiar el `CircleAvatar` (líneas ~45–56):

```dart
CircleAvatar(
  radius: 48,
  backgroundImage: member.photoUrl != null
      ? CachedNetworkImageProvider(member.photoUrl!)
      : null,
  child: member.photoUrl == null
      ? Text(
          member.nickname.isNotEmpty
              ? member.nickname[0].toUpperCase()
              : '?',
          style: const TextStyle(fontSize: 32),
        )
      : null,
),
```

- [ ] **Step 3: `own_profile_screen.dart`**

Añadir import:
```dart
import 'package:cached_network_image/cached_network_image.dart';
```

Cambiar el `CircleAvatar` (líneas ~60–74):

```dart
CircleAvatar(
  key: const Key('own_avatar'),
  radius: 48,
  backgroundImage: profile.photoUrl != null
      ? CachedNetworkImageProvider(profile.photoUrl!)
      : null,
  child: profile.photoUrl == null
      ? Text(
          profile.nickname.isNotEmpty
              ? profile.nickname[0].toUpperCase()
              : '?',
          style: const TextStyle(fontSize: 32),
        )
      : null,
),
```

- [ ] **Step 4: `today_task_card_todo.dart` — clase `_AssigneeAvatar`**

Añadir import:
```dart
import 'package:cached_network_image/cached_network_image.dart';
```

Cambiar el `build` de `_AssigneeAvatar` (líneas ~133–147):

```dart
@override
Widget build(BuildContext context) {
  if (photoUrl != null) {
    return CircleAvatar(
      radius: 16,
      backgroundImage: CachedNetworkImageProvider(photoUrl!),
    );
  }
  return CircleAvatar(
    radius: 16,
    backgroundColor: AppColors.secondary,
    child: Text(
      _initials,
      style: const TextStyle(fontSize: 11, color: Colors.white),
    ),
  );
}
```

- [ ] **Step 5: `history_event_tile.dart` — clase `_Avatar`**

Añadir import:
```dart
import 'package:cached_network_image/cached_network_image.dart';
```

Cambiar el `build` de `_Avatar` (líneas ~70–82):

```dart
@override
Widget build(BuildContext context) {
  if (photoUrl != null && photoUrl!.isNotEmpty) {
    return CircleAvatar(
      radius: 20,
      backgroundImage: CachedNetworkImageProvider(photoUrl!),
    );
  }
  return CircleAvatar(
    radius: 20,
    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
  );
}
```

- [ ] **Step 6: Ejecutar todos los tests de las features afectadas**

```bash
flutter test test/ui/features/members/ test/ui/features/profile/ test/ui/features/tasks/today_task_card_todo_test.dart test/ui/features/history/ -v
```

Esperado: PASS en todos.

- [ ] **Step 7: Análisis estático**

```bash
flutter analyze lib/
```

Esperado: sin errores.

- [ ] **Step 8: Commit**

```bash
git add \
  lib/features/members/presentation/widgets/member_card.dart \
  lib/features/members/presentation/member_profile_screen.dart \
  lib/features/profile/presentation/own_profile_screen.dart \
  lib/features/tasks/presentation/widgets/today_task_card_todo.dart \
  lib/features/history/presentation/widgets/history_event_tile.dart
git commit -m "perf: usar CachedNetworkImageProvider en todos los avatares para caché de fotos en disco"
```

---

## Verificación final

- [ ] **Ejecutar toda la suite de tests**

```bash
flutter test test/unit/ test/ui/ -v
```

Esperado: todos los tests pasan.

- [ ] **Análisis completo**

```bash
flutter analyze lib/
```

Esperado: sin errores, solo warnings esperados.
