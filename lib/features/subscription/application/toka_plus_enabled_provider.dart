import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/services/remote_config_service.dart';

part 'toka_plus_enabled_provider.g.dart';

/// Si el eje de entitlement individual "Toka Plus" está activo en la UI.
///
/// Lee `toka_plus_enabled` de Remote Config (vía [RemoteConfigService]). Default
/// OFF: con el flag apagado NADIE ve features Plus (skins Plus ocultas, entradas
/// ocultas) ni nada se desbloquea, aunque exista el doc de entitlement. Espeja
/// `TOKA_PLUS_FLAG` del backend.
///
/// Fail-safe a OFF si Remote Config no está disponible (p. ej. tests sin
/// Firebase). Se recomputa en tiempo real al publicar un cambio en la consola.
/// Override en tests con `overrideWithValue`.
@Riverpod(keepAlive: true)
bool tokaPlusEnabled(TokaPlusEnabledRef ref) {
  try {
    final rc = RemoteConfigService(FirebaseRemoteConfig.instance);
    final sub = rc.onConfigUpdated.listen((_) async {
      await rc.activate();
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);
    return rc.tokaPlusEnabled;
  } catch (_) {
    return false;
  }
}
