import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/plus_paywall_view_model.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_products.dart';
import 'package:toka/features/subscription/domain/subscription_repository.dart';
import 'package:toka/features/subscription/domain/tier_catalog.dart';

class _MockSubRepo extends Mock implements SubscriptionRepository {}

/// Paywall falso que NO escucha la store y registra las compras solicitadas.
class _RecordingPaywall extends Paywall {
  final List<({String homeId, String productId})> calls = [];

  @override
  AsyncValue<PurchaseResult?> build() => const AsyncValue.data(null);

  @override
  Future<void> startPurchase({
    required String homeId,
    required String productId,
  }) async {
    calls.add((homeId: homeId, productId: productId));
  }
}

void main() {
  group('plusProductIdForCycle', () {
    test('annual → SKU anual', () {
      expect(plusProductIdForCycle(BillingCycle.annual), kPlusAnnualProductId);
    });
    test('monthly → SKU mensual', () {
      expect(plusProductIdForCycle(BillingCycle.monthly), kPlusMonthlyProductId);
    });
  });

  group('PlusPaywallViewModel', () {
    late _RecordingPaywall paywall;
    late _MockSubRepo repo;
    late ProviderContainer container;

    setUp(() {
      paywall = _RecordingPaywall();
      repo = _MockSubRepo();
      when(() => repo.restorePurchases(homeId: any(named: 'homeId')))
          .thenAnswer((_) async => const PurchaseResult.cancelled());
      container = ProviderContainer(overrides: [
        paywallProvider.overrideWith(() => paywall),
        subscriptionRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
    });

    PlusPaywallViewModel vm() => container.read(plusPaywallViewModelProvider);

    test('ciclo por defecto es anual', () {
      expect(vm().cycle, BillingCycle.annual);
    });

    test('selectCycle cambia el ciclo', () {
      vm().selectCycle(BillingCycle.monthly);
      expect(vm().cycle, BillingCycle.monthly);
    });

    test('startPurchase delega con homeId vacío y SKU anual por defecto',
        () async {
      await vm().startPurchase();
      expect(paywall.calls, hasLength(1));
      expect(paywall.calls.single.homeId, '');
      expect(paywall.calls.single.productId, kPlusAnnualProductId);
    });

    test('startPurchase usa el SKU mensual tras seleccionar mensual', () async {
      vm().selectCycle(BillingCycle.monthly);
      await vm().startPurchase();
      expect(paywall.calls.single.productId, kPlusMonthlyProductId);
    });

    test('refleja error de compra del paywall', () {
      container.read(plusPaywallViewModelNotifierProvider.notifier);
      paywall.state =
          const AsyncValue.data(PurchaseResult.error(message: 'boom'));
      expect(vm().purchaseError, 'boom');
    });

    test('refleja compra exitosa del paywall', () {
      container.read(plusPaywallViewModelNotifierProvider.notifier);
      paywall.state =
          const AsyncValue.data(PurchaseResult.success(chargeId: 'c1'));
      expect(vm().purchasedSuccessfully, isTrue);
    });

    test('restore delega en restorePurchases con homeId vacío', () async {
      await vm().restore();
      verify(() => repo.restorePurchases(homeId: '')).called(1);
    });
  });
}
