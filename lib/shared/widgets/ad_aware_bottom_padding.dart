import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';
import 'keyboard_visible_provider.dart';
import 'skins/main_shell_v2.dart';

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
/// (Premium, `showBanner=false`) o el `unitId` está vacío.
///
/// Las constantes de la NavBar se importan de [MainShellV2] para mantener
/// una única fuente de verdad. `extra` permite añadir respiración adicional
/// (por ejemplo, para separar el último card visual del final del scroll).
///
/// Uso típico:
///
/// ```dart
/// ListView.builder(
///   padding: EdgeInsets.only(
///     top: 16,
///     bottom: adAwareBottomPadding(context, ref, extra: 16),
///   ),
///   // ...
/// )
/// ```
double adAwareBottomPadding(
  BuildContext context,
  WidgetRef ref, {
  double extra = 0,
}) {
  final config = ref.watch(adBannerConfigProvider);
  final keyboardVisible = ref.watch(keyboardVisibleProvider);
  final bannerVisible =
      config.show && config.unitId.isNotEmpty && !keyboardVisible;

  final banner = bannerVisible
      ? AdBanner.kBannerHeight + AdBanner.kBannerGap
      : 0.0;
  final navBar = keyboardVisible
      ? 0.0
      : MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom;
  final safeArea = MediaQuery.paddingOf(context).bottom;

  return banner + navBar + safeArea + extra;
}
