import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/purchase_result.dart';
import 'subscription_provider.dart';

part 'paywall_provider.g.dart';

@riverpod
class Paywall extends _$Paywall {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String _pendingHomeId = '';

  @override
  AsyncValue<PurchaseResult?> build() {
    ref.onDispose(() => _purchaseSubscription?.cancel());
    _listenPurchaseUpdates();
    return const AsyncValue.data(null);
  }

  void _listenPurchaseUpdates() {
    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchases,
      onError: (_) => state = const AsyncValue.data(
        PurchaseResult.error(message: 'Purchase stream error'),
      ),
    );
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = const AsyncValue.loading();
        case PurchaseStatus.error:
          state = AsyncValue.data(
            PurchaseResult.error(message: purchase.error?.message ?? 'Unknown error'),
          );
          await InAppPurchase.instance.completePurchase(purchase);
        case PurchaseStatus.canceled:
          state = const AsyncValue.data(PurchaseResult.cancelled());
          await InAppPurchase.instance.completePurchase(purchase);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _syncAndComplete(purchase);
      }
    }
  }

  Future<void> _syncAndComplete(PurchaseDetails purchase) async {
    state = const AsyncValue.loading();
    try {
      final receiptData = _buildReceiptData(purchase);
      // homeId se pasa como applicationUserName en el purchaseParam (ver PaywallScreen)
      final homeId = _pendingHomeId;

      await ref.read(subscriptionRepositoryProvider).syncEntitlement(
        homeId: homeId,
        receiptData: receiptData,
        platform: purchase.verificationData.source == 'app_store' ? 'ios' : 'android',
        chargeId: purchase.purchaseID ?? purchase.verificationData.localVerificationData,
      );

      await InAppPurchase.instance.completePurchase(purchase);
      state = AsyncValue.data(PurchaseResult.success(chargeId: purchase.purchaseID ?? ''));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  String _buildReceiptData(PurchaseDetails purchase) {
    final endsAt = DateTime.now().add(
      purchase.productID.contains('annual')
          ? const Duration(days: 365)
          : const Duration(days: 31),
    );
    final plan = purchase.productID.contains('annual') ? 'annual' : 'monthly';
    return '{"status":"active","plan":"$plan","endsAt":"${endsAt.toIso8601String()}","autoRenewEnabled":true}';
  }

  Future<void> startPurchase({
    required String homeId,
    required String productId,
  }) async {
    _pendingHomeId = homeId;
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      await repo.purchase(homeId: homeId, productId: productId);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> saveDowngradePlan({
    required String homeId,
    required List<String> memberIds,
    required List<String> taskIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(subscriptionRepositoryProvider).saveDowngradePlan(
        homeId: homeId,
        selectedMemberIds: memberIds,
        selectedTaskIds: taskIds,
      );
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> restorePremium({required String homeId}) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(subscriptionRepositoryProvider).restorePremium(homeId: homeId);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
