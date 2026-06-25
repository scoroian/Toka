import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/subscription/application/plus_provider.dart';
import 'app_skin.dart';
import 'skin_catalog.dart';
import 'skin_provider.dart';

part 'effective_skin_provider.g.dart';

/// Skin EFECTIVA a aplicar, combinando la preferencia del usuario
/// ([skinModeProvider]) con su entitlement Plus ([plusActiveProvider]).
///
/// Si la skin elegida es cosmética-Plus y el usuario NO tiene Plus efectivo
/// (sin Plus, expirado, o flag OFF), cae a [AppSkin.v2]. La PREFERENCIA se
/// conserva en SharedPreferences: al reactivar Plus la skin elegida vuelve a
/// aplicarse sola, sin que el usuario tenga que reseleccionarla.
///
/// `app.dart` (tema) y `SkinSwitch` (widgets) consumen ESTE provider, de modo
/// que activar/desactivar Plus re-tematiza la app EN VIVO.
@riverpod
AppSkin effectiveSkin(EffectiveSkinRef ref) {
  final selected = ref.watch(skinModeProvider);
  if (!isPlusSkin(selected)) return selected;
  return ref.watch(plusActiveProvider) ? selected : AppSkin.v2;
}
