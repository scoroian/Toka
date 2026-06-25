/// Límites numéricos del plan Free para un hogar.
///
/// Fuente de verdad en cliente. Debe mantenerse sincronizado con
/// `functions/src/shared/free_limits.ts`.
class FreeLimits {
  static const int maxActiveMembers = 3;
  static const int maxActiveTasks = 4;
  static const int maxAdminsTotal = 1; // solo el owner
  static const int maxAutomaticRecurringTasks = 3;
}

/// Tope absoluto de miembros de un hogar (tier Grupo + todos los packs).
/// Espejo de `ABSOLUTE_MAX_MEMBERS` del backend (`functions/src/shared/
/// tier_catalog.ts`). Por encima de este tope solo aplica Toka Business.
const int kAbsoluteMaxMembers = 25;

/// Estados de `premiumStatus` en los que un hogar todavía tiene
/// capacidades Premium (billing activo, cancelado en espera o rescue).
///
/// Valor canónico persistido: `cancelledPendingEnd`. La variante legacy
/// `cancelled_pending_end` se acepta temporalmente durante la migración.
const Set<String> kPremiumActiveStatuses = {
  'active',
  'cancelledPendingEnd',
  'cancelled_pending_end',
  'rescue',
};

bool isHomePremium(String? premiumStatus) =>
    premiumStatus != null && kPremiumActiveStatuses.contains(premiumStatus);

String normalizePremiumStatus(String? premiumStatus) {
  switch (premiumStatus) {
    case 'cancelled_pending_end':
      return 'cancelledPendingEnd';
    case 'expired_free':
      return 'expiredFree';
    default:
      return premiumStatus ?? 'free';
  }
}
