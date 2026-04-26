# Skin Futurista 2F · Cleanup paridad y SSoT padding · Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deduplicar `_isActionable`/`_formatDueForMessage` y `_showRateSheet` (vivían en v2 y futurista), y migrar 10 pantallas futurista con bottom padding hardcodeado al helper centralizado `adAwareBottomPadding`.

**Architecture:** `TaskActionability` se introduce como utility class pure-static en `lib/features/tasks/domain/`. `showRateSheet` se introduce como función top-level en `lib/features/history/presentation/widgets/`. Ambos consumidores v2 y futurista llaman a las nuevas APIs. Las 10 pantallas migradas reemplazan literales `24`/`32` por `adAwareBottomPadding(context, ref, extra: 16)`.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod, GoRouter, `flutter_test`. Sin nuevas dependencias.

**Spec:** [docs/superpowers/specs/2026-04-26-skin-futurista-2f-design.md](../specs/2026-04-26-skin-futurista-2f-design.md)

---

## File map

### Crear (3)

- `lib/features/tasks/domain/task_actionability.dart` — clase `TaskActionability` con dos `static`: `isActionable(TaskPreview, {DateTime? now})` y `formatDueForMessage(TaskPreview, Locale)`.
- `lib/features/history/presentation/widgets/show_rate_sheet.dart` — función top-level `showRateSheet(BuildContext, HistoryViewModel, TaskEventItem)`.
- `test/unit/features/tasks/domain/task_actionability_test.dart` — 12 tests puros (`test()`, no `testWidgets()`).

### Modificar (14)

**Helpers (4):**
- `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart`
- `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`
- `lib/features/history/presentation/skins/history_screen_v2.dart`
- `lib/features/history/presentation/skins/futurista/history_screen_futurista.dart`

**Paddings (10):**
- `lib/features/homes/presentation/skins/futurista/home_settings_screen_futurista.dart` (línea 160, bottom 24)
- `lib/features/homes/presentation/skins/futurista/my_homes_screen_futurista.dart` (línea 78, bottom 24)
- `lib/features/members/presentation/skins/futurista/vacation_screen_futurista.dart` (línea 147, bottom 32)
- `lib/features/notifications/presentation/skins/futurista/notification_settings_screen_futurista.dart` (línea 102, bottom 24)
- `lib/features/subscription/presentation/skins/futurista/subscription_management_screen_futurista.dart` (línea 92, bottom 24)
- `lib/features/subscription/presentation/skins/futurista/paywall_screen_futurista.dart` (línea 77, bottom 32)
- `lib/features/subscription/presentation/skins/futurista/rescue_screen_futurista.dart` (línea 55, bottom 32)
- `lib/features/profile/presentation/skins/futurista/profile_screen_futurista.dart` (línea 382, bottom 32)
- `lib/features/profile/presentation/skins/futurista/edit_profile_screen_futurista.dart` (línea 167, bottom 32)
- `lib/features/tasks/presentation/skins/futurista/create_edit_task_screen_futurista.dart` (línea 214, bottom 32)

(Líneas aproximadas — el implementer localiza por contenido si se mueven.)

---

## Task 1: Extracción de helpers (Ola 1)

**Files:**
- Create: `lib/features/tasks/domain/task_actionability.dart`
- Create: `lib/features/history/presentation/widgets/show_rate_sheet.dart`
- Create: `test/unit/features/tasks/domain/task_actionability_test.dart`
- Modify: `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart`
- Modify: `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`
- Modify: `lib/features/history/presentation/skins/history_screen_v2.dart`
- Modify: `lib/features/history/presentation/skins/futurista/history_screen_futurista.dart`

### Step 1.1: Escribir test fallido para `TaskActionability`

- [ ] Crear archivo `test/unit/features/tasks/domain/task_actionability_test.dart`:

