import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/subscription_products.dart';
import 'intro_offer_parser.dart';
import 'tier_pricing_provider.dart';

part 'plus_pricing_provider.g.dart';

/// Precios localizados (y trial) de los 2 SKUs de Toka Plus, consultados a la
/// store. Reutiliza [inAppPurchaseProvider] y el DTO [TierProductInfo].
///
/// Devuelve `productId → TierProductInfo` SOLO con los SKUs que la store
/// resolvió. El paywall hace fallback a los precios de referencia (ARB) para
/// los ausentes. Nunca lanza: ante store no disponible o error, mapa vacío.
@riverpod
Future<Map<String, TierProductInfo>> plusPricing(PlusPricingRef ref) async {
  final iap = ref.watch(inAppPurchaseProvider);
  try {
    if (!await iap.isAvailable()) return const {};
    final response = await iap.queryProductDetails(kPlusProductIds);
    final result = <String, TierProductInfo>{};
    for (final details in response.productDetails) {
      if (!kPlusProductIds.contains(details.id)) continue;
      result[details.id] = TierProductInfo(
        productId: details.id,
        price: details.price,
        introOffer: extractIntroOffer(details),
      );
    }
    return result;
  } catch (_) {
    return const {};
  }
}
