// lib/shared/widgets/skins/main_shell_v2.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../ad_banner.dart';
import '../ad_banner_config_provider.dart';

class MainShellV2 extends ConsumerWidget {
  const MainShellV2({super.key, required this.child});
  final Widget child;

  static int _tabIndex(String location) {
    if (location.startsWith(AppRoutes.history)) return 1;
    if (location.startsWith(AppRoutes.members)) return 2;
    if (location.startsWith(AppRoutes.tasks))   return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  // Rutas del shell donde NO mostramos el banner (legales/formales).
  static bool _suppressBannerFor(String location) {
    return location.startsWith(AppRoutes.settings);
  }

  // Altura total que la barra flotante ocupa desde el borde inferior de la pantalla.
  // Usada tanto para el placeholder transparente (MediaQuery) como para el Positioned.
  // Públicas para que los inner Scaffolds puedan calcular el padding del FAB.
  static const double kNavBarHeight  = 56;
  static const double kNavBarBottom  = 12;
  // Compatibilidad interna
  static const double _kNavBarHeight = kNavBarHeight;
  static const double _kNavBarBottom = kNavBarBottom;

  // Gap entre el top de la NavBar y el bottom del banner.
  // Fuente única en AdBanner.kBannerGap.
  static double get _kBannerGap => AdBanner.kBannerGap;

  // Altura total reservada en la parte inferior cuando el banner está visible
  // (sin contar safeBottom que se suma aparte).
  // El Scaffold del shell reserva esto en su bottomNavigationBar para que el
  // body no quede tapado por el banner ni la NavBar.
  static double bannerSlotHeight({required bool bannerVisible}) {
    if (!bannerVisible) return 0;
    return AdBanner.kBannerHeight + _kBannerGap;
  }

  /// Padding inferior total que un `ScrollView` dentro de una pantalla tab
  /// debe aplicar para que su último ítem quede por encima del banner y
  /// la NavBar flotante.
  ///
  ///   safeBottom + kNavBarHeight + kNavBarBottom + bannerSlotHeight(...)
  ///
  /// Debe llamarse desde un `build` o `Consumer.builder`: hace `ref.watch`.
  static double bottomContentPadding(BuildContext ctx, WidgetRef ref) {
    final safeBottom = MediaQuery.of(ctx).padding.bottom;
    final cfg = ref.watch(adBannerConfigProvider);
    final location = GoRouterState.of(ctx).matchedLocation;
    final visible = cfg.show
        && cfg.unitId.isNotEmpty
        && !_suppressBannerFor(location);
    return safeBottom
        + kNavBarHeight
        + kNavBarBottom
        + bannerSlotHeight(bannerVisible: visible);
  }

  /// Padding inferior que un `floatingActionButton` dentro de una pantalla tab
  /// debe aplicar para quedar por encima del banner + NavBar.
  ///
  ///   kNavBarHeight + kNavBarBottom + bannerSlotHeight(...)
  ///
  /// `safeBottom` NO se incluye: el Scaffold interno ya lo aporta vía
  /// `MediaQuery.padding.bottom` (el shell reserva ese espacio).
  static double fabBottomPadding(BuildContext ctx, WidgetRef ref) {
    final cfg = ref.watch(adBannerConfigProvider);
    final location = GoRouterState.of(ctx).matchedLocation;
    final visible = cfg.show
        && cfg.unitId.isNotEmpty
        && !_suppressBannerFor(location);
    return kNavBarHeight
        + kNavBarBottom
        + bannerSlotHeight(bannerVisible: visible);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final tabIndex = _tabIndex(location);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final adConfig = ref.watch(adBannerConfigProvider);
    final bannerVisible = adConfig.show
        && adConfig.unitId.isNotEmpty
        && !_suppressBannerFor(location);
    final bannerSlot = bannerSlotHeight(bannerVisible: bannerVisible);

    // El SizedBox transparente registra la altura de la barra + banner en
    // el Scaffold, de modo que MediaQuery.padding.bottom crece para los hijos.
    // Gracias a extendBody: true el body sigue extendiéndose por detrás — el
    // blur de la NavBar sigue siendo visible — pero showModalBottomSheet,
    // teclados y FABs ya posicionan su borde inferior por encima del banner
    // y la NavBar.
    //
    // PopScope intercepta el botón físico BACK de Android (y el gesto de iOS):
    // - canPop == true solo en Hoy (índice 0): Flutter sale de la app normalmente.
    // - canPop == false en cualquier otro tab: se llama onPopInvokedWithResult
    //   que redirige a Hoy en lugar de salir.
    return PopScope(
      canPop: tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: SizedBox(
          height: _kNavBarHeight + _kNavBarBottom + safeBottom + bannerSlot,
        ),
        body: Stack(
          children: [
            child,
            if (bannerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: _kNavBarHeight + _kNavBarBottom + safeBottom + _kBannerGap,
                child: const AdBanner(key: Key('ad_banner')),
              ),
            Positioned(
              left: 16, right: 16,
              bottom: _kNavBarBottom + safeBottom,
              child: _FloatingNavBar(selectedIndex: tabIndex),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF14141E).withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.60),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                blurRadius: isDark ? 24 : 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined,    selectedIcon: Icons.home,         index: 0, sel: selectedIndex, route: AppRoutes.home,    label: l10n.today_screen_title),
              _NavItem(icon: Icons.history_outlined, selectedIcon: Icons.history,      index: 1, sel: selectedIndex, route: AppRoutes.history, label: l10n.history_title),
              _NavItem(icon: Icons.people_outline,   selectedIcon: Icons.people,       index: 2, sel: selectedIndex, route: AppRoutes.members, label: l10n.members_title),
              _NavItem(icon: Icons.task_alt_outlined,selectedIcon: Icons.task_alt,     index: 3, sel: selectedIndex, route: AppRoutes.tasks,   label: l10n.tasks_title),
              _NavItem(icon: Icons.settings_outlined,selectedIcon: Icons.settings,     index: 4, sel: selectedIndex, route: AppRoutes.settings,label: l10n.settings_title),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon, required this.selectedIcon,
    required this.index, required this.sel,
    required this.route, required this.label,
  });
  final IconData icon, selectedIcon;
  final int index, sel;
  final String route, label;

  @override
  Widget build(BuildContext context) {
    final isActive = index == sel;
    const activeColor = AppColorsV2.primary;
    final inactiveColor = Theme.of(context).iconTheme.color?.withValues(alpha: 0.3)
        ?? Colors.grey.withValues(alpha: 0.3);

    return GestureDetector(
      key: Key('nav_item_$index'),
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? selectedIcon : icon,
                color: isActive ? activeColor : inactiveColor, size: 22),
            if (isActive)
              Container(
                key: Key('nav_dot_$index'),
                width: 4, height: 4,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}
