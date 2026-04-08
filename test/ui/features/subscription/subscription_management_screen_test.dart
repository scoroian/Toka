// test/ui/features/subscription/subscription_management_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/features/subscription/presentation/subscription_management_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

class _FakeCurrentHome extends CurrentHome {
  final Home? _home;
  _FakeCurrentHome(this._home);

  @override
  Future<Home?> build() async => _home;
}

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

Home _makeHome(HomePremiumStatus status) => Home(
      id: 'h1',
      name: 'Test',
      ownerUid: 'u1',
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: status,
      premiumPlan: 'monthly',
      premiumEndsAt: DateTime(2026, 5),
      restoreUntil: DateTime(2026, 6),
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 10),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

List<Override> _overridesFor(SubscriptionState subState, Home home) {
  final mockRepo = _MockSubscriptionRepository();
  return [
    currentHomeProvider.overrideWith(() => _FakeCurrentHome(home)),
    subscriptionRepositoryProvider.overrideWithValue(mockRepo),
    subscriptionStateProvider.overrideWith((_) => subState),
    paywallProvider.overrideWith(() => _FakePaywall()),
  ];
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
  testWidgets(
      'SubscriptionManagementScreen: sin spinner para SubscriptionState.active',
      (tester) async {
    final subState = SubscriptionState.active(
      plan: 'annual',
      endsAt: DateTime(2027),
      autoRenew: true,
    );
    final home = _makeHome(HomePremiumStatus.active);

    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreen(),
      overrides: _overridesFor(subState, home),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('subscription_status_tile')), findsOneWidget);
  });

  testWidgets(
      'SubscriptionManagementScreen: se renderiza para SubscriptionState.free',
      (tester) async {
    const subState = SubscriptionState.free();
    final home = _makeHome(HomePremiumStatus.free);

    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreen(),
      overrides: _overridesFor(subState, home),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byKey(const Key('subscription_status_tile')), findsOneWidget);
    // En estado free debe mostrarse el botón de actualizar a premium
    expect(find.byKey(const Key('btn_go_premium')), findsOneWidget);
  });

  testWidgets(
      'SubscriptionManagementScreen: se renderiza para SubscriptionState.restorable',
      (tester) async {
    final subState = SubscriptionState.restorable(
      restoreUntil: DateTime(2026, 6),
    );
    final home = _makeHome(HomePremiumStatus.restorable);

    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreen(),
      overrides: _overridesFor(subState, home),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byKey(const Key('subscription_status_tile')), findsOneWidget);
    // En estado restorable debe mostrarse el botón de restaurar premium
    expect(find.byKey(const Key('btn_restore_premium')), findsOneWidget);
  });

  test(
      'SubscriptionManagementViewModel: isLoading es false con FakePaywall en estado data',
      () {
    final mockRepo = _MockSubscriptionRepository();
    final container = ProviderContainer(overrides: [
      currentHomeProvider
          .overrideWith(() => _FakeCurrentHome(_makeHome(HomePremiumStatus.active))),
      subscriptionRepositoryProvider.overrideWithValue(mockRepo),
      subscriptionStateProvider.overrideWith(
        (_) => SubscriptionState.active(
          plan: 'monthly',
          endsAt: DateTime(2027),
          autoRenew: true,
        ),
      ),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ]);
    addTearDown(container.dispose);

    final paywall = container.read(paywallProvider);
    expect(paywall.isLoading, isFalse);
  });
}
