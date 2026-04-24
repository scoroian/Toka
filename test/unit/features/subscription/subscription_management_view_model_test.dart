// test/unit/features/subscription/subscription_management_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/subscription_dashboard_provider.dart';
import 'package:toka/features/subscription/application/subscription_management_view_model.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_dashboard.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

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

SubscriptionDashboard _makeDashboard({
  String homeId = 'h1',
  HomePremiumStatus status = HomePremiumStatus.active,
  String? plan = 'annual',
  DateTime? endsAt,
}) =>
    SubscriptionDashboard(
      homeId: homeId,
      status: status,
      plan: plan,
      endsAt: endsAt ?? DateTime(2027),
      restoreUntil: null,
      autoRenew: true,
      currentPayerUid: 'u1',
      planCounters: PlanCounters.empty(),
    );

ProviderContainer _makeContainer({
  required Stream<SubscriptionDashboard> dashboardStream,
}) {
  return ProviderContainer(
    overrides: [
      subscriptionDashboardProvider().overrideWith((_) => dashboardStream),
      paywallProvider.overrideWith(() => _FakePaywall()),
    ],
  );
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('SubscriptionManagementViewModel — dashboard', () {
    test('expone el dashboard activo correctamente', () async {
      final dashboard = _makeDashboard();
      final container = _makeContainer(
        dashboardStream: Stream.value(dashboard),
      );
      addTearDown(container.dispose);

      await container.read(subscriptionDashboardProvider().future);
      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.dashboard.valueOrNull?.status, HomePremiumStatus.active);
      expect(vm.dashboard.valueOrNull?.plan, 'annual');
      expect(vm.homeId, 'h1');
    });

    test('expone estado free', () async {
      final dashboard = _makeDashboard(
        status: HomePremiumStatus.free,
        plan: null,
      );
      final container = _makeContainer(
        dashboardStream: Stream.value(dashboard),
      );
      addTearDown(container.dispose);

      await container.read(subscriptionDashboardProvider().future);
      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.dashboard.valueOrNull?.status, HomePremiumStatus.free);
    });

    test('expone estado restorable', () async {
      final dashboard = _makeDashboard(
        status: HomePremiumStatus.restorable,
        plan: null,
      );
      final container = _makeContainer(
        dashboardStream: Stream.value(dashboard),
      );
      addTearDown(container.dispose);

      await container.read(subscriptionDashboardProvider().future);
      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.dashboard.valueOrNull?.status, HomePremiumStatus.restorable);
    });
  });

  group('SubscriptionManagementViewModel — homeId', () {
    test('homeId es el id del dashboard cargado', () async {
      final dashboard = _makeDashboard(homeId: 'custom-home');
      final container = _makeContainer(
        dashboardStream: Stream.value(dashboard),
      );
      addTearDown(container.dispose);

      await container.read(subscriptionDashboardProvider().future);
      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.homeId, 'custom-home');
    });

    test('homeId es vacío mientras el stream no ha emitido', () {
      final container = _makeContainer(
        dashboardStream: const Stream.empty(),
      );
      addTearDown(container.dispose);

      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.homeId, '');
      expect(vm.dashboard.valueOrNull, isNull);
    });
  });

  group('SubscriptionManagementViewModel — isLoading', () {
    test('isLoading false cuando paywall está en data', () async {
      final dashboard = _makeDashboard();
      final container = _makeContainer(
        dashboardStream: Stream.value(dashboard),
      );
      addTearDown(container.dispose);

      await container.read(subscriptionDashboardProvider().future);
      final vm = container.read(subscriptionManagementViewModelProvider);

      expect(vm.isLoading, isFalse);
    });
  });
}
