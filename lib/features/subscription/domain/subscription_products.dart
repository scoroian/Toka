/// Identificadores de los productos IAP de Toka Premium.
///
/// Deben coincidir EXACTAMENTE con los IDs configurados en Google Play Console
/// y App Store Connect. El plan anual lleva además una oferta introductoria de
/// prueba gratuita (14 días) configurada en la store sobre su base plan
/// (Hallazgo #14); el mensual no tiene trial.
const String kMonthlyProductId = 'toka_premium_monthly';
const String kAnnualProductId = 'toka_premium_annual';

/// Identificadores IAP de **Toka Plus** (producto INDIVIDUAL por usuario, no de
/// hogar). Mensual 1,99 € / anual 14,99 €. Deben coincidir EXACTAMENTE con los
/// IDs de las stores y con el prefijo `toka_plus` que el backend usa para
/// enrutar el SKU al eje de entitlement individual (`isPlusProductId`).
const String kPlusMonthlyProductId = 'toka_plus_monthly';
const String kPlusAnnualProductId = 'toka_plus_annual';
const Set<String> kPlusProductIds = {kPlusMonthlyProductId, kPlusAnnualProductId};
