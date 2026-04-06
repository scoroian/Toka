// test/unit/features/subscription/subscription_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';

// ---------------------------------------------------------------------------
// Fake CurrentHome that resolves synchronously to a given Home?
// ---------------------------------------------------------------------------

class _FakeCurrentHome extends CurrentHome {
  final Home? _home;
  _FakeCurrentHome(this._home);
  @override
  Future<Home?> build() async => _home;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Home _makeHome(
  HomePremiumStatus status, {
  String? premiumPlan,
  DateTime? premiumEndsAt,
  DateTime? restoreUntil,
  bool autoRenewEnabled = false,
}) =>
    Home(
      id: 'h1',
      name: 'Test',
      ownerUid: 'u1',
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: status,
      premiumPlan: premiumPlan,
      premiumEndsAt: premiumEndsAt,
      restoreUntil: restoreUntil,
      autoRenewEnabled: autoRenewEnabled,
      limits: const HomeLimits(maxMembers: 10),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

ProviderContainer _containerWithHome(Home? home) {
  return ProviderContainer(
    overrides: [
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(home)),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('subscriptionStateProvider derivation', () {
    test('HomePremiumStatus.free → SubscriptionState.free()', () async {
      final container = _containerWithHome(_makeHome(HomePremiumStatus.free));
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final state = container.read(subscriptionStateProvider);
      expect(state, const SubscriptionState.free());
    });

    test('HomePremiumStatus.active → SubscriptionState.active()', () async {
      final endsAt = DateTime(2027, 1, 1);
      final container = _containerWithHome(_makeHome(
        HomePremiumStatus.active,
        premiumPlan: 'annual',
        premiumEndsAt: endsAt,
        autoRenewEnabled: true,
      ));
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final state = container.read(subscriptionStateProvider);
      state.maybeWhen(
        active: (plan, _, autoRenew) {
          expect(plan, 'annual');
          expect(autoRenew, true);
        },
        orElse: () => fail('Expected SubscriptionState.active'),
      );
    });

    test('HomePremiumStatus.cancelledPendingEnd → SubscriptionState.cancelledPendingEnd()', () async {
      final endsAt = DateTime(2027, 6, 1);
      final container = _containerWithHome(_makeHome(
        HomePremiumStatus.cancelledPendingEnd,
        premiumPlan: 'monthly',
        premiumEndsAt: endsAt,
      ));
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final state = container.read(subscriptionStateProvider);
      state.maybeWhen(
        cancelledPendingEnd: (plan, _) => expect(plan, 'monthly'),
        orElse: () => fail('Expected SubscriptionState.cancelledPendingEnd'),
      );
    });

    test('HomePremiumStatus.rescue → SubscriptionState.rescue() with daysLeft', () async {
      final endsAt = DateTime.now().add(const Duration(days: 2));
      final container = _containerWithHome(_makeHome(
        HomePremiumStatus.rescue,
        premiumPlan: 'monthly',
        premiumEndsAt: endsAt,
      ));
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final state = container.read(subscriptionStateProvider);
      state.maybeWhen(
        rescue: (plan, _, daysLeft) {
          expect(plan, 'monthly');
          expect(daysLeft, inInclusiveRange(1, 3));
        },
        orElse: () => fail('Expected SubscriptionState.rescue'),
      );
    });

    test('HomePremiumStatus.expiredFree → SubscriptionState.expiredFree()', () async {
      final container = _containerWithHome(_makeHome(HomePremiumStatus.expiredFree));
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final state = container.read(subscriptionStateProvider);
      expect(state, const SubscriptionState.expiredFree());
    });

    test('HomePremiumStatus.restorable → SubscriptionState.restorable()', () async {
      final restoreUntil = DateTime(2027, 1, 1);
      final container = _containerWithHome(_makeHome(
        HomePremiumStatus.restorable,
        restoreUntil: restoreUntil,
      ));
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final state = container.read(subscriptionStateProvider);
      state.maybeWhen(
        restorable: (until) => expect(until, restoreUntil),
        orElse: () => fail('Expected SubscriptionState.restorable'),
      );
    });

    test('HomePremiumStatus.purged → SubscriptionState.purged()', () async {
      final container = _containerWithHome(_makeHome(HomePremiumStatus.purged));
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final state = container.read(subscriptionStateProvider);
      expect(state, const SubscriptionState.purged());
    });

    test('null home → SubscriptionState.free()', () async {
      final container = _containerWithHome(null);
      addTearDown(container.dispose);

      await container.read(currentHomeProvider.future);
      final state = container.read(subscriptionStateProvider);
      expect(state, const SubscriptionState.free());
    });
  });
}
