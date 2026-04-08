// lib/features/subscription/application/paywall_view_model.dart
// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../domain/purchase_result.dart';
import 'paywall_provider.dart';

part 'paywall_view_model.freezed.dart';
part 'paywall_view_model.g.dart';

abstract class PaywallViewModel {
  bool get isLoading;
  bool get purchasedSuccessfully;
  String? get purchaseError;
  Future<void> startPurchase(String productId);
  Future<void> restorePremium();
  void clearPurchaseResult();
}

@freezed
class _PaywallVMState with _$PaywallVMState {
  const factory _PaywallVMState({
    @Default(false) bool purchasedSuccessfully,
    String? purchaseError,
  }) = __PaywallVMState;
}

@riverpod
class PaywallViewModelNotifier extends _$PaywallViewModelNotifier
    implements PaywallViewModel {
  @override
  _PaywallVMState build() {
    ref.listen<AsyncValue<PurchaseResult?>>(paywallProvider, (_, next) {
      next.whenOrNull(data: (result) {
        if (result == null) return;
        _handleResult(result);
      });
    });
    return const _PaywallVMState();
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

  String get _homeId =>
      ref.read(currentHomeProvider).valueOrNull?.id ?? '';

  @override
  bool get isLoading => ref.read(paywallProvider).isLoading;

  @override
  bool get purchasedSuccessfully => state.purchasedSuccessfully;

  @override
  String? get purchaseError => state.purchaseError;

  @override
  Future<void> startPurchase(String productId) =>
      ref.read(paywallProvider.notifier).startPurchase(
            homeId: _homeId,
            productId: productId,
          );

  @override
  Future<void> restorePremium() =>
      ref.read(paywallProvider.notifier).restorePremium(homeId: _homeId);

  @override
  void clearPurchaseResult() =>
      state = state.copyWith(purchasedSuccessfully: false, purchaseError: null);
}

@riverpod
PaywallViewModel paywallViewModel(PaywallViewModelRef ref) {
  ref.watch(paywallViewModelNotifierProvider);
  ref.watch(paywallProvider);
  return ref.read(paywallViewModelNotifierProvider.notifier);
}
