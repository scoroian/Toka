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

  /// Construye el payload que viaja al backend (`syncEntitlement`).
  ///
  /// El cliente NO debe enviar campos del estado Premium (`status`, `endsAt`,
  /// `plan`) calculados localmente: hacerlo permite a un atacante autenticado
  /// llamar a la callable con un payload arbitrario y obtener Premium sin
  /// pago. La fuente de verdad sobre el plan, fechas y autoRenew es el
  /// backend, que valida `purchaseToken` contra Google Play / App Store.
  ///
  /// Aquí solo enviamos lo que la store sabe firmar:
  /// - `productId`: id del producto IAP, para que el servidor derive `plan`.
  /// - `purchaseToken`: `serverVerificationData` — el token firmado que el
  ///   servidor usa para llamar a Google Play Developer API (Android) o
  ///   App Store Server API (iOS).
  /// - `transactionId`: id local de la transacción (puede ser nulo en iOS
  ///   restored), útil como pista de idempotencia.
  /// - `source`: la store que firmó el recibo.
  String _buildReceiptData(PurchaseDetails purchase) {
    final productId = purchase.productID;
    final purchaseToken = purchase.verificationData.serverVerificationData;
    final transactionId = purchase.purchaseID ?? '';
    final source = purchase.verificationData.source;
    // JSON conservador: si en el futuro añadimos campos firmados se
    // extiende sin romper el backend (Object.entries en TS los ignora si
    // no los espera).
    return '{'
        '"productId":"$productId",'
        '"purchaseToken":"$purchaseToken",'
        '"transactionId":"$transactionId",'
        '"source":"$source"'
        '}';
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
