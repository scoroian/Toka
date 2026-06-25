import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/subscription/application/home_tiers_provider.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/subscription_dashboard_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_dashboard.dart';
import 'package:toka/features/subscription/presentation/skins/subscription_management_screen_v2.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';

const _payer = AuthUser(
  uid: 'payer1',
  email: 'p@test.com',
  displayName: 'P',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() {
    ref.onDispose(() {});
    return const AsyncValue.data(null);
  }

  @override
  Future<void> startPurchase(
      {required String homeId, required String productId}) async {}
  @override
  Future<void> restorePremium({required String homeId}) async {}
}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.authenticated(_payer);
}

SubscriptionDashboard _dashboard({
  HomePremiumStatus status = HomePremiumStatus.active,
  String? tier,
  int? maxMembers,
}) =>
    SubscriptionDashboard(
      homeId: 'h1',
      status: status,
      plan: 'annual',
      endsAt: DateTime(2027),
      restoreUntil: null,
      autoRenew: true,
      currentPayerUid: 'payer1',
      planCounters: PlanCounters.empty(),
      tier: tier,
      maxMembers: maxMembers,
    );

List<Override> _overrides(SubscriptionDashboard dash, {bool tiersEnabled = true}) =>
    [
      homeTiersEnabledProvider.overrideWithValue(tiersEnabled),
      authProvider.overrideWith(() => _FakeAuth()),
      subscriptionDashboardProvider().overrideWith((_) => Stream.value(dash)),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ];

Widget _wrap(Widget child, {required List<Override> overrides}) => ProviderScope(
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
  testWidgets('estado active con tier Familia muestra el resumen de tier y tope',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(_dashboard(tier: 'familia', maxMembers: 5)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan_tier_summary')), findsOneWidget);
    expect(find.textContaining('Toka Familia'), findsOneWidget);
    expect(find.textContaining('5'), findsWidgets);
  });

  testWidgets('estado active con tier Grupo muestra Toka Grupo y 10',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(_dashboard(tier: 'grupo', maxMembers: 10)),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Toka Grupo'), findsOneWidget);
  });

  testWidgets('flag ON + pagador: aparece CTA "Cambiar de plan" en active',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(_dashboard(tier: 'pareja', maxMembers: 2)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_change_plan_tier')), findsOneWidget);
  });

  testWidgets('flag OFF: NO aparece CTA de cambiar tier ni resumen de tier',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(_dashboard(tier: null), tiersEnabled: false),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_change_plan_tier')), findsNothing);
    expect(find.byKey(const Key('plan_tier_summary')), findsNothing);
    // El comportamiento binario (gestionar facturación) se mantiene.
    expect(find.byKey(const Key('btn_manage_billing')), findsOneWidget);
  });
}
