// test/unit/features/subscription/rescue_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/rescue_view_model.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';

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

Home _makeHome(HomePremiumStatus status) => Home(
      id: 'h1',
      name: 'Test',
      ownerUid: 'u1',
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: status,
      premiumPlan: 'monthly',
      premiumEndsAt: DateTime(2026, 5),
      restoreUntil: null,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 10),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

ProviderContainer _makeContainer({
  required SubscriptionState subState,
  Home? home,
}) {
  final mockRepo = _MockSubscriptionRepository();
  return ProviderContainer(overrides: [
    currentHomeProvider
        .overrideWith(() => _FakeCurrentHome(home ?? _makeHome(HomePremiumStatus.rescue))),
    subscriptionRepositoryProvider.overrideWithValue(mockRepo),
    subscriptionStateProvider.overrideWith((_) => subState),
    paywallProvider.overrideWith(() => _FakePaywall()),
  ]);
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('RescueViewModel — daysLeft', () {
    test('extrae daysLeft del estado rescue', () {
      final container = _makeContainer(
        subState: const SubscriptionState.rescue(
          plan: 'monthly',
          endsAt: null,
          daysLeft: 3,
        ),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.daysLeft, 3);
    });

    test('daysLeft es 0 para otros estados', () {
      final container = _makeContainer(
        subState: const SubscriptionState.free(),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.daysLeft, 0);
    });

    test('daysLeft es 0 para estado active', () {
      final container = _makeContainer(
        subState: SubscriptionState.active(
          plan: 'monthly',
          endsAt: DateTime(2027),
          autoRenew: true,
        ),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.daysLeft, 0);
    });
  });

  group('RescueViewModel — homeId', () {
    test('homeId es el id del hogar actual', () async {
      final container = _makeContainer(
        subState: const SubscriptionState.rescue(
          plan: 'monthly',
          endsAt: null,
          daysLeft: 2,
        ),
      );
      addTearDown(container.dispose);
      // Await the async notifier so valueOrNull is populated before reading VM.
      await container.read(currentHomeProvider.future);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.homeId, 'h1');
    });

    test('homeId es vacío si no hay hogar', () async {
      final mockRepo = _MockSubscriptionRepository();
      final container = ProviderContainer(overrides: [
        currentHomeProvider.overrideWith(() => _FakeCurrentHome(null)),
        subscriptionRepositoryProvider.overrideWithValue(mockRepo),
        subscriptionStateProvider.overrideWith((_) => const SubscriptionState.free()),
        paywallProvider.overrideWith(() => _FakePaywall()),
      ]);
      addTearDown(container.dispose);
      // Await so the async notifier resolves to null before reading VM.
      await container.read(currentHomeProvider.future);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.homeId, '');
    });
  });

  group('RescueViewModel — isLoading', () {
    test('isLoading es false con paywall en estado data', () {
      final container = _makeContainer(
        subState: const SubscriptionState.rescue(
          plan: 'monthly',
          endsAt: null,
          daysLeft: 1,
        ),
      );
      addTearDown(container.dispose);
      final vm = container.read(rescueViewModelProvider);
      expect(vm.isLoading, isFalse);
    });
  });
}
