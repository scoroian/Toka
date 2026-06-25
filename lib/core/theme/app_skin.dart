// lib/core/theme/app_skin.dart

/// Skins visuales soportadas por Toka. El skin activo se gobierna vía
/// [SkinMode] (ver `skin_provider.dart`), que persiste la preferencia del
/// usuario en SharedPreferences.
///
/// Por ahora solo existe una skin (`v2`), pero la maquinaria de cambio de skin
/// (`SkinMode`, `SkinSwitch`, `AppearancePicker`, `shellMetricsProvider`) se
/// mantiene intacta: para añadir una nueva skin basta con sumar un valor a este
/// enum y su rama correspondiente en cada `switch (skin)`.
enum AppSkin {
  v2, // coral cálido, light default — skin gratuita por defecto
  oceano, // azul frío — skin COSMÉTICA de Toka Plus (gated, ver skin_catalog.dart)
}

extension AppSkinX on AppSkin {
  /// Clave usada para persistir el skin en SharedPreferences.
  /// Equivale al nombre del enum (`v2`).
  String get persistKey => name;
}
