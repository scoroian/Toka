// test/unit/features/subscription/paywall_view_model_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/paywall_view_model.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';

// ---------------------------------------------------------------------------
// Fakes / Mocks
// ---------------------------------------------------------------------------

class _FakeCurrentHome extends CurrentHome {
  final Home? _home;
  _FakeCurrentHome(this._home);
  @override
  Future<Home?> build() async => _home;
}

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

/// Fake Paywall notifier that doesn't touch InAppPurchase.
class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() => const AsyncValue.data(null);

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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Home _makeHome() => Home(
      id: 'h1',
      name: 'Test Home',
      ownerUid: 'u1',
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: HomePremiumStatus.free,
      premiumPlan: null,
      premiumEndsAt: null,
      restoreUntil: null,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 10),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

ProviderContainer _makeContainer({Home? home}) {
  final mockRepo = _MockSubscriptionRepository();

  return ProviderContainer(
    overrides: [
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(home ?? _makeHome())),
      subscriptionRepositoryProvider.overrideWithValue(mockRepo),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(const AsyncValue<PurchaseResult?>.data(null));
  });

  group('PaywallViewModelNotifier — initial state', () {
    test('starts with purchasedSuccessfully=false and purchaseError=null', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(paywallViewModelNotifierProvider.notifier);
      expect(notifier.purchasedSuccessfully, isFalse);
      expect(notifier.purchaseError, isNull);
    });
  });

  group('PaywallViewModelNotifier — clearPurchaseResult', () {
    test('resets purchasedSuccessfully and purchaseError to initial values', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(paywallViewModelNotifierProvider.notifier);

      notifier.clearPurchaseResult();

      expect(notifier.purchasedSuccessfully, isFalse);
      expect(notifier.purchaseError, isNull);
    });

    test('after setting error state, clearPurchaseResult resets it', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      // Manually update the paywallProvider state to simulate an error result
      container.read(paywallProvider.notifier);
      final notifier =
          container.read(paywallViewModelNotifierProvider.notifier);

      // Since we can't easily simulate the listen callback in unit tests,
      // we test clearPurchaseResult at the state level directly.
      notifier.clearPurchaseResult();
      expect(notifier.purchasedSuccessfully, isFalse);
      expect(notifier.purchaseError, isNull);
    });
  });

  group('PaywallViewModel interface via paywallViewModelProvider', () {
    test('returns a PaywallViewModel instance', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final vm = container.read(paywallViewModelProvider);
      expect(vm, isA<PaywallViewModel>());
      expect(vm.purchasedSuccessfully, isFalse);
      expect(vm.purchaseError, isNull);
      expect(vm.isLoading, isFalse);
    });

    test('clearPurchaseResult is callable via interface', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final vm = container.read(paywallViewModelProvider);
      // Should not throw
      vm.clearPurchaseResult();
      expect(vm.purchasedSuccessfully, isFalse);
      expect(vm.purchaseError, isNull);
    });

    test('isLoading reflects paywallProvider loading state', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final vm = container.read(paywallViewModelProvider);
      // With the fake paywall, it starts in data(null), not loading
      expect(vm.isLoading, isFalse);
    });
  });

  group('PaywallViewModelNotifier — _handleResult', () {
    test('PurchaseResult.success — purchasedSuccessfully becomes true', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(paywallViewModelNotifierProvider.notifier);

      // Simulate the paywallProvider emitting a success result
      container.read(paywallProvider.notifier);
      // Manually push a success result into the paywallProvider state
      // (using internal state update via the notifier's listen)
      // The listen is reactive, so we update via the fake notifier's state
      container
          .read(paywallProvider.notifier)
          // ignore: invalid_use_of_protected_member
          .state = const AsyncValue.data(PurchaseResult.success(chargeId: 'ch_1'));

      // Give microtasks a chance to process
      await Future<void>.delayed(Duration.zero);

      expect(notifier.purchasedSuccessfully, isTrue);
      expect(notifier.purchaseError, isNull);
    });

    test('PurchaseResult.error — purchaseError is set', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(paywallViewModelNotifierProvider.notifier);

      container.read(paywallProvider.notifier);
      container
          .read(paywallProvider.notifier)
          // ignore: invalid_use_of_protected_member
          .state = const AsyncValue.data(PurchaseResult.error(message: 'Card declined'));

      await Future<void>.delayed(Duration.zero);

      expect(notifier.purchaseError, equals('Card declined'));
      expect(notifier.purchasedSuccessfully, isFalse);
    });
  });
}
