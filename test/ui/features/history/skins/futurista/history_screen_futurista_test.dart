import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/history/application/history_view_model.dart';
import 'package:toka/features/history/domain/history_filter.dart';
import 'package:toka/features/history/presentation/skins/futurista/history_screen_futurista.dart';
import 'package:toka/features/history/presentation/skins/history_screen.dart';
import 'package:toka/features/history/presentation/skins/history_screen_v2.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

class _FakeHistoryViewModel implements HistoryViewModel {
  const _FakeHistoryViewModel();

  @override
  AsyncValue<List<TaskEventItem>> get items =>
      const AsyncValue.data(<TaskEventItem>[]);

  @override
  HistoryFilter get filter => const HistoryFilter();

  @override
  bool get hasMore => false;

  @override
  bool get isPremium => false;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => const _FakeHistoryViewModel(),
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
        (ref) => const _FakeHistoryViewModel(),
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
}
