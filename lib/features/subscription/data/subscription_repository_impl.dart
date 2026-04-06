import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/purchase_result.dart';
import '../domain/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required InAppPurchase inAppPurchase,
  })  : _firestore = firestore,
        _functions = functions,
        _iap = inAppPurchase;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final InAppPurchase _iap;

  @override
  Future<void> syncEntitlement({
    required String homeId,
    required String receiptData,
    required String platform,
    required String chargeId,
  }) async {
    final callable = _functions.httpsCallable('syncEntitlement');
    await callable.call<Map<String, dynamic>>({
      'homeId': homeId,
      'receiptData': receiptData,
      'platform': platform,
      'chargeId': chargeId,
    });
  }

  @override
  Future<PurchaseResult> purchase({
    required String homeId,
    required String productId,
  }) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      return const PurchaseResult.error(message: 'Product not found');
    }
    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: homeId,
    );
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      return const PurchaseResult.cancelled();
    }
    // El resultado llega en el stream purchaseUpdates manejado en PaywallProvider
    return const PurchaseResult.cancelled();
  }

  @override
  Future<PurchaseResult> restorePurchases({required String homeId}) async {
    await _iap.restorePurchases();
    // El resultado llega via purchaseUpdates stream en PaywallProvider
    return const PurchaseResult.cancelled();
  }

  @override
  Future<void> saveDowngradePlan({
    required String homeId,
    required List<String> selectedMemberIds,
    required List<String> selectedTaskIds,
  }) async {
    await _firestore
        .collection('homes')
        .doc(homeId)
        .collection('downgrade')
        .doc('current')
        .set({
      'selectedMemberIds': selectedMemberIds,
      'selectedTaskIds': selectedTaskIds,
      'selectionMode': 'manual',
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> restorePremium({required String homeId}) async {
    final callable = _functions.httpsCallable('restorePremiumState');
    await callable.call<void>({'homeId': homeId});
  }
}
