import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/profile/application/personal_metrics_view_model.dart';
import 'package:toka/features/profile/domain/personal_metrics.dart';
import 'package:toka/features/profile/presentation/skins/personal_metrics_screen_v2.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';
import 'package:toka/l10n/app_localizations.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

PersonalMetrics _data() => const PersonalMetrics(
      tasksCompleted: 12,
      passedCount: 3,
      compliancePercent: 87,
      currentStreak: 4,
      averageScore: 8.2,
      sharePercent: 40,
      hasData: true,
    );

Widget _harness({
  required bool hasPlus,
  AsyncValue<PersonalMetrics>? metrics,
  Locale locale = const Locale('es'),
}) {
  return ProviderScope(
    overrides: [
      plusActiveProvider.overrideWithValue(hasPlus),
      if (metrics != null)
        personalMetricsViewModelProvider.overrideWithValue(metrics),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      localizationsDelegates: _delegates,
      home: const PersonalMetricsScreenV2(),
    ),
  );
}

Widget _routerHarness({required bool hasPlus}) {
  final router = GoRouter(
    initialLocation: AppRoutes.personalMetrics,
    routes: [
      GoRoute(
        path: AppRoutes.personalMetrics,
        builder: (_, __) => const PersonalMetricsScreenV2(),
      ),
      GoRoute(
        path: AppRoutes.plusPaywall,
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('PLUS_PAYWALL_PROBE'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [plusActiveProvider.overrideWithValue(hasPlus)],
    child: MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      localizationsDelegates: _delegates,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('sin Plus: muestra bloqueo con CTA y nada de métricas',
      (tester) async {
    await tester.pumpWidget(_harness(hasPlus: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrics_locked')), findsOneWidget);
    expect(find.byKey(const Key('metrics_unlock_cta')), findsOneWidget);
    expect(find.byKey(const Key('metric_completed')), findsNothing);
  });

  testWidgets('sin Plus: el CTA navega al paywall de Plus', (tester) async {
    await tester.pumpWidget(_routerHarness(hasPlus: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('metrics_unlock_cta')));
    await tester.pumpAndSettle();

    expect(find.text('PLUS_PAYWALL_PROBE'), findsOneWidget);
  });

  testWidgets('con Plus y datos: muestra todas las métricas con sus valores',
      (tester) async {
    await tester.pumpWidget(
      _harness(hasPlus: true, metrics: AsyncValue.data(_data())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrics_locked')), findsNothing);
    expect(find.byKey(const Key('metric_completed')), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4'), findsOneWidget); // racha
    expect(find.text('87%'), findsOneWidget); // puntualidad
    expect(find.text('8.2'), findsOneWidget); // media
    expect(find.text('3'), findsOneWidget); // pasados
    expect(find.text('40%'), findsOneWidget); // reparto
  });

  testWidgets('con Plus sin actividad: muestra estado vacío', (tester) async {
    await tester.pumpWidget(
      _harness(hasPlus: true, metrics: AsyncValue.data(PersonalMetrics.empty())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrics_empty')), findsOneWidget);
    expect(find.byKey(const Key('metric_completed')), findsNothing);
  });

  testWidgets('con Plus cargando: muestra spinner', (tester) async {
    await tester.pumpWidget(
      _harness(hasPlus: true, metrics: const AsyncValue.loading()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('golden', () {
    for (final locale in const [Locale('es'), Locale('en'), Locale('ro')]) {
      testWidgets('métricas con datos (${locale.languageCode})',
          (tester) async {
        await tester.pumpWidget(_harness(
          hasPlus: true,
          metrics: AsyncValue.data(_data()),
          locale: locale,
        ));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(PersonalMetricsScreenV2),
          matchesGoldenFile('goldens/personal_metrics_${locale.languageCode}.png'),
        );
      });
    }

    testWidgets('métricas bloqueadas (es)', (tester) async {
      await tester.pumpWidget(_harness(hasPlus: false));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(PersonalMetricsScreenV2),
        matchesGoldenFile('goldens/personal_metrics_locked_es.png'),
      );
    });
  });
}
