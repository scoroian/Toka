import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';
import 'keyboard_visible_provider.dart';
import 'skins/shell_metrics.dart';
import 'skins/shell_presence_marker.dart';

/// Padding inferior total que cualquier `ScrollView` de contenido
/// debe aplicar para que su último ítem quede visible por encima
/// del banner publicitario, la NavigationBar flotante y la safe area.
///
/// Devuelve:
///   - `safeArea + extra` si el widget está FUERA del shell (push routes
///     como /paywall, /profile, /vacation: no renderizan NavBar ni AdBanner).
///   - `banner + navBar + safeArea + extra` si está bajo un `MainShellV2` o
///     `MainShellFuturista` (detectado vía `ShellPresenceMarker`).
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
  final safeArea = MediaQuery.paddingOf(context).bottom;

  // Pantallas fuera del shell (push routes como /paywall, /profile,
  // /vacation, etc.) no renderizan NavBar ni AdBanner. Solo necesitan
  // safeArea + extra. Esto evita ~64-140px de espacio muerto al fondo.
  // Bonus: al no leer adBannerConfigProvider/shellMetricsProvider/etc.
  // se evita disparar la cadena que mantiene vivo el Timer 15s de
  // authProvider en tests sin mock completo.
  if (!ShellPresenceMarker.of(context)) {
    return safeArea + extra;
  }

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

  return banner + navBar + safeArea + extra;
}

/// Devuelve la ruta actual desde [GoRouterState], o cadena vacía si el
/// widget que invoca [adAwareBottomPadding] no está dentro de un
/// [GoRouter]. Tras el early-return de [ShellPresenceMarker], este path
/// solo se ejecuta dentro del shell — donde GoRouter siempre existe en
/// producción — así que el fallback queda como defensivo para tests o
/// goldens que monten un shell sin router. El fallback `''` provoca que
/// `suppressBannerFor` devuelva `false` (cálculo conservador: asume
/// banner visible y reserva espacio extra).
String _safeLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).matchedLocation;
  } catch (_) {
    return '';
  }
}
