import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/skins/futurista/today_screen_futurista.dart';
import 'package:toka/features/tasks/presentation/skins/today_screen.dart';
import 'package:toka/features/tasks/presentation/skins/today_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockTodayViewModel extends Mock implements TodayViewModel {}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

Widget _harness(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const TodayScreen(),
      ),
    );

TodayViewData _dataWithTasks({
  String? currentUid,
  List<TaskPreview> todos = const [],
}) {
  return TodayViewData(
    grouped: todos.isEmpty
        ? const {}
        : {
            'daily': (todos: todos, dones: const <DoneTaskPreview>[]),
          },
    counters: const DashboardCounters(
      totalActiveTasks: 1,
      totalMembers: 1,
      tasksDueToday: 1,
      tasksDoneToday: 0,
    ),
    showAdBanner: false,
    adBannerUnit: '',
    currentUid: currentUid,
    homeId: 'home-1',
    recurrenceOrder: const ['hourly', 'daily', 'weekly', 'monthly', 'yearly'],
  );
}

TaskPreview _taskFor(String uid) => TaskPreview(
      taskId: 'task-$uid',
      title: 'Tarea de prueba',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: uid,
      currentAssigneeName: 'Alex',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2099, 1, 1, 10, 30),
      isOverdue: false,
      status: 'active',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockTodayViewModel vm;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    vm = _MockTodayViewModel();
    when(() => vm.homes).thenReturn([]);
  });

  group('TodayScreen wrapper', () {
    testWidgets('renders TodayScreenV2 when skin is v2 (default)',
        (tester) async {
      when(() => vm.viewData).thenReturn(const AsyncValue.loading());
      await tester.pumpWidget(_harness([
        todayViewModelProvider.overrideWith((_) => vm),
        authProvider.overrideWith(_FakeAuth.new),
        currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      ]));
      await tester.pump();

      expect(find.byType(TodayScreenV2), findsOneWidget);
      expect(find.byType(TodayScreenFuturista), findsNothing);
    });

    testWidgets('renders TodayScreenFuturista when skin is futurista',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {SkinMode.persistKey: AppSkin.futurista.persistKey});
      when(() => vm.viewData).thenReturn(AsyncValue.data(_dataWithTasks(
        currentUid: 'uid-1',
        todos: [_taskFor('uid-1')],
      )));
      await tester.pumpWidget(_harness([
        todayViewModelProvider.overrideWith((_) => vm),
        authProvider.overrideWith(_FakeAuth.new),
        currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      ]));
      // Varios pumps para dejar resolver microtask de SkinMode._load() y
      // completar la transición del AnimatedSwitcher (220ms).
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }

      expect(find.byType(TodayScreenFuturista), findsOneWidget);
      expect(find.byType(TodayScreenV2), findsNothing);
    });
  });

  group('TodayScreenFuturista states', () {
    Future<void> pumpFuturista(
      WidgetTester tester, {
      required AsyncValue<TodayViewData?> state,
    }) async {
      SharedPreferences.setMockInitialValues(
          {SkinMode.persistKey: AppSkin.futurista.persistKey});
      when(() => vm.viewData).thenReturn(state);
      when(() => vm.retry()).thenReturn(null);
      await tester.pumpWidget(_harness([
        todayViewModelProvider.overrideWith((_) => vm),
        authProvider.overrideWith(_FakeAuth.new),
        currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      ]));
      // Evitamos pumpAndSettle porque el CircularProgressIndicator anima
      // indefinidamente en el estado loading. Pumps discretos para resolver
      // el microtask de SkinMode._load() y la transición de AnimatedSwitcher.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
    }

    testWidgets('loading state renders without errors', (tester) async {
      await pumpFuturista(tester, state: const AsyncValue.loading());
      expect(tester.takeException(), isNull);
      expect(find.byType(TodayScreenFuturista), findsOneWidget);
    });

    testWidgets('error state renders retry button', (tester) async {
      await pumpFuturista(tester,
          state: const AsyncValue.error('boom', StackTrace.empty));
      expect(tester.takeException(), isNull);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('data with no tasks renders empty state (no hero)',
        (tester) async {
      await pumpFuturista(
        tester,
        state: AsyncValue.data(_dataWithTasks(currentUid: 'uid-1')),
      );
      expect(tester.takeException(), isNull);
      // Sin tareas no puede haber hero ni card.
      expect(find.byKey(const Key('hero_btn_done')), findsNothing);
    });

    testWidgets('data with my task shows hero block', (tester) async {
      await pumpFuturista(
        tester,
        state: AsyncValue.data(_dataWithTasks(
          currentUid: 'uid-1',
          todos: [_taskFor('uid-1')],
        )),
      );
      expect(tester.takeException(), isNull);
      // Hero botón visible.
      expect(find.byKey(const Key('hero_btn_done')), findsOneWidget);
    });

    testWidgets(
        "data with someone else's task doesn't show hero but shows card",
        (tester) async {
      await pumpFuturista(
        tester,
        state: AsyncValue.data(_dataWithTasks(
          currentUid: 'uid-me',
          todos: [_taskFor('uid-other')],
        )),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('hero_btn_done')), findsNothing);
      expect(find.byKey(const Key('task_card_fut_task-uid-other')),
          findsOneWidget);
    });
  });
}
