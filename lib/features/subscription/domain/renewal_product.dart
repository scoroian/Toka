/// Resolución del SKU de **renovación** del Premium del hogar (pantalla de
/// rescate).
///
/// Con el modelo de tiers activo (`home_tiers_enabled`), renovar debe re-comprar
/// el **tier actual** del hogar (`toka_{pareja|familia|grupo}_*`), no el SKU
/// legacy `toka_premium_*`: el backend mapea el legacy a Grupo, de modo que un
/// hogar Pareja/Familia que renovara por la vía legacy sufriría un **upgrade de
/// tier no deseado** y un precio equivocado. Con el flag OFF (modo binario) o si
/// el tier actual no se conoce (dashboards antiguos sin `tier` denormalizado), se
/// conserva el SKU legacy.
library;

import 'subscription_products.dart';
import 'tier_catalog.dart';

/// productId a comprar para renovar el Premium vigente.
///
/// - `tiersEnabled` ON **y** [tier] conocido → SKU del tier (`productIdFor`).
/// - en cualquier otro caso → SKU legacy `toka_premium_{annual|monthly}`.
String renewalProductId({
  required bool tiersEnabled,
  required HomeTier? tier,
  required BillingCycle cycle,
}) {
  if (tiersEnabled && tier != null) {
    return productIdFor(tier, cycle);
  }
  return cycle == BillingCycle.annual ? kAnnualProductId : kMonthlyProductId;
}
