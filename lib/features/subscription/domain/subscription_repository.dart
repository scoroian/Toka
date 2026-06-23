import 'purchase_result.dart';

abstract interface class SubscriptionRepository {
  /// Llama a la Cloud Function syncEntitlement.
  ///
  /// El `chargeId` de idempotencia lo deriva el backend server-side del recibo
  /// verificado (purchaseToken / originalTransactionId), no el cliente — por eso
  /// no se envía aquí (`purchase.purchaseID` puede ser nulo en iOS restored).
  Future<void> syncEntitlement({
    required String homeId,
    required String receiptData,
    required String platform,
  });

  /// Inicia una compra in-app.
  Future<PurchaseResult> purchase({
    required String homeId,
    required String productId,
  });

  /// Restaura compras anteriores.
  Future<PurchaseResult> restorePurchases({required String homeId});

  /// Guarda un plan manual de downgrade en homes/{homeId}/downgrade/current.
  Future<void> saveDowngradePlan({
    required String homeId,
    required List<String> selectedMemberIds,
    required List<String> selectedTaskIds,
  });

  /// Llama a la Cloud Function restorePremiumState.
  Future<void> restorePremium({required String homeId});
}