```dart
import 'dart:ui' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/domain/task_actionability.dart';

TaskPreview _t({
  required String recurrence,
  required DateTime due,
}) =>
    TaskPreview(
      taskId: 't1',
      title: 'Test task',
      currentAssigneeUid: null,
      currentAssigneeName: null,
      currentAssigneePhoto: null,
      nextDueAt: due,
      isOverdue: due.isBefore(DateTime.now()),
      recurrenceType: recurrence,
      visualKind: 'icon',
      visualValue: 'task',
    );

void main() {
  const es = Locale('es');

  group('TaskActionability.isActionable', () {
    test('overdue is always actionable', () {
      final t = _t(
        recurrence: 'weekly',
        due: DateTime(2026, 1, 1, 10, 0),
      );
      expect(
        TaskActionability.isActionable(t, now: DateTime(2026, 4, 26, 12, 0)),
        isTrue,
      );
    });

    test('hourly: due in current hour is actionable', () {
      final now = DateTime(2026, 4, 26, 14, 30);
      final t = _t(recurrence: 'hourly', due: DateTime(2026, 4, 26, 14, 45));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('hourly: due in next hour is NOT actionable', () {
      final now = DateTime(2026, 4, 26, 14, 30);
      final t = _t(recurrence: 'hourly', due: DateTime(2026, 4, 26, 15, 5));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('daily: due today is actionable', () {
      final now = DateTime(2026, 4, 26, 8, 0);
      final t = _t(recurrence: 'daily', due: DateTime(2026, 4, 26, 22, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('daily: due tomorrow is NOT actionable', () {
      final now = DateTime(2026, 4, 26, 8, 0);
      final t = _t(recurrence: 'daily', due: DateTime(2026, 4, 27, 1, 0));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('weekly: due this ISO week is actionable', () {
      // 2026-04-26 is Sunday (weekday 7). Week spans 2026-04-20..04-26.
      final now = DateTime(2026, 4, 22, 10, 0); // Wednesday
      final t = _t(recurrence: 'weekly', due: DateTime(2026, 4, 26, 23, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('weekly: due next week is NOT actionable', () {
      final now = DateTime(2026, 4, 22, 10, 0);
      final t = _t(recurrence: 'weekly', due: DateTime(2026, 4, 27, 1, 0));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('monthly: due this month is actionable', () {
      final now = DateTime(2026, 4, 5, 10, 0);
      final t = _t(recurrence: 'monthly', due: DateTime(2026, 4, 28, 12, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('monthly: due next month is NOT actionable', () {
      final now = DateTime(2026, 4, 5, 10, 0);
      final t = _t(recurrence: 'monthly', due: DateTime(2026, 5, 1, 0, 0));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('yearly: due this year is actionable', () {
      final now = DateTime(2026, 4, 5, 10, 0);
      final t = _t(recurrence: 'yearly', due: DateTime(2026, 12, 31, 23, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('yearly: due next year is NOT actionable', () {
      final now = DateTime(2026, 4, 5, 10, 0);
      final t = _t(recurrence: 'yearly', due: DateTime(2027, 1, 1, 0, 0));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('default (oneTime / unknown): behaves like daily', () {
      final now = DateTime(2026, 4, 26, 8, 0);
      final t = _t(recurrence: 'oneTime', due: DateTime(2026, 4, 26, 22, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
      final t2 = _t(recurrence: 'unknown', due: DateTime(2026, 4, 27, 1, 0));
      expect(TaskActionability.isActionable(t2, now: now), isFalse);
    });
  });

  group('TaskActionability.formatDueForMessage', () {
    test('hourly: returns short time only', () {
      final t = _t(recurrence: 'hourly', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      // El formato exacto depende de TokaDates.timeShort; al menos contiene "14"
      expect(out, contains('14'));
    });

    test('daily: returns weekday + date + time', () {
      final t = _t(recurrence: 'daily', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      // Contiene un separador y la hora
      expect(out, contains('·'));
    });

    test('weekly: returns weekday + date (no time)', () {
      final t = _t(recurrence: 'weekly', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      // No contiene separador "·" ni los dos puntos del time
      expect(out, isNot(contains(':')));
    });

    test('monthly: returns long day-month format', () {
      final t = _t(recurrence: 'monthly', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      expect(out, isNotEmpty);
    });

    test('yearly: returns month-year format', () {
      final t = _t(recurrence: 'yearly', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      expect(out, isNotEmpty);
    });
  });
}
```

### Step 1.2: Verificar que el test falla

Run: `flutter test test/unit/features/tasks/domain/task_actionability_test.dart`
Expected: FAIL — "Target of URI doesn't exist: 'package:toka/features/tasks/domain/task_actionability.dart'".

### Step 1.3: Crear `task_actionability.dart`

- [ ] Crear archivo `lib/features/tasks/domain/task_actionability.dart`:

