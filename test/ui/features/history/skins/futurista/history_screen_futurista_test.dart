import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/history/application/history_view_model.dart';
import 'package:toka/features/history/domain/history_filter.dart';
import 'package:toka/features/history/domain/task_event.dart';
import 'package:toka/features/history/presentation/skins/futurista/history_screen_futurista.dart';
import 'package:toka/features/history/presentation/skins/history_screen.dart';
import 'package:toka/features/history/presentation/skins/history_screen_v2.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/l10n/app_localizations.dart';

TaskEventItem _completedItem({
  required String id,
  bool isOwnEvent = false,
  bool isRated = false,
  bool canRate = false,
}) {
  final ev = CompletedEvent(
    id: id,
    taskId: 't1',
    taskTitleSnapshot: 'Sacar basura',
    taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🗑️'),
    actorUid: 'u-actor',
    performerUid: 'u-actor',
    completedAt: DateTime(2026, 4, 25, 10, 0),
    createdAt: DateTime(2026, 4, 25, 10, 0),
  );
  return TaskEventItem(
    raw: ev,
    actorName: 'Ana',
    isOwnEvent: isOwnEvent,
    isRated: isRated,
    canRate: canRate,
  );
}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

class _FakeCurrentHomeWithId extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
        id: 'h1',
        name: 'Casa',
        ownerUid: 'owner',
        currentPayerUid: null,
        lastPayerUid: null,
        premiumStatus: HomePremiumStatus.free,
        premiumPlan: null,
        premiumEndsAt: null,
        restoreUntil: null,
        autoRenewEnabled: false,
        limits: const HomeLimits(maxMembers: 5),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
}

class _FakeHistoryViewModel implements HistoryViewModel {
  _FakeHistoryViewModel({
    this.itemsList = const <TaskEventItem>[],
    this.premium = false,
  });

  final List<TaskEventItem> itemsList;
  final bool premium;

  @override
  AsyncValue<List<TaskEventItem>> get items => AsyncValue.data(itemsList);

  @override
  HistoryFilter get filter => const HistoryFilter();

  @override
  bool get hasMore => false;

  @override
  bool get isPremium => premium;

  @override
  bool get hasHome => true;

  @override
  void loadMore() {}

  @override
  void applyFilter(HistoryFilter newFilter) {}

  @override
  Future<void> rateEvent(String eventId, double rating, {String? note}) async {}
}

Widget _harness({required ProviderContainer container}) =>
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en'), Locale('ro')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HistoryScreen(),
      ),
    );

Widget _routerHarness({
  required ProviderContainer container,
  required void Function() onDetailVisited,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/:homeId/:eventId',
        builder: (_, __) {
          onDetailVisited();
          return const Scaffold(body: Text('detail-screen'));
        },
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    await tester.pump();
    expect(find.byType(HistoryScreenV2), findsOneWidget);
    expect(find.byType(HistoryScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    // Pumps discretos: evitamos pumpAndSettle porque el AnimatedSwitcher
    // encadena transiciones y algún frame puede no estacionarse.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(HistoryScreenFuturista), findsOneWidget);
    expect(find.byType(HistoryScreenV2), findsNothing);
  });

  testWidgets('futurista: free user sees PremiumBannerFuturista at end of list',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(
          itemsList: [_completedItem(id: 'e1')],
          premium: false,
        ),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byKey(const Key('premium_banner_futurista')), findsOneWidget);
  });

  testWidgets('futurista: premium user does NOT see PremiumBannerFuturista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(
          itemsList: [_completedItem(id: 'e1')],
          premium: true,
        ),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byKey(const Key('premium_banner_futurista')), findsNothing);
  });

  testWidgets('futurista: premium user sees star rate button on canRate event',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(
          itemsList: [_completedItem(id: 'e1', canRate: true)],
          premium: true,
        ),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byKey(const Key('rate_button_fut_e1')), findsOneWidget);
  });

  testWidgets(
      'futurista: tap en CompletedEvent navega a historyEventDetail',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    var navigated = false;
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(
          itemsList: [_completedItem(id: 'e-tap')],
          premium: true,
        ),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHomeWithId.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_routerHarness(
      container: c,
      onDetailVisited: () => navigated = true,
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.tap(find.byKey(const Key('history_tile_tap_e-tap')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(navigated, true);
  });
}
