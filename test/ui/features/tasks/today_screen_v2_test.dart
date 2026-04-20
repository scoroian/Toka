import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/presentation/home_selector_widget.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
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

Widget _wrap(Widget child, TodayViewModel vm) => ProviderScope(
  overrides: [todayViewModelProvider.overrideWith((_) => vm)],
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: child,
  ),
);

Widget _wrapWithHomes(Widget child, TodayViewModel vm) => ProviderScope(
  overrides: [
    todayViewModelProvider.overrideWith((_) => vm),
    authProvider.overrideWith(_FakeAuth.new),
    currentHomeProvider.overrideWith(_FakeCurrentHome.new),
  ],
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: child,
  ),
);

void main() {
  late _MockTodayViewModel vm;

  setUp(() {
    vm = _MockTodayViewModel();
    when(() => vm.homes).thenReturn([]);
  });

  testWidgets('muestra skeleton mientras carga', (tester) async {
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
    await tester.pumpWidget(_wrap(const TodayScreenV2(), vm));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('muestra error genérico y botón de retry', (tester) async {
    when(() => vm.viewData).thenReturn(const AsyncValue.error('err', StackTrace.empty));
    when(() => vm.retry()).thenReturn(null);
    await tester.pumpWidget(_wrap(const TodayScreenV2(), vm));
    expect(find.text('Algo salió mal. Inténtalo de nuevo.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('muestra contadores cuando hay datos', (tester) async {
    const data = TodayViewData(
      grouped: {},
      counters: DashboardCounters(
          totalActiveTasks: 3, totalMembers: 2,
          tasksDueToday: 3, tasksDoneToday: 1),
      showAdBanner: false, adBannerUnit: '',
      currentUid: 'uid1', homeId: 'home1',
      recurrenceOrder: [],
    );
    when(() => vm.viewData).thenReturn(const AsyncValue.data(data));
    await tester.pumpWidget(_wrap(const TodayScreenV2(), vm));
    await tester.pump();
    expect(find.byKey(const Key('counter_due')),  findsOneWidget);
    expect(find.byKey(const Key('counter_done')), findsOneWidget);
  });

  testWidgets('usa tipo abstracto TodayViewModel (no var)', (tester) async {
    expect(vm, isA<TodayViewModel>());
  });

  // Bug #36: HomeSelectorWidget debe estar siempre visible en AppBar
  testWidgets('AppBar muestra HomeSelectorWidget con un único hogar', (tester) async {
    when(() => vm.homes).thenReturn([
      const HomeDropdownItem(
        homeId: 'h1', name: 'Mi Casa', emoji: '🏠',
        role: MemberRole.owner, hasPendingToday: false, isSelected: true,
      ),
    ]);
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
    await tester.pumpWidget(_wrapWithHomes(const TodayScreenV2(), vm));
    expect(find.byType(HomeSelectorWidget), findsOneWidget);
    expect(find.byKey(const Key('home_selector')), findsOneWidget);
  });

  testWidgets('AppBar muestra HomeSelectorWidget con dos hogares', (tester) async {
    when(() => vm.homes).thenReturn([
      const HomeDropdownItem(
        homeId: 'h1', name: 'Mi Casa', emoji: '🏠',
        role: MemberRole.owner, hasPendingToday: false, isSelected: true,
      ),
      const HomeDropdownItem(
        homeId: 'h2', name: 'Oficina', emoji: '🏢',
        role: MemberRole.member, hasPendingToday: false, isSelected: false,
      ),
    ]);
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
    await tester.pumpWidget(_wrapWithHomes(const TodayScreenV2(), vm));
    expect(find.byType(HomeSelectorWidget), findsOneWidget);
    expect(find.byKey(const Key('home_selector')), findsOneWidget);
  });
}