```dart
import 'dart:ui' show Locale;

import '../../../core/utils/toka_dates.dart';
import 'home_dashboard.dart' show TaskPreview;

/// Lógica de actionability + formato de mensaje "vence el {fecha}" para
/// tareas. Compartida entre la skin v2 (`TodayTaskCardTodoV2`) y la skin
/// futurista (`TodayScreenFuturista`).
///
/// Pure-static: no estado, no providers, no dependencias UI más allá de
/// `Locale` (para `intl`). Testeable con `test()` puro sin widget tester.
class TaskActionability {
  TaskActionability._();

  /// Determina si la tarea puede completarse ahora según su tipo de
  /// recurrencia. Reglas:
  /// - Tareas vencidas (due < now) son siempre actionable.
  /// - hourly: due cae en la hora actual.
  /// - daily: due cae hoy.
  /// - weekly: due cae en la semana ISO actual (lunes-domingo).
  /// - monthly: due cae en el mes actual.
  /// - yearly: due cae en el año actual.
  /// - oneTime / desconocido: equivalente a daily.
  static bool isActionable(TaskPreview t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final due = t.nextDueAt;
    if (due.isBefore(n)) return true;
    switch (t.recurrenceType) {
      case 'hourly':
        return due.isBefore(DateTime(n.year, n.month, n.day, n.hour + 1));
      case 'daily':
        return due.isBefore(DateTime(n.year, n.month, n.day + 1));
      case 'weekly':
        final daysFromMonday = n.weekday - 1;
        final weekStart = DateTime(n.year, n.month, n.day - daysFromMonday);
        return due.isBefore(weekStart.add(const Duration(days: 7)));
      case 'monthly':
        return due.isBefore(DateTime(n.year, n.month + 1, 1));
      case 'yearly':
        return due.isBefore(DateTime(n.year + 1, 1, 1));
      default:
        return due.isBefore(DateTime(n.year, n.month, n.day + 1));
    }
  }

  /// Formato del mensaje "vence el {fecha}" según el tipo de recurrencia.
  /// Devuelve la cadena que se inyecta en `l10n.today_hecho_not_yet(date)`.
  static String formatDueForMessage(TaskPreview t, Locale locale) {
    final due = t.nextDueAt.toLocal();
    switch (t.recurrenceType) {
      case 'hourly':
        return TokaDates.timeShort(due, locale);
      case 'daily':
        return '${TokaDates.dateMediumWithWeekday(due, locale)} · '
            '${TokaDates.timeShort(due, locale)}';
      case 'weekly':
        return TokaDates.dateMediumWithWeekday(due, locale);
      case 'monthly':
        return TokaDates.dateLongDayMonth(due, locale);
      case 'yearly':
        return TokaDates.monthYearLong(due, locale);
      default:
        return '${TokaDates.dateMediumWithWeekday(due, locale)} · '
            '${TokaDates.timeShort(due, locale)}';
    }
  }
}
```

### Step 1.4: Verificar que los tests pasan

Run: `flutter test test/unit/features/tasks/domain/task_actionability_test.dart`
Expected: 12 tests verdes.

Si el helper `_t` (TaskPreview) requiere campos distintos en el constructor, abrir `lib/features/tasks/domain/home_dashboard.dart`, ajustar y re-correr. La firma exacta de `TaskPreview` puede tener más campos (p. ej. `recurrenceType` puede llamarse distinto). Si la firma cambia, ajustar `_t()` para usar los nombres reales.

### Step 1.5: Crear `show_rate_sheet.dart`

- [ ] Crear archivo `lib/features/history/presentation/widgets/show_rate_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../application/history_view_model.dart';
import 'rate_event_sheet.dart';

/// Abre el bottom sheet de valoración para un evento del historial.
/// Función top-level compartida por la skin v2 y la futurista — el sheet en
/// sí (`RateEventSheet`) es el mismo en ambas skins.
Future<void> showRateSheet(
  BuildContext ctx,
  HistoryViewModel vm,
  TaskEventItem item,
) {
  return showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    builder: (_) => RateEventSheet(
      onSubmit: (rating, note) =>
          vm.rateEvent(item.raw.id, rating, note: note),
    ),
  );
}
```

### Step 1.6: Migrar `today_task_card_todo_v2.dart`

- [ ] Editar `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart`. Añadir import al inicio:

```dart
import '../../../domain/task_actionability.dart';
```

