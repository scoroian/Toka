import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';
import 'keyboard_visible_provider.dart';
import 'skins/shell_metrics.dart';

/// Padding inferior total que cualquier `ScrollView` de contenido
/// debe aplicar para que su último ítem quede visible por encima
/// del banner publicitario, la NavigationBar flotante y la safe area.
///
/// Devuelve:
///
///   banner + navBar + safeArea + extra
///
/// Tanto `banner` como `navBar` se evalúan a 0 cuando el teclado del
/// sistema está visible: la spec oculta ambos mientras el usuario escribe
/// para no tapar el input (ver `keyboard_visible_provider.dart`).
/// Adicionalmente `banner` es 0 cuando la config remota no lo muestra
/// (Premium, `showBanner=false`), el `unitId` está vacío, o la ruta actual
/// está en la lista de rutas que suprimen el banner (p. ej. `/settings`).
///
/// Las dimensiones (NavBar height/bottom, bannerGap) se obtienen del
/// `shellMetricsProvider`, que devuelve la impl correcta según la skin
/// activa. Esto evita el desfase entre v2 (56+12) y futurista (64+12).
double adAwareBottomPadding(
  BuildContext context,
  WidgetRef ref, {
  double extra = 0,
}) {
  final metrics = ref.watch(shellMetricsProvider);
  final config = ref.watch(adBannerConfigProvider);
  final keyboardVisible = ref.watch(keyboardVisibleProvider);
  final location = _safeLocation(context);
  final suppressedHere = metrics.suppressBannerFor(location);
  final bannerVisible = config.show
      && config.unitId.isNotEmpty
      && !keyboardVisible
      && !suppressedHere;

  final banner = bannerVisible
      ? AdBanner.kBannerHeight + metrics.bannerGap
      : 0.0;
  final navBar = keyboardVisible
      ? 0.0
      : metrics.navBarHeight + metrics.navBarBottom;
  final safeArea = MediaQuery.paddingOf(context).bottom;

  return banner + navBar + safeArea + extra;
}

String _safeLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).matchedLocation;
  } catch (_) {
    return '';
  }
}
