import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/services/remote_config_service.dart';

part 'home_tiers_provider.g.dart';

/// Si el modelo de tiers por tamaño de hogar está activo en la UI.
///
/// Lee `home_tiers_enabled` de Remote Config (vía [RemoteConfigService]). Con el
/// flag OFF la UI vuelve al comportamiento binario (paywall Premium único). El
/// backend ya gobierna los TOPES por su cuenta con el mismo flag, así que los
/// límites de miembros son correctos en ambos estados; este provider solo decide
/// qué paywall y qué copy de tier se pintan.
///
/// Fail-safe a OFF si Remote Config no está disponible (p. ej. tests sin
/// Firebase). Se recomputa en tiempo real al publicar un cambio en la consola.
/// Override en tests con `overrideWithValue`.
@Riverpod(keepAlive: true)
bool homeTiersEnabled(HomeTiersEnabledRef ref) {
  try {
    final rc = RemoteConfigService(FirebaseRemoteConfig.instance);
    final sub = rc.onConfigUpdated.listen((_) async {
      await rc.activate();
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);
    return rc.homeTiersEnabled;
  } catch (_) {
    return false;
  }
}
