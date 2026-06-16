import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_skin.dart';
import '../../../core/theme/skin_provider.dart';
import '../ad_banner.dart';

/// Métricas del shell según skin activo. Single source of truth para alturas
/// de NavBar y reglas de supresión de banner. `adAwareBottomPadding` y
/// `MainShellV2.bottomContentPadding/fabBottomPadding` la consumen vía
/// `shellMetricsProvider`. Al añadir una nueva skin se suma su
/// implementación de [ShellMetrics] y su rama en `shellMetricsProvider`.
abstract class ShellMetrics {
  const ShellMetrics();
  double get navBarHeight;
  double get navBarBottom;
  double get bannerGap;
  bool suppressBannerFor(String location);
}

class MainShellV2Metrics extends ShellMetrics {
  const MainShellV2Metrics();
  static const double kNavBarHeight = 56;
  static const double kNavBarBottom = 12;
  @override
  double get navBarHeight => kNavBarHeight;
  @override
  double get navBarBottom => kNavBarBottom;
  @override
  double get bannerGap => AdBanner.kBannerGap;
  @override
  bool suppressBannerFor(String location) =>
      location.startsWith(AppRoutes.settings);
}

final shellMetricsProvider = Provider<ShellMetrics>((ref) {
  final skin = ref.watch(skinModeProvider);
  switch (skin) {
    case AppSkin.v2:
      return const MainShellV2Metrics();
  }
});
