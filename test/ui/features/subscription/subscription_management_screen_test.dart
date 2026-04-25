// test/ui/features/subscription/subscription_management_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/subscription_dashboard_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_dashboard.dart';
import 'package:toka/features/subscription/presentation/skins/subscription_management_screen_v2.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() {
    ref.onDispose(() {});
    return const AsyncValue.data(null);
  }

  @override
  Future<void> startPurchase({
    required String homeId,
    required String productId,
  }) async {}

  @override
  Future<void> saveDowngradePlan({
    required String homeId,
    required List<String> memberIds,
    required List<String> taskIds,
  }) async {}

  @override
  Future<void> restorePremium({required String homeId}) async {}
}

SubscriptionDashboard _makeDashboard(HomePremiumStatus status) =>
    SubscriptionDashboard(
      homeId: 'h1',
      status: status,
      plan: 'monthly',
      endsAt: DateTime(2026, 5),
      restoreUntil: DateTime(2026, 6),
      autoRenew: false,
      currentPayerUid: null,
      planCounters: PlanCounters.empty(),
    );

List<Override> _overridesFor(SubscriptionDashboard dashboard) => [
      subscriptionDashboardProvider()
          .overrideWith((_) => Stream.value(dashboard)),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ];

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
  testWidgets('SubscriptionManagementScreen: estado active muestra card y sin spinner',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overridesFor(_makeDashboard(HomePremiumStatus.active)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('plan_summary_card')), findsOneWidget);
    expect(find.byKey(const Key('btn_manage_billing')), findsOneWidget);
  });

  testWidgets('SubscriptionManagementScreen: estado free muestra btn_go_premium',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overridesFor(_makeDashboard(HomePremiumStatus.free)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan_summary_card')), findsOneWidget);
    expect(find.byKey(const Key('btn_go_premium')), findsOneWidget);
  });

  testWidgets(
      'SubscriptionManagementScreen: estado restorable muestra btn_restore_premium',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overridesFor(_makeDashboard(HomePremiumStatus.restorable)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan_summary_card')), findsOneWidget);
    expect(find.byKey(const Key('btn_restore_premium')), findsOneWidget);
  });

  testWidgets(
      'SubscriptionManagementScreen: estado cancelledPendingEnd muestra btn_reactivate_renewal',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides:
          _overridesFor(_makeDashboard(HomePremiumStatus.cancelledPendingEnd)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_reactivate_renewal')), findsOneWidget);
    expect(find.byKey(const Key('btn_change_plan')), findsOneWidget);
  });

  testWidgets('SubscriptionManagementScreen: estado rescue muestra btn_renew',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overridesFor(_makeDashboard(HomePremiumStatus.rescue)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rescue_warning_banner')), findsOneWidget);
    expect(find.byKey(const Key('btn_renew')), findsOneWidget);
    expect(find.byKey(const Key('btn_plan_downgrade')), findsOneWidget);
  });

  testWidgets(
      'SubscriptionManagementScreen: estado expiredFree muestra btn_reactivate_premium',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overridesFor(_makeDashboard(HomePremiumStatus.expiredFree)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_reactivate_premium')), findsOneWidget);
  });
}
