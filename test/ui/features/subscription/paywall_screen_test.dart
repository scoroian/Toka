// test/ui/features/subscription/paywall_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/intro_offer_provider.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/domain/intro_offer.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
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
  final Home? home;
  _FakeCurrentHome({this.home});

  @override
  Future<Home?> build() async => home;
}

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() {
    ref.onDispose(() {});
    return const AsyncValue.data(null);
  }
}

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: child,
      ),
    );

void main() {
  // Por defecto, sin trial (determinista: evita tocar el canal de in_app_purchase
  // en tests). Los tests del trial overridean este provider.
  final baseOverrides = <Override>[
    currentHomeProvider.overrideWith(() => _FakeCurrentHome(home: _freeHome)),
    paywallProvider.overrideWith(() => _FakePaywall()),
    annualIntroOfferProvider.overrideWith((ref) async => IntroOffer.none),
  ];

  List<Override> overridesWithOffer(IntroOffer offer) => [
        currentHomeProvider
            .overrideWith(() => _FakeCurrentHome(home: _freeHome)),
        paywallProvider.overrideWith(() => _FakePaywall()),
        annualIntroOfferProvider.overrideWith((ref) async => offer),
      ];

  testWidgets('PaywallScreen muestra CTA anual y mensual', (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_cta_annual')), findsOneWidget);
    expect(find.byKey(const Key('btn_cta_monthly')), findsOneWidget);
    expect(find.byKey(const Key('btn_restore')), findsOneWidget);
  });

  testWidgets('PaywallScreen muestra PlanComparisonCard', (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan_comparison_card')), findsOneWidget);
  });

  testWidgets('con free trial: CTA anual muestra "14 días gratis" + nota',
      (tester) async {
    await tester.pumpWidget(_wrap(const PaywallScreenV2(),
        overrides: overridesWithOffer(const IntroOffer(freeTrialDays: 14))));
    await tester.pumpAndSettle();

    // El botón anual pasa a copy de trial parametrizado por días.
    final ctaAnnual = tester.widget<FilledButton>(
      find.byKey(const Key('btn_cta_annual')),
    );
    final ctaText = ((ctaAnnual.child) as Text).data ?? '';
    expect(ctaText.contains('14'), isTrue);
    // Nota tranquilizadora visible.
    expect(find.byKey(const Key('paywall_trial_note')), findsOneWidget);
  });

  testWidgets('sin free trial: no aparece la nota de trial', (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('paywall_trial_note')), findsNothing);
  });

  testWidgets('golden: PaywallScreen', (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/paywall_screen.png'),
    );
  });
}
