import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/homes/application/my_homes_view_model.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/presentation/skins/futurista/my_homes_screen_futurista.dart';
import 'package:toka/features/homes/presentation/skins/my_homes_screen.dart';
import 'package:toka/features/homes/presentation/skins/my_homes_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeMyHomesViewModel implements MyHomesViewModel {
  const _FakeMyHomesViewModel({required this.memberships});

  @override
  final AsyncValue<List<HomeMembership>> memberships;

  @override
  String get currentHomeId => '';

  @override
  void switchHome(String homeId) {}
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
        home: MyHomesScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: [
      myHomesViewModelProvider.overrideWith(
        (ref) => const _FakeMyHomesViewModel(
          memberships: AsyncValue.data(<HomeMembership>[]),
        ),
      ),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    await tester.pump();
    expect(find.byType(MyHomesScreenV2), findsOneWidget);
    expect(find.byType(MyHomesScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      myHomesViewModelProvider.overrideWith(
        (ref) => const _FakeMyHomesViewModel(
          memberships: AsyncValue.data(<HomeMembership>[]),
        ),
      ),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    // Pumps discretos para que SkinMode cargue la preferencia persistida.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(MyHomesScreenFuturista), findsOneWidget);
    expect(find.byType(MyHomesScreenV2), findsNothing);
  });
}
