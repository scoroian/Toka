import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/member_pack_catalog.dart';
import 'tier_pricing_provider.dart';

part 'member_packs_pricing_provider.g.dart';

/// Precios localizados de los 4 SKUs de pack de miembro, consultados a la store.
/// Reutiliza [inAppPurchaseProvider]. Los packs no tienen oferta introductoria
/// (trial), así que basta el precio (`productId → precio localizado`).
///
/// Devuelve SOLO los SKUs que la store resolvió; el paywall hace fallback a los
/// precios de referencia (ARB) para los ausentes. Nunca lanza: ante store no
/// disponible o error, mapa vacío (todo fallback).
@riverpod
Future<Map<String, String>> memberPacksPricing(MemberPacksPricingRef ref) async {
  final iap = ref.watch(inAppPurchaseProvider);
  try {
    if (!await iap.isAvailable()) return const {};
    final response = await iap.queryProductDetails(allMemberPackProductIds);
    final result = <String, String>{};
    for (final details in response.productDetails) {
      if (!allMemberPackProductIds.contains(details.id)) continue;
      result[details.id] = details.price;
    }
    return result;
  } catch (_) {
    return const {};
  }
}
