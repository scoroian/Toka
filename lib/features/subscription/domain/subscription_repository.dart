import 'purchase_result.dart';

abstract interface class SubscriptionRepository {
  /// Llama a la Cloud Function syncEntitlement.
  Future<void> syncEntitlement({
    required String homeId,
    required String receiptData,
    required String platform,
    required String chargeId,
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
