/// Catálogo de **packs de miembro** en el CLIENTE (eje aditivo sobre el tier
/// Grupo).
///
/// Espejo estructural de `functions/src/entitlement/pack_catalog.ts` y
/// `functions/src/shared/tier_catalog.ts` (fuente de verdad del backend). Aquí
/// solo vive el mapeo `pack ↔ productId ↔ plazas` y la previsualización del tope
/// resultante; el tope efectivo de un hogar concreto se LEE siempre del
/// entitlement (`dashboard.premiumFlags.maxMembers/memberPacks`), nunca se
/// recomputa. Los precios de referencia NO viven aquí (ver `pack_display.dart`).
library;

import '../../../core/constants/free_limits.dart';
import 'tier_catalog.dart';

// El tope absoluto (25) vive en `core/constants/free_limits.dart` como fuente
// única (lo comparten members y subscription); se re-exporta aquí porque es,
// semánticamente, el tope del eje de packs.
export '../../../core/constants/free_limits.dart' show kAbsoluteMaxMembers;

/// Packs de miembro disponibles. El `id` coincide con el `PackKind` del backend
/// (`plus5` | `plus10`) y con las claves de `premiumFlags.memberPacks`.
enum MemberPack { plus5, plus10 }

extension MemberPackX on MemberPack {
  /// Plazas que añade el pack (spec de producto). Coincide con `PACK_SEATS` del
  /// backend.
  int get seats {
    switch (this) {
      case MemberPack.plus5:
        return 5;
      case MemberPack.plus10:
        return 10;
    }
  }

  /// Identificador persistido por el backend (`PackKind` / clave en
  /// `premiumFlags.memberPacks`).
  String get id => name;
}

/// productId del SKU IAP para un `(pack, ciclo)`. Debe coincidir EXACTAMENTE con
/// los IDs configurados en Google Play / App Store y con `PRODUCT_PACK_CATALOG`
/// del backend (`toka_pack5_*` / `toka_pack10_*`).
String packProductIdFor(MemberPack pack, BillingCycle cycle) {
  final suffix = cycle == BillingCycle.monthly ? 'monthly' : 'annual';
  return 'toka_pack${pack.seats}_$suffix';
}

/// Conjunto de los 4 SKUs de pack (+5/+10 × mensual/anual).
final Set<String> allMemberPackProductIds = {
  for (final pack in MemberPack.values)
    for (final cycle in BillingCycle.values) packProductIdFor(pack, cycle),
};

/// Revierte un productId de pack a su [MemberPack]. SKU no catalogado (incl. los
/// SKUs de tier) → `null`.
MemberPack? memberPackForProductId(String productId) {
  for (final pack in MemberPack.values) {
    for (final cycle in BillingCycle.values) {
      if (packProductIdFor(pack, cycle) == productId) return pack;
    }
  }
  return null;
}

/// Tope resultante de comprar [pack] partiendo de un tope efectivo actual
/// [currentMax] (que ya incluye los packs activos). Capado al tope absoluto.
/// Es solo previsualización para el paywall; el tope real lo escribe el backend.
int resultingCap({required int currentMax, required MemberPack pack}) {
  final total = currentMax + pack.seats;
  return total > kAbsoluteMaxMembers ? kAbsoluteMaxMembers : total;
}
