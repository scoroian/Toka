import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../ad_banner.dart';
import '../ad_banner_config_provider.dart';
import '../futurista/tocka_tab_bar.dart';
import '../keyboard_visible_provider.dart';
import 'shell_metrics.dart';
import 'shell_presence_marker.dart';

/// Shell futurista con TockaTabBar floating + AdBanner flotante al pie y
/// PopScope que redirige a Hoy desde otras tabs (paridad con MainShellV2).
///
/// Mismo contrato que MainShellV2:
///  - `extendBody: true` + bottomNavigationBar placeholder transparente para
///    que MediaQuery.padding.bottom crezca y los hijos posicionen FABs/sheets
///    por encima del banner + nav bar.
///  - AdBanner real (AdMob) en `Positioned` flotante encima de la nav bar.
///  - Banner se oculta en `/settings` (regla legal compartida con v2) y
///    cuando el teclado está visible.
///  - `PopScope` captura el botón hardware BACK: si la tab activa no es Hoy,
///    redirige a Hoy en lugar de salir de la app.
class MainShellFuturista extends ConsumerWidget {
  const MainShellFuturista({super.key, required this.child});
  final Widget child;

  static const _routes = [
    AppRoutes.home,
    AppRoutes.history,
    AppRoutes.members,
    AppRoutes.tasks,
    AppRoutes.settings,
  ];

  int _indexFromRoute(String location) {
    for (var i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final tabIndex = _indexFromRoute(location);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final metrics = ref.watch(shellMetricsProvider);

    final adConfig = ref.watch(adBannerConfigProvider);
    final keyboardVisible = ref.watch(keyboardVisibleProvider);
    final bannerVisible = adConfig.show
        && adConfig.unitId.isNotEmpty
        && !metrics.suppressBannerFor(location)
        && !keyboardVisible;
    final bannerSlot = bannerVisible
        ? AdBanner.kBannerHeight + metrics.bannerGap
        : 0.0;
    final navBarSlot = keyboardVisible
        ? 0.0
        : metrics.navBarHeight + metrics.navBarBottom;

    final items = [
      TockaTabBarItem(icon: Icons.home_outlined, label: l10n.today_screen_title),
      TockaTabBarItem(icon: Icons.history, label: l10n.history_title),
      TockaTabBarItem(icon: Icons.group_outlined, label: l10n.members_title),
      TockaTabBarItem(icon: Icons.check_circle_outline, label: l10n.tasks_title),
      TockaTabBarItem(icon: Icons.settings_outlined, label: l10n.settings_title),
    ];

    return PopScope(
      canPop: tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: SizedBox(
          height: navBarSlot + safeBottom + bannerSlot,
        ),
        body: Stack(
          children: [
            ShellPresenceMarker(child: child),
            if (bannerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: navBarSlot + safeBottom + metrics.bannerGap,
                child: const AdBanner(key: Key('ad_banner_futurista_shell')),
              ),
            if (!keyboardVisible)
              Positioned(
                left: 10,
                right: 10,
                bottom: metrics.navBarBottom + safeBottom,
                child: TockaTabBar(
                  activeIndex: tabIndex,
                  items: items,
                  onTap: (i) => context.go(_routes[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
