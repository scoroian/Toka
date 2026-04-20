// lib/core/theme/app_skin.dart

/// Identifies available visual skins.
/// Add a new value here when a new full redesign is introduced.
///
/// Infraestructura viva: hoy sólo existe `v2` porque la skin V1 ha sido
/// eliminada, pero el enum y [SkinConfig] se mantienen para acomodar una
/// futura V3/V4 sin reintroducir la plumería.
enum AppSkin { v2 }

/// Single point of control for which skin the app renders.
/// Change [current] to switch all screens to a different visual design.
/// In the future, this can read from Firebase Remote Config or SharedPreferences.
class SkinConfig {
  SkinConfig._();
  static AppSkin current = AppSkin.v2;
}
