import 'package:flutter/material.dart';

enum TockaBtnVariant { primary, ghost, soft, glow, gold, danger }
enum TockaBtnSize { sm, md, lg }

/// Botón futurista con 6 variantes del canvas y 3 tamaños.
/// Wrapping de Material con estilo custom — usa InkWell para ripple.
class TockaBtn extends StatelessWidget {
  const TockaBtn({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = TockaBtnVariant.primary,
    this.size = TockaBtnSize.md,
    this.icon,
    this.fullWidth = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final TockaBtnVariant variant;
  final TockaBtnSize size;
  final Widget? icon;
  final bool fullWidth;

  ({double h, double px, double fs}) get _s => switch (size) {
        TockaBtnSize.sm => (h: 32, px: 12, fs: 13),
        TockaBtnSize.md => (h: 42, px: 16, fs: 14),
        TockaBtnSize.lg => (h: 52, px: 20, fs: 15),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final disabled = onPressed == null;
    final s = _s;

    late final Color bg;
    late final Color fg;
    late final Color border;
    Gradient? gradient;
    List<BoxShadow>? shadow;

    switch (variant) {
      case TockaBtnVariant.primary:
        bg = cs.primary;
        fg = cs.onPrimary;
        border = Colors.transparent;
        break;
      case TockaBtnVariant.ghost:
        bg = Colors.transparent;
        fg = cs.onSurface;
        border = cs.outline;
        break;
      case TockaBtnVariant.soft:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
        border = theme.dividerColor;
        break;
      case TockaBtnVariant.glow:
        bg = cs.primary;
        fg = cs.onPrimary;
        border = Colors.transparent;
        gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.primary, cs.primary.withValues(alpha: 0.87)],
        );
        shadow = [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];
        break;
      case TockaBtnVariant.gold:
        bg = const Color(0xFFF5B544);
        fg = const Color(0xFF1A1000);
        border = Colors.transparent;
        gradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5B544), Color(0xFFD97706)],
        );
        shadow = const [
          BoxShadow(
            color: Color(0x59F5B544),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ];
        break;
      case TockaBtnVariant.danger:
        bg = Colors.transparent;
        fg = cs.error;
        border = cs.error.withValues(alpha: 0.33);
        break;
    }

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: s.px),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme.merge(
              data: IconThemeData(color: fg, size: s.fs + 2),
              child: icon!,
            ),
            const SizedBox(width: 8),
          ],
          DefaultTextStyle.merge(
            style: TextStyle(
              color: fg,
              fontSize: s.fs,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
            child: child,
          ),
        ],
      ),
    );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: s.h,
            width: fullWidth ? double.infinity : null,
            decoration: BoxDecoration(
              color: gradient == null ? bg : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
              boxShadow: shadow,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
