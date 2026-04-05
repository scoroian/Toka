import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/i18n/application/language_provider.dart';
import 'package:toka/features/i18n/domain/language.dart';
import 'package:toka/features/i18n/domain/language_repository.dart';
import 'package:toka/features/i18n/presentation/language_selector_widget.dart';
import 'package:toka/l10n/app_localizations.dart';

const _testLanguages = [
  Language(
    code: 'es', name: 'Español', flag: '🇪🇸',
    arbKey: 'app_es', enabled: true, sortOrder: 1,
  ),
  Language(
    code: 'en', name: 'English', flag: '🇬🇧',
    arbKey: 'app_en', enabled: true, sortOrder: 2,
  ),
  Language(
    code: 'ro', name: 'Română', flag: '🇷🇴',
    arbKey: 'app_ro', enabled: true, sortOrder: 3,
  ),
];

class _FakeLanguageRepository implements LanguageRepository {
  @override
  Future<List<Language>> fetchAvailableLanguages() async => _testLanguages;
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      languageRepositoryProvider.overrideWithValue(_FakeLanguageRepository()),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('renders flag, name and selection icon for each language',
      (tester) async {
    await tester.pumpWidget(_wrap(const LanguageSelectorWidget()));
    await tester.pump(); // resolve async provider

    expect(find.text('🇪🇸'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('🇬🇧'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('🇷🇴'), findsOneWidget);
    expect(find.text('Română'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
  });

  testWidgets('tapping a language calls onSelected callback', (tester) async {
    bool called = false;

    await tester.pumpWidget(_wrap(
      LanguageSelectorWidget(onSelected: () => called = true),
    ));
    await tester.pump();

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(called, isTrue);
  });

  testWidgets('golden: three languages displayed', (tester) async {
    await tester.pumpWidget(_wrap(const LanguageSelectorWidget()));
    await tester.pump();

    await expectLater(
      find.byType(LanguageSelectorWidget),
      matchesGoldenFile('goldens/language_selector_widget.png'),
    );
  });
}
