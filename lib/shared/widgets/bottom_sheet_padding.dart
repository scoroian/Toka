import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';
import 'skins/main_shell_v2.dart';

/// Devuelve el padding inferior que un BottomSheet debe aplicar para que
/// sus acciones no queden tapadas por la NavBar del shell, el AdBanner ni
/// el teclado del sistema.
///
/// - [hasNavBar]: pasa `true` cuando el sheet se abre desde una pantalla
///   dentro de `MainShellV2` (Hoy, Historial, Miembros, Lista de tareas);
///   `false` cuando se abre desde una pantalla push (detalles, create/edit).
///
/// Fórmula:
///   viewInsets.bottom (teclado)
/// + padding.bottom    (gesture area / safe area)
/// + kNavBarHeight + kNavBarBottom      (si hasNavBar)
/// + AdBanner.kBannerHeight + kBannerGap (si el banner está visible)
double bottomSheetSafeBottom(
  BuildContext context,
  WidgetRef ref, {
  required bool hasNavBar,
}) {
  final mq = MediaQuery.of(context);
  final cfg = ref.watch(adBannerConfigProvider);
  final bannerVisible = cfg.show && cfg.unitId.isNotEmpty;

  final navBar = hasNavBar
      ? MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom
      : 0.0;
  final banner = bannerVisible
      ? AdBanner.kBannerHeight + AdBanner.kBannerGap
      : 0.0;

  return mq.viewInsets.bottom + mq.padding.bottom + navBar + banner;
}
