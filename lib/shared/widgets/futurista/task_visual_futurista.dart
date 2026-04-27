// lib/shared/widgets/futurista/task_visual_futurista.dart
//
// Render del visual de una tarea en skin futurista. Respeta el `visualKind`
// y `visualValue` que el usuario eligió en `CreateEditTaskScreen` (paridad
// con `taskVisualWidget` de v2) pero envuelto en un slot futurista (border
// cs.primary alpha + glow opcional + fondo translúcido).
//
// Reglas de fallback (en orden):
//   1. `visualKind == 'icon'` y `visualValue` parseable → Material Icon.
//   2. `visualKind == 'emoji'` y `visualValue` no vacío → emoji.
//   3. `fallbackGlyph` no nulo (legacy o derivado de recurrencia) → TaskGlyph.
//   4. Emoji por defecto `📋`.

import 'package:flutter/material.dart';

import 'task_glyph.dart';

class TaskVisualFuturista extends StatelessWidget {
  const TaskVisualFuturista({
    super.key,
    required this.visualKind,
    required this.visualValue,
    required this.color,
    this.size = 20,
    this.slotSize,
    this.slotRadius = 10,
    this.glow = false,
    this.fallbackGlyph,
    this.transparent = false,
  });

  /// 'icon' | 'emoji' | 'glyph' (legacy) | '' (vacío → fallback).
  final String visualKind;

  /// Material codePoint si kind=='icon'; emoji string si kind=='emoji';
  /// nombre de TaskGlyphKind si kind=='glyph'.
  final String visualValue;

  /// Color del icono / glyph / acento del slot.
  final Color color;

  /// Tamaño del icono dentro del slot.
  final double size;

  /// Tamaño del contenedor (slot). Si es null, no se pinta el contenedor —
  /// solo el icono (útil para hero cards donde el wrapper lo pinta el caller).
  final double? slotSize;

  final double slotRadius;
  final bool glow;

  /// Glyph que se pinta cuando no hay visual seleccionado (típicamente
  /// derivado de la recurrencia). Mantiene la identidad visual futurista
  /// de tareas creadas antes de añadir el picker de iconos.
  final TaskGlyphKind? fallbackGlyph;

  /// Cuando true, no pinta el fondo translúcido ni el border. Usado en
  /// pickers donde el slot ya tiene su propio styling.
  final bool transparent;

  Widget _buildContent() {
    if (visualKind == 'icon' && visualValue.isNotEmpty) {
      final cp = int.tryParse(visualValue);
      if (cp != null) {
        return Icon(
          IconData(cp, fontFamily: 'MaterialIcons'),
          size: size,
          color: color,
        );
      }
    }
    if (visualKind == 'emoji' && visualValue.isNotEmpty) {
      return Text(
        visualValue,
        style: TextStyle(fontSize: size * 0.95),
      );
    }
    if (visualKind == 'glyph' && visualValue.isNotEmpty) {
      // Legacy: tareas creadas durante el experimento de los 10 glifos.
      final kind = TaskGlyphKind.values
          .where((k) => k.name == visualValue)
          .cast<TaskGlyphKind?>()
          .firstWhere((_) => true, orElse: () => null);
      if (kind != null) {
        return TaskGlyph(kind: kind, color: color, size: size);
      }
    }
    if (fallbackGlyph != null) {
      return TaskGlyph(kind: fallbackGlyph!, color: color, size: size);
    }
    // Último recurso: emoji genérico, paridad con v2 fallback.
    return Text('📋', style: TextStyle(fontSize: size * 0.95));
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (slotSize == null) return content;

    final theme = Theme.of(context);
    if (transparent) {
      return SizedBox(
        width: slotSize,
        height: slotSize,
        child: Center(child: content),
      );
    }
    return Container(
      width: slotSize,
      height: slotSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(slotRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      foregroundDecoration: theme.brightness == Brightness.dark
          ? null
          : null, // hook por si añadimos efectos extra dependientes del modo
      child: Center(child: content),
    );
  }
}
