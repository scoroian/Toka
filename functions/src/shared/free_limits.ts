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
 * - `active`              : suscripción al día.
 * - `cancelledPendingEnd` : cancelada pero aún dentro del periodo pagado.
 * - `rescue`              : ventana de rescate de 3 días antes del downgrade.
 *
 * Los estados `free`, `expiredFree` y `restorable` devuelven `false`.
 */
const PREMIUM_ACTIVE_STATUSES = new Set<string>([
  "active",
  "cancelledPendingEnd",
  "rescue",
]);

export function isPremium(status: string | null | undefined): boolean {
  if (!status) return false;
  return PREMIUM_ACTIVE_STATUSES.has(status);
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
