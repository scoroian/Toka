import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_flags_provider.dart';
import 'package:toka/shared/widgets/ad_visibility_provider.dart';
import 'package:toka/shared/widgets/skins/main_shell_root.dart';

/// Harness: monta MainShellRoot (→ MainShellV2) bajo un GoRouter mínimo, sin
/// mockear `adBannerConfigProvider`: ejercita la cadena REAL (flag maestro +
/// adVisibility) para decidir si el banner del shell aparece.
Widget _harness(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (_, __, child) => MainShellRoot(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const Text('home-content')),
        ],
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
    ),
  );
}

HomeDashboard _dash({required bool isPremium, bool showBanner = true}) =>
    HomeDashboard.fromFirestore({
      'premiumFlags': {'isPremium': isPremium, 'showAds': !isPremium},
      'adFlags': {
        'showBanner': showBanner,
        'bannerUnit': 'ca-app-pub-3940256099942544/6300978111',
      },
    });

ProviderContainer _container({
  required bool master,
  AdVisibility? visibility,
  required HomeDashboard dashboard,
}) {
  final c = ProviderContainer(overrides: [
    skinModeProvider.overrideWith(_FakeSkinMode.new),
    adDifferentiatedEnabledProvider.overrideWithValue(master),
    dashboardProvider.overrideWith((_) => Stream.value(dashboard)),
    if (visibility != null)
      adVisibilityProvider.overrideWithValue(visibility),
  ]);
  c.read(skinModeProvider.notifier).set(AppSkin.v2);
  return c;
}

final _bannerKey = find.byKey(const Key('ad_banner'));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> _pumpShell(WidgetTester tester, ProviderContainer c) async {
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(c));
    await tester.pump();
    await tester.pump();
  }

  // Desmonta el árbol para cancelar el Timer.periodic del banner cuando estuvo
  // presente (evita timers pendientes al cerrar el test).
  Future<void> _teardownBanner(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  group('flag maestro ON → banner del shell sigue adVisibility (matriz)', () {
    testWidgets('Fila 1: Free sin Plus (banner=true) → AdBanner presente',
        (tester) async {
      await _pumpShell(
        tester,
        _container(
          master: true,
          visibility: const AdVisibility(banner: true, interstitial: true),
          dashboard: _dash(isPremium: false),
        ),
      );
      expect(_bannerKey, findsOneWidget);
      await _teardownBanner(tester);
    });

    testWidgets('Fila 2: Free con Plus (banner=false) → AdBanner ausente',
        (tester) async {
      await _pumpShell(
        tester,
        _container(
          master: true,
          visibility: AdVisibility.hidden,
          dashboard: _dash(isPremium: false),
        ),
      );
      expect(_bannerKey, findsNothing);
    });

    testWidgets('Fila 3: Premium pagador (banner=false) → AdBanner ausente',
        (tester) async {
      await _pumpShell(
        tester,
        _container(
          master: true,
          visibility: AdVisibility.hidden,
          dashboard: _dash(isPremium: true, showBanner: false),
        ),
      );
      expect(_bannerKey, findsNothing);
    });

    testWidgets(
        'Fila 4: Premium miembro sin Plus (banner=true) → AdBanner PRESENTE '
        'aunque el dashboard sea premium (unit vacío)', (tester) async {
      await _pumpShell(
        tester,
        _container(
          master: true,
          visibility: const AdVisibility(banner: true, interstitial: false),
          dashboard: _dash(isPremium: true, showBanner: false),
        ),
      );
      expect(_bannerKey, findsOneWidget);
      await _teardownBanner(tester);
    });

    testWidgets('Fila 5: Premium miembro con Plus (banner=false) → AdBanner ausente',
        (tester) async {
      await _pumpShell(
        tester,
        _container(
          master: true,
          visibility: AdVisibility.hidden,
          dashboard: _dash(isPremium: true, showBanner: false),
        ),
      );
      expect(_bannerKey, findsNothing);
    });
  });

  group('flag maestro OFF → comportamiento de hogar (legacy)', () {
    testWidgets('hogar gratis con banner activo → AdBanner presente',
        (tester) async {
      await _pumpShell(
        tester,
        _container(
          master: false,
          dashboard: _dash(isPremium: false, showBanner: true),
        ),
      );
      expect(_bannerKey, findsOneWidget);
      await _teardownBanner(tester);
    });

    testWidgets(
        'hogar premium → AdBanner ausente para todos (revierte la matriz)',
        (tester) async {
      await _pumpShell(
        tester,
        _container(
          master: false,
          dashboard: _dash(isPremium: true, showBanner: false),
        ),
      );
      expect(_bannerKey, findsNothing);
    });
  });
}

class _FakeSkinMode extends SkinMode {
  @override
  AppSkin build() => AppSkin.v2;
  @override
  Future<void> set(AppSkin skin) async => state = skin;
}
