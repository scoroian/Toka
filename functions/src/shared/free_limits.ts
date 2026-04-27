// functions/src/shared/free_limits.ts
//
// Fuente de verdad de los límites del plan Free y del predicado isPremium.
// Debe mantenerse sincronizado con `lib/core/constants/free_limits.dart`.

export const FREE_LIMITS = {
  maxActiveMembers: 3,
  maxActiveTasks: 4,
  maxAdminsTotal: 1, // solo el owner
  maxAutomaticRecurringTasks: 3,
} as const;

/**
 * Conjunto de `premiumStatus` que se consideran "con Premium vigente":
 * el hogar disfruta de todas las capacidades Premium.
 *
 * Valor canónico persistido: `cancelledPendingEnd`.
 * La variante legacy `cancelled_pending_end` se acepta temporalmente durante
 * la migración para no dejar hogares pagados como Free.
 */
const PREMIUM_ACTIVE_STATUSES = new Set<string>([
  "active",
  "cancelledPendingEnd",
  "cancelled_pending_end",
  "rescue",
]);

export function isPremium(status: string | null | undefined): boolean {
  if (!status) return false;
  return PREMIUM_ACTIVE_STATUSES.has(status);
}

export function normalizePremiumStatus(status: string | null | undefined): string {
  switch (status) {
    case "cancelled_pending_end":
      return "cancelledPendingEnd";
    case "expired_free":
      return "expiredFree";
    default:
      return status ?? "free";
  }
}

// Códigos de error devueltos en HttpsError("failed-precondition", code)
// — consumidos por el cliente para mostrar banners/snackbars específicos.
export const FREE_LIMIT_CODES = {
  members: "free_limit_members",
  tasks: "free_limit_tasks",
  recurring: "free_limit_recurring",
  admins: "free_limit_admins",
  reviews: "free_no_reviews",
} as const;
