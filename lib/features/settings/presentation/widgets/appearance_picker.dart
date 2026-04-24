import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_skin.dart';
import '../../../../core/theme/futurista/futurista_colors.dart';
import '../../../../core/theme/futurista/futurista_tokens.dart';
import '../../../../core/theme/skin_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Selector visual del skin de la app. Dos cards lado a lado (v2 / futurista);
/// al tocar una, [skinModeProvider] cambia y la app se retematiza en caliente.
class AppearancePicker extends ConsumerWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(skinModeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (final skin in AppSkin.values) ...[
            Expanded(
              child: _SkinCard(
                skin: skin,
                selected: current == skin,
                onTap: () =>
                    ref.read(skinModeProvider.notifier).set(skin),
              ),
            ),
            if (skin != AppSkin.values.last) const SizedBox(width: 12),
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
    required this.onTap,
  });

  final AppSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, description) = switch (skin) {
      AppSkin.v2 => (l10n.skinClassicLabel, l10n.skinClassicDescription),
      AppSkin.futurista =>
        (l10n.skinFuturistaLabel, l10n.skinFuturistaDescription),
    };
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
            boxShadow:
                (selected && skin == AppSkin.futurista) ? FShadows.glowCyan : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniPreview(skin: skin),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (selected)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini preview del skin — pinta 2 swatches + una barra simulada de texto.
/// Los colores aquí SON hardcodeados a propósito: esta preview representa el
/// skin contrario al activo (excepción documentada a la regla "sin colores
/// hardcodeados nuevos").
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
      AppSkin.futurista => (
          FuturistaColors.bg0,
          FuturistaColors.primary,
          FuturistaColors.bg2,
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
