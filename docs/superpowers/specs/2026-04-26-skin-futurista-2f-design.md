# Skin Futurista · Iteración 2F · Cleanup paridad y SSoT padding · Diseño

**Fecha:** 2026-04-26
**Estado:** aprobado para plan de implementación
**Scope:** Cerrar la deuda técnica identificada por los reviewers de 2E. (a) Deduplicar 4 helpers que existen literalmente en v2 y futurista. (b) Migrar 10 pantallas futurista con bottom padding hardcodeado al helper centralizado `adAwareBottomPadding`.
**Fuera de scope:** features nuevas, cambios de UX, nuevos componentes, refactor de `_showUpgradeSheet` (divergencia v2/futurista intencional tras 4f90fef).

**Spec anterior:** [2026-04-25-skin-futurista-2e-design.md](2026-04-25-skin-futurista-2e-design.md).

---

## 1 · Contexto

Tras 2E, los reviewers identificaron tres clases de deuda repetidamente:

1. **Helpers duplicados literalmente:** `_isActionable`/`_formatDueForMessage` en `today_task_card_todo_v2.dart` y `today_screen_futurista.dart`; `_showRateSheet` en `history_screen_v2.dart` y `history_screen_futurista.dart`. La duplicación fue deliberada en 2E para evitar acoplar las skins durante la migración. Ahora que ambas skins funcionan, se puede extraer sin riesgo.
2. **Pantallas futurista con bottom padding hardcodeado:** 10 pantallas siguen usando literales `24` o `32` en el `EdgeInsets` inferior de su `ListView`/`ScrollView` raíz. Tras 2E el shell reserva nav+banner correctamente, pero estas pantallas no consumen `adAwareBottomPadding`, así que su último item se clipea bajo el banner cuando el usuario scrollea a fondo.
3. **`_showUpgradeSheet`:** divergencia visual intencional v2 (Material) vs futurista (TockaBtn). NO se deduplica.

Esta spec arregla (1) y (2) con cambios localizados en 14 archivos modificados, 3 nuevos.

---

## 2 · Invariantes anclados

- **Mismo VM**: ningún cambio toca providers, repositorios ni viewmodels.
- **Mismas firmas públicas**: los wrappers de pantalla siguen exponiendo el mismo constructor.
- **Mismas keys de tests**: los tests existentes deben seguir funcionando sin cambios.
- **Sin nuevos providers**: `TaskActionability` es pure-static, no entra en el grafo Riverpod.
- **`_showUpgradeSheet` queda donde está**: no se deduplica.

---

## 3 · Decisiones tomadas

### 3.1 `TaskActionability` como utility class pure-static

`lib/features/tasks/domain/task_actionability.dart`:

```dart
import 'dart:ui' show Locale;
import '../../../core/utils/toka_dates.dart';
import 'home_dashboard.dart' show TaskPreview;

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

Constructor privado `TaskActionability._()` para evitar instanciación accidental — clase es 100% static.

### 3.2 `showRateSheet` como función top-level

`lib/features/history/presentation/widgets/show_rate_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../application/history_view_model.dart';
import 'rate_event_sheet.dart';

