# Spec: i18n de fechas, horas y plurales ICU

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Media (BUG-15, BUG-18, BUG-22, BUG-24)

---

## Contexto

Toka soporta **es / en / ro** pero formatea fechas y plurales con cadenas hardcoded en muchos puntos. La sesión QA 2026-04-20 detectó:

- **BUG-15:** la hora muestra AM/PM aunque el locale sea `es_ES` (debería ser 24h).
- **BUG-18:** "en 3 días" se muestra también en singular ("en 1 días") — falta plural.
- **BUG-22:** los nombres de meses aparecen en inglés en "Próximas fechas" aunque el locale sea español.
- **BUG-24:** fecha absoluta en formato `MM/DD/YYYY` en locales no-EN.

La raíz: cada pantalla formatea por su cuenta con `DateFormat.Hm()` sin pasar locale, con `toString()` ad hoc, o concatenando strings.

Esta spec centraliza el formateo en helpers con locale y reemplaza plurales con claves ICU.

---

## Decisiones clave

- **Un único módulo** `lib/core/utils/toka_dates.dart` expone todos los formateadores. Ninguna pantalla importa `DateFormat` directamente.
- **Locale resuelto:** el helper lee `Localizations.localeOf(context)` al vuelo. Si se usa fuera de un contexto Flutter (servicios), recibe el locale por parámetro.
- **Plurales:** se migran a claves ARB con sintaxis ICU. Ninguna pantalla hace `if (n == 1) "día" else "días"`.

---

## Helpers centralizados

`lib/core/utils/toka_dates.dart`:

```dart
import 'package:intl/intl.dart';

class TokaDates {
  // "09:30" (24h en es/ro, 24h forzado también en en para consistencia interna)
  static String timeShort(DateTime dt, Locale locale) =>
      DateFormat.Hm(locale.toString()).format(dt);

  // "vie 25 abr" / "Fri 25 Apr" / "vin 25 apr"
  static String dateMediumWithWeekday(DateTime dt, Locale locale) =>
      DateFormat('EEE d MMM', locale.toString()).format(dt);

  // "25 de abril" / "April 25" / "25 aprilie"
  static String dateLongDayMonth(DateTime dt, Locale locale) =>
      DateFormat('d MMMM', locale.toString()).format(dt);

  // "25 de abril de 2026"  (incluye año)
  static String dateLongFull(DateTime dt, Locale locale) =>
      DateFormat('d MMMM y', locale.toString()).format(dt);

  // "25/04/2026" (es/ro) — "04/25/2026" (en-US) — "25/04/2026" (en-GB)
  static String dateShort(DateTime dt, Locale locale) =>
      DateFormat.yMd(locale.toString()).format(dt);

  // "25/04/2026 — 09:30"
  static String dateTimeShort(DateTime dt, Locale locale) =>
      "${dateShort(dt, locale)} — ${timeShort(dt, locale)}";
}
```

**Nota 24h en `en`:** decisión deliberada para consistencia interna. Si producto prefiere 12h en inglés, cambiar `DateFormat.Hm` por `DateFormat.jm` en `en`. Se propone 24h.

**Plurales ICU:** las claves que cuentan cantidad pasan a usar la sintaxis ICU de ARB:

```json
"daysUntil": "{count, plural, =0{hoy} =1{en 1 día} other{en {count} días}}",
"@daysUntil": {"placeholders": {"count": {"type": "int"}}}
```

Traducciones equivalentes en `en`:

```json
"daysUntil": "{count, plural, =0{today} =1{in 1 day} other{in {count} days}}"
```

en `ro`:

```json
"daysUntil": "{count, plural, =0{azi} =1{în 1 zi} other{în {count} de zile}}"
```

*(ro tiene plural compuesto 2-19 que requiere `few` — añadir:  `few{în {count} zile}` para count de 2 a 19 según las reglas del CLDR.)*

---

## Migración por pantallas

