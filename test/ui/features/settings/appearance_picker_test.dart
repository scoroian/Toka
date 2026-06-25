import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/settings/presentation/widgets/appearance_picker.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';
import 'package:toka/features/subscription/application/toka_plus_enabled_provider.dart';
import 'package:toka/l10n/app_localizations.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Widget _harness({
  List<Override> overrides = const [],
  Locale locale = const Locale('es'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      localizationsDelegates: _delegates,
      home: const Scaffold(body: AppearancePicker()),
    ),
  );
}

Widget _routerHarness({required List<Override> overrides}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: AppearancePicker()),
      ),
      GoRoute(
        path: AppRoutes.plusPaywall,
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('PLUS_PAYWALL_PROBE')),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      localizationsDelegates: _delegates,
      routerConfig: router,
    ),
  );
}

List<Override> _overrides({required bool flag, required bool plus}) => [
      tokaPlusEnabledProvider.overrideWithValue(flag),
      plusActiveProvider.overrideWithValue(plus),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('flag OFF: solo Clásico, sin skins Plus ni Futurista',
      (tester) async {
    await tester.pumpWidget(_harness(overrides: _overrides(flag: false, plus: false)));
    await tester.pumpAndSettle();

    expect(find.text('Clásico'), findsOneWidget);
    expect(find.byKey(const Key('skin_card_v2')), findsOneWidget);
    expect(find.byKey(const Key('skin_card_oceano')), findsNothing);
    expect(find.text('Futurista'), findsNothing);
  });

  testWidgets('la card activa (Clásico) muestra el check', (tester) async {
    await tester.pumpWidget(_harness(overrides: _overrides(flag: false, plus: false)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('flag ON + sin Plus: Océano visible pero BLOQUEADA con CTA',
      (tester) async {
    await tester.pumpWidget(_harness(overrides: _overrides(flag: true, plus: false)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skin_card_oceano')), findsOneWidget);
    expect(find.byKey(const Key('skin_lock_oceano')), findsOneWidget);
    expect(find.text('Requiere Toka Plus'), findsOneWidget);
    // Clásico sigue siendo la seleccionada (efectiva).
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('flag ON + con Plus: Océano seleccionable (sin candado)',
      (tester) async {
    await tester.pumpWidget(_harness(overrides: _overrides(flag: true, plus: true)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skin_card_oceano')), findsOneWidget);
    expect(find.byKey(const Key('skin_lock_oceano')), findsNothing);
    expect(find.text('Requiere Toka Plus'), findsNothing);
  });

  testWidgets('tap en Océano bloqueada navega al paywall de Plus',
      (tester) async {
    await tester.pumpWidget(
      _routerHarness(overrides: _overrides(flag: true, plus: false)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skin_card_oceano')));
    await tester.pumpAndSettle();

    expect(find.text('PLUS_PAYWALL_PROBE'), findsOneWidget);
  });

  testWidgets('tap en Océano con Plus la selecciona (check en Océano)',
      (tester) async {
    await tester.pumpWidget(_harness(overrides: _overrides(flag: true, plus: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skin_card_oceano')));
    await tester.pumpAndSettle();

    // La selección efectiva pasa a Océano: el check aparece en su card.
    final oceanoCard = find.byKey(const Key('skin_card_oceano'));
    expect(
      find.descendant(of: oceanoCard, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );
  });

  group('golden', () {
    for (final locale in const [Locale('es'), Locale('en'), Locale('ro')]) {
      testWidgets('picker bloqueado (${locale.languageCode})', (tester) async {
        await tester.pumpWidget(_harness(
          overrides: _overrides(flag: true, plus: false),
          locale: locale,
        ));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(AppearancePicker),
          matchesGoldenFile('goldens/appearance_picker_locked_${locale.languageCode}.png'),
        );
      });
    }

    testWidgets('picker desbloqueado (es)', (tester) async {
      await tester.pumpWidget(_harness(overrides: _overrides(flag: true, plus: true)));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(AppearancePicker),
        matchesGoldenFile('goldens/appearance_picker_unlocked_es.png'),
      );
    });
  });
}
