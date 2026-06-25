import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/intro_offer.dart';
import '../domain/tier_catalog.dart';
import 'intro_offer_parser.dart';

part 'tier_pricing_provider.g.dart';

/// Precio localizado de la store + oferta de trial de un SKU de tier.
class TierProductInfo {
  const TierProductInfo({
    required this.productId,
    required this.price,
    required this.introOffer,
  });

  /// productId del SKU.
  final String productId;

  /// Precio localizado tal cual lo reporta la store (p. ej. "2,99 €").
  final String price;

  /// Oferta introductoria (trial) reportada por la store para este SKU.
  final IntroOffer introOffer;
}

/// Instancia de [InAppPurchase] inyectable (seam de DI). Por defecto el
/// singleton; override en tests con `overrideWithValue`.
@Riverpod(keepAlive: true)
InAppPurchase inAppPurchase(InAppPurchaseRef ref) => InAppPurchase.instance;

/// Precios localizados (y trials) de los 6 SKUs de tier, consultados a la store.
///
/// Devuelve un mapa `productId → [TierProductInfo]` que SOLO contiene los SKUs
/// que la store resolvió. El consumidor (paywall) hace fallback a los precios de
/// referencia (ARB) para los SKUs ausentes. Nunca lanza: ante store no
/// disponible o error, devuelve un mapa vacío (todo fallback).
@riverpod
Future<Map<String, TierProductInfo>> tierPricing(TierPricingRef ref) async {
  final iap = ref.watch(inAppPurchaseProvider);
  try {
    if (!await iap.isAvailable()) return const {};
    final response = await iap.queryProductDetails(allTierProductIds);
    final result = <String, TierProductInfo>{};
    for (final details in response.productDetails) {
      if (!allTierProductIds.contains(details.id)) continue;
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
