import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/members/application/vacation_provider.dart';
import 'package:toka/features/members/presentation/skins/futurista/vacation_screen_futurista.dart';
import 'package:toka/features/members/presentation/skins/vacation_screen.dart';
import 'package:toka/features/members/presentation/skins/vacation_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _harness(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en'), Locale('ro')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: VacationScreen(homeId: 'h1', uid: 'u1'),
      ),
    );

ProviderContainer _container() => ProviderContainer(overrides: [
      memberVacationProvider(homeId: 'h1', uid: 'u1')
          .overrideWith((_) => Stream.value(null)),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pumpAndSettle();
    expect(find.byType(VacationScreenV2), findsOneWidget);
    expect(find.byType(VacationScreenFuturista), findsNothing);
  });

  testWidgets(
      'wrapper renders futurista when skin = futurista y muestra date pickers '
      'al activar el toggle', (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    // Pumps discretos para dejar correr microtasks (load de SkinMode +
    // VacationVM init) sin pumpAndSettle (AnimatedSwitcher / animaciones).
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    expect(find.byType(VacationScreenFuturista), findsOneWidget);
    expect(find.byType(VacationScreenV2), findsNothing);
    expect(find.byKey(const Key('vacation_toggle')), findsOneWidget);
    expect(find.byKey(const Key('vacation_date_pickers')), findsNothing);

    await tester.tap(find.byKey(const Key('vacation_toggle')));
    await tester.pump();

    expect(find.byKey(const Key('vacation_date_pickers')), findsOneWidget);
    // El CTA Guardar puede estar fuera del viewport en ListView; comprobamos
    // que existe al menos una vez tras hacer scroll para evitar dependencia
    // del tamaño de pantalla del runner.
    await tester.scrollUntilVisible(
      find.byKey(const Key('btn_save_vacation')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('btn_save_vacation')), findsOneWidget);
  });
}
