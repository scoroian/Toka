import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/profile/application/own_profile_view_model.dart';
import 'package:toka/features/profile/presentation/skins/futurista/profile_screen_futurista.dart';
import 'package:toka/features/profile/presentation/skins/own_profile_screen.dart';
import 'package:toka/features/profile/presentation/skins/own_profile_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeOwnProfileViewModel implements OwnProfileViewModel {
  const _FakeOwnProfileViewModel(this.viewData);

  @override
  final AsyncValue<OwnProfileViewData?> viewData;

  @override
  Future<void> signOut() async {}
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
        home: OwnProfileScreen(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: [
      ownProfileViewModelProvider.overrideWith(
        (ref) => const _FakeOwnProfileViewModel(AsyncValue.loading()),
      ),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    await tester.pump();
    expect(find.byType(OwnProfileScreenV2), findsOneWidget);
    expect(find.byType(ProfileScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      ownProfileViewModelProvider.overrideWith(
        (ref) => const _FakeOwnProfileViewModel(AsyncValue.loading()),
      ),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    // Pumps discretos: evitamos pumpAndSettle porque el estado loading muestra
    // un CircularProgressIndicator infinito.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(ProfileScreenFuturista), findsOneWidget);
    expect(find.byType(OwnProfileScreenV2), findsNothing);
  });
}
