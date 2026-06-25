import 'ad_visibility_provider.dart';

/// Decisión PURA de si procede mostrar un intersticial AHORA. Sin AdMob ni
/// Firebase: se puede testear de forma exhaustiva.
///
/// Devuelve `true` ⇔:
/// - `enabled` (maestro ∧ `ad_interstitial_enabled`),
/// - la visibilidad per-usuario permite intersticial (`visibility.interstitial`),
/// - no se ha alcanzado el tope por sesión (`sessionCount < maxPerSession`),
/// - ha pasado el intervalo mínimo desde el último (`now - lastShownAt ≥ minInterval`;
///   `lastShownAt == null` lo cumple siempre).
bool shouldShowInterstitial({
  required bool enabled,
  required AdVisibility visibility,
  required DateTime now,
  required DateTime? lastShownAt,
  required int sessionCount,
  required int minIntervalSeconds,
  required int maxPerSession,
}) {
  if (!enabled) return false;
  if (!visibility.interstitial) return false;
  if (sessionCount >= maxPerSession) return false;
  if (lastShownAt != null &&
      now.difference(lastShownAt).inSeconds < minIntervalSeconds) {
    return false;
  }
  return true;
}
