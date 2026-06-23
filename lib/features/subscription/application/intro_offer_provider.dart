import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/intro_offer.dart';
import '../domain/subscription_products.dart';
import 'intro_offer_parser.dart';

part 'intro_offer_provider.g.dart';

/// Oferta introductoria (prueba gratuita) del plan ANUAL, leída de la store
/// (Hallazgo #14). El paywall la usa para mostrar el copy del trial solo cuando
/// la store realmente lo concede. Si la store no está disponible o no devuelve
/// el producto/oferta, resuelve a [IntroOffer.none] (sin trial), nunca lanza.
@riverpod
Future<IntroOffer> annualIntroOffer(AnnualIntroOfferRef ref) async {
  final iap = InAppPurchase.instance;
  try {
    if (!await iap.isAvailable()) return IntroOffer.none;
    final response = await iap.queryProductDetails({kAnnualProductId});
    final matches =
        response.productDetails.where((p) => p.id == kAnnualProductId).toList();
    if (matches.isEmpty) return IntroOffer.none;
    return extractIntroOffer(matches.first);
  } catch (_) {
    return IntroOffer.none;
  }
}
