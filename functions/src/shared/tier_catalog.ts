// functions/src/shared/tier_catalog.ts
//
// Fuente ÚNICA de verdad del modelo de tiers por tamaño de hogar.
//
// El tope de miembros de un hogar deja de ser binario (Free 3 / Premium 10) y
// pasa a depender del TIER premium contratado, cuyo precio escala con el tope:
//
//   - Toka Pareja  → 2 miembros
//   - Toka Familia → 5 miembros
//   - Toka Grupo   → 10 miembros
//   - Free         → 3 miembros (sin cambios)
//
// Todo el catálogo productId→tier vive aquí y es EXTENSIBLE: añadir un SKU nuevo
// (o un futuro modelo de packs / Toka Plus) es una entrada más en el mapa, sin
// reescribir `sync_entitlement` ni la reconciliación.
//
// La derivación efectiva del tope (`resolveEntitlement`) es PURA y es el único
// punto donde se decide `maxMembers`: la usan el enforcement, el alta/sync, la
// reconciliación con stores, el downgrade y el restore. Está gateada por el
// flag de Remote Config `home_tiers_enabled` (ver `feature_flags.ts`): con el
// flag OFF reproduce el comportamiento binario actual.

import { isPremium } from "./free_limits";
import { PACK_SEATS, type ActivePacks } from "../entitlement/pack_catalog";

export type { ActivePacks };

/** Tiers premium por tamaño de hogar. */
export type HomeTier = "pareja" | "familia" | "grupo";

/** Tier efectivo de cara al cliente: incluye Free además de los premium. */
export type EffectiveTier = HomeTier | "free";

/** Tope de miembros del plan Free (sin cambios respecto al modelo binario). */
export const FREE_MAX_MEMBERS = 3;

/**
 * Tope de miembros del Premium binario (modelo legacy, usado cuando el flag de
 * tiers está OFF). Coincide con el tope del tier Grupo.
 */
export const BINARY_PREMIUM_MAX_MEMBERS = 10;

/** Tope de miembros por tier premium (spec de producto). */
export const TIER_MAX_MEMBERS: Record<HomeTier, number> = {
  pareja: 2,
  familia: 5,
  grupo: 10,
};

/**
 * Tope ABSOLUTO de miembros de un hogar: Grupo (10) + Pack +5 + Pack +10 = 25.
 * Por encima de 25 NO se permite (sería Toka Business, otro producto fuera de
 * alcance). `effectiveMaxMembers` capa cualquier combinación a este valor.
 */
export const ABSOLUTE_MAX_MEMBERS = 25;

/**
 * Tope efectivo de miembros = tope del tier + Σ plazas de los packs activos,
 * capado a `ABSOLUTE_MAX_MEMBERS` (25). Los packs son ADITIVOS y **requieren
 * Grupo**: si el tier efectivo no es `grupo`, o el flag de packs está OFF, las
 * plazas de los packs no cuentan y el tope es el del tier (`baseMaxMembers`).
 *
 * Pura: la suma/cap viven aquí, único punto de derivación junto con
 * `resolveEntitlement`.
 */
export function effectiveMaxMembers(
  tier: EffectiveTier | null,
  baseMaxMembers: number,
  activePacks: ActivePacks,
  packsEnabled: boolean,
): number {
  if (tier !== "grupo" || !packsEnabled) return baseMaxMembers;
  const extra =
    (activePacks.plus5 ? PACK_SEATS.plus5 : 0) +
    (activePacks.plus10 ? PACK_SEATS.plus10 : 0);
  return Math.min(baseMaxMembers + extra, ABSOLUTE_MAX_MEMBERS);
}

/**
 * Catálogo extensible productId → tier. Incluye los 6 SKUs de tier
 * (Pareja/Familia/Grupo × mensual/anual) y los SKUs legacy `toka_premium_*`,
 * que se mapean a Grupo para preservar el "Premium = 10" histórico.
 *
 * Las claves se comparan en minúsculas (ver `tierFromProductId`).
 */
