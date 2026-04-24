import 'package:flutter/material.dart';

import 'task_glyph.dart';
import 'tocka_avatar.dart';

/// Tarjeta de tarea futurista. Estados: mine (glow + check btn), done (tachado),
/// urgent (warning color), overdue (danger en when).
class TaskCardFuturista extends StatelessWidget {
  const TaskCardFuturista({
    super.key,
    required this.title,
    required this.assignee,
    required this.assigneeColor,
    this.when,
    this.done = false,
    this.glyph = TaskGlyphKind.ring,
    this.urgent = false,
    this.overdue = false,
    this.mine = false,
    this.compact = false,
    this.onTap,
    this.onComplete,
  });

  final String title;
  final String assignee;
  final Color assigneeColor;
  final String? when;
  final bool done;
  final TaskGlyphKind glyph;
  final bool urgent;
  final bool overdue;
  final bool mine;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color glyphColor;
    if (urgent) {
      glyphColor = const Color(0xFFF5B544); // warning
    } else if (mine) {
      glyphColor = cs.primary;
    } else {
      glyphColor = cs.onSurfaceVariant;
    }

    final borderColor = (mine && !done)
        ? cs.primary.withValues(alpha: 0.25)
        : theme.dividerColor;

    final bgColor = done ? Colors.transparent : cs.surface;

    final shadow = (mine && !done)
        ? [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.15),
              blurRadius: 0,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ]
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: shadow,
          ),
          child: Row(
            children: [
              _leftSlot(context, glyphColor),
              const SizedBox(width: 12),
              Expanded(child: _center(context)),
              const SizedBox(width: 8),
              _rightSlot(context, cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftSlot(BuildContext context, Color glyphColor) {
    if (done) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Icon(Icons.check, color: Color(0xFF34D399), size: 20),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: glyphColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: glyphColor.withValues(alpha: 0.19),
          width: 1,
        ),
      ),
      child: Center(
        child: TaskGlyph(kind: glyph, color: glyphColor, size: 22),
      ),
    );
  }

  Widget _center(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            color: cs.onSurface,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: cs.onSurface.withValues(alpha: 0.22),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              done ? 'Hecho por ' : 'Toca a ',
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
            ),
            TockaAvatar(name: assignee, color: assigneeColor, size: 16),
            const SizedBox(width: 5),
            Text(
              assignee,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            if (when != null) ...[
              const SizedBox(width: 6),
              Text(
                '· $when',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'JetBrainsMono',
                  letterSpacing: 0.2,
                  color: overdue
                      ? cs.error
                      : cs.onSurface.withValues(alpha: 0.42),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _rightSlot(BuildContext context, ColorScheme cs) {
    if (done) return const SizedBox.shrink();
    if (mine) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onComplete,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cs.primary, cs.primary.withValues(alpha: 0.87)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.check, color: cs.onPrimary, size: 20),
          ),
        ),
      );
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Icon(
        Icons.lock_outline,
        size: 14,
        color: cs.onSurface.withValues(alpha: 0.22),
      ),
    );
  }
}
