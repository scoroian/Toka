import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/home_tiers_provider.dart';
import 'package:toka/features/subscription/application/member_packs_enabled_provider.dart';
import 'package:toka/features/subscription/application/member_packs_pricing_provider.dart';
import 'package:toka/features/subscription/application/paywall_view_model.dart';
import 'package:toka/features/subscription/application/tier_pricing_provider.dart';
import 'package:toka/features/subscription/presentation/skins/paywall_screen_v2.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';

final _home = Home(
  id: 'h1',
  name: 'Casa',
  ownerUid: 'u1',
  currentPayerUid: 'u1',
  lastPayerUid: 'u1',
  premiumStatus: HomePremiumStatus.active,
  premiumPlan: 'toka_grupo_annual',
  premiumEndsAt: DateTime(2027),
  restoreUntil: null,
  autoRenewEnabled: true,
  limits: const HomeLimits(maxMembers: 10),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => _home;
}

class _SpyPaywallVM implements PaywallViewModel {
  String? lastProductId;
  @override
  bool get isLoading => false;
  @override
  bool get purchasedSuccessfully => false;
  @override
  String? get purchaseError => null;
  @override
  Future<void> startPurchase(String productId) async {
    lastProductId = productId;
  }

  @override
  Future<void> restorePremium() async {}
  @override
  void clearPurchaseResult() {}
}

HomeDashboard _dashboard({
  required String tier,
  required int maxMembers,
  bool plus5 = false,
  bool plus10 = false,
}) =>
    HomeDashboard.fromFirestore({
      'activeTasksPreview': [],
      'doneTasksPreview': [],
      'counters': {},
      'planCounters': {'activeMembers': 0},
      'memberPreview': [],
      'premiumFlags': {
        'isPremium': true,
        'showAds': false,
        'tier': tier,
        'maxMembers': maxMembers,
        'memberPacks': {'plus5': plus5, 'plus10': plus10},
      },
      'adFlags': {},
      'rescueFlags': {},
      'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
    });

Widget _wrap(Widget child,
        {required List<Override> overrides, Locale locale = const Locale('es')}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
        locale: locale,
        home: child,
      ),
    );

List<Override> _overrides({
  required HomeDashboard dashboard,
  bool packsEnabled = true,
  _SpyPaywallVM? vm,
  Map<String, String> packPricing = const {},
}) =>
    [
      homeTiersEnabledProvider.overrideWithValue(true),
      memberPacksEnabledProvider.overrideWithValue(packsEnabled),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      dashboardProvider.overrideWith((ref) => Stream.value(dashboard)),
      tierPricingProvider.overrideWith((ref) async => const {}),
      memberPacksPricingProvider.overrideWith((ref) async => packPricing),
      if (vm != null) paywallViewModelProvider.overrideWithValue(vm),
    ];

