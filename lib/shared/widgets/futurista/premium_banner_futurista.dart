import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import 'tocka_btn.dart';

/// Banner intercalado para usuarios free en history futurista.
/// Reusa los strings `history_premium_banner_*` de v2 con un look acorde
/// al lenguaje futurista (surfaceContainerHighest + border primary muted).
class PremiumBannerFuturista extends StatelessWidget {
  const PremiumBannerFuturista({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('premium_banner_futurista'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lock, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.history_premium_banner_title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.history_premium_banner_body,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TockaBtn(
            key: const Key('premium_banner_futurista_cta'),
            variant: TockaBtnVariant.primary,
            size: TockaBtnSize.md,
            fullWidth: true,
            onPressed: () => context.push(AppRoutes.paywall),
            child: Text(l10n.history_premium_banner_cta),
          ),
        ],
      ),
    );
  }
}
