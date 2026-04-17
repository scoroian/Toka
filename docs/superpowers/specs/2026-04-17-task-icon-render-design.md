# Spec: Renderizado correcto de iconos de tareas (Bugs #37 y #38)

**Fecha:** 2026-04-17
**Estado:** Aprobado
**Bugs:** #37 (preview con fondo naranja + icono hardcoded), #38 (codepoint numérico visible en tarjeta y detalle)

---

## Contexto

Las tareas pueden tener como visual un emoji (`kind = 'emoji'`) o un icono Material (`kind = 'icon'`). Cuando se elige un icono, se guarda su `codePoint` como string (ej. `"58206"`) en Firestore como `visualValue`. Este valor no se convierte correctamente en un `IconData` al renderizar.

Hay dos bugs relacionados:

- **Bug #37:** El preview en `TaskVisualPicker` siempre muestra fondo `primaryContainer` (naranja) y el icono `Icons.task_alt` hardcodeado, ignorando el icono seleccionado.
- **Bug #38:** En `TodayTaskCardTodoV2` y `TaskDetailScreenV2`, el visual se renderiza como `Text(task.visualValue)`, lo que muestra la cadena numérica cruda (ej. `"57405 Fregar platos"`) en vez del icono.

---

## Solución

### 1. Función helper compartida: `taskVisualWidget`

Crear una función pura en `lib/features/tasks/presentation/utils/task_visual_utils.dart`:

```dart
import 'package:flutter/material.dart';

/// Devuelve el widget visual apropiado para una tarea.
/// [kind] es 'emoji' o 'icon'.
/// [value] es el emoji string o el codePoint como string.
/// [size] controla el tamaño.
Widget taskVisualWidget(String kind, String value, {double size = 22}) {
  if (kind == 'icon' && value.isNotEmpty) {
    final cp = int.tryParse(value);
    if (cp != null) {
      return Icon(
        IconData(cp, fontFamily: 'MaterialIcons'),
        size: size,
      );
    }
  }
  // Fallback: emoji o valor desconocido
  return Text(value.isNotEmpty ? value : '📋',
      style: TextStyle(fontSize: size * 0.9));
}
```

Esta función se usará en los tres puntos de renderizado.

### 2. Corregir el preview en `TaskVisualPicker`

**Archivo:** `lib/features/tasks/presentation/widgets/task_visual_picker.dart`

Cambiar el bloque del preview (líneas 72–88) para:
- Eliminar el fondo `primaryContainer` cuando el kind es `icon` (usar `Colors.transparent`).
- Renderizar el icono real seleccionado usando `taskVisualWidget`.

```dart
// Antes:
Center(
  child: Container(
    width: 64, height: 64,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: widget.selectedKind == 'emoji'
          ? Text(widget.selectedValue, style: const TextStyle(fontSize: 32))
          : Icon(Icons.task_alt, size: 36,
              color: Theme.of(context).colorScheme.onPrimaryContainer),
    ),
  ),
),

// Después:
Center(
  child: Container(
    width: 64, height: 64,
    decoration: BoxDecoration(
      color: widget.selectedKind == 'emoji'
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: taskVisualWidget(widget.selectedKind, widget.selectedValue, size: 36),
    ),
  ),
),
```

### 3. Corregir `TodayTaskCardTodoV2`

**Archivo:** `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart`

Línea 195: reemplazar el `Text` que muestra el visual + título concatenados por un `Row` que separa el visual del título:

```dart
// Antes (línea 195):
Text('${widget.task.visualValue} ${widget.task.title}', ...)

// Después:
Row(children: [
  taskVisualWidget(widget.task.visualKind, widget.task.visualValue, size: 16),
  const SizedBox(width: 4),
  Expanded(
    child: Text(widget.task.title,
      style: GoogleFonts.plusJakartaSans(...),
      overflow: TextOverflow.ellipsis,
    ),
  ),
]),
```

### 4. Corregir `TaskDetailScreenV2`

**Archivo:** `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart`

Línea 99: reemplazar `Text(task.visualValue, ...)` por la helper:

```dart
// Antes (línea 99):
Text(task.visualValue, style: const TextStyle(fontSize: 36)),

// Después:
taskVisualWidget(task.visualKind, task.visualValue, size: 36),
```

---

## Archivos afectados

| Archivo | Acción |
|---|---|
| `lib/features/tasks/presentation/utils/task_visual_utils.dart` | Crear nuevo |
| `lib/features/tasks/presentation/widgets/task_visual_picker.dart` | Modificar preview (líneas 72-88) |
| `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart` | Modificar línea 195 |
| `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` | Modificar línea 99 |

---

## Tests requeridos

### Unitarios
- `taskVisualWidget('emoji', '🏠')` devuelve un `Text` con el emoji.
- `taskVisualWidget('icon', '57405')` devuelve un `Icon` con `codePoint == 57405`.
- `taskVisualWidget('icon', 'no-es-numero')` devuelve un `Text` con fallback '📋'.
- `taskVisualWidget('icon', '')` devuelve un `Text` con fallback '📋'.

### Widget
- `TaskVisualPicker` con `selectedKind = 'icon'` y `selectedValue = '57405'`: el preview muestra un `Icon` y **no** tiene fondo de color `primaryContainer`.
- `TaskVisualPicker` con `selectedKind = 'emoji'` y `selectedValue = '🍳'`: el preview muestra el emoji con fondo `primaryContainer`.
- `TodayTaskCardTodoV2` con una tarea de `visualKind = 'icon'`, `visualValue = '57405'`: título visible sin texto numérico.
- `TaskDetailScreenV2` con `visualKind = 'icon'`, `visualValue = '57405'`: renderiza un `Icon`, no un `Text`.
