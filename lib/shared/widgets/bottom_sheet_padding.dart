import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';
import 'skins/shell_metrics.dart';

/// Padding inferior que un BottomSheet debe aplicar para que su última
/// fila quede visible por encima de:
///   - el teclado (`viewInsets.bottom`)
///   - la safe area / gesture indicator (`padding.bottom`)
///   - la NavBar flotante de la skin activa (solo si `hasNavBar`)
///   - el banner publicitario, si está activo (no-Premium, unitId no vacío)
///
/// Las dimensiones (NavBar height/bottom, bannerGap) salen de
/// `shellMetricsProvider`, que devuelve la impl correcta según la skin
/// activa (56+12 en v2, 64+12 en futurista). Sin esto, los sheets que
/// se montan sobre el shell quedan tapados por la NavBar flotante en
/// teléfonos sin gesture area amplia.
double bottomSheetSafeBottom(
  BuildContext context,
  WidgetRef ref, {
  required bool hasNavBar,
}) {
  final mq = MediaQuery.of(context);
  final metrics = ref.watch(shellMetricsProvider);
  final config = ref.watch(adBannerConfigProvider);
  final bannerVisible = config.show && config.unitId.isNotEmpty;
  final banner =
      bannerVisible ? AdBanner.kBannerHeight + metrics.bannerGap : 0.0;
  final navBar = hasNavBar ? metrics.navBarHeight + metrics.navBarBottom : 0.0;
  return mq.viewInsets.bottom + mq.padding.bottom + navBar + banner;
}
