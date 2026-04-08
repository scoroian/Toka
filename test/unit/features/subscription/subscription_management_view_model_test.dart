// test/unit/features/subscription/subscription_management_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/subscription_management_view_model.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';

// ---------------------------------------------------------------------------
// Fakes / Mocks
// ---------------------------------------------------------------------------

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

class _FakeCurrentHome extends CurrentHome {
  final Home? _home;
  _FakeCurrentHome(this._home);
  @override
  Future<Home?> build() async => _home;
}

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
      premiumStatus: HomePremiumStatus.active,
      premiumPlan: 'annual',
      premiumEndsAt: DateTime(2027, 1),
      restoreUntil: null,
      autoRenewEnabled: true,
      limits: const HomeLimits(maxMembers: 10),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

ProviderContainer _makeContainer({
  required SubscriptionState subState,
  Home? home,
}) {
  final mockRepo = _MockSubscriptionRepository();
  return ProviderContainer(
    overrides: [
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(home ?? _makeHome())),
      subscriptionRepositoryProvider.overrideWithValue(mockRepo),
      subscriptionStateProvider.overrideWith((_) => subState),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('SubscriptionManagementViewModel — subscriptionState', () {
    test('expone el estado active correcto', () {
      final state = SubscriptionState.active(
        plan: 'annual',
        endsAt: DateTime(2027),
        autoRenew: true,
      );
      final container = _makeContainer(subState: state);
      addTearDown(container.dispose);

      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.subscriptionState, equals(state));
    });

    test('expone estado free', () {
      final container = _makeContainer(subState: const SubscriptionState.free());
      addTearDown(container.dispose);

      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.subscriptionState, const SubscriptionState.free());
    });

    test('expone estado restorable', () {
      final state = SubscriptionState.restorable(
        restoreUntil: DateTime(2026, 5, 1),
      );
      final container = _makeContainer(subState: state);
      addTearDown(container.dispose);

      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.subscriptionState, equals(state));
    });
  });

  group('SubscriptionManagementViewModel — homeId', () {
    test('homeId es el id del hogar actual', () async {
      final container = _makeContainer(subState: const SubscriptionState.free());
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.homeId, 'h1');
    });

    test('homeId es vacío si no hay hogar', () async {
      final mockRepo = _MockSubscriptionRepository();
      final container = ProviderContainer(
        overrides: [
          currentHomeProvider.overrideWith(() => _FakeCurrentHome(null)),
          subscriptionRepositoryProvider.overrideWithValue(mockRepo),
          subscriptionStateProvider.overrideWith((_) => const SubscriptionState.free()),
          paywallProvider.overrideWith(() => _FakePaywall()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.homeId, '');
    });
  });

  group('SubscriptionManagementViewModel — isLoading', () {
    test('isLoading false cuando paywall está en data', () {
      final container = _makeContainer(subState: const SubscriptionState.free());
      addTearDown(container.dispose);

      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.isLoading, isFalse);
    });
  });
}
