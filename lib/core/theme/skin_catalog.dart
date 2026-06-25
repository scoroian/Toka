// lib/core/theme/skin_catalog.dart
import 'app_skin.dart';

/// Nivel de acceso de una skin.
enum SkinTier {
  /// Disponible para todos.
  free,

  /// Cosmético de Toka Plus: requiere entitlement Plus activo.
  plus,
}

/// Clasifica cada [AppSkin] como gratuita o cosmética-Plus.
///
/// ÚNICO punto de verdad del gating de skins: para gatear una skin futura basta
/// añadir su rama aquí. El `switch` exhaustivo obliga a clasificar cada nueva
/// skin (el compilador falla si se olvida).
SkinTier skinTier(AppSkin skin) => switch (skin) {
      AppSkin.v2 => SkinTier.free,
      AppSkin.oceano => SkinTier.plus,
    };

/// Si la skin requiere Toka Plus.
bool isPlusSkin(AppSkin skin) => skinTier(skin) == SkinTier.plus;