export const PRODUCT_TIER_CATALOG: Record<string, HomeTier> = {
  toka_pareja_monthly: "pareja",
  toka_pareja_annual: "pareja",
  toka_familia_monthly: "familia",
  toka_familia_annual: "familia",
  toka_grupo_monthly: "grupo",
  toka_grupo_annual: "grupo",
  // Legacy binario → Grupo (10).
  toka_premium_monthly: "grupo",
  toka_premium_annual: "grupo",
};

/** Resuelve el tier de un productId. `null` si no está catalogado. */
export function tierFromProductId(
  productId: string | null | undefined,
): HomeTier | null {
  if (!productId) return null;
  return PRODUCT_TIER_CATALOG[productId.toLowerCase()] ?? null;
}

/** Tope de miembros de un tier premium. */
export function maxMembersForTier(tier: HomeTier): number {
  return TIER_MAX_MEMBERS[tier];
}

export interface ResolveEntitlementInput {
  /** `premiumStatus` del hogar (gobierna si hay Premium vigente). */
  premiumStatus?: string | null;
  /** Tier premium persistido (sticky) — lo usan enforcement y restore. */
  tier?: HomeTier | null;
  /** productId del recibo — lo usan sync y reconciliación. */
  productId?: string | null;
  /** Estado del flag de Remote Config `home_tiers_enabled`. */
  tiersEnabled: boolean;
  /**
   * Packs de miembro activos del hogar (eje aditivo, solo sobre Grupo). Opcional
   * y retrocompatible: si no se pasa (o `packsEnabled` es falsy), el tope es el
   * del tier, idéntico al comportamiento previo a los packs.
   */
  packs?: ActivePacks;
  /** Estado del flag de Remote Config `member_packs_enabled`. */
  packsEnabled?: boolean;
}

export interface ResolvedEntitlement {
  /**
   * Tier efectivo de cara al cliente: `'free'` si no hay Premium vigente, el
   * tier premium si lo hay, o `null` cuando el flag está OFF (modo binario, el
   * concepto de tier no aplica).
   */
  tier: EffectiveTier | null;
  /** Tope de miembros efectivo. */
  maxMembers: number;
  /** true si se aplicó el fail-safe por producto premium no catalogado. */
  failSafe: boolean;
}

/**
 * Deriva el tier efectivo y el tope de miembros de un hogar. Único punto de
 * decisión de `maxMembers` en todo el backend.
 *
 *  - Flag OFF → binario: Premium 10 / Free 3 (tier `null`).
 *  - Flag ON, no premium → Free (3).
 *  - Flag ON, premium → tope del tier (de `tier` persistido o derivado de
 *    `productId`). Producto premium NO catalogado → fail-safe Free (3) marcado.
 */
export function resolveEntitlement(
  opts: ResolveEntitlementInput,
): ResolvedEntitlement {
  const premium = isPremium(opts.premiumStatus);

  if (!opts.tiersEnabled) {
    return {
      tier: null,
      maxMembers: premium ? BINARY_PREMIUM_MAX_MEMBERS : FREE_MAX_MEMBERS,
      failSafe: false,
    };
  }

  if (!premium) {
    return { tier: "free", maxMembers: FREE_MAX_MEMBERS, failSafe: false };
  }

  const tier = opts.tier ?? tierFromProductId(opts.productId);
  if (tier == null) {
    // Premium con producto no catalogado: fail-safe conservador a Free (3).
    return { tier: "free", maxMembers: FREE_MAX_MEMBERS, failSafe: true };
  }
  // Tope del tier + packs aditivos (solo Grupo, gateado por `packsEnabled`).
  const maxMembers = effectiveMaxMembers(
    tier,
    maxMembersForTier(tier),
    opts.packs ?? {},
    opts.packsEnabled ?? false,
  );
  return { tier, maxMembers, failSafe: false };
}
