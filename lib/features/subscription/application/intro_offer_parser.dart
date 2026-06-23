// Extrae la oferta introductoria (prueba gratuita) de un `ProductDetails` de
// in_app_purchase, cubriendo Google Play y App Store. La detección es
// DEFENSIVA: ante cualquier diferencia de versión del paquete o dato ausente,
// devuelve `IntroOffer.none` en lugar de fallar (así el paywall nunca promete
// un trial que la store no concedería). Hallazgo #14.

// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/intro_offer.dart';

/// Convierte un periodo ISO-8601 de Google Play (`P14D`, `P2W`, `P1M`, `P1Y`)
/// a días aproximados. Devuelve 0 si no se reconoce.
int iso8601PeriodToDays(String period) {
  final match = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$')
      .firstMatch(period.trim());
  if (match == null) return 0;
  final years = int.tryParse(match.group(1) ?? '0') ?? 0;
  final months = int.tryParse(match.group(2) ?? '0') ?? 0;
  final weeks = int.tryParse(match.group(3) ?? '0') ?? 0;
  final days = int.tryParse(match.group(4) ?? '0') ?? 0;
  return years * 365 + months * 30 + weeks * 7 + days;
}

/// Días de una unidad de periodo de StoreKit.
int _skUnitToDays(SKSubscriptionPeriodUnit unit) {
  switch (unit) {
    case SKSubscriptionPeriodUnit.day:
      return 1;
    case SKSubscriptionPeriodUnit.week:
      return 7;
    case SKSubscriptionPeriodUnit.month:
      return 30;
    case SKSubscriptionPeriodUnit.year:
      return 365;
  }
}

/// Lee la oferta introductoria reportada por la store para [details].
IntroOffer extractIntroOffer(ProductDetails details) {
  try {
    if (details is GooglePlayProductDetails) {
      return _fromGooglePlay(details);
    }
    if (details is AppStoreProductDetails) {
      return _fromAppStore(details);
    }
  } catch (_) {
    // Tolerancia a cambios de API / datos malformados: sin trial.
    return IntroOffer.none;
  }
  return IntroOffer.none;
}

IntroOffer _fromGooglePlay(GooglePlayProductDetails details) {
  final offers = details.productDetails.subscriptionOfferDetails;
  if (offers == null || offers.isEmpty) return IntroOffer.none;

  var maxTrialDays = 0;
  for (final offer in offers) {
    var trialDays = 0;
    for (final phase in offer.pricingPhases) {
      // Una fase de precio 0 es un tramo de prueba gratuita.
      if (phase.priceAmountMicros == 0) {
        trialDays += iso8601PeriodToDays(phase.billingPeriod);
      }
    }
    if (trialDays > maxTrialDays) maxTrialDays = trialDays;
  }
  return IntroOffer(freeTrialDays: maxTrialDays);
}

IntroOffer _fromAppStore(AppStoreProductDetails details) {
  final discount = details.skProduct.introductoryPrice;
  if (discount == null) return IntroOffer.none;
  // NOTA: el enum del paquete in_app_purchase_storekit tiene un typo histórico
  // en el identificador ("freeTrail" en vez de "freeTrial"). Es el valor que
  // representa la prueba gratuita.
  if (discount.paymentMode != SKProductDiscountPaymentMode.freeTrail) {
    return IntroOffer.none;
  }
  final period = discount.subscriptionPeriod;
  final days = _skUnitToDays(period.unit) *
      period.numberOfUnits *
      // numberOfPeriods: cuántas veces se repite el periodo del trial.
      (discount.numberOfPeriods > 0 ? discount.numberOfPeriods : 1);
  return IntroOffer(freeTrialDays: days);
}