### Hoy ([lib/features/tasks/presentation/skins/today_screen_v2.dart](lib/features/tasks/presentation/skins/today_screen_v2.dart))

- Encabezados "Hoy / Esta semana / Este mes": ya vienen de ARB, pero asegurar que no hay hardcode residual en `today_task_section.dart`.
- Counter "X tareas hechas" → clave `tasksDone` con plural.

### Lista completa de tareas

- En [lib/features/tasks/presentation/widgets/upcoming_dates_preview.dart](lib/features/tasks/presentation/widgets/upcoming_dates_preview.dart), sustituir el `DateFormat` actual por `TokaDates.dateMediumWithWeekday` con locale.
- En el preview de tareas anuales añadir año (ver spec 10).

### Task detail

- Fecha de creación: `TokaDates.dateTimeShort`.
- Próxima ejecución: `TokaDates.dateMediumWithWeekday`.

### Historial

- Cabeceras por día: `TokaDates.dateLongFull` (evita confusión al ver historial de meses anteriores).

### Suscripción

- Fechas `premiumEndsAt`, `restoreUntil`: `TokaDates.dateLongFull`.

### Create/Edit Task

- Pickers usan los widgets nativos de Material — respetarán el locale si el `MaterialApp` tiene `localizationsDelegates` correctamente configurados (verificar en `app.dart`).

---

## Plurales: nuevas claves ARB

| Clave                | es                            | en                      | ro                                   |
| -------------------- | ----------------------------- | ----------------------- | ------------------------------------ |
| `daysUntil`          | hoy / en 1 día / en {n} días  | today / in 1 day / ...  | azi / în 1 zi / în {n} zile / de zile |
| `tasksActiveCount`   | 1 tarea activa / {n} tareas activas | 1 active task / ... | 1 sarcină activă / ...               |
| `membersCount`       | 1 miembro / {n} miembros      | 1 member / ...          | 1 membru / ...                       |
| `daysLeft`           | queda 1 día / quedan {n} días | 1 day left / ...        | 1 zi rămasă / ...                    |
| `reviewsCount`       | 1 valoración / {n} valoraciones | ...                   | ...                                  |

Los existentes que usen "$n tareas" con concatenación se reemplazan por `l10n.tasksActiveCount(n)`.

---

## Configuración de i18n

Verificar en [lib/app.dart](lib/app.dart):

```dart
MaterialApp.router(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
  locale: ref.watch(currentLocaleProvider),
  // ...
)
```

Asegurar que `intl` está en `dependencies` y que `flutter gen-l10n` incluye las variantes ICU (la CLI las acepta sin config extra).

---

## Tests

- `toka_dates_test.dart`: cada helper con locale `es_ES`, `en_US`, `ro_RO` produce el formato esperado para 3 fechas de muestra (incluyendo enero/diciembre para cubrir meses con nombres especiales en ro).
- Golden: re-generar goldens que tocan fechas (task detail, upcoming preview, subscription management).
- Plurales: unit test que llama `l10n.daysUntil(0/1/2/21)` en los 3 locales y compara con snapshots.

---

## Migración progresiva

Auditoría con `grep`:

```
rg 'DateFormat\(' lib/features --glob '!**/*.g.dart'
rg 'DateFormat\.' lib/features --glob '!**/*.g.dart'
```

Cada match que no sea `TokaDates` se migra. Se hace en un único PR — el coste es localizado (menos de 30 ocurrencias según la sesión QA).

Plurales: `rg '\.isSingular|==\s*1\s*\?\s*"' lib/features` para detectar los condicionales manuales.

---

## Fuera de alcance

- Formatos regionales alternativos (en-GB, es-419) — se añaden en el futuro si producto los prioriza.
- Localización de números decimales (valoraciones) — ya se renderiza como `star.toString()`, no hay decimales.
- Formato de duraciones relativas (`timeago`) — se mantiene `package:timeago` actual, se configurará la locale correcta en un trabajo aparte si sigue fallando.
