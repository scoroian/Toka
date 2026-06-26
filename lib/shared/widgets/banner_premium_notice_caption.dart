import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors_v2.dart';
import '../../l10n/app_localizations.dart';
import 'ad_banner_notice_provider.dart';

/// Caption fina y descartable que se pinta encima del banner SOLO para un
/// miembro no-pagador de un hogar Premium sin Toka Plus (la fila "Premium pero
/// con banner"). Explica por qué sigue viendo banner y ofrece quitarlo con Plus.
///
/// Va separada del anuncio por el gap del shell (política AdMob: sin solape ni
/// adyacencia que induzca clics accidentales). El shell decide mostrarla vía
/// [adBannerNoticeVisibleProvider]; este widget solo se renderiza cuando procede.
class BannerPremiumNoticeCaption extends ConsumerWidget {
  const BannerPremiumNoticeCaption({super.key});

  /// Altura visual de la caption. El shell reserva este alto (+ gap) para que no
  /// tape contenido ni FABs.
  static const double kNoticeHeight = 34;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight;
    final bd = isDark ? AppColorsV2.borderDark : AppColorsV2.borderLight;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          key: const Key('banner_premium_notice'),
          height: kNoticeHeight,
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bd),
          ),
          padding: const EdgeInsets.only(left: 10, right: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: InkWell(
                  key: const Key('banner_premium_notice_cta'),
                  onTap: () => context.push(AppRoutes.plusPaywall),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.ad_banner_notice_text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: scheme.primary),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('banner_premium_notice_dismiss'),
                tooltip: l10n.ad_banner_notice_dismiss,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close),
                onPressed: () => ref
                    .read(adBannerNoticeDismissedProvider.notifier)
                    .dismiss(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
