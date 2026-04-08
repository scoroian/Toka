// test/unit/features/subscription/downgrade_planner_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/downgrade_planner_view_model.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
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
  });

  group('DowngradePlannerViewModelNotifier — initial state', () {
    test('starts with empty selectedMemberIds and selectedTaskIds', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );
      expect(notifier.selectedMemberIds, isEmpty);
      expect(notifier.selectedTaskIds, isEmpty);
      expect(notifier.isLoading, isFalse);
      expect(notifier.savedSuccessfully, isFalse);
    });
  });

  group('DowngradePlannerViewModelNotifier — toggleMember', () {
    test('adds member when checked and count < _kMaxFreeMembers (3)', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );

      notifier.toggleMember('u1', true);
      notifier.toggleMember('u2', true);
      notifier.toggleMember('u3', true);

      expect(notifier.selectedMemberIds, {'u1', 'u2', 'u3'});
    });

    test('does not add member when count == _kMaxFreeMembers (3)', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );

      notifier.toggleMember('u1', true);
      notifier.toggleMember('u2', true);
      notifier.toggleMember('u3', true);
      // This 4th add should be rejected
      notifier.toggleMember('u4', true);

      expect(notifier.selectedMemberIds.length, 3);
      expect(notifier.selectedMemberIds.contains('u4'), isFalse);
    });

    test('removes member when unchecked', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );

      notifier.toggleMember('u1', true);
      notifier.toggleMember('u1', false);

      expect(notifier.selectedMemberIds, isEmpty);
    });

    test('can add more members after removing one', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );

      notifier.toggleMember('u1', true);
      notifier.toggleMember('u2', true);
      notifier.toggleMember('u3', true);
      // Remove one and add a different one
      notifier.toggleMember('u2', false);
      notifier.toggleMember('u4', true);

      expect(notifier.selectedMemberIds, {'u1', 'u3', 'u4'});
    });
  });

  group('DowngradePlannerViewModelNotifier — toggleTask', () {
    test('adds task when checked and count < _kMaxFreeTasks (4)', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );

      notifier.toggleTask('t1', true);
      notifier.toggleTask('t2', true);
      notifier.toggleTask('t3', true);
      notifier.toggleTask('t4', true);

      expect(notifier.selectedTaskIds, {'t1', 't2', 't3', 't4'});
    });

    test('does not add task when count == _kMaxFreeTasks (4)', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );

      notifier.toggleTask('t1', true);
      notifier.toggleTask('t2', true);
      notifier.toggleTask('t3', true);
      notifier.toggleTask('t4', true);
      // This 5th add should be rejected
      notifier.toggleTask('t5', true);

      expect(notifier.selectedTaskIds.length, 4);
      expect(notifier.selectedTaskIds.contains('t5'), isFalse);
    });

    test('removes task when unchecked', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );

      notifier.toggleTask('t1', true);
      notifier.toggleTask('t1', false);

      expect(notifier.selectedTaskIds, isEmpty);
    });

    test('can add more tasks after removing one', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );

      notifier.toggleTask('t1', true);
      notifier.toggleTask('t2', true);
      notifier.toggleTask('t3', true);
      notifier.toggleTask('t4', true);
      notifier.toggleTask('t2', false);
      notifier.toggleTask('t5', true);

      expect(notifier.selectedTaskIds, {'t1', 't3', 't4', 't5'});
    });
  });

  group('DowngradePlannerViewModel interface via downgradePlannerViewModelProvider', () {
    test('returns a DowngradePlannerViewModel instance', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final vm = container.read(downgradePlannerViewModelProvider);
      expect(vm, isA<DowngradePlannerViewModel>());
      expect(vm.selectedMemberIds, isEmpty);
      expect(vm.selectedTaskIds, isEmpty);
    });

    test('toggleMember and toggleTask are callable via interface', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      // Access notifier directly for mutation since provider returns interface
      final notifier = container.read(
        downgradePlannerViewModelNotifierProvider.notifier,
      );
      notifier.toggleMember('u1', true);
      notifier.toggleTask('t1', true);

      final vm = container.read(downgradePlannerViewModelProvider);
      expect(vm.selectedMemberIds, {'u1'});
      expect(vm.selectedTaskIds, {'t1'});
    });
  });
}
