// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/purchase_result.dart';
import '../domain/subscription_products.dart';
import '../domain/tier_catalog.dart';
import 'paywall_provider.dart';
import 'subscription_provider.dart';

part 'plus_paywall_view_model.freezed.dart';
part 'plus_paywall_view_model.g.dart';

/// SKU de Toka Plus correspondiente al ciclo de facturación.
String plusProductIdForCycle(BillingCycle cycle) =>
    cycle == BillingCycle.annual ? kPlusAnnualProductId : kPlusMonthlyProductId;

abstract class PlusPaywallViewModel {
  BillingCycle get cycle;
  bool get isLoading;
  bool get purchasedSuccessfully;
  String? get purchaseError;
  void selectCycle(BillingCycle cycle);
  Future<void> startPurchase();
  Future<void> restore();
  void clearPurchaseResult();
}

@freezed
class _PlusPaywallState with _$PlusPaywallState {
  const factory _PlusPaywallState({
    @Default(BillingCycle.annual) BillingCycle cycle,
    @Default(false) bool purchasedSuccessfully,
    String? purchaseError,
  }) = __PlusPaywallState;
}

@riverpod
class PlusPaywallViewModelNotifier extends _$PlusPaywallViewModelNotifier
    implements PlusPaywallViewModel {
  @override
  _PlusPaywallState build() {
    ref.listen<AsyncValue<PurchaseResult?>>(paywallProvider, (_, next) {
      next.whenOrNull(data: (result) {
        if (result == null) return;
        _handleResult(result);
      });
    });
    return const _PlusPaywallState();
  }

  void _handleResult(PurchaseResult result) {
    result.when(
      success: (_) =>
          state = state.copyWith(purchasedSuccessfully: true, purchaseError: null),
      alreadyOwned: () =>
          state = state.copyWith(purchasedSuccessfully: true, purchaseError: null),
      cancelled: () => state = state.copyWith(purchaseError: null),
      error: (message) =>
          state = state.copyWith(purchaseError: message, purchasedSuccessfully: false),
    );
  }

  @override
  BillingCycle get cycle => state.cycle;

  @override
  bool get isLoading => ref.read(paywallProvider).isLoading;

  @override
  bool get purchasedSuccessfully => state.purchasedSuccessfully;

  @override
  String? get purchaseError => state.purchaseError;

  @override
  void selectCycle(BillingCycle cycle) => state = state.copyWith(cycle: cycle);

  @override
  Future<void> startPurchase() =>
      ref.read(paywallProvider.notifier).startPurchase(
            // Plus es per-usuario: el backend enruta por SKU e ignora homeId,
            // usando el uid de auth. Pasamos homeId vacío a propósito.
            homeId: '',
            productId: plusProductIdForCycle(state.cycle),
          );

  @override
  Future<void> restore() =>
      // homeId vacío: restorePurchases() solo re-emite los recibos por el
      // purchaseStream; el SKU de Plus se enruta server-side por el uid.
      ref.read(subscriptionRepositoryProvider).restorePurchases(homeId: '');

  @override
  void clearPurchaseResult() =>
      state = state.copyWith(purchasedSuccessfully: false, purchaseError: null);
}

@riverpod
PlusPaywallViewModel plusPaywallViewModel(PlusPaywallViewModelRef ref) {
  ref.watch(plusPaywallViewModelNotifierProvider);
  ref.watch(paywallProvider);
  return ref.read(plusPaywallViewModelNotifierProvider.notifier);
}
