import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/i18n/application/language_provider.dart';
import 'package:toka/features/i18n/domain/language.dart';
import 'package:toka/features/i18n/domain/language_repository.dart';
import 'package:toka/features/i18n/domain/languages_result.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/language_step_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

const _remoteLanguages = [
  Language(
      code: 'es',
      name: 'Español',
      flag: '🇪🇸',
      arbKey: 'app_es',
      enabled: true,
      sortOrder: 1),
  Language(
      code: 'en',
      name: 'English',
      flag: '🇬🇧',
      arbKey: 'app_en',
      enabled: true,
      sortOrder: 2),
  Language(
      code: 'ro',
      name: 'Română',
      flag: '🇷🇴',
      arbKey: 'app_ro',
      enabled: true,
      sortOrder: 3),
  Language(
      code: 'fr',
      name: 'Français',
      flag: '🇫🇷',
      arbKey: 'app_fr',
      enabled: true,
      sortOrder: 4),
];

/// Repositorio que falla la primera lectura (offline → fallback) y devuelve la
/// lista remota completa en la segunda (simula que volvió la red tras reintentar).
class _OfflineThenOnlineRepo implements LanguageRepository {
  int calls = 0;

  @override
  Future<LanguagesResult> fetchAvailableLanguages() async {
    calls++;
    if (calls == 1) {
      return const LanguagesResult(
          languages: Language.defaults, isFallback: true);
    }
    return const LanguagesResult(languages: _remoteLanguages);
  }
}

Widget _wrap({
  required List<Override> overrides,
  String? selectedLocale,
  ValueChanged<String>? onLocaleSelected,
  VoidCallback? onNext,
  VoidCallback? onPrev,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      home: Scaffold(
        body: LanguageStepV2(
          selectedLocale: selectedLocale,
          onLocaleSelected: onLocaleSelected ?? (_) {},
          onNext: onNext ?? () {},
          onPrev: onPrev ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'fallback offline: muestra los 3 idiomas por defecto + Reintentar + aviso',
      (tester) async {
    await tester.pumpWidget(_wrap(
      overrides: [
        availableLanguagesProvider.overrideWith(
          (ref) => Future.value(const LanguagesResult(
              languages: Language.defaults, isFallback: true)),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    // Los 3 idiomas base son seleccionables (la pantalla no está muerta).
    expect(find.byKey(const Key('lang_es')), findsOneWidget);
    expect(find.byKey(const Key('lang_en')), findsOneWidget);
    expect(find.byKey(const Key('lang_ro')), findsOneWidget);

    // Botón Reintentar y aviso de sin conexión presentes.
    expect(find.byKey(const Key('retry_languages')), findsOneWidget);
    expect(find.byKey(const Key('language_offline_notice')), findsOneWidget);
  });

  testWidgets('carga normal (online): no muestra Reintentar ni aviso',
      (tester) async {
    await tester.pumpWidget(_wrap(
      overrides: [
        availableLanguagesProvider.overrideWith(
          (ref) =>
              Future.value(const LanguagesResult(languages: _remoteLanguages)),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lang_fr')), findsOneWidget);
    expect(find.byKey(const Key('retry_languages')), findsNothing);
    expect(find.byKey(const Key('language_offline_notice')), findsNothing);
  });

  testWidgets('auto-avance: al seleccionar un idioma llama onLocaleSelected y onNext',
      (tester) async {
    String? selected;
    var nextCalls = 0;

    await tester.pumpWidget(_wrap(
      overrides: [
        availableLanguagesProvider.overrideWith(
          (ref) =>
              Future.value(const LanguagesResult(languages: Language.defaults)),
        ),
      ],
      onLocaleSelected: (code) => selected = code,
      onNext: () => nextCalls++,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lang_en')));
    await tester.pumpAndSettle();

    expect(selected, 'en');
    expect(nextCalls, 1);
  });

  testWidgets('Reintentar recarga la lista remota cuando vuelve la red',
      (tester) async {
    final repo = _OfflineThenOnlineRepo();

    await tester.pumpWidget(_wrap(
      overrides: [
        languageRepositoryProvider.overrideWithValue(repo),
      ],
    ));
    await tester.pumpAndSettle();

    // Primera carga: offline → fallback con los 3 básicos + Reintentar.
    expect(find.byKey(const Key('retry_languages')), findsOneWidget);
    expect(find.byKey(const Key('lang_fr')), findsNothing);

    // Reintentar con red disponible → carga la lista remota (incluye 'fr').
    await tester.tap(find.byKey(const Key('retry_languages')));
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.byKey(const Key('lang_fr')), findsOneWidget);
    expect(find.byKey(const Key('retry_languages')), findsNothing);
    expect(find.byKey(const Key('language_offline_notice')), findsNothing);
  });
}
