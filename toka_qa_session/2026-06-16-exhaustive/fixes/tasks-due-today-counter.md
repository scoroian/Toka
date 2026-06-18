# §13 — Contador "tareas para hoy" (`counters.tasksDueToday`)

Estado: **resuelto.** Implementado, verificado con tests unitarios y verificado
end-to-end en prod sobre los DOS dispositivos (functions desplegadas a `toka-dd241`).

## ¿Era bug real? Sí — discrepancia de zona horaria + obsolescencia del snapshot

El síntoma reportado ("0 tareas para hoy" mientras un tile mostraba "Hoy") es real y
tenía dos causas que se combinaban:

1. **El contador y los tiles usaban definiciones de "hoy" distintas.**
   - **Cabecera** (`counters.tasksDueToday`): lo calcula el backend en
     `functions/src/tasks/update_dashboard.ts`. La ventana del día se construía con
     `new Date(now.getFullYear(), now.getMonth(), now.getDate())`, que en Cloud
     Functions es **UTC** (el proceso corre en UTC; el cron `resetDashboardsDaily`
     dispara a `0 0 * * *` UTC = 02:00 Madrid en verano). Además era un **snapshot
     denormalizado**: solo se recalcula al reconstruir el dashboard.
   - **Tile** (`today_task_card_todo_v2.dart::_dueDateLabel`): decidía "Hoy"
     recalculando en vivo con `nextDueAt.toLocal()` vs `DateTime.now()` → **zona del
     dispositivo** (Madrid en el MI_9, GMT en el emulador).
   - Resultado: el contador (UTC, snapshot) y la etiqueta del tile (zona del
     dispositivo, en vivo) podían no cuadrar, sobre todo cerca de medianoche y en
     dispositivos cuya zona difiere de UTC.

2. **Semántica laxa del contador.** `tasksDueToday` contaba `nextDueAt < todayEnd`,
   es decir **vencidas + las de hoy**, no solo "las que vencen hoy".

Las recurrencias ya se autoran en la zona del hogar (`RecurrenceRule.timezone`,
default `Europe/Madrid`, vía `tz.TZDateTime` en `recurrence_calculator.dart`), así que
el `nextDueAt` guardado es un instante "pensado en Madrid", pero el dashboard lo
agrupaba por día **UTC**. Esa es la raíz de la incoherencia.

## Definición correcta de "due today" (decidida con el usuario)

- **Zona**: la **zona horaria del hogar** (`homes/{homeId}.timezone`, default
  `Europe/Madrid`). No la del proceso (UTC) ni la del dispositivo. Así el contador es
  el mismo para todos los miembros y no depende de dónde corra el servidor.
- **Semántica**: **estricta**. `tasksDueToday` = nº de tareas activas cuyo
  `nextDueAt` cae en `[inicio_de_hoy, inicio_de_mañana)` **en la zona del hogar**.
  Las vencidas de días anteriores **no** suman al contador (siguen visibles y
  ordenadas arriba en la lista).
- `pendingTodayCount` (vencidas + hoy) se conserva por separado para alimentar
  `hasPendingToday` (el punto del selector de hogares), que sí representa "tienes algo
  accionable hoy".

## Fix

### Backend (`functions/`)
- **Nuevo** `src/tasks/today_window.ts` (puro, sin dependencias; usa `Intl` con ICU de
  Node 20, resuelve DST y offsets):
  - `localDayBoundsUtc(now, timeZone)` → instantes UTC `{start, end}` del día natural
    actual en `timeZone`.
  - `classifyDue(nextDueAt, bounds)` → `"overdue" | "today" | "future"`.
  - `summarizeDue(nextDueAts, now, timeZone)` → `{bounds, dueTodayCount, pendingTodayCount}`.
  - `normalizeTimeZone(tz)` y `DEFAULT_HOME_TIMEZONE = "Europe/Madrid"`.
- `src/tasks/update_dashboard.ts`:
  - Lee `home.timezone` (normalizada; fallback Madrid) y calcula la ventana del día con
    `summarizeDue`.
  - `counters.tasksDueToday = dueTodayCount` (estricto).
  - Cada `activeTasksPreview[i]` lleva ahora `isDueToday` (clasificación en zona del
    hogar) además de `isOverdue`, calculados con la **misma** ventana que el contador.
  - La query de "completados hoy" usa `dayBounds.start/end` (antes UTC).
  - `hasPendingToday` sigue usando `pendingTodayCount` (vencidas + hoy).
