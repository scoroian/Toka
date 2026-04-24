# i18n de fechas, horas y plurales ICU — Plan de implementación

> **Para agentes:** Usar `superpowers:executing-plans` o `superpowers:subagent-driven-development`. Los pasos usan `- [ ]` para tracking.

**Goal:** Centralizar el formateo de fechas en `TokaDates` con locale explícito y migrar los plurales manuales a claves ARB con sintaxis ICU, de modo que en es/en/ro no aparezcan meses en inglés ni concordancias incorrectas.

**Architecture:**
- Nuevo módulo `lib/core/utils/toka_dates.dart` expone 6 helpers que internamente usan `intl.DateFormat` con locale explícito. Ninguna pantalla importa `DateFormat` directamente tras la migración.
- En widgets se obtiene el `Locale` vía `Localizations.localeOf(context)`; en capa `application` (ViewModels) se construye a partir de `l10n.localeName`.
- Las claves de contadores (`daysUntil`, `tasksActiveCount`, `membersCount`, `daysLeft`, `reviewsCount`) se añaden con sintaxis ICU `{count, plural, ...}` en es/en/ro. Ro incluye `few` para 2-19.

**Tech Stack:** Flutter, Dart, `intl ^0.20.0`, `flutter_localizations`, ARB.

---

## Task 1: Crear `TokaDates`

**Files:**
- Create: `lib/core/utils/toka_dates.dart`
- Test: `test/unit/core/utils/toka_dates_test.dart`

- [ ] **Step 1: Escribir test `toka_dates_test.dart`** con 3 locales × 6 helpers × fechas representativas (enero, abril, diciembre para cubrir meses que cambian de forma en ro).

```dart
// test/unit/core/utils/toka_dates_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:toka/core/utils/toka_dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
    await initializeDateFormatting('ro');
  });

  const esLocale = Locale('es');
  const enLocale = Locale('en');
  const roLocale = Locale('ro');
  final date = DateTime(2026, 4, 25, 9, 30); // viernes 25 abril 2026 09:30

  group('TokaDates.timeShort', () {
    test('es usa 24h', () {
      expect(TokaDates.timeShort(date, esLocale), '09:30');
    });
    test('en usa 24h (consistencia interna)', () {
      expect(TokaDates.timeShort(date, enLocale), '09:30');
    });
    test('ro usa 24h', () {
      expect(TokaDates.timeShort(date, roLocale), '09:30');
    });
  });

  group('TokaDates.dateMediumWithWeekday', () {
    test('es contiene abr y 25', () {
      final r = TokaDates.dateMediumWithWeekday(date, esLocale);
      expect(r, contains('25'));
      expect(r.toLowerCase(), contains('abr'));
    });
    test('en contiene Apr y 25', () {
      final r = TokaDates.dateMediumWithWeekday(date, enLocale);
      expect(r, contains('25'));
      expect(r, contains('Apr'));
    });
    test('ro contiene apr y 25', () {
      final r = TokaDates.dateMediumWithWeekday(date, roLocale);
      expect(r, contains('25'));
      expect(r.toLowerCase(), contains('apr'));
    });
  });

  group('TokaDates.dateLongDayMonth', () {
    test('es: día + mes largo en español', () {
      final r = TokaDates.dateLongDayMonth(date, esLocale);
      expect(r, contains('25'));
      expect(r.toLowerCase(), contains('abril'));
    });
    test('en: mes largo en inglés', () {
      final r = TokaDates.dateLongDayMonth(date, enLocale);
      expect(r, contains('April'));
    });
    test('ro: mes largo en rumano', () {
      final r = TokaDates.dateLongDayMonth(date, roLocale);
      expect(r.toLowerCase(), contains('aprilie'));
    });
  });

  group('TokaDates.dateLongFull', () {
    test('es incluye año', () {
      final r = TokaDates.dateLongFull(date, esLocale);
      expect(r, contains('2026'));
      expect(r.toLowerCase(), contains('abril'));
    });
    test('en incluye año', () {
      final r = TokaDates.dateLongFull(date, enLocale);
      expect(r, contains('2026'));
      expect(r, contains('April'));
    });
    test('ro incluye año', () {
      final r = TokaDates.dateLongFull(date, roLocale);
      expect(r, contains('2026'));
      expect(r.toLowerCase(), contains('aprilie'));
    });
  });

  group('TokaDates.dateShort', () {
    test('es: formato con /', () {
      final r = TokaDates.dateShort(date, esLocale);
      expect(r, contains('25'));
      expect(r, contains('4'));
      expect(r, contains('2026'));
    });
    test('en: formato con /', () {
      final r = TokaDates.dateShort(date, enLocale);
      expect(r, contains('4'));
      expect(r, contains('25'));
      expect(r, contains('2026'));
    });
    test('ro: formato con /', () {
      final r = TokaDates.dateShort(date, roLocale);
      expect(r, contains('25'));
      expect(r, contains('4'));
      expect(r, contains('2026'));
    });
  });

  group('TokaDates.dateTimeShort', () {
    test('es compone fecha + hora', () {
      final r = TokaDates.dateTimeShort(date, esLocale);
      expect(r, contains('2026'));
      expect(r, contains('09:30'));
      expect(r, contains('—'));
    });
  });

  group('mes distinto en ro (ianuarie vs aprilie vs decembrie)', () {
    test('enero -> ianuarie en ro', () {
      final d = DateTime(2026, 1, 10);
      expect(TokaDates.dateLongDayMonth(d, roLocale).toLowerCase(),
          contains('ianuarie'));
    });
    test('diciembre -> decembrie en ro', () {
      final d = DateTime(2026, 12, 20);
      expect(TokaDates.dateLongDayMonth(d, roLocale).toLowerCase(),
          contains('decembrie'));
    });
  });
}
```

