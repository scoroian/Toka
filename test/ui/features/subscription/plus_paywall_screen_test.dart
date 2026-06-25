import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/plus_pricing_provider.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';
import 'package:toka/features/subscription/domain/intro_offer.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_products.dart';
import 'package:toka/features/subscription/presentation/skins/plus_paywall_screen_v2.dart';
import 'package:toka/features/subscription/application/tier_pricing_provider.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakePaywall extends Paywall {
  final List<({String homeId, String productId})> calls = [];
  @override
  AsyncValue<PurchaseResult?> build() => const AsyncValue.data(null);
  @override
  Future<void> startPurchase({
    required String homeId,
    required String productId,
  }) async {
    calls.add((homeId: homeId, productId: productId));
  }
}

TierProductInfo _info(String id, String price) =>
    TierProductInfo(productId: id, price: price, introOffer: IntroOffer.none);

Widget _harness({
  required bool hasPlus,
  Map<String, TierProductInfo> pricing = const {},
  _FakePaywall? paywall,
  Locale locale = const Locale('es'),
}) {
  return ProviderScope(
    overrides: [
      plusActiveProvider.overrideWithValue(hasPlus),
      plusPricingProvider.overrideWith((ref) async => pricing),
      paywallProvider.overrideWith(() => paywall ?? _FakePaywall()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const PlusPaywallScreenV2(),
    ),
  );
}

void main() {
  testWidgets('muestra planes con precios fallback y beneficios',
      (tester) async {
    await tester.pumpWidget(_harness(hasPlus: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plus_plan_annual')), findsOneWidget);
    expect(find.byKey(const Key('plus_plan_monthly')), findsOneWidget);
    expect(find.text('14,99 €'), findsOneWidget);
    expect(find.text('1,99 €'), findsOneWidget);
    expect(find.text('Aspectos exclusivos'), findsOneWidget);
    expect(find.text('Métricas personales'), findsOneWidget);
    expect(find.byKey(const Key('plus_cta')), findsOneWidget);
  });

  testWidgets('usa el precio de la store cuando existe', (tester) async {
    await tester.pumpWidget(_harness(
      hasPlus: false,
      pricing: {kPlusAnnualProductId: _info(kPlusAnnualProductId, '12,00 €')},
    ));
    await tester.pumpAndSettle();

    expect(find.text('12,00 €'), findsOneWidget); // store
    expect(find.text('1,99 €'), findsOneWidget); // fallback mensual
  });

  testWidgets('por defecto el plan anual está seleccionado', (tester) async {
    await tester.pumpWidget(_harness(hasPlus: false));
    await tester.pumpAndSettle();

    final annual = find.byKey(const Key('plus_plan_annual'));
    expect(
      find.descendant(of: annual, matching: find.byIcon(Icons.radio_button_checked)),
      findsOneWidget,
    );
  });

  testWidgets('tap en mensual lo selecciona', (tester) async {
    await tester.pumpWidget(_harness(hasPlus: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plus_plan_monthly')));
    await tester.pumpAndSettle();

    final monthly = find.byKey(const Key('plus_plan_monthly'));
    expect(
      find.descendant(of: monthly, matching: find.byIcon(Icons.radio_button_checked)),
      findsOneWidget,
    );
  });

  testWidgets('tap en CTA inicia compra con homeId vacío y SKU anual',
      (tester) async {
    final paywall = _FakePaywall();
    await tester.pumpWidget(_harness(hasPlus: false, paywall: paywall));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plus_cta')));
    await tester.pump();

    expect(paywall.calls, hasLength(1));
    expect(paywall.calls.single.homeId, '');
    expect(paywall.calls.single.productId, kPlusAnnualProductId);
  });

  testWidgets('estado ya activo: sin planes, muestra confirmación',
      (tester) async {
    await tester.pumpWidget(_harness(hasPlus: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plus_already_active')), findsOneWidget);
    expect(find.byKey(const Key('plus_plan_annual')), findsNothing);
    expect(find.text('Ya tienes Toka Plus'), findsOneWidget);
  });

  group('golden', () {
    for (final locale in const [Locale('es'), Locale('en'), Locale('ro')]) {
      testWidgets('paywall Plus (${locale.languageCode})', (tester) async {
        await tester.pumpWidget(_harness(hasPlus: false, locale: locale));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(PlusPaywallScreenV2),
          matchesGoldenFile('goldens/plus_paywall_${locale.languageCode}.png'),
        );
      });
    }
  });
}
