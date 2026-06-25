// functions/src/entitlement/pack_catalog.ts
//
// Catálogo y lógica PURA del eje de entitlement "packs de miembros".
//
// Un pack amplía el TOPE DE MIEMBROS de un hogar **Grupo (10)** vendiéndose como
// suscripción reversible (NO permanente): mientras está pagado suma plazas; al
// cancelar/expirar, los miembros que excedan el nuevo tope se congelan (reusa la
// maquinaria de downgrade). Es ortogonal a:
//   - los slots de hogar permanentes (`lifetimeUnlockedHomeSlots`, otro eje),
//   - el estado premium / tier del hogar (lo conserva intacto),
//   - el eje individual Toka Plus (`plus_catalog.ts`).
//
// Este módulo es la fuente ÚNICA de verdad de:
//   - qué productIds son de pack y a qué incremento de plazas corresponden,
//   - el ciclo (mensual/anual) derivado del productId,
//   - qué estados cuentan como pack activo.
//
// Es PURO (sin Firestore ni red) para que el enrutado de `syncEntitlement`, la
// reconciliación con stores y el cómputo del tope efectivo compartan exactamente
// la misma decisión. La suma de plazas y el cap a 25 viven en `tier_catalog.ts`
// (`effectiveMaxMembers`), el único punto de derivación del tope.

/** Tipo de pack de plazas. `plus5` = +5 miembros, `plus10` = +10 miembros. */
export type PackKind = "plus5" | "plus10";

/** Ciclo de facturación de un pack. */
export type PackCycle = "monthly" | "annual";

/**
 * Packs de miembro activos sobre un hogar (cada uno suma plazas). Es la entrada
 * del cómputo del tope (`effectiveMaxMembers` en `tier_catalog.ts`). Vive aquí,
 * en el módulo hoja, para que `tier_catalog` lo importe sin ciclos.
 */
export interface ActivePacks {
  plus5?: boolean;
  plus10?: boolean;
}

/** Plazas que aporta cada pack (spec de producto). */
export const PACK_SEATS: Record<PackKind, number> = {
  plus5: 5,
  plus10: 10,
};

/**
 * Catálogo extensible productId → kind. Los 4 SKUs de pack
 * (+5/+10 × mensual/anual). Las claves se comparan en minúsculas
 * (ver `packFromProductId`).
 */
export const PRODUCT_PACK_CATALOG: Record<string, PackKind> = {
  toka_pack5_monthly: "plus5",
  toka_pack5_annual: "plus5",
  toka_pack10_monthly: "plus10",
  toka_pack10_annual: "plus10",
};

/** Resuelve el kind de pack de un productId. `null` si no está catalogado. */
export function packFromProductId(
  productId: string | null | undefined,
): PackKind | null {
  if (!productId) return null;
  return PRODUCT_PACK_CATALOG[productId.toLowerCase()] ?? null;
}

/**
 * ¿El productId corresponde al eje de packs? Único punto de clasificación
 * "producto de pack" vs "producto de hogar/Plus". Se basa en el catálogo, así
 * que un prefijo parecido pero no catalogado (`toka_packaging_*`) NO cuenta y
 * nunca colisiona con `toka_plus_*` / `toka_grupo_*` / `toka_premium_*`.
 */
export function isPackProductId(productId: string | null | undefined): boolean {
  return packFromProductId(productId) !== null;
}

/** Deriva el ciclo del pack del productId (anual si contiene 'annual'). */
export function packCycleFromProductId(productId: string): PackCycle {
  return productId.toLowerCase().includes("annual") ? "annual" : "monthly";
}

/**
 * Estados de pack que se consideran "con acceso vigente". Espeja el criterio de
 * Toka Plus (`active` + `cancelledPendingEnd`) PERO sin `rescue`, que es un
 * concepto exclusivo del ciclo de vida del hogar y no aplica a un pack. Acepta
 * la variante legacy snake_case durante la migración.
 */
const PACK_ACTIVE_STATUSES = new Set<string>([
  "active",
  "cancelledPendingEnd",
  "cancelled_pending_end",
]);

/** ¿El `status` persistido representa un pack con acceso vigente? */
export function isPackActive(status: string | null | undefined): boolean {
  if (!status) return false;
  return PACK_ACTIVE_STATUSES.has(status);
}

/** Vista mínima de una entrada de pack persistida en `home.memberPacks.{kind}`. */
export interface PackEntryView {
  status?: string;
  endsAt?: { toMillis(): number } | null;
}

/**
 * ¿Una entrada de pack del hogar está VIGENTE? Es la verdad de la store (NO se
 * gatea por el flag de Remote Config — eso se aplica al computar el tope), con un
 * guard de `endsAt` como defensa en profundidad ante una notificación de
 * expiración perdida (espeja `isPlusEffectivelyActive`).
 */
export function isPackEntryActive(
  entry: PackEntryView | null | undefined,
  nowMs: number,
): boolean {
  if (!entry || !isPackActive(entry.status)) return false;
  if (entry.endsAt && entry.endsAt.toMillis() <= nowMs) return false;
  return true;
}

/**
 * Deriva qué packs están vigentes a partir del doc del hogar (`memberPacks`).
 * Verdad de la store (sin gatear por flag); el gateo del flag se aplica en
 * `resolveEntitlement`/`effectiveMaxMembers`. Pura y reusable por sync,
 * reconciliación, enforcement y restore.
 */
export function activePacksFromHome(
  homeData: { memberPacks?: Record<string, PackEntryView> } | null | undefined,
  nowMs: number,
): ActivePacks {
  const m = homeData?.memberPacks ?? {};
  return {
    plus5: isPackEntryActive(m["plus5"], nowMs),
    plus10: isPackEntryActive(m["plus10"], nowMs),
  };
}