void main() {
  testWidgets('Grupo + flag ON: muestra la sección con ambos packs y caps',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(dashboard: _dashboard(tier: 'grupo', maxMembers: 10)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paywall_packs_section')), findsOneWidget);
    expect(find.byKey(const Key('paywall_pack_card_plus5')), findsOneWidget);
    expect(find.byKey(const Key('paywall_pack_card_plus10')), findsOneWidget);
    // Cap resultante: +5 → 15, +10 → 20.
    expect(find.text('Hasta 15 miembros'), findsOneWidget);
    expect(find.text('Hasta 20 miembros'), findsOneWidget);
    // Precios fallback anual (default = anual). Se acotan a la tarjeta del pack
    // porque el fallback anual de Pareja (19,99 €) coincide con el del Pack +10.
    expect(
      find.descendant(
        of: find.byKey(const Key('paywall_pack_card_plus5')),
        matching: find.text('9,99 €'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('paywall_pack_card_plus10')),
        matching: find.text('19,99 €'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Grupo con +10 activo: +10 marca Activo y +5 lleva a 25',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(
          dashboard: _dashboard(tier: 'grupo', maxMembers: 20, plus10: true)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paywall_pack_active_plus10')), findsOneWidget);
    expect(find.byKey(const Key('paywall_pack_buy_plus10')), findsNothing);
    // +5 sobre 20 → 25.
    expect(find.text('Hasta 25 miembros'), findsOneWidget);
    expect(find.byKey(const Key('paywall_pack_buy_plus5')), findsOneWidget);
  });

  testWidgets('Grupo con ambos packs (cap 25): muestra el tile de Toka Business',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(
          dashboard: _dashboard(
              tier: 'grupo', maxMembers: 25, plus5: true, plus10: true)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paywall_packs_business_tile')), findsOneWidget);
    expect(find.byKey(const Key('paywall_pack_buy_plus5')), findsNothing);
    expect(find.byKey(const Key('paywall_pack_buy_plus10')), findsNothing);
  });

  testWidgets('Tile Business abre el diálogo informativo', (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(
          dashboard: _dashboard(
              tier: 'grupo', maxMembers: 25, plus5: true, plus10: true)),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('paywall_packs_business_tile')));
    await tester.tap(find.byKey(const Key('paywall_packs_business_tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('toka_business_dialog')), findsOneWidget);
  });

  testWidgets('No-Grupo (Familia): sección bloqueada con CTA a Grupo',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides:
          _overrides(dashboard: _dashboard(tier: 'familia', maxMembers: 5)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paywall_packs_locked')), findsOneWidget);
    expect(find.byKey(const Key('paywall_packs_upgrade_cta')), findsOneWidget);
    expect(find.byKey(const Key('paywall_pack_card_plus5')), findsNothing);
  });

  testWidgets('Flag OFF: no se ofrece ninguna sección de packs', (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(
        dashboard: _dashboard(tier: 'grupo', maxMembers: 10),
        packsEnabled: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paywall_packs_section')), findsNothing);
    expect(find.byKey(const Key('paywall_packs_locked')), findsNothing);
  });

  testWidgets('Comprar pack +5 dispara startPurchase con el SKU anual',
      (tester) async {
    final vm = _SpyPaywallVM();
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(
          dashboard: _dashboard(tier: 'grupo', maxMembers: 10), vm: vm),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('paywall_pack_buy_plus5')));
    await tester.tap(find.byKey(const Key('paywall_pack_buy_plus5')));
    await tester.pumpAndSettle();
    expect(vm.lastProductId, 'toka_pack5_annual');
  });

  testWidgets('Con ciclo mensual, comprar pack +10 usa el SKU mensual',
      (tester) async {
    final vm = _SpyPaywallVM();
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(
          dashboard: _dashboard(tier: 'grupo', maxMembers: 10), vm: vm),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('paywall_pack_buy_plus10')));
    await tester.tap(find.byKey(const Key('paywall_pack_buy_plus10')));
    await tester.pumpAndSettle();
    expect(vm.lastProductId, 'toka_pack10_monthly');
  });

  testWidgets('CTA "Sube a Grupo" selecciona el tier Grupo', (tester) async {
    final vm = _SpyPaywallVM();
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(
          dashboard: _dashboard(tier: 'familia', maxMembers: 5), vm: vm),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('paywall_packs_upgrade_cta')));
    await tester.tap(find.byKey(const Key('paywall_packs_upgrade_cta')));
    await tester.pumpAndSettle();
    // Tras seleccionar Grupo, el CTA principal compra el SKU de Grupo.
    await tester.ensureVisible(find.byKey(const Key('btn_tier_cta')));
    await tester.tap(find.byKey(const Key('btn_tier_cta')));
    await tester.pumpAndSettle();
    expect(vm.lastProductId, 'toka_grupo_annual');
  });

  testWidgets('precio de la store gana sobre el fallback', (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(
        dashboard: _dashboard(tier: 'grupo', maxMembers: 10),
        packPricing: const {'toka_pack5_annual': r'US$11.99'},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text(r'US$11.99'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('paywall_pack_card_plus10')),
        matching: find.text('19,99 €'),
      ),
      findsOneWidget,
    ); // +10 sigue fallback
  });

  testWidgets('en inglés la sección viene de ARB', (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(dashboard: _dashboard(tier: 'grupo', maxMembers: 10)),
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Expand your home'), findsOneWidget);
    expect(find.text('Up to 15 members'), findsOneWidget);
  });

  testWidgets('en rumano renderiza sin overflow', (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(dashboard: _dashboard(tier: 'grupo', maxMembers: 10)),
      locale: const Locale('ro'),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('paywall_packs_section')), findsOneWidget);
  });

  for (final locale in ['es', 'en', 'ro']) {
    testWidgets('golden: sección de packs Grupo ($locale)', (tester) async {
      // Lienzo alto para que la sección de packs (bajo los tiers) entre entera
      // en el golden sin recortes del scroll.
      tester.view.physicalSize = const Size(1080, 3800);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(
        const PaywallScreenV2(),
        overrides:
            _overrides(dashboard: _dashboard(tier: 'grupo', maxMembers: 10)),
        locale: Locale(locale),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/paywall_packs_grupo_$locale.png'),
      );
    });
  }

  testWidgets('golden: sección bloqueada (no-Grupo, es)', (tester) async {
    tester.view.physicalSize = const Size(1080, 3800);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides:
          _overrides(dashboard: _dashboard(tier: 'familia', maxMembers: 5)),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/paywall_packs_locked.png'),
    );
  });
}