- `src/homes/index.ts` → `createHome`: guarda `timezone: normalizeTimeZone(data.timezone)`.
  El cliente puede enviarla; si no, default Madrid.

### Cliente (`lib/`)
- `home_dashboard.dart`: `TaskPreview` gana `@Default(false) bool isDueToday`
  (parseado en `fromMap`; cae a `false` en snapshots antiguos).
- `today_task_card_todo_v2.dart`: la etiqueta "Hoy" la decide **`task.isDueToday`** (la
  clasificación del backend), no un recálculo en la zona del dispositivo. Así el
  contador y las etiquetas siempre cuadran aunque el dispositivo esté en otra zona
  (emulador GMT vs hogar Madrid).
- `today_view_model.dart` (ruta de **fallback** sin dashboard): `_taskToPreview` calcula
  `isDueToday` y el contador de fallback cuenta `t.isDueToday` (estricto).

> El tile **v1** (`presentation/widgets/today_task_card_todo.dart`) conserva la lógica
> antigua a propósito: es legacy y NO está cableado en la app (la pantalla activa es
> `TodayScreenV2` vía `SkinSwitch`). No se toca para no ensuciar sus goldens.

### Migración
- `secrets/qa_backfill_home_timezone.js [tz] [--dry]`: rellena `timezone` (default
  Madrid) en los hogares existentes que no lo tengan. No reconstruye el dashboard (lo
  recalculan el cron diario y el bootstrap `refreshDashboard` del cliente).

## Tests (fallan antes del fix, pasan después)
- `functions/src/tasks/today_window.test.ts` — **17 tests**:
  - `localDayBoundsUtc`: Madrid verano (+02:00) e invierno (+01:00), UTC, día de
    spring-forward (23 h), zona detrás de UTC (America/New_York), zona inválida → Madrid.
  - `classifyDue`/`summarizeDue` con `now` fijo: 23:00 Madrid hoy → cuenta; **00:30
    Madrid de mañana → NO cuenta** (en UTC habría caído en "hoy"; es el bug); vencida →
    no cuenta en estricto pero sí en `pendingTodayCount`; bordes exactos del día.
  - `normalizeTimeZone`: válida se conserva; inválida/vacía/null → Madrid.
- `test/unit/features/tasks/home_dashboard_test.dart`: `TaskPreview.fromMap` parsea
  `isDueToday`; cae a `false` sin el campo.
- `test/ui/features/tasks/today_task_card_todo_v2_due_label_test.dart` — **3 tests**
  (verificado RED→GREEN revirtiendo el fix del tile): "Hoy" sigue a `isDueToday` aunque
  el día del dispositivo diga lo contrario en ambas direcciones; vencida → "Vencida".

Comandos: `cd functions && npx jest today_window` (17 ✓) · suite backend completa
`npx jest --testPathIgnorePatterns test/rules test/integration` (242 ✓, los fallos de
`test/rules` son por no tener el emulador 8080 levantado) · `tsc --noEmit` limpio ·
`flutter test test/unit/features/tasks/` (187 ✓) ·
`flutter test test/ui/features/tasks/today_task_card_todo_v2_due_label_test.dart today_screen_v2_test.dart` (✓) ·
`flutter analyze` sin errores nuevos (2 avisos pre-existentes ajenos).

## Verificación en dispositivo — HECHA (2026-06-18, prod toka-dd241)
Autorizada por el usuario. Pasos ejecutados:
1. **Deploy**: `FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy --only functions
   --project toka-dd241` → "Deploy complete" (incluye `createHome`, `refreshDashboard`
   y los callers de `updateHomeDashboard`).
2. **Migración**: `node secrets/qa_backfill_home_timezone.js` → 12/12 hogares con
   `timezone=Europe/Madrid` (ninguno lo tenía).
