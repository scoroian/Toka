// lib/core/theme/app_skin.dart

/// Identifies available visual skins.
/// Add a new value here when a new full redesign is introduced.
enum AppSkin { material }

/// Single point of control for which skin the app renders.
/// Change [current] to switch all screens to a different visual design.
/// In the future, this can read from Firebase Remote Config or SharedPreferences.
class SkinConfig {
  SkinConfig._();
  static AppSkin current = AppSkin.material;
}