- [ ] Eliminar el método privado `_isActionable()` completo (aprox líneas 65-94).
- [ ] Eliminar el método privado `_formatDueForMessage(BuildContext context)` completo (aprox líneas 96-115).
- [ ] Localizar la única invocación de `_isActionable()` (dentro de `build`, aprox línea 164: `final actionable = _isActionable();`) y reemplazar por:

```dart
final actionable = TaskActionability.isActionable(
  widget.task,
  now: widget.now,
);
```

- [ ] Localizar `_handleDoneNotReady` (aprox línea 128) y dentro reemplazar `final dateStr = _formatDueForMessage(context);` por:

```dart
final dateStr = TaskActionability.formatDueForMessage(
  widget.task,
  Localizations.localeOf(context),
);
```

### Step 1.7: Migrar `today_screen_futurista.dart`

- [ ] Editar `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`. Añadir import:

```dart
import '../../../domain/task_actionability.dart';
```

- [ ] Eliminar los 2 helpers privados `_isActionable(TaskPreview t, {DateTime? now})` y `_formatDueForMessage(BuildContext context, TaskPreview t)` (añadidos en 2E, al final de la clase `TodayScreenFuturista`).
- [ ] Mantener el helper `_snackNotYet(BuildContext ctx, AppLocalizations l10n, TaskPreview t)`. Reemplazar su body por:

```dart
void _snackNotYet(BuildContext ctx, AppLocalizations l10n, TaskPreview t) {
  final dateStr = TaskActionability.formatDueForMessage(
    t,
    Localizations.localeOf(ctx),
  );
  ScaffoldMessenger.of(ctx)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(l10n.today_hecho_not_yet(dateStr)),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
}
```

- [ ] Localizar el `itemBuilder` dentro de `_recurrenceBlock` (línea ~230) y cambiar:

```dart
final actionable = _isActionable(t);
```

por:

```dart
final actionable = TaskActionability.isActionable(t);
```

- [ ] Eliminar el import `core/utils/toka_dates.dart` si ya no se usa directamente.

### Step 1.8: Migrar `history_screen_v2.dart`

- [ ] Editar `lib/features/history/presentation/skins/history_screen_v2.dart`. Añadir import:

```dart
import '../widgets/show_rate_sheet.dart';
```

- [ ] Eliminar el método privado `_showRateSheet(TaskEventItem item, HistoryViewModel vm)` completo (aprox líneas 177-185 — la firma original es:
  ```dart
  void _showRateSheet(TaskEventItem item, HistoryViewModel vm) { ... }
  ```
  Y solo abre `showModalBottomSheet` con `RateEventSheet`).

- [ ] Localizar la única invocación dentro de `_buildTile` (aprox línea 137):
  ```dart
  onPressed: () => _showRateSheet(item, vm),
  ```
  Reemplazar por:
  ```dart
  onPressed: () => showRateSheet(context, vm, item),
  ```

### Step 1.9: Migrar `history_screen_futurista.dart`

- [ ] Editar `lib/features/history/presentation/skins/futurista/history_screen_futurista.dart`. Añadir import:

```dart
import '../../widgets/show_rate_sheet.dart';
```

- [ ] Eliminar el método privado `_showRateSheet(BuildContext ctx, HistoryViewModel vm, TaskEventItem item)` completo.
- [ ] Localizar la invocación en el `itemBuilder` y la propagación a `_DayGroup.onRate`:
  ```dart
  onRate: (item) => _showRateSheet(ctx, vm, item),
  ```
  Reemplazar por:
  ```dart
  onRate: (item) => showRateSheet(ctx, vm, item),
  ```

### Step 1.10: Run tests verdes

Run: `flutter test`
Expected: todos verdes incluyendo:
- 12 nuevos tests en `task_actionability_test.dart`.
- Tests existentes de `today_screen_v2_with_keyboard_test.dart`, `today_screen_futurista_test.dart`, `task_card_futurista_test.dart`, `history_screen_v2_test.dart`, `history_screen_futurista_test.dart`.

Si surgen fallos, NO commitear; investigar y arreglar primero.

### Step 1.11: `flutter analyze lib test`

Expected: 0 errores nuevos.

### Step 1.12: Commit

