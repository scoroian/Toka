import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'task_glyph.dart';
import 'task_visual_futurista.dart';
import 'tocka_avatar.dart';
import 'tocka_btn.dart';

/// Tarjeta de tarea futurista. Estados: mine (glow + fila inferior con
/// [Hecho][Pasar]), done (tachado), urgent (warning color), overdue (danger).
///
/// Cuando `mine && !done`, debajo del row principal aparece una fila con dos
/// botones: `TockaBtn glow lg fullWidth icon=check` (Hecho) + `TockaBtn ghost
/// lg icon=swap_horiz` (Pasar). El botón Hecho aplica gating: si `actionable`
/// es false, se renderiza con icono `lock_clock` y al pulsarlo invoca
/// `onActionableHint` en vez de `onComplete`. La card NO conoce
/// `task.nextDueAt` ni `recurrenceType`, así que el cálculo de `actionable`
/// y el formato del SnackBar viven en el consumidor.
///
/// `onTap` representa "tap general en la card" (para navegar al detalle).
/// Es independiente de `onComplete`/`onPass`.
class TaskCardFuturista extends StatelessWidget {
  const TaskCardFuturista({
    super.key,
    required this.title,
    required this.assignee,
    required this.assigneeColor,
    this.when,
    this.done = false,
    this.glyph = TaskGlyphKind.ring,
    this.visualKind = '',
    this.visualValue = '',
    this.urgent = false,
    this.overdue = false,
    this.mine = false,
    this.compact = false,
    this.actionable = true,
    this.onTap,
    this.onComplete,
    this.onPass,
    this.onActionableHint,
    this.doneLabel,
  });

  final String title;
  final String assignee;
  final Color assigneeColor;
  final String? when;
  final bool done;
  // Glyph derivado de la recurrencia. Solo se usa como FALLBACK cuando el
  // usuario no eligió un visual propio (visualKind/visualValue vacíos).
  final TaskGlyphKind glyph;
  // Visual elegido por el usuario en el form (paridad con v2): 'icon' con
  // codePoint Material, o 'emoji' con string. Si está vacío, se usa `glyph`.
  final String visualKind;
  final String visualValue;
  final bool urgent;
  final bool overdue;
  final bool mine;
  final bool compact;
  final bool actionable;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onPass;
  final VoidCallback? onActionableHint;
  final String? doneLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color glyphColor;
    if (urgent) {
      glyphColor = const Color(0xFFF5B544);
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

    final showButtonsRow = mine && !done;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _leftSlot(context, glyphColor),
                  const SizedBox(width: 12),
                  Expanded(child: _center(context)),
                  if (!showButtonsRow) ...[
                    const SizedBox(width: 8),
                    _rightSlotForNonOwn(context, cs),
                  ],
                ],
              ),
              if (showButtonsRow) ...[
                const SizedBox(height: 12),
                _buttonsRow(context, cs),
              ],
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
    // TaskVisualFuturista pinta su propio slot (border + bg) y respeta el
    // visualKind del usuario; si está vacío, cae al glyph derivado de
    // recurrencia. Mantiene 100% la estética anterior cuando no hay visual.
    return TaskVisualFuturista(
      visualKind: visualKind,
      visualValue: visualValue,
      color: glyphColor,
      size: 22,
      slotSize: 44,
      slotRadius: 12,
      fallbackGlyph: glyph,
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
              done
                  ? '${AppLocalizations.of(context).task_card_done_by} '
                  : '${AppLocalizations.of(context).task_card_assigned_to} ',
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

  Widget _rightSlotForNonOwn(BuildContext context, ColorScheme cs) {
    if (done) return const SizedBox.shrink();
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

  Widget _buttonsRow(BuildContext context, ColorScheme cs) {
    final isLocked = !actionable;
    final label = doneLabel ?? AppLocalizations.of(context).today_btn_done;
    return Row(
      children: [
        Expanded(
          child: TockaBtn(
            key: const Key('task_card_done_btn'),
            variant: isLocked ? TockaBtnVariant.ghost : TockaBtnVariant.glow,
            size: TockaBtnSize.lg,
            fullWidth: true,
            icon: Icon(isLocked ? Icons.lock_clock : Icons.check),
            onPressed: isLocked ? onActionableHint : onComplete,
            child: Text(label),
          ),
        ),
        const SizedBox(width: 8),
        TockaBtn(
          key: const Key('task_card_pass_btn'),
          variant: TockaBtnVariant.ghost,
          size: TockaBtnSize.lg,
          onPressed: onPass,
          child: const Icon(Icons.swap_horiz),
        ),
      ],
    );
  }
}
