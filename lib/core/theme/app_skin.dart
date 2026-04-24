// lib/core/theme/app_skin.dart

/// Skins visuales soportadas por Toka. El skin activo se gobierna vía
/// [SkinMode] (ver `skin_provider.dart`), que persiste la preferencia del
/// usuario en SharedPreferences.
enum AppSkin {
  v2,        // actual — coral cálido, light default
  futurista, // nuevo — cyan espacial, dark default
}

extension AppSkinX on AppSkin {
  /// Clave usada para persistir el skin en SharedPreferences.
  /// Equivale al nombre del enum (`v2`, `futurista`).
  String get persistKey => name;
}
