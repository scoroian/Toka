// test/ui/features/subscription/rescue_screen_test.dart
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
import 'package:toka/features/subscription/presentation/skins/rescue_screen_v2.dart';
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

final _rescueHome = Home(
  id: 'h1',
  name: 'Test',
  ownerUid: 'u1',
  currentPayerUid: null,
  lastPayerUid: null,
  premiumStatus: HomePremiumStatus.rescue,
  premiumPlan: 'monthly',
  premiumEndsAt: DateTime(2026, 5),
  restoreUntil: null,
  autoRenewEnabled: false,
  limits: const HomeLimits(maxMembers: 10),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

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
  late List<Override> baseOverrides;

  setUp(() {
    final mockRepo = _MockSubscriptionRepository();
    baseOverrides = [
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(_rescueHome)),
      subscriptionRepositoryProvider.overrideWithValue(mockRepo),
      subscriptionStateProvider.overrideWith(
        (_) => const SubscriptionState.rescue(
          plan: 'monthly',
          endsAt: null,
          daysLeft: 2,
        ),
      ),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ];
  });

  testWidgets('RescueScreen: se renderiza correctamente (Scaffold)',
      (tester) async {
    await tester.pumpWidget(_wrap(const RescueScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('RescueScreen: muestra botón de renovación anual', (tester) async {
    await tester.pumpWidget(_wrap(const RescueScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_renew_annual')), findsOneWidget);
  });

  testWidgets('RescueScreen: muestra botón de renovación mensual',
      (tester) async {
    await tester.pumpWidget(_wrap(const RescueScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_renew_monthly')), findsOneWidget);
  });

  testWidgets('RescueScreen: muestra botón de plan downgrade', (tester) async {
    await tester.pumpWidget(_wrap(const RescueScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_plan_downgrade')), findsOneWidget);
  });

  test('RescueViewModel: isLoading es false con FakePaywall en estado data', () {
    final mockRepo = _MockSubscriptionRepository();
    final container = ProviderContainer(overrides: [
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(_rescueHome)),
      subscriptionRepositoryProvider.overrideWithValue(mockRepo),
      subscriptionStateProvider.overrideWith(
        (_) => const SubscriptionState.rescue(
          plan: 'monthly',
          endsAt: null,
          daysLeft: 2,
        ),
      ),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ]);
    addTearDown(container.dispose);

    final paywall = container.read(paywallProvider);
    expect(paywall.isLoading, isFalse);
  });
}
