// functions/src/entitlement/plus_catalog.ts
//
// Catálogo y lógica PURA del eje de entitlement individual "Toka Plus".
//
// Toka Plus es un producto POR USUARIO (ortogonal al hogar): habilita —solo para
// ese usuario— quitar el banner de anuncios, cosméticos/skins y métricas
// personales. A diferencia del entitlement de hogar (que vive en el dashboard
// COMPARTIDO y no puede expresar estado per-usuario), Plus se persiste en
// `users/{uid}/entitlements/plus` (ver `plus_entitlement.ts`).
//
// Este módulo es la fuente ÚNICA de verdad de:
//   - qué productIds son de Plus (mapa productId → efecto "eje usuario"),
//   - el ciclo (mensual/anual) derivado del productId,
//   - qué estados cuentan como Plus activo,
//   - y la activación EFECTIVA al consumir (gateada por el flag de Remote Config
//     `toka_plus_enabled`): con el flag OFF, ningún usuario tiene Plus activo
//     aunque exista el doc.
//
// Es PURO (sin Firestore ni red) para que el enrutado de `syncEntitlement`, la
// reconciliación y los consumidores de Fases 4/5 compartan exactamente la misma
// decisión.

/** Ciclo de facturación de Toka Plus. */
export type PlusCycle = "monthly" | "annual";

/**
 * Prefijo de los productIds de Toka Plus. Un único SKU individual con dos
 * opciones de ciclo: `toka_plus_monthly` (1,99 €) y `toka_plus_annual`
 * (14,99 €). Se acepta también un `toka_plus` pelado por robustez ante la forma
 * concreta del productId que devuelva cada store.
 */
export const PLUS_PRODUCT_PREFIX = "toka_plus";

/**
 * ¿El productId corresponde al eje de Toka Plus? Único punto de clasificación
 * "producto de usuario" vs "producto de hogar" (tiers/legacy premium). Compara
 * en minúsculas. Los productos de hogar (`toka_premium_*`, `toka_pareja_*`,
 * `toka_familia_*`, `toka_grupo_*`) NO empiezan por `toka_plus`, así que nunca
 * colisionan.
 */
export function isPlusProductId(productId: string | null | undefined): boolean {
  if (!productId) return false;
  return productId.toLowerCase().startsWith(PLUS_PRODUCT_PREFIX);
}

/** Deriva el ciclo de Plus del productId (anual si contiene 'annual'). */
export function plusCycleFromProductId(productId: string): PlusCycle {
  return productId.toLowerCase().includes("annual") ? "annual" : "monthly";
}

/**
 * Estados de Plus que se consideran "con acceso vigente". Espeja el criterio del
 * entitlement de hogar (`active` + `cancelledPendingEnd`) PERO sin `rescue`, que
 * es un concepto exclusivo del ciclo de vida del hogar y no aplica a Plus.
 * Acepta la variante legacy snake_case durante la migración.
 */
const PLUS_ACTIVE_STATUSES = new Set<string>([
  "active",
  "cancelledPendingEnd",
  "cancelled_pending_end",
]);

/** ¿El `status` persistido representa Plus con acceso vigente? */
export function isPlusActive(status: string | null | undefined): boolean {
  if (!status) return false;
  return PLUS_ACTIVE_STATUSES.has(status);
}

/** Vista mínima del doc de Plus que necesita la decisión de activación efectiva. */
export interface PlusEntitlementView {
  active?: boolean;
  endsAt?: { toMillis(): number } | null;
}

/**
 * Activación EFECTIVA de Plus al consumir (Fases 4/5). El doc guarda la verdad
 * de la store (`active` = `isPlusActive(status)`, sin gatear por flag); el flag
 * `toka_plus_enabled` se aplica AQUÍ, al consumir:
 *
 *   efectivo = doc.active && flagEnabled && (endsAt == null || endsAt > now)
 *
 * Así, con el flag OFF, ningún usuario tiene Plus activo aunque el doc exista, y
 * los cambios del flag (ON/OFF) surten efecto al instante sin recomputar nada.
 * El guard de `endsAt` es defensa en profundidad ante una notificación de
 * expiración perdida.
 */
export function isPlusEffectivelyActive(
  doc: PlusEntitlementView | null | undefined,
  flagEnabled: boolean,
  nowMs: number = Date.now(),
): boolean {
  if (!doc || !flagEnabled || doc.active !== true) return false;
  if (doc.endsAt && doc.endsAt.toMillis() <= nowMs) return false;
  return true;
}
