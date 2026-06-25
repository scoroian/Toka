import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/shared/services/remote_config_service.dart';
import 'package:toka/shared/widgets/ad_flags_provider.dart';
import 'package:toka/shared/widgets/ad_visibility_provider.dart';

part 'ad_banner_config_provider.g.dart';

class AdBannerConfig {
  const AdBannerConfig({required this.show, required this.unitId});
  final bool show;
  final String unitId;
}

/// Banner unit IDs por plataforma servidos por Remote Config. Permite cambiar el
/// id del anuncio desde la consola de Firebase SIN redesplegar functions ni
/// republicar la app.
class BannerAdUnits {
  const BannerAdUnits({required this.android, required this.ios});
  final String android;
  final String ios;

  String forPlatform({required bool isIos}) => isIos ? ios : android;
}

/// Lee los banner unit IDs de Remote Config (claves `ad_banner_unit_android` /
/// `ad_banner_unit_ios`, vía [RemoteConfigService]). Si Remote Config no está
/// disponible (p. ej. en tests sin Firebase) devuelve cadenas vacías, de modo
/// que el consumidor cae al unit del dashboard y, en último término, a los test
/// IDs (ver `ad_banner.dart`). Override en tests con `overrideWithValue`.
@Riverpod(keepAlive: true)
BannerAdUnits remoteBannerAdUnits(RemoteBannerAdUnitsRef ref) {
  try {
    final rc = RemoteConfigService(FirebaseRemoteConfig.instance);
    // Tiempo real: cuando se publica un cambio en la consola de Remote Config,
    // activamos los nuevos valores y recomputamos este provider para que el
    // banner tome el nuevo unit AL INSTANTE, sin reiniciar la app.
    final sub = rc.onConfigUpdated.listen((_) async {
      await rc.activate();
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);
    return BannerAdUnits(
      android: rc.adBannerUnitAndroid,
      ios: rc.adBannerUnitIos,
    );
  } catch (_) {
    return const BannerAdUnits(android: '', ios: '');
  }
}

@Riverpod(keepAlive: true)
AdBannerConfig adBannerConfig(AdBannerConfigRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  final isIos = defaultTargetPlatform == TargetPlatform.iOS;

  // Precedencia del unit ID (igual en ambos caminos):
  //   1) Remote Config (cambiable sin redeploy desde la consola).
  //   2) dashboard.adFlags (inyectado por el backend desde env, con guardrail).
  //   3) test IDs (fallback de debug/vacío, resuelto en ad_banner.dart).
  // En hogares Premium el dashboard deja el unit vacío (banner suprimido a nivel
  // de hogar); por eso, en el camino per-usuario, el unit real debe venir de
  // Remote Config y, en dev, lo cubre el test ID de `ad_banner.dart`.
  final rcUnit = ref.watch(remoteBannerAdUnitsProvider).forPlatform(isIos: isIos);
  final dashUnit = dashboard?.adFlags.bannerUnitFor(isIos: isIos) ?? '';
  final unitId = rcUnit.isNotEmpty ? rcUnit : dashUnit;

  // ── Flag MAESTRO de la publicidad diferenciada ──────────────────────────
  // ON  → la visibilidad del banner es per-usuario (`adVisibilityProvider`):
  //       un flag de hogar binario no puede expresar "banner sí para el miembro,
  //       no para el pagador". El banner se quita individualmente (pagador de un
  //       hogar Premium, o con Toka Plus).
  // OFF → comportamiento de hogar actual: `showAds && showBanner` (ambos a nivel
  //       de hogar, premium-gated por el backend).
  if (ref.watch(adDifferentiatedEnabledProvider)) {
    return AdBannerConfig(
      show: ref.watch(adVisibilityProvider).banner,
      unitId: unitId,
    );
  }

  // `premiumFlags.showAds` es la fuente de verdad del estado premium del hogar.
  // `adFlags` es un flag derivado que puede quedar desincronizado; gateamos
  // también por `showAds` para que un hogar premium nunca muestre banner aunque
  // `adFlags` llegue stale. Una única instancia de AdBanner (la del shell)
  // consume este config: cubre Hoy, Tareas, Miembros, Historial y Crear/Editar.
  final adsAllowed = dashboard?.premiumFlags.showAds ?? true;
  return AdBannerConfig(
    show: adsAllowed && (dashboard?.adFlags.showBanner ?? false),
    unitId: unitId,
  );
}
