import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/home_tiers_provider.dart';
import 'package:toka/features/subscription/application/paywall_view_model.dart';
import 'package:toka/features/subscription/application/tier_pricing_provider.dart';
import 'package:toka/features/subscription/domain/intro_offer.dart';
import 'package:toka/features/subscription/presentation/skins/paywall_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

final _freeHome = Home(
  id: 'h1',
  name: 'Test',
  ownerUid: 'u1',
  currentPayerUid: null,
  lastPayerUid: null,
  premiumStatus: HomePremiumStatus.free,
  premiumPlan: null,
  premiumEndsAt: null,
  restoreUntil: null,
  autoRenewEnabled: false,
  limits: const HomeLimits(maxMembers: 3),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => _freeHome;
}

class _SpyPaywallVM implements PaywallViewModel {
  String? lastProductId;
  bool restoreCalled = false;
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
  Future<void> restorePremium() async {
    restoreCalled = true;
  }

  @override
  void clearPurchaseResult() {}
}

Widget _wrap(Widget child, {required List<Override> overrides, Locale locale = const Locale('es')}) =>
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
  _SpyPaywallVM? vm,
  Map<String, TierProductInfo> pricing = const {},
}) =>
    [
      homeTiersEnabledProvider.overrideWithValue(true),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      dashboardProvider.overrideWith((ref) => Stream.value(null)),
      tierPricingProvider.overrideWith((ref) async => pricing),
      if (vm != null) paywallViewModelProvider.overrideWithValue(vm),
    ];

void main() {
  testWidgets('flag ON: muestra los 3 tiers y el copy de "mismas funciones"',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: _overrides()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paywall_tier_card_pareja')), findsOneWidget);
    expect(find.byKey(const Key('paywall_tier_card_familia')), findsOneWidget);
    expect(find.byKey(const Key('paywall_tier_card_grupo')), findsOneWidget);
    expect(find.text('Toka Pareja'), findsOneWidget);
    expect(find.text('Toka Familia'), findsOneWidget);
    expect(find.text('Toka Grupo'), findsOneWidget);
    expect(find.byKey(const Key('paywall_tiers_copy')), findsOneWidget);
    // No se muestra el paywall binario.
    expect(find.byKey(const Key('btn_cta_annual')), findsNothing);
  });

  testWidgets('muestra los topes de miembros por tier', (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: _overrides()));
    await tester.pumpAndSettle();

    expect(find.text('Hasta 2 miembros'), findsOneWidget);
    expect(find.text('Hasta 5 miembros'), findsOneWidget);
    expect(find.text('Hasta 10 miembros'), findsOneWidget);
  });

  testWidgets('sin precios de store usa los precios fallback (ARB), ciclo anual',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: _overrides()));
    await tester.pumpAndSettle();

    // Default = anual.
    expect(find.text('19,99 €'), findsOneWidget); // pareja anual
    expect(find.text('29,99 €'), findsOneWidget); // familia anual
    expect(find.text('49,99 €'), findsOneWidget); // grupo anual
  });

  testWidgets('con precios de store: muestra el precio localizado de la store',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(pricing: {
        'toka_pareja_annual': const TierProductInfo(
          productId: 'toka_pareja_annual',
          price: 'US\$21.99',
          introOffer: IntroOffer.none,
        ),
      }),
    ));
    await tester.pumpAndSettle();

    expect(find.text('US\$21.99'), findsOneWidget); // precio de store gana
    expect(find.text('29,99 €'), findsOneWidget); // familia sigue fallback
  });

  testWidgets('toggle mensual cambia los precios a mensuales', (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: _overrides()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();

    expect(find.text('2,99 €'), findsOneWidget); // pareja mensual
    expect(find.text('3,99 €'), findsOneWidget); // familia mensual
    expect(find.text('5,99 €'), findsOneWidget); // grupo mensual
  });

  testWidgets('seleccionar tier + CTA compra el productId correcto (anual)',
      (tester) async {
    final vm = _SpyPaywallVM();
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: _overrides(vm: vm)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paywall_tier_card_grupo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_tier_cta')));
    await tester.pumpAndSettle();

    expect(vm.lastProductId, 'toka_grupo_annual');
  });

  testWidgets('CTA con ciclo mensual compra el SKU mensual', (tester) async {
    final vm = _SpyPaywallVM();
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: _overrides(vm: vm)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paywall_tier_card_familia')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_tier_cta')));
    await tester.pumpAndSettle();

    expect(vm.lastProductId, 'toka_familia_monthly');
  });

  testWidgets('trial de store en el SKU anual muestra badge de días gratis',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: _overrides(pricing: {
        'toka_pareja_annual': const TierProductInfo(
          productId: 'toka_pareja_annual',
          price: '19,99 €',
          introOffer: IntroOffer(freeTrialDays: 14),
        ),
      }),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('14'), findsWidgets);
  });

  testWidgets('en inglés los textos vienen de ARB (i18n)', (tester) async {
    await tester.pumpWidget(_wrap(const PaywallScreenV2(),
        overrides: _overrides(), locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Up to 2 members'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
  });

  testWidgets('en rumano renderiza sin overflow (i18n ro)', (tester) async {
    await tester.pumpWidget(_wrap(const PaywallScreenV2(),
        overrides: _overrides(), locale: const Locale('ro')));
    await tester.pumpAndSettle();
    // pumpAndSettle lanzaría si hubiese RenderFlex overflow; además verificamos
    // que el copy ro está presente.
    expect(find.text('Până la 2 membri'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('golden: paywall tiers anual', (tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: _overrides()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tiered_paywall_annual.png'),
    );
  });

  testWidgets('golden: paywall tiers mensual', (tester) async {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: _overrides()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tiered_paywall_monthly.png'),
    );
  });

  testWidgets('flag OFF: vuelve al paywall Premium único (binario)',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const PaywallScreenV2(),
      overrides: [
        homeTiersEnabledProvider.overrideWithValue(false),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        dashboardProvider.overrideWith((ref) => Stream.value(null)),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_cta_annual')), findsOneWidget);
    expect(find.byKey(const Key('btn_cta_monthly')), findsOneWidget);
    expect(find.byKey(const Key('paywall_tier_card_pareja')), findsNothing);
  });
}