```bash
git add lib/features/tasks/domain/task_actionability.dart \
        lib/features/history/presentation/widgets/show_rate_sheet.dart \
        test/unit/features/tasks/domain/task_actionability_test.dart \
        lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart \
        lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart \
        lib/features/history/presentation/skins/history_screen_v2.dart \
        lib/features/history/presentation/skins/futurista/history_screen_futurista.dart
git commit -m "refactor(skin): extraer TaskActionability + showRateSheet (dedup v2/futurista)"
```

---

## Task 2: Padding ad-aware en 5 pantallas tab futurista (Ola 2)

**Files:**
- Modify: `lib/features/homes/presentation/skins/futurista/home_settings_screen_futurista.dart`
- Modify: `lib/features/homes/presentation/skins/futurista/my_homes_screen_futurista.dart`
- Modify: `lib/features/members/presentation/skins/futurista/vacation_screen_futurista.dart`
- Modify: `lib/features/notifications/presentation/skins/futurista/notification_settings_screen_futurista.dart`
- Modify: `lib/features/subscription/presentation/skins/futurista/subscription_management_screen_futurista.dart`

Patrón uniforme aplicado a las 5: añadir import (si falta) a `ad_aware_bottom_padding.dart`, reemplazar el bottom hardcoded del scroll outer por `adAwareBottomPadding(context, ref, extra: 16)`, eliminar `const` del `EdgeInsets`. Si la pantalla es `StatelessWidget`, migrar a `ConsumerWidget` (todas estas YA son ConsumerWidget/ConsumerStatefulWidget — sin migración requerida).

### Step 2.1: `home_settings_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~160):

```dart
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
```

Reemplazar por:

```dart
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                adAwareBottomPadding(context, ref, extra: 16),
              ),
```

### Step 2.2: `my_homes_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~78):

```dart
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
```

Reemplazar por:

```dart
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      adAwareBottomPadding(context, ref, extra: 16),
                    ),
```

### Step 2.3: `vacation_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~147):

```dart
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
```

Reemplazar por:

```dart
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          adAwareBottomPadding(context, ref, extra: 16),
        ),
```

(`vacation_screen` es `ConsumerStatefulWidget`; el `ref` está disponible vía `this.ref` dentro del state.)

### Step 2.4: `notification_settings_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~102, dentro de `_SettingsBodyFuturista.build`):

```dart
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
```

Reemplazar por:

```dart
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        adAwareBottomPadding(context, ref, extra: 16),
      ),
```

(`_SettingsBodyFuturista` ya es `ConsumerWidget` con `ref` en `build`.)

### Step 2.5: `subscription_management_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~92):

```dart
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
```

Reemplazar por:

```dart
          data: (data) => ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              12,
              0,
              adAwareBottomPadding(context, ref, extra: 16),
            ),
```

(El widget contenedor es `ConsumerWidget`; `ref` disponible en el `build` outer. La closure `data: (data) => ListView(...)` captura `context` y `ref` del enclosing scope.)

### Step 2.6: Run tests

Run: `flutter test`
Expected: todos verdes (igual baseline que tras Task 1).

### Step 2.7: `flutter analyze lib test`

Expected: 0 errores nuevos.

### Step 2.8: Commit

```bash
git add lib/features/homes/presentation/skins/futurista/home_settings_screen_futurista.dart \
        lib/features/homes/presentation/skins/futurista/my_homes_screen_futurista.dart \
        lib/features/members/presentation/skins/futurista/vacation_screen_futurista.dart \
        lib/features/notifications/presentation/skins/futurista/notification_settings_screen_futurista.dart \
        lib/features/subscription/presentation/skins/futurista/subscription_management_screen_futurista.dart
git commit -m "fix(skin): padding ad-aware en 5 pantallas tab futurista"
```

---

## Task 3: Padding ad-aware en 5 pantallas push futurista (Ola 3)

**Files:**
- Modify: `lib/features/subscription/presentation/skins/futurista/paywall_screen_futurista.dart`
- Modify: `lib/features/subscription/presentation/skins/futurista/rescue_screen_futurista.dart`
- Modify: `lib/features/profile/presentation/skins/futurista/profile_screen_futurista.dart`
- Modify: `lib/features/profile/presentation/skins/futurista/edit_profile_screen_futurista.dart`
- Modify: `lib/features/tasks/presentation/skins/futurista/create_edit_task_screen_futurista.dart`

### Step 3.1: `paywall_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~76-77):

```dart
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
```

Reemplazar por:

