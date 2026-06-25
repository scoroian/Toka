/// Catálogo de tiers por tamaño de hogar en el CLIENTE.
///
/// Espejo estructural de `functions/src/shared/tier_catalog.ts` (fuente de
/// verdad del backend). Aquí solo vive el mapeo `tier ↔ productId ↔ maxMembers`
/// y la selección de tier por tamaño; los TOPES efectivos de un hogar concreto
/// se leen SIEMPRE del entitlement (`dashboard.premiumFlags.maxMembers/tier`),
/// nunca se recomputan. Estas constantes describen el catálogo de venta, no el
/// estado de un hogar.
///
/// Los precios de referencia NO viven aquí: el precio mostrado es el localizado
/// de la store cuando existe, con fallback a los strings ARB (i18n).
library;

/// Tiers premium por tamaño de hogar (no incluye Free, que es un estado).
enum HomeTier { pareja, familia, grupo }

/// Ciclo de facturación de una suscripción.
enum BillingCycle { monthly, annual }

extension HomeTierX on HomeTier {
  /// Tope de miembros del tier (spec de producto). Coincide con
  /// `TIER_MAX_MEMBERS` del backend.
  int get maxMembers {
    switch (this) {
      case HomeTier.pareja:
        return 2;
      case HomeTier.familia:
        return 5;
      case HomeTier.grupo:
        return 10;
    }
  }

  /// Identificador persistido por el backend (`premiumTier` / `premiumFlags.tier`).
  String get id => name;
}

/// Mapea un string del backend (`'pareja'|'familia'|'grupo'|'free'|null`) a su
/// tier premium. `'free'`, `null` y valores desconocidos → `null` (no es un
/// tier premium).
HomeTier? homeTierFromString(String? value) {
  switch (value) {
    case 'pareja':
      return HomeTier.pareja;
    case 'familia':
      return HomeTier.familia;
    case 'grupo':
      return HomeTier.grupo;
    default:
      return null;
  }
}

/// productId del SKU IAP para un `(tier, ciclo)`. Debe coincidir EXACTAMENTE con
/// los IDs configurados en Google Play / App Store y con `PRODUCT_TIER_CATALOG`
/// del backend.
String productIdFor(HomeTier tier, BillingCycle cycle) {
  final suffix = cycle == BillingCycle.monthly ? 'monthly' : 'annual';
  return 'toka_${tier.id}_$suffix';
}

/// Conjunto de los 6 SKUs de tier (Pareja/Familia/Grupo × mensual/anual).
final Set<String> allTierProductIds = {
  for (final tier in HomeTier.values)
    for (final cycle in BillingCycle.values) productIdFor(tier, cycle),
};

/// Revierte un productId de tier a su `HomeTier`. SKU no catalogado (incl. los
/// legacy `toka_premium_*`) → `null`.
HomeTier? tierForProductId(String productId) {
  for (final tier in HomeTier.values) {
    for (final cycle in BillingCycle.values) {
      if (productIdFor(tier, cycle) == productId) return tier;
    }
  }
  return null;
}

/// Menor tier cuyo tope cabe [memberCount] miembros. Por encima del mayor tope
/// cae al tier mayor (Grupo). Se usa para preseleccionar un tier en el paywall
/// según el tamaño actual del hogar.
HomeTier smallestTierForMembers(int memberCount) {
  for (final tier in HomeTier.values) {
    if (tier.maxMembers >= memberCount) return tier;
  }
  return HomeTier.grupo;
}
