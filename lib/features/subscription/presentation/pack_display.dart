import '../../../l10n/app_localizations.dart';
import '../domain/member_pack_catalog.dart';
import '../domain/tier_catalog.dart';

/// Nombre de marca del pack (localizado).
String packDisplayName(AppLocalizations l10n, MemberPack pack) {
  switch (pack) {
    case MemberPack.plus5:
      return l10n.pack_name_plus5;
    case MemberPack.plus10:
      return l10n.pack_name_plus10;
  }
}

/// Precio de referencia (fallback) de un `(pack, ciclo)` desde ARB. Se usa solo
/// cuando la store no devuelve el precio localizado del SKU.
String packFallbackPrice(
  AppLocalizations l10n,
  MemberPack pack,
  BillingCycle cycle,
) {
  switch (pack) {
    case MemberPack.plus5:
      return cycle == BillingCycle.monthly
          ? l10n.pack_price_plus5_monthly
          : l10n.pack_price_plus5_annual;
    case MemberPack.plus10:
      return cycle == BillingCycle.monthly
          ? l10n.pack_price_plus10_monthly
          : l10n.pack_price_plus10_annual;
  }
}

/// Precio a mostrar para un `(pack, ciclo)`: el localizado de la store si lo
/// resolvió ([storePrices] de `memberPacksPricingProvider`), con fallback a ARB.
String packDisplayPrice(
  AppLocalizations l10n,
  MemberPack pack,
  BillingCycle cycle,
  Map<String, String> storePrices,
) =>
    storePrices[packProductIdFor(pack, cycle)] ??
    packFallbackPrice(l10n, pack, cycle);
