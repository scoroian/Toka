import 'package:flutter/material.dart';

/// Chip de filtro futurista. Active usa primary con opacidad sobre bg + border
/// primary; inactive usa bg transparente + dividerColor.
class TockaChip extends StatelessWidget {
  const TockaChip({
    super.key,
    required this.child,
    this.active = false,
    this.onTap,
  });

  final Widget child;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = active
        ? cs.primary.withValues(alpha: 0.09)
        : Colors.transparent;
    final borderColor = active
        ? cs.primary.withValues(alpha: 0.33)
        : theme.dividerColor;
    final fg = active ? cs.primary : cs.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.05,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: fg, size: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [child],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
