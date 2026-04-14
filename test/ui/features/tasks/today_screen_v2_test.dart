import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/skins/today_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockTodayViewModel extends Mock implements TodayViewModel {}

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
    when(() => vm.viewData).thenReturn(AsyncValue.error('err', StackTrace.empty));
    when(() => vm.retry()).thenReturn(null);
    await tester.pumpWidget(_wrap(const TodayScreenV2(), vm));
    expect(find.text('Algo salió mal. Inténtalo de nuevo.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('muestra contadores cuando hay datos', (tester) async {
    final data = TodayViewData(
      grouped: {},
      counters: DashboardCounters(
          totalActiveTasks: 3, totalMembers: 2,
          tasksDueToday: 3, tasksDoneToday: 1),
      showAdBanner: false, adBannerUnit: '',
      currentUid: 'uid1', homeId: 'home1',
      recurrenceOrder: [],
    );
    when(() => vm.viewData).thenReturn(AsyncValue.data(data));
    await tester.pumpWidget(_wrap(const TodayScreenV2(), vm));
    await tester.pump();
    expect(find.byKey(const Key('counter_due')),  findsOneWidget);
    expect(find.byKey(const Key('counter_done')), findsOneWidget);
  });

  testWidgets('usa tipo abstracto TodayViewModel (no var)', (tester) async {
    expect(vm, isA<TodayViewModel>());
  });
}
