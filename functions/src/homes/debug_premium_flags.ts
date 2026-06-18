// functions/src/homes/debug_premium_flags.ts
//
// Lógica pura (sin Firestore) que deriva los flags del dashboard a partir del
// estado premium de QA/debug. Aislada en su propio módulo para poder testearla
// sin cargar `index.ts` (que inicializa firebase-admin a nivel de módulo).

import { DEFAULT_BANNER_UNIT_ID } from "../shared/ad_constants";

export const DEBUG_VALID_STATUSES = [
  "free",
  "active",
  "cancelledPendingEnd",
  "rescue",
  "expiredFree",
  "restorable",
] as const;

export type DebugPremiumStatus = typeof DEBUG_VALID_STATUSES[number];

export interface DebugDashboardFlags {
  isPremium: boolean;
  premiumFlags: {
    isPremium: boolean;
    showAds: boolean;
    canUseSmartDistribution: boolean;
    canUseVacations: boolean;
    canUseReviews: boolean;
  };
  adFlags: { showBanner: boolean; bannerUnit: string };
  rescueFlags: { isInRescue: boolean; daysLeft: number | null };
}

// Deriva premiumFlags + adFlags + rescueFlags de forma coherente.
// Invariante clave: `adFlags.showBanner` SIEMPRE coincide con
// `premiumFlags.showAds` (ambos = `!isPremium`). Si divergen (p. ej. showAds
// false pero showBanner true), la UI pinta el banner pese a premium
// (bug QA "banner de AdMob visible en Crear tarea"). Espejo de lo que hacen
// syncEntitlement/updateDashboard en producción.
export function buildDebugDashboardFlags(
  typed: DebugPremiumStatus
): DebugDashboardFlags {
  const isPremium =
    typed === "active" ||
    typed === "cancelledPendingEnd" ||
    typed === "rescue";
  return {
    isPremium,
    premiumFlags: {
      isPremium,
      showAds: !isPremium,
      canUseSmartDistribution: isPremium,
      canUseVacations: isPremium,
      canUseReviews: isPremium,
    },
    adFlags: {
      showBanner: !isPremium,
      bannerUnit: isPremium ? "" : DEFAULT_BANNER_UNIT_ID,
    },
    rescueFlags: {
      isInRescue: typed === "rescue",
      daysLeft: typed === "rescue" ? 2 : null,
    },
  };
}
