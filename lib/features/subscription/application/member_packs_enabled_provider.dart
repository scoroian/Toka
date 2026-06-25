import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/services/remote_config_service.dart';

part 'member_packs_enabled_provider.g.dart';

/// Si el eje de **packs de miembro** está activo en la UI.
///
/// Lee `member_packs_enabled` de Remote Config (vía [RemoteConfigService]).
/// Default OFF: con el flag apagado la UI no ofrece packs (sección oculta en el
/// paywall, sin gestión de packs) y el tope máximo mostrado es el del tier.
/// Espeja `member_packs_enabled` del backend
/// (`functions/src/shared/feature_flags.ts`).
///
/// Fail-safe a OFF si Remote Config no está disponible (p. ej. tests sin
/// Firebase). Se recomputa en tiempo real al publicar un cambio en la consola.
/// Override en tests con `overrideWithValue`.
@Riverpod(keepAlive: true)
bool memberPacksEnabled(MemberPacksEnabledRef ref) {
  try {
    final rc = RemoteConfigService(FirebaseRemoteConfig.instance);
    final sub = rc.onConfigUpdated.listen((_) async {
      await rc.activate();
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);
    return rc.memberPacksEnabled;
  } catch (_) {
    return false;
  }
}
