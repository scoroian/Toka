import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toka/features/homes/application/dashboard_provider.dart';

part 'ad_banner_config_provider.g.dart';

class AdBannerConfig {
  const AdBannerConfig({required this.show, required this.unitId});
  final bool show;
  final String unitId;
}

@Riverpod(keepAlive: true)
AdBannerConfig adBannerConfig(AdBannerConfigRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  // `premiumFlags.showAds` es la fuente de verdad del estado premium del hogar.
  // `adFlags` es un flag derivado que puede quedar desincronizado si el premium
  // cambia por una vía que no recomputa el dashboard completo (p. ej. el toggle
  // de QA `debugSetPremiumStatus`, que actualiza `premiumFlags` pero no
  // `adFlags`). Gateamos también por `showAds` para que un hogar premium nunca
  // muestre banner aunque `adFlags` llegue stale. Una única instancia de
  // AdBanner (la del shell) consume este config, así que esto cubre Hoy,
  // Tareas, Miembros, Historial y Crear/Editar tarea de una vez.
  final adsAllowed = dashboard?.premiumFlags.showAds ?? true;
  return AdBannerConfig(
    show: adsAllowed && (dashboard?.adFlags.showBanner ?? false),
    unitId: dashboard?.adFlags.bannerUnit ?? '',
  );
}
