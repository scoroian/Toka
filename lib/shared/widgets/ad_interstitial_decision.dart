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

/// Decisión PURA de si el regreso a primer plano ("app resume") es un MOMENTO
/// elegible para evaluar un intersticial. NO decide la frecuencia (eso lo hace
/// [shouldShowInterstitial] dentro del controlador); solo discierne si este
/// resume sigue a un background lo bastante largo como para considerarse un
/// "me fui y volví" en vez de un vistazo fugaz.
///
/// Devuelve `true` ⇔ hubo un background previo (`backgroundedAt != null`) y han
/// transcurrido al menos `minBackgroundSeconds` desde entonces. Un
/// `backgroundedAt == null` (cold-start, sin background previo) devuelve `false`
/// para que abrir la app nunca quede gateado por un anuncio.
bool shouldShowInterstitialOnResume({
  required DateTime? backgroundedAt,
  required DateTime now,
  required int minBackgroundSeconds,
}) {
  if (backgroundedAt == null) return false;
  return now.difference(backgroundedAt).inSeconds >= minBackgroundSeconds;
}