- [ ] **Step 2: Ejecutar el test (debe fallar porque `TokaDates` no existe).**

Run: `flutter test test/unit/core/utils/toka_dates_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:toka/core/utils/toka_dates.dart'`.

- [ ] **Step 3: Implementar `TokaDates`**

```dart
// lib/core/utils/toka_dates.dart
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formateadores de fecha/hora centralizados para Toka.
///
/// - Todos los helpers reciben el [Locale] explícito. En widgets usar
///   `Localizations.localeOf(context)`. Fuera de un BuildContext (services,
///   view-models) construir el Locale a partir de `l10n.localeName`.
/// - Horas en formato 24h en los 3 locales (decisión interna, BUG-15).
class TokaDates {
  const TokaDates._();

  /// "09:30"
  static String timeShort(DateTime dt, Locale locale) =>
      DateFormat.Hm(locale.toString()).format(dt);

  /// "vie 25 abr" / "Fri 25 Apr" / "vin. 25 apr."
  static String dateMediumWithWeekday(DateTime dt, Locale locale) =>
      DateFormat('EEE d MMM', locale.toString()).format(dt);

  /// "25 de abril" / "April 25" / "25 aprilie"
  static String dateLongDayMonth(DateTime dt, Locale locale) =>
      DateFormat('d MMMM', locale.toString()).format(dt);

  /// "25 de abril de 2026"
  static String dateLongFull(DateTime dt, Locale locale) =>
      DateFormat('d MMMM y', locale.toString()).format(dt);

  /// "25/4/2026" (es/ro) — "4/25/2026" (en)
  static String dateShort(DateTime dt, Locale locale) =>
      DateFormat.yMd(locale.toString()).format(dt);

  /// "25/4/2026 — 09:30"
  static String dateTimeShort(DateTime dt, Locale locale) =>
      '${dateShort(dt, locale)} — ${timeShort(dt, locale)}';
}
```

- [ ] **Step 4: Re-ejecutar tests**