/// Abre el bottom sheet de valoración para un evento del historial.
/// Comparte el mismo modal en v2 y futurista.
Future<void> showRateSheet(
  BuildContext ctx,
  HistoryViewModel vm,
  TaskEventItem item,
) {
  return showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    builder: (_) => RateEventSheet(
      onSubmit: (rating, note) => vm.rateEvent(item.raw.id, rating, note: note),
    ),
  );
}
```

### 3.3 Migración de los 4 consumidores

**`lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart`:**
- Eliminar `_isActionable()` (líneas ~65-94) y `_formatDueForMessage(BuildContext)` (líneas ~96-115).
- Reemplazar uso interno `_isActionable()` → `TaskActionability.isActionable(widget.task, now: widget.now)`.
- Reemplazar uso interno `_formatDueForMessage(context)` → `TaskActionability.formatDueForMessage(widget.task, Localizations.localeOf(context))`.
- Importar `package:toka/features/tasks/domain/task_actionability.dart`.

**`lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`:**
- Eliminar los 2 helpers privados `_isActionable(t)` y `_formatDueForMessage(context, t)` añadidos en 2E.
- Mantener el helper privado `_snackNotYet(ctx, l10n, t)` que SÍ es UI puro (muestra el SnackBar). Cambiar su body a:
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
- En el `itemBuilder`, cambiar `actionable: _isActionable(t)` → `actionable: TaskActionability.isActionable(t)`.
- Importar `package:toka/features/tasks/domain/task_actionability.dart`.
- Eliminar import `core/utils/toka_dates.dart` si ya no se usa directamente.

**`lib/features/history/presentation/skins/history_screen_v2.dart`:**
- Eliminar el método `_showRateSheet(TaskEventItem item, HistoryViewModel vm)` (líneas ~177-185).
- Reemplazar la llamada en `_buildTile` (línea ~137) `() => _showRateSheet(item, vm)` → `() => showRateSheet(context, vm, item)`.
- Importar `'../widgets/show_rate_sheet.dart'`.

**`lib/features/history/presentation/skins/futurista/history_screen_futurista.dart`:**
- Eliminar el método `_showRateSheet(BuildContext ctx, HistoryViewModel vm, TaskEventItem item)`.
- Reemplazar la llamada en el `itemBuilder` `(item) => _showRateSheet(ctx, vm, item)` → `(item) => showRateSheet(ctx, vm, item)`.
- Importar `'../../widgets/show_rate_sheet.dart'`.

### 3.4 Migración de paddings

10 pantallas futurista. Cada cambio sigue el mismo patrón:

**Antes:**
```dart
class FooScreenFuturista extends ConsumerWidget {
  // o StatelessWidget — en cuyo caso migrar a ConsumerWidget
  @override
  Widget build(BuildContext context /*, WidgetRef ref*/) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), // <-- bottom hardcoded
      children: [...],
    );
  }
}
```

**Después:**
```dart
class FooScreenFuturista extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        adAwareBottomPadding(context, ref, extra: 16),
      ),
      children: [...],
    );
  }
}
```

Notas:
- `const` se elimina (`adAwareBottomPadding` es runtime).
- Si la pantalla es `StatelessWidget`, migrar a `ConsumerWidget` (añadir `WidgetRef ref` al `build`).
- Importar `'../../../../../shared/widgets/ad_aware_bottom_padding.dart'` (ajustar profundidad si difiere).
- Mantener `extra: 16` uniforme (convención post-Task 3-4 de 2E).

Pantallas a migrar:

| # | Pantalla | Categoría | Bottom actual |
|---|---|---|---|
| 1 | `home_settings_screen_futurista.dart` | tab | 24 |
| 2 | `my_homes_screen_futurista.dart` | tab | 24 |
| 3 | `vacation_screen_futurista.dart` | tab (push interno) | 32 |
| 4 | `notification_settings_screen_futurista.dart` | tab (push interno) | 24 |
| 5 | `subscription_management_screen_futurista.dart` | tab (push interno) | 24 |
| 6 | `paywall_screen_futurista.dart` | push | 32 |
| 7 | `rescue_screen_futurista.dart` | push | 32 |
| 8 | `profile_screen_futurista.dart` | tab (push) | 32 |
| 9 | `edit_profile_screen_futurista.dart` | push | 32 |
| 10 | `create_edit_task_screen_futurista.dart` | push | 32 |

Todas las "push" están bajo `MainShellFuturista` vía `ShellRoute` (verificado en `lib/app.dart`), así que el banner y la nav bar siguen visibles → el padding ad-aware es necesario.

---

## 4 · Arquitectura y archivos

### 4.1 Crear (3)

| Path | Contenido |
|---|---|
| `lib/features/tasks/domain/task_actionability.dart` | Clase utility con 2 métodos static (§3.1). |
| `lib/features/history/presentation/widgets/show_rate_sheet.dart` | Función top-level `showRateSheet` (§3.2). |
| `test/unit/features/tasks/domain/task_actionability_test.dart` | 12 tests puros (sin Flutter widget tester). |

### 4.2 Modificar (14)

**Helpers (4):**
- `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart`
- `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`
- `lib/features/history/presentation/skins/history_screen_v2.dart`
- `lib/features/history/presentation/skins/futurista/history_screen_futurista.dart`

**Paddings (10):** ver tabla §3.4.

### 4.3 Borrar

Nada.

---

## 5 · Estrategia de delegación

| Ola | Trabajo | Estimación | Commit |
|---|---|---|---|
| **1 — Extracción helpers** | Crear `task_actionability.dart` + `show_rate_sheet.dart` + tests unitarios. Migrar 4 consumidores. `flutter analyze` + `flutter test`. | 30-40 min | `refactor(skin): extraer TaskActionability + showRateSheet (dedup v2/futurista)` |
| **2 — Paddings tab (5)** | `home_settings`, `my_homes`, `vacation`, `notification_settings`, `subscription_management`. | 25-30 min | `fix(skin): padding ad-aware en 5 pantallas tab futurista` |
| **3 — Paddings push (5)** | `paywall`, `rescue`, `profile`, `edit_profile`, `create_edit_task`. | 25-30 min | `fix(skin): padding ad-aware en 5 pantallas push futurista` |

**3 olas, 3 commits, 80-100 min total.**

### 5.1 Control de riesgos

- **Compatibilidad de comportamiento**: `TaskActionability.isActionable` y `formatDueForMessage` deben retornar exactamente los mismos valores que las versiones inline. Tests cubren las 6 ramas.
- **Pantallas StatelessWidget → ConsumerWidget**: cambio mínimo de signatura. Verificar que ningún test externo construye estas pantallas con el constructor anterior (no debería: usan los wrappers `SkinSwitch`).
- **Imports relativos**: la profundidad del import a `ad_aware_bottom_padding.dart` varía según ubicación. Si el implementer falla, escalar.
- **`Localizations.localeOf(context)`**: el helper formato necesita `Locale`, no `BuildContext`. Esto desacopla el helper de Flutter widget tree (puede testearse con un Locale pasado a mano).

---

## 6 · Tests

### 6.1 Nuevos (1 fichero, 12 tests)

`test/unit/features/tasks/domain/task_actionability_test.dart`:

- `isActionable` cubre 7 casos:
  1. Overdue → siempre true.
  2. Hourly → due en hora actual = true; due en hora siguiente = false.
  3. Daily → due hoy = true; due mañana = false.
  4. Weekly → due esta semana = true; due semana siguiente = false.
  5. Monthly → due este mes = true; due mes siguiente = false.
  6. Yearly → due este año = true; due año siguiente = false.
  7. Default (oneTime / desconocido) → comportamiento daily.

- `formatDueForMessage` cubre 5 casos:
  1. Hourly → solo hora.
  2. Daily → fecha+hora.
  3. Weekly → fecha (sin hora).
  4. Monthly → "DD de Mes".
  5. Yearly → "Mes Año".

Total 12 tests, todos con `Locale('es')`. Sin Flutter widget tester (usar `test()`, no `testWidgets()`).

### 6.2 Existentes

- `task_card_futurista_test.dart` (7 tests) y `today_screen_futurista_test.dart` (7 tests) deben seguir verdes — la card y el screen siguen comportándose igual.
- `history_screen_futurista_test.dart` (6 tests) verdes.
- `today_screen_v2_with_keyboard_test.dart` y otros tests v2 verdes.

### 6.3 Sin tests para paddings

Las migraciones de padding son cambios mecánicos. La verificación es manual (scroll a fondo → último item visible). Si en el futuro queremos test automatizado, sería un golden test del scroll completo — fuera de scope aquí.

---

## 7 · Criterios de aceptación

| # | Criterio | Verificación |
|---|---|---|
| AC1 | `TaskActionability.isActionable` retorna mismos valores que la implementación previa para las 6 ramas + overdue + default | tests unitarios |
| AC2 | `TaskActionability.formatDueForMessage` retorna mismos strings para las 5 ramas | tests unitarios |
| AC3 | `showRateSheet` abre `RateEventSheet` y al confirmar dispara `vm.rateEvent` | tests history futurista pasan sin tocar |
| AC4 | Tests existentes de today/history verdes en v2 y futurista | `flutter test` |
| AC5 | Las 10 pantallas migradas: scroll a fondo deja último item visible sobre nav+banner | manual en dispositivo `43340fd2` |
| AC6 | `flutter analyze lib test` 0 errores nuevos | CI |
| AC7 | Tests nuevos `task_actionability_test.dart` 12 verdes | CI |

---

## 8 · Commits previstos

| # | Mensaje | Ola |
|---|---|---|
| 1 | `refactor(skin): extraer TaskActionability + showRateSheet (dedup v2/futurista)` | 1 |
| 2 | `fix(skin): padding ad-aware en 5 pantallas tab futurista` | 2 |
| 3 | `fix(skin): padding ad-aware en 5 pantallas push futurista` | 3 |

Total **3 commits**.

---

## 9 · Pruebas manuales requeridas

Antes de cerrar la spec, verificar en dispositivo `43340fd2`:

1. Skin futurista. Scroll a fondo en cada pantalla migrada — último item visible sobre nav+banner:
   - Mis hogares (`/my-homes`).
   - Ajustes del hogar (`/home-settings`).
   - Vacaciones (`/vacation`).
   - Ajustes de notificaciones (`/notification-settings`).
   - Gestión de suscripción (`/subscription`).
   - Paywall (`/subscription/paywall`).
   - Rescate (`/subscription/rescue`).
   - Perfil (`/profile`).
   - Editar perfil (`/profile/edit`).
   - Crear/editar tarea (`/tasks/new` y `/tasks/:id/edit`).
2. Hoy (skin futurista): verificar que el botón Hecho sigue mostrando SnackBar correcto en tareas no actionable.
3. Historial (skin futurista y v2): tap en estrella sigue abriendo el sheet de valoración.
4. Toggle a skin Clásico: todo sigue funcionando igual.
