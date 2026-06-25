import '../../../l10n/app_localizations.dart';
import '../domain/tier_catalog.dart';

/// Nombre de marca del tier (localizado, aunque se mantiene "Toka X" en todos
/// los idiomas por ser nombre de producto).
String tierDisplayName(AppLocalizations l10n, HomeTier tier) {
  switch (tier) {
    case HomeTier.pareja:
      return l10n.tier_name_pareja;
    case HomeTier.familia:
      return l10n.tier_name_familia;
    case HomeTier.grupo:
      return l10n.tier_name_grupo;
  }
}

/// Precio de referencia (fallback) de un `(tier, ciclo)` desde ARB. Se usa solo
/// cuando la store no devuelve el precio localizado del SKU.
String tierFallbackPrice(
  AppLocalizations l10n,
  HomeTier tier,
  BillingCycle cycle,
) {
  switch (tier) {
    case HomeTier.pareja:
      return cycle == BillingCycle.monthly
          ? l10n.tier_price_pareja_monthly
          : l10n.tier_price_pareja_annual;
    case HomeTier.familia:
      return cycle == BillingCycle.monthly
          ? l10n.tier_price_familia_monthly
          : l10n.tier_price_familia_annual;
    case HomeTier.grupo:
      return cycle == BillingCycle.monthly
          ? l10n.tier_price_grupo_monthly
          : l10n.tier_price_grupo_annual;
  }
}
