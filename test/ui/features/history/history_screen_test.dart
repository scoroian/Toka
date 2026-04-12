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
