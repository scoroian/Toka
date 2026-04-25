import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/i18n/application/language_provider.dart';
import 'package:toka/features/i18n/domain/language.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/futurista/language_step_futurista.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/language_step.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/language_step_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

const _kLanguages = <Language>[
  Language(
    code: 'es',
    name: 'Español',
    flag: '🇪🇸',
    arbKey: 'app_es',
    enabled: true,
    sortOrder: 1,
  ),
];

Widget _harness(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: LanguageStep(
            selectedLocale: 'es',
            onLocaleSelected: (_) {},
            onNext: () {},
            onPrev: () {},
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: [
      availableLanguagesProvider
          .overrideWith((ref) => Future.value(_kLanguages)),
    ]);
    addTearDown(c.dispose);

    await tester.pumpWidget(_harness(c));
    await tester.pump();

    expect(find.byType(LanguageStepV2), findsOneWidget);
    expect(find.byType(LanguageStepFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tocka.skin': 'futurista'});
    final c = ProviderContainer(overrides: [
      availableLanguagesProvider
          .overrideWith((ref) => Future.value(_kLanguages)),
    ]);
    addTearDown(c.dispose);

    await tester.pumpWidget(_harness(c));
    // Initial frame + microtask para cargar SkinMode + settle del
    // AnimatedSwitcher que transiciona entre v2 y futurista.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(LanguageStepFuturista), findsOneWidget);
    expect(find.byType(LanguageStepV2), findsNothing);
  });
}
