import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/theme/app_skin.dart';
import '../../../../core/theme/effective_skin_provider.dart';
import '../../../../core/theme/skin_catalog.dart';
import '../../../../core/theme/skin_provider.dart';
import '../../../../features/subscription/application/plus_provider.dart';
import '../../../../features/subscription/application/toka_plus_enabled_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Selector visual del skin de la app. Pinta una card por cada [AppSkin]
/// visible; al tocar una disponible, [skinModeProvider] cambia y la app se
/// retematiza en caliente.
///
/// Gating de Toka Plus:
/// - Con `toka_plus_enabled` OFF NO se listan skins Plus (nadie ve features
///   Plus).
/// - Con el flag ON pero sin Plus, las skins Plus se muestran como PREVIEW
///   bloqueada (candado + "Requiere Toka Plus"); tocarlas abre el paywall de
///   Plus en vez de seleccionarlas.
/// - Con Plus activo se pueden seleccionar como cualquier otra.
class AppearancePicker extends ConsumerWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effective = ref.watch(effectiveSkinProvider);
    final plusEnabled = ref.watch(tokaPlusEnabledProvider);
    final hasPlus = ref.watch(plusActiveProvider);

    final visibleSkins = <AppSkin>[
      for (final skin in AppSkin.values)
        if (plusEnabled || !isPlusSkin(skin)) skin,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final skin in visibleSkins) ...[
            Expanded(
              child: _SkinCard(
                skin: skin,
                selected: effective == skin,
                locked: isPlusSkin(skin) && !hasPlus,
                onTap: () {
                  if (isPlusSkin(skin) && !hasPlus) {
                    context.push(AppRoutes.plusPaywall);
                  } else {
                    ref.read(skinModeProvider.notifier).set(skin);
                  }
                },
              ),
            ),
            if (skin != visibleSkins.last) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final AppSkin skin;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, description) = switch (skin) {
      AppSkin.v2 => (l10n.skinClassicLabel, l10n.skinClassicDescription),
      AppSkin.oceano => (l10n.skinOceanoLabel, l10n.skinOceanoDescription),
    };
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '$label — ${l10n.plusLockedBadge}' : label,
      child: InkWell(
        key: Key('skin_card_${skin.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Opacity(
                    opacity: locked ? 0.55 : 1,
                    child: _MiniPreview(skin: skin),
                  ),
                  if (locked)
                    Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.lock_outline,
                          key: Key('skin_lock_${skin.name}'),
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(description, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              if (selected)
                Icon(Icons.check_circle,
                    size: 18, color: theme.colorScheme.primary)
              else if (locked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.plusLockedBadge,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini preview del skin — pinta 2 swatches + una barra simulada de texto.
/// Los colores aquí SON hardcodeados a propósito (excepción documentada).
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.skin});
  final AppSkin skin;

  @override
  Widget build(BuildContext context) {
    final (bg, accent, surface) = switch (skin) {
      AppSkin.v2 => (
          const Color(0xFFF9F9F7),
          const Color(0xFFF4845F),
          const Color(0xFFFFFFFF),
        ),
      AppSkin.oceano => (
          const Color(0xFFF3F7FD),
          const Color(0xFF2E6BE6),
          const Color(0xFFFFFFFF),
        ),
    };

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 6, width: 40, color: surface),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  width: 60,
                  color: surface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
