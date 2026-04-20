import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';

/// Wrapper de [Scaffold] para pantallas push (fuera del `MainShellV2`)
/// que necesitan mostrar el [AdBanner] al pie.
///
/// - Reserva espacio inferior vía `bottomNavigationBar` para que
///   `MediaQuery.padding.bottom` crezca y sheets/teclados se posicionen
///   correctamente.
/// - Pinta el banner en un `Stack` por encima cuando `adBannerConfig.show`.
/// - Si hay `floatingActionButton`, lo sube con un `Padding` equivalente
///   a la altura del banner.
///
/// Los `ScrollView` internos deben aplicar `bottomPaddingOf(ctx, ref)` como
/// padding inferior para que su último ítem quede por encima del banner.
class AdAwareScaffold extends ConsumerWidget {
  const AdAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  /// Altura total que el banner ocupa (contenedor + gap) cuando está visible.
  /// No incluye `safeBottom`.
  static double bannerSlot({required bool bannerVisible}) {
    if (!bannerVisible) return 0;
    return AdBanner.kBannerHeight + AdBanner.kBannerGap;
  }

  /// Padding inferior que los scrollables del `body` deben aplicar para que
  /// su último ítem quede por encima del banner.
  ///
  ///   safeBottom + bannerSlot(bannerVisible)
  static double bottomPaddingOf(BuildContext ctx, WidgetRef ref) {
    final safeBottom = MediaQuery.of(ctx).padding.bottom;
    final cfg = ref.watch(adBannerConfigProvider);
    final visible = cfg.show && cfg.unitId.isNotEmpty;
    return safeBottom + bannerSlot(bannerVisible: visible);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(adBannerConfigProvider);
    final visible = cfg.show && cfg.unitId.isNotEmpty;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final slot = bannerSlot(bannerVisible: visible);

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      appBar: appBar,
      bottomNavigationBar: SizedBox(height: safeBottom + slot),
      body: Stack(
        children: [
          body,
          if (visible)
            Positioned(
              left: 0,
              right: 0,
              bottom: safeBottom + AdBanner.kBannerGap,
              child: const AdBanner(key: Key('ad_banner')),
            ),
        ],
      ),
      floatingActionButton: floatingActionButton == null
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: slot),
              child: floatingActionButton,
            ),
    );
  }
}