```dart
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: adAwareBottomPadding(context, ref, extra: 16),
                ),
```

### Step 3.2: `rescue_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~54-55):

```dart
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
```

Reemplazar por:

```dart
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: adAwareBottomPadding(context, ref, extra: 16),
          ),
```

### Step 3.3: `profile_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~382):

```dart
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 32),
```

Reemplazar por:

```dart
      padding: EdgeInsets.fromLTRB(
        0,
        10,
        0,
        adAwareBottomPadding(context, ref, extra: 16),
      ),
```

(Verificar que el widget envolvente es `ConsumerWidget` — debe tener `ref` en `build`. `ProfileScreenFuturista` es ConsumerWidget desde 2C; si el cambio se aplica dentro de un widget interno `StatelessWidget` _foo_, migrar ese widget interno a `ConsumerWidget` para tener acceso a `ref`. Si no es viable, escalar.)

### Step 3.4: `edit_profile_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~167):

```dart
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
```

Reemplazar por:

```dart
          padding: EdgeInsets.fromLTRB(
            0,
            4,
            0,
            adAwareBottomPadding(context, ref, extra: 16),
          ),
```

(`EditProfileScreenFuturista` es `ConsumerStatefulWidget`; `ref` disponible vía `this.ref`.)

### Step 3.5: `create_edit_task_screen_futurista.dart`

- [ ] Añadir import si no existe:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] Localizar (línea ~214):

```dart
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
```

Reemplazar por:

```dart
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            adAwareBottomPadding(context, ref, extra: 16),
          ),
```

(Widget envolvente: verificar; si Stateful sin `ref`, escalar.)

### Step 3.6: Run tests

Run: `flutter test`
Expected: todos verdes.

### Step 3.7: `flutter analyze lib test`

Expected: 0 errores nuevos.

### Step 3.8: Commit

```bash
git add lib/features/subscription/presentation/skins/futurista/paywall_screen_futurista.dart \
        lib/features/subscription/presentation/skins/futurista/rescue_screen_futurista.dart \
        lib/features/profile/presentation/skins/futurista/profile_screen_futurista.dart \
        lib/features/profile/presentation/skins/futurista/edit_profile_screen_futurista.dart \
        lib/features/tasks/presentation/skins/futurista/create_edit_task_screen_futurista.dart
git commit -m "fix(skin): padding ad-aware en 5 pantallas push futurista"
```

---

## Verificación final manual (después de Task 3)

Antes de marcar la spec como DONE, verificar en dispositivo `43340fd2`:

1. **Skin futurista activado**, scroll a fondo en cada pantalla migrada — último item visible sobre nav+banner:
   - Mis hogares (`/my-homes`)
   - Ajustes del hogar (`/home-settings`)
   - Vacaciones (`/vacation`)
   - Ajustes de notificaciones (`/notification-settings`)
   - Gestión de suscripción (`/subscription`)
   - Paywall (`/subscription/paywall`)
   - Rescate (`/subscription/rescue`)
   - Perfil (`/profile`)
   - Editar perfil (`/profile/edit`)
   - Crear/editar tarea (`/tasks/new` y `/tasks/:id/edit`)

2. **Hoy (skin futurista):** verificar que el botón Hecho sigue mostrando SnackBar correcto en tareas no actionable (el flujo del SnackBar pasa ahora por `TaskActionability.formatDueForMessage`).

3. **Historial (skin futurista y v2):** tap en estrella sigue abriendo el sheet de valoración (ahora vía `showRateSheet`).

4. **Toggle a skin Clásico:** todo sigue funcionando igual.

---

## Self-review checklist

- [x] **Spec coverage:** las 3 secciones (§3.1, §3.2, §3.3, §3.4) mapean a Tasks 1-3. AC1-AC7 cubiertos por tests + verificación manual.
- [x] **Placeholder scan:** ninguno; todos los pasos contienen código completo y comandos exactos.
- [x] **Type consistency:** `TaskActionability.isActionable(TaskPreview, {DateTime? now})` y `TaskActionability.formatDueForMessage(TaskPreview, Locale)` son consistentes en spec, implementación y tests. `showRateSheet(BuildContext, HistoryViewModel, TaskEventItem)` consistente en los 4 sites.
- [x] **No types undefined:** `TaskActionability` se crea en Task 1 antes de ser referenciada por las migraciones del mismo Task. `showRateSheet` idem.
