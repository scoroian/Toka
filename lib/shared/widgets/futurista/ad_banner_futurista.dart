import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ad_banner_config_provider.dart';

/// Banner AdMob maqueta visual en look futurista. Lee `adBannerConfigProvider`
/// para decidir si mostrar. La integración con el SDK real se hace en
/// una iteración posterior reutilizando la infraestructura de `ad_banner.dart`.
class AdBannerFuturista extends ConsumerWidget {
  const AdBannerFuturista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(adBannerConfigProvider);
    if (!config.show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF34D399), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Ao',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Anuncio · AdMob',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'JetBrainsMono',
                        letterSpacing: 0.6,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aora — Organiza tu casa 10× más rápido',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Instalar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          left: 6,
          child: Text(
            'AD',
            style: TextStyle(
              fontSize: 8.5,
              fontFamily: 'JetBrainsMono',
              letterSpacing: 0.4,
              color: cs.onSurface.withValues(alpha: 0.22),
            ),
          ),
        ),
      ],
    );
  }
}
