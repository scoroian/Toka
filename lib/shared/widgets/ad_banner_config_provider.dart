import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/shared/services/remote_config_service.dart';

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
  // `premiumFlags.showAds` es la fuente de verdad del estado premium del hogar.
  // `adFlags` es un flag derivado que puede quedar desincronizado si el premium
  // cambia por una vía que no recomputa el dashboard completo (p. ej. una vía
  // interna que actualiza `premiumFlags` pero no
  // `adFlags`). Gateamos también por `showAds` para que un hogar premium nunca
  // muestre banner aunque `adFlags` llegue stale. Una única instancia de
  // AdBanner (la del shell) consume este config, así que esto cubre Hoy,
  // Tareas, Miembros, Historial y Crear/Editar tarea de una vez.
  final adsAllowed = dashboard?.premiumFlags.showAds ?? true;
  final isIos = defaultTargetPlatform == TargetPlatform.iOS;

  // Precedencia del unit ID:
  //   1) Remote Config (cambiable sin redeploy desde la consola).
  //   2) dashboard.adFlags (inyectado por el backend desde env, con guardrail).
  //   3) test IDs (fallback de debug/vacío, resuelto en ad_banner.dart).
  final rcUnit = ref.watch(remoteBannerAdUnitsProvider).forPlatform(isIos: isIos);
  final dashUnit = dashboard?.adFlags.bannerUnitFor(isIos: isIos) ?? '';
  final unitId = rcUnit.isNotEmpty ? rcUnit : dashUnit;

  return AdBannerConfig(
    show: adsAllowed && (dashboard?.adFlags.showBanner ?? false),
    unitId: unitId,
  );
}