3. **Rebuild del dashboard con código nuevo** (vía bootstrap `refreshDashboard` al abrir
   la app como N2 en `SMQRtCjrA09gPIr1wazD`). Lectura por Admin SDK:
   - **ANTES** (snapshot viejo): `tasksDueToday=1` — contaba la tarea **vencida**
     "Reparar grifo URGENTE" (06-17), e `isDueToday` no existía.
   - **DESPUÉS** (código nuevo): `tasksDueToday=0` (estricto; la vencida ya no cuenta),
     `isDueToday=false` presente en las 3 tareas, límites del día Madrid
     `[2026-06-17T22:00Z, 2026-06-18T22:00Z)`. **Este es exactamente el síntoma
     reportado, corregido.**
4. **Cross-TZ en los dos dispositivos** (APK debug nuevo instalado en ambos):
   - **Emulador** (GMT): cabecera "0 tareas para hoy"; grifo → "Vencida"; futuras con
     hora GMT ("mié 07:00").
   - **MI_9** (Madrid): cabecera "0 tareas para hoy" (idéntica) para el mismo hogar y
     cuenta; grifo → "Vencida"; futuras con hora Madrid ("mié 09:00"). La **etiqueta de
     día** (Vencida/futura/Hoy) coincide entre dispositivos porque la decide el backend
     en la zona del hogar; solo difiere la **hora** mostrada (`toLocal()`), como debe.
   → Confirma que el contador es por zona del **hogar** y consistente aunque el
   dispositivo esté en otra zona (la causa raíz del bug original).

5. **Caso positivo en los DOS dispositivos** (creando la tarea por la app, sin Admin
   SDK). Aclaración: el emulador está logueado como **miembro** (QA Tel N3) y el MI_9
   como **owner** (N2); por eso el FAB "+" de crear tarea solo aparece en el MI_9
   (`canManage` = owner/admin) — no es un bug, es el comportamiento correcto. Desde el
   MI_9 creé "Tarea HOY test" diaria a las **23:00 Europe/Madrid** asignada a N2:
   - **Backend** (Admin SDK read): `tasksDueToday` pasó 0→**1**; "Tarea HOY test"
     `isDueToday=true` (nextDueAt 2026-06-18T21:00Z = 23:00 Madrid); la vencida y las
     futuras siguen `isDueToday=false`.
   - **MI_9** (Madrid): cabecera **"1 tareas para hoy"**; tile "Tarea HOY test" con chip
     **"Hoy 23:00"**.
   - **Emulador** (GMT): cabecera **"1 tareas para hoy"** (idéntica); mismo tile con chip
     **"Hoy 21:00"** (21:00 GMT = 23:00 Madrid). Misma etiqueta "Hoy" en ambos pese a la
     distinta zona del dispositivo, porque la decide el backend (zona del hogar); solo
     difiere la hora mostrada (`toLocal()`). El contador (1) == nº de tiles "Hoy" (1) en
     los dos dispositivos.
   - Tras borrar la tarea de prueba por la app (swipe → Eliminar), el dashboard volvió a
     `tasksDueToday=0`. Hogar QA restaurado a sus 3 tareas originales.

Cubierto además de forma **determinista** por el test de widget
`today_task_card_todo_v2_due_label_test.dart` (widget real; RED→GREEN), que prueba los
dos caminos del tile (con/sin "Hoy") incluido el caso de borde de zona horaria.

Capturas analizadas y borradas; scripts temporales de verificación eliminados (queda solo
`secrets/qa_backfill_home_timezone.js`, que es la migración entregable).

## Otros hallazgos durante el trabajo
- **build_runner en WSL** regeneró el **hash** de varios `*.g.dart` de Riverpod (churn de
  versión, gotcha conocido) y, por estar sin regenerar, completó campos en
  `home_membership.freezed.dart` (campo `homePhotoSnapshot`, de trabajo previo staged) y
  `rated_events_provider.g.dart`. Solo `home_dashboard.freezed.dart` es regeneración de
  mi cambio. Al commitear este fix conviene incluir únicamente los archivos de §13.
- **Desfase residual de "hoy" overnight**: el cron diario corre a `0 0 * * *` **UTC**
  (= 02:00 Madrid). Entre 00:00–02:00 Madrid el snapshot puede reflejar el día anterior
  hasta que el cliente abre la app (bootstrap `refreshDashboard`) o hay una acción. Lo
  mitiga el bootstrap por sesión del `dashboardProvider`. Para eliminarlo del todo habría
  que programar el reset por zona del hogar (fuera del alcance de §13).
