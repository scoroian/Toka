import 'package:flutter/material.dart';

/// Pill / badge futurista. Fondo translúcido del color o neutro del theme,
/// border sutil y opción de `glow` con sombra del mismo color.
///
/// Uso: `TockaPill(child: Text('Te toca'), color: Colors.cyan, glow: true)`.
class TockaPill extends StatelessWidget {
  const TockaPill({
    super.key,
    required this.child,
    this.color,
    this.glow = false,
  });

  final Widget child;
  final Color? color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = color ?? theme.colorScheme.onSurfaceVariant;
    final bgColor = color != null
        ? color!.withValues(alpha: 0.13)
        : theme.colorScheme.surfaceContainerHighest;
    final borderColor = color != null
        ? color!.withValues(alpha: 0.19)
        : theme.dividerColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: resolved.withValues(alpha: 0.2),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: color != null ? resolved : theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: color != null ? resolved : theme.colorScheme.onSurfaceVariant,
              size: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [child],
            ),
          ),
        ),
      ),
    );
  }
}