Run: `flutter test test/unit/core/utils/toka_dates_test.dart`
Expected: PASS (16+ tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/toka_dates.dart test/unit/core/utils/toka_dates_test.dart
git commit -m "feat(core): add TokaDates helpers with explicit locale"
```

---

## Task 2: Añadir claves ICU plural a los ARBs

**Files:**
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_ro.arb`

- [ ] **Step 1: Añadir las 5 claves ICU antes del `}` final en `app_es.arb`**

Insertar justo antes del cierre (línea 1094):

```json
  "memberProfileLastReviews": "Últimas valoraciones",
  "@memberProfileLastReviews": { "description": "Section title on member profile listing recent reviews" },

  "daysUntil": "{count, plural, =0{hoy} =1{en 1 día} other{en {count} días}}",
  "@daysUntil": {
    "description": "Relative days counter used in task previews",
    "placeholders": { "count": { "type": "int" } }
  },
  "tasksActiveCount": "{count, plural, =0{sin tareas activas} =1{1 tarea activa} other{{count} tareas activas}}",
  "@tasksActiveCount": {
    "description": "Active task count label",
    "placeholders": { "count": { "type": "int" } }
  },
  "membersCount": "{count, plural, =0{sin miembros} =1{1 miembro} other{{count} miembros}}",
  "@membersCount": {
    "description": "Members count label",
    "placeholders": { "count": { "type": "int" } }
  },
  "daysLeft": "{count, plural, =0{último día} =1{queda 1 día} other{quedan {count} días}}",
  "@daysLeft": {
    "description": "Countdown days remaining",
    "placeholders": { "count": { "type": "int" } }
  },
  "reviewsCount": "{count, plural, =0{sin valoraciones} =1{1 valoración} other{{count} valoraciones}}",
  "@reviewsCount": {
    "description": "Reviews count label",
    "placeholders": { "count": { "type": "int" } }
  }
}
```

Nota: borrar la coma final tras el último bloque anterior y añadir la coma al cerrar `memberProfileLastReviews`.

- [ ] **Step 2: Añadir el equivalente en `app_en.arb`**

```json
  "daysUntil": "{count, plural, =0{today} =1{in 1 day} other{in {count} days}}",
  "@daysUntil": {
    "description": "Relative days counter used in task previews",
    "placeholders": { "count": { "type": "int" } }
  },
  "tasksActiveCount": "{count, plural, =0{no active tasks} =1{1 active task} other{{count} active tasks}}",
  "@tasksActiveCount": { ... },
  "membersCount": "{count, plural, =0{no members} =1{1 member} other{{count} members}}",
  "@membersCount": { ... },
  "daysLeft": "{count, plural, =0{last day} =1{1 day left} other{{count} days left}}",
  "@daysLeft": { ... },
  "reviewsCount": "{count, plural, =0{no reviews} =1{1 review} other{{count} reviews}}",
  "@reviewsCount": { ... }
```

Los `@` deben tener el mismo shape (description + placeholders) que en es.

- [ ] **Step 3: Añadir en `app_ro.arb` con cláusula `few` (CLDR: 2-19)**

```json
  "daysUntil": "{count, plural, =0{azi} =1{în 1 zi} few{în {count} zile} other{în {count} de zile}}",
  "@daysUntil": { ... },
  "tasksActiveCount": "{count, plural, =0{nicio sarcină activă} =1{1 sarcină activă} few{{count} sarcini active} other{{count} de sarcini active}}",
  "@tasksActiveCount": { ... },
  "membersCount": "{count, plural, =0{niciun membru} =1{1 membru} few{{count} membri} other{{count} de membri}}",
  "@membersCount": { ... },
  "daysLeft": "{count, plural, =0{ultima zi} =1{1 zi rămasă} few{{count} zile rămase} other{{count} de zile rămase}}",
  "@daysLeft": { ... },
  "reviewsCount": "{count, plural, =0{nicio evaluare} =1{1 evaluare} few{{count} evaluări} other{{count} de evaluări}}",
  "@reviewsCount": { ... }
```

- [ ] **Step 4: Ejecutar `flutter gen-l10n`**

Run: `flutter gen-l10n`
Expected: sin errores. Regenera `lib/l10n/app_localizations*.dart` con métodos `daysUntil(int count)`, `tasksActiveCount(int count)`, etc.

- [ ] **Step 5: Verificar con `flutter analyze` (esperado: pasa)**

Run: `flutter analyze`
Expected: no new errors relacionados con l10n.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ro.arb lib/l10n/app_localizations*.dart
git commit -m "feat(l10n): add ICU plural keys for counters (es/en/ro)"
```

---

## Task 3: Migrar `DateFormat` a `TokaDates` en widgets de tasks

**Files:**
- Modify: `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart`
- Modify: `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart`
- Modify: `lib/features/tasks/presentation/widgets/today_task_card_todo.dart`
- Modify: `lib/features/tasks/presentation/widgets/today_task_card_done.dart`
- Modify: `lib/features/tasks/presentation/widgets/task_card.dart`
- Modify: `lib/features/tasks/presentation/widgets/upcoming_dates_preview.dart`

Todos cambian `import 'package:intl/intl.dart';` → `import '…/core/utils/toka_dates.dart';` y sustituyen las llamadas de `DateFormat` por `TokaDates`. El locale se obtiene con `Localizations.localeOf(context)`.

- [ ] **Step 1: `task_detail_screen_v2.dart` — sustituir los dos `DateFormat('EEE d MMM', 'es')` (líneas ~161, ~190)**

Cambiar:
```dart
value: DateFormat('EEE d MMM', 'es').format(task.nextDueAt.toLocal()),
```
por:
```dart
value: TokaDates.dateMediumWithWeekday(task.nextDueAt.toLocal(),
    Localizations.localeOf(context)),
```

y
```dart
DateFormat('EEE d MMM HH:mm', 'es').format(o.date),
```
por (combina fecha+hora; añadir helper si necesario — aquí la forma "EEE d MMM · HH:mm" con TokaDates se compone):
```dart
'${TokaDates.dateMediumWithWeekday(o.date, Localizations.localeOf(context))} · ${TokaDates.timeShort(o.date, Localizations.localeOf(context))}',
```

Cambiar también el import: `import 'package:intl/intl.dart';` → `import '../../../../core/utils/toka_dates.dart';`.

- [ ] **Step 2: `today_task_card_todo_v2.dart` — 7 ocurrencias**

Las líneas que usan `DateFormat(…, locale)` cambian a TokaDates. Para los casos compuestos el patrón es:

| Antes | Después |
|---|---|
| `DateFormat('HH:mm', locale).format(due)` | `TokaDates.timeShort(due, Locale(locale))` |
| `DateFormat('EEE d MMM · HH:mm', locale)` | `'${TokaDates.dateMediumWithWeekday(due, loc)} · ${TokaDates.timeShort(due, loc)}'` |
| `DateFormat('EEE d MMM', locale)` | `TokaDates.dateMediumWithWeekday(due, loc)` |
| `DateFormat('d MMMM', locale)` | `TokaDates.dateLongDayMonth(due, loc)` |
| `DateFormat('MMMM yyyy', locale)` | usar `DateFormat.yMMMM(locale.toString()).format(due)` — **no está en la spec**; añadir helper `monthYearLong` a TokaDates. |

Añadir a `TokaDates`:
```dart
/// "abril 2026" / "April 2026" / "aprilie 2026"
static String monthYearLong(DateTime dt, Locale locale) =>
    DateFormat.yMMMM(locale.toString()).format(dt);
```
(y cubrir con test en Task 1.4: `TokaDates.monthYearLong(d, esLocale)` contiene `abril` y `2026`.)

Cambiar el tipo local `locale` de `String` a `Locale`. Reemplazar:
```dart
final locale = Localizations.localeOf(context).toString();
```
por:
```dart
final locale = Localizations.localeOf(context);
```
y actualizar cada return.

Además reemplazar el `DateFormat('HH:mm').format(due)` sin locale (línea ~141) por `TokaDates.timeShort(due, Localizations.localeOf(context))`, y `DateFormat('EEE', locale).format(due)` por una cadena derivada de `TokaDates.dateMediumWithWeekday` parseada — mejor: exponer un helper adicional `TokaDates.weekdayShort(dt, locale) => DateFormat('EEE', locale.toString()).format(dt)`. Añadir test.

- [ ] **Step 3: `today_task_card_todo.dart` (V1, legacy)**

Sustituir `DateFormat('HH:mm').format(dueDate)` por `TokaDates.timeShort(dueDate, Localizations.localeOf(context))` y `DateFormat('EEE', …)` por `TokaDates.weekdayShort(dueDate, Localizations.localeOf(context))`. Eliminar import de `intl`.

- [ ] **Step 4: `today_task_card_done.dart`**

Sustituir `DateFormat('HH:mm').format(task.completedAt.toLocal())` por `TokaDates.timeShort(task.completedAt.toLocal(), Localizations.localeOf(context))`. Eliminar import de `intl`.

- [ ] **Step 5: `task_card.dart`**

Sustituir `DateFormat.MMMd(Localizations.localeOf(context).toString()).add_Hm().format(task.nextDueAt)` por:
```dart
final loc = Localizations.localeOf(context);
final dateStr = '${DateFormat.MMMd(loc.toString()).format(task.nextDueAt)} '
                '${TokaDates.timeShort(task.nextDueAt, loc)}';
```

Mejor: añadir helper `TokaDates.dayMonthTimeShort(dt, locale) => '${DateFormat.MMMd(locale.toString()).format(dt)} ${timeShort(dt, locale)}'`, cubrir con test y usar `TokaDates.dayMonthTimeShort(task.nextDueAt, Localizations.localeOf(context))`.

- [ ] **Step 6: `upcoming_dates_preview.dart`**

Sustituir `DateFormat.yMMMd().add_Hm().format(item.date)` por `TokaDates.dateMediumWithWeekday` **con año** si la tarea es anual. La spec original pide `dateMediumWithWeekday` aquí; como hay un preview que puede cubrir más de un año, usar:

```dart
final locale = Localizations.localeOf(context);
title: Text('${TokaDates.dateLongFull(item.date, locale)} · ${TokaDates.timeShort(item.date, locale)}'),
```

Esto cubre BUG-22 (meses localizados) y añade el año (spec 10 fuera de alcance, pero preserva legibilidad).

- [ ] **Step 7: Ejecutar `flutter analyze`**

Run: `flutter analyze lib/features/tasks`
Expected: sin errores.

- [ ] **Step 8: Commit**

```bash
git add lib/core/utils/toka_dates.dart lib/features/tasks test/unit/core/utils/toka_dates_test.dart
git commit -m "refactor(tasks): migrate DateFormat usages to TokaDates"
```

---

## Task 4: Migrar `DateFormat` en History

**Files:**
- Modify: `lib/features/history/presentation/widgets/history_event_tile.dart`
- Modify: `lib/features/history/presentation/history_event_detail_screen.dart`

- [ ] **Step 1: `history_event_tile.dart`**

`_formatRelativeTime` ahora debe recibir locale. Cambiar firma a `_formatRelativeTime(AppLocalizations l10n, DateTime dt, Locale locale)` y sustituir `DateFormat('EEE d MMM, HH:mm').format(dt)` por `'${TokaDates.dateMediumWithWeekday(dt, locale)}, ${TokaDates.timeShort(dt, locale)}'`.

En `build` pasar `Localizations.localeOf(context)` al helper. Eliminar import de `intl`.

- [ ] **Step 2: `history_event_detail_screen.dart`**

`_eventDate` pasa a ser un método del widget que recibe `BuildContext`:
```dart
String _eventDate(BuildContext ctx, DateTime dt) {
  final loc = Localizations.localeOf(ctx);
  return TokaDates.dateLongFull(dt, loc) + ' · ' + TokaDates.timeShort(dt, loc);
}
```
Ajustar `_EventHeader` para que reciba el locale vía `Localizations.localeOf(context)` dentro de su `build`. Eliminar import de `intl`.

- [ ] **Step 3: `flutter analyze lib/features/history`**

Expected: limpio.

- [ ] **Step 4: Commit**

```bash
git add lib/features/history
git commit -m "refactor(history): use TokaDates for event timestamps"
```

---

## Task 5: Migrar `DateFormat` en Members y Subscription

**Files:**
- Modify: `lib/features/members/presentation/vacation_screen.dart`
- Modify: `lib/features/members/presentation/widgets/invite_member_sheet.dart`
- Modify: `lib/features/members/presentation/skins/member_profile_screen_v2.dart`
- Modify: `lib/features/subscription/presentation/widgets/plan_summary_card.dart`
- Modify: `lib/features/homes/application/home_settings_view_model.dart`

- [ ] **Step 1: `vacation_screen.dart`**

Sustituir `DateFormat.yMd()` por `TokaDates.dateShort(dt, Localizations.localeOf(context))` en los dos `ListTile` que muestran fecha de inicio/fin. Eliminar `final fmt = DateFormat.yMd();` y usar el helper directamente. Quitar import intl.

- [ ] **Step 2: `invite_member_sheet.dart` línea 161**

Cambiar `DateFormat('dd MMM yyyy · HH:mm').format(_expiresAt!)` por:
```dart
final loc = Localizations.localeOf(context);
l10n.invite_code_expires_at(
  '${TokaDates.dateMediumWithWeekday(_expiresAt!, loc)} · ${TokaDates.timeShort(_expiresAt!, loc)}',
)
```

- [ ] **Step 3: `member_profile_screen_v2.dart` línea 364**

La variable `dateStr` está dentro de `_LastReviewTile.build(context)`. Sustituir `DateFormat('d MMM yyyy').format(r.createdAt!)` por:
```dart
final dateStr = r.createdAt == null
    ? ''
    : TokaDates.dateLongFull(r.createdAt!, Localizations.localeOf(context));
```
Quitar import intl si ya no queda uso.

- [ ] **Step 4: `plan_summary_card.dart`**

Sustituir el parámetro `DateFormat dateFmt` en todos los métodos (`_buildActive`, `_buildCancelledPendingEnd`, `_buildRescue`, `_buildExpiredFree`, `_buildRestorable`) por `Locale locale`. En cada uso reemplazar `dateFmt.format(x)` por `TokaDates.dateLongFull(x, locale)`.

Cabecera `build`:
```dart
final locale = Localizations.localeOf(context);
...
return Column(... children: _buildContent(context, theme, l10n, locale));
```

Eliminar el import de `intl`.

- [ ] **Step 5: `home_settings_view_model.dart`**

El provider ya recibe `AppLocalizations`. Cambiar `_planLabel(Home home, AppLocalizations l10n)` para pasar el `Locale` derivado de `l10n.localeName`:

```dart
String _planLabel(Home home, AppLocalizations l10n) {
  if (home.premiumStatus == HomePremiumStatus.free ||
      home.premiumStatus == HomePremiumStatus.expiredFree) {
    return l10n.homes_plan_free;
  }
  final endsAt = home.premiumEndsAt;
  if (endsAt != null) {
    final formatted =
        TokaDates.dateShort(endsAt, Locale(l10n.localeName));
    return '${l10n.homes_plan_premium} · ${l10n.homes_plan_ends(formatted)}';
  }
  return l10n.homes_plan_premium;
}
```

Sustituir el import `package:intl/intl.dart` por el de `TokaDates`.

- [ ] **Step 6: `flutter analyze`**

Run: `flutter analyze lib/features/members lib/features/subscription lib/features/homes`
Expected: limpio.

- [ ] **Step 7: Commit**

```bash
git add lib/features/members lib/features/subscription lib/features/homes
git commit -m "refactor: migrate remaining DateFormat usages to TokaDates"
```

---

## Task 6: Verificar configuración de `app.dart`

**Files:**
- Read-only: `lib/app.dart`

- [ ] **Step 1:** Confirmar que `MaterialApp.router` ya incluye `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate` y los `supportedLocales` (es/en/ro). Si falta alguno, añadirlo. (Verificación previa: ya están. Esto queda como check explícito.)

Ningún commit asociado si no hubo cambios.

---

## Task 7: Auditoría final y pruebas

- [ ] **Step 1: Re-grep de `DateFormat` fuera de `TokaDates`**

Run: `rg "DateFormat" lib/features` y `rg "DateFormat" lib/core`
Expected: 0 matches fuera de `lib/core/utils/toka_dates.dart`.

- [ ] **Step 2: Ejecutar `flutter gen-l10n && flutter analyze`**

Run: `flutter gen-l10n && flutter analyze`
Expected: analyze sin errores.

- [ ] **Step 3: Ejecutar todos los tests unitarios**

Run: `flutter test test/unit/`
Expected: tests pasan.

- [ ] **Step 4: Regenerar goldens tocados por los cambios**

Run: `flutter test test/ui --update-goldens`
Expected: goldens actualizados para `history_event_tile_completed`, `plan_summary_card_*`, `today_card_*`.

- [ ] **Step 5: Ejecutar `flutter test`** (todos)

Expected: tests pasan.

- [ ] **Step 6: Build & emulador — smoke manual**

```bash
flutter run -d emulator-5554
# Ajustes → Idioma → Español — abrir tarea anual y validar meses
# Cambiar a English — validar "April", 24h, fechas localizadas
# Cambiar a Română — validar "aprilie", plurales azi/în 1 zi/în 5 zile
```

Capturas con `adb exec-out screencap -p > c:\tmp\screen_es.png` (repetir para en/ro). Redimensionar a ≤1900px con ImageMagick: `magick c:\tmp\screen_es.png -resize 1900x1900\> c:\tmp\screen_es_1900.png`.

- [ ] **Step 7: Commit final con goldens y verificación**

```bash
git add -u test/ui
git commit -m "test(ui): regenerate goldens for i18n-dates migration"
```

---

## Self-review

1. **Cobertura de spec:**
   - 6 helpers en `TokaDates` → Task 1 (se amplía a 8 helpers: `monthYearLong`, `weekdayShort`, `dayMonthTimeShort` añadidos porque el código real los necesita).
   - Auditoría `rg 'DateFormat' lib/features` → Task 7 step 1.
   - Claves ICU daysUntil, tasksActiveCount, membersCount, daysLeft, reviewsCount con `few` en ro → Task 2.
   - Eliminar condicionales `if (n == 1)` → no hay ocurrencias en `lib/features` (audit confirmado con `rg`), no hay trabajo pendiente. Las claves ICU quedan disponibles para uso en futuras iteraciones.
   - `app.dart` con los 3 delegates `GlobalXxxLocalizations` + `AppLocalizations.delegate` → Task 6 (ya presentes).

2. **Placeholders:** Ninguno ("…" aparece solo en la descripción de `@daysUntil` para abreviar el bloque en este plan; al aplicarlo se expande al mismo shape del ejemplo completo).

3. **Consistencia de tipos:** `TokaDates` siempre recibe `Locale`. En capas de aplicación se construye `Locale(l10n.localeName)`. En widgets se usa `Localizations.localeOf(context)`.
