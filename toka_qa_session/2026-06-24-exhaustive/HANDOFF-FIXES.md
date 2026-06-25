# Handoff — Corrección de hallazgos QA 2026-06-24

Documento de traspaso para que otra sesión de Claude Code continúe. Resume qué se
ha hecho, qué falta, el detalle técnico exacto de cada fix pendiente, el estado
del entorno y los gotchas que han bloqueado la verificación.

---

## 1. Contexto

Tras una QA exhaustiva (informe en `HALLAZGOS.md`, misma carpeta), el usuario pidió
**corregir los 6 hallazgos uno por uno**, recompilando y verificando en los **dos
dispositivos** (emulador + MI_9 físico). Decisiones de diseño ya aprobadas por el usuario:

1. Alcance: **los 6** hallazgos (🟡 #1,#2,#3 + 🔵 #4,#5,#6).
2. Zona horaria (#2): **la del hogar** como canónica en TODA la UI.
3. Ocurrencia futura en Hoy (#3): **mantenerla pero agrupada** en una sección "Próximas".
4. Cadencia: por hallazgo (build + verificar en ambos), aunque por la inestabilidad
   del entorno conviene apoyarse en **tests unitarios** como verificación primaria.

---

## 2. Estado de los 6 fixes

| # | Fix | Código | Test unitario | Verif. visual | Falta |
|---|-----|--------|---------------|---------------|-------|
| 1 | Pluralización i18n | ✅ | — | ✅ ambos disp. | nada |
| 4 | Padding banner (ARREGLO DE RAÍZ) | ✅ | ✅ ad_aware_scaffold 4/4 | ⏳ | verificación visual en device |
| 5 | Gracia intersticial 1er cambio pestaña | ✅ | ✅ 10/10 | ⏳ (opcional) | — |
| 3 | Sección "Próximas" en Hoy | ✅ | ✅ today_view_model 14/14 | ⏳ | verificación visual en device |
| 2 | Zona horaria del hogar | ✅ | ✅ toka_dates inZone 28/28 | ⏳ | verificación visual en device |
| 6 | Redirect del expulsado | ✅ | ✅ app_router 10/10 | ⏳ (cubierto por test) | — |

**ESTADO 2026-06-25: los 6 fixes IMPLEMENTADOS y verificados por test. `test/unit`
completo = 911/911 verde. Falta solo la verificación VISUAL en dispositivo de #4/#3/#2.**

### Cambios de implementación (resumen, sesión 2026-06-25)
- **#4 (raíz):** `AdAwareScaffold.bottomPaddingOf` ahora DELEGA en
  `MainShellV2.bottomContentPadding` (safeBottom+navBar+banner). Arregla a la vez
  create_edit_task, task_detail y member_profile. Consolidado el cambio quirúrgico
  previo de `create_edit_task_screen_v2.dart` (vuelve a llamar a `bottomPaddingOf`).
  Test `ad_aware_scaffold_test.dart` actualizado al nuevo contrato.
- **#5:** `ad_interstitial_controller.dart` → flag `_firstTabChangeSeen`; el primer
  `maybeShow()` de la sesión no muestra (precarga y sale). Tests de gracia añadidos.
- **#3:** `RecurrenceGroup` ahora `(todos, upcoming, dones)`. `groupByRecurrence`
  parte activas por `TaskActionability.isActionable(now)`. `TodayTaskSectionV2`
  renderiza bloque "Próximas" entre todos y dones. i18n `today_section_upcoming`
  (es/en/ro). `today_screen_v2` pasa `upcoming`.
- **#2:** helper puro `TokaDates.inZone(instant, tz)` (TZDateTime, fallback toLocal).
  `Home` expone `timezone` (`@Default('Europe/Madrid')`, leído en `home_model.dart`).
  Cableado en `today_task_card_todo_v2` (via currentHomeProvider), `task_card`
  (param `homeTimezone` desde all_tasks_screen_v2) y `task_detail_screen_v2` ("Próxima
  vez"). NO se tocó `task_actionability` (la decisión sigue por instante).
- **#6:** `app.dart` `RouterNotifier.redirect` rama authenticated: si
  `currentHomeProvider.hasError` y location != /home → redirige a /home.

### ⚠️ Goldens preexistentes (NO tocar)
La suite `test/ui` tiene ~52 goldens fallando con diffs de rendering pequeños
(0.03%–3.47%) en TODAS las features (login, paywall, radar, settings, members,
tasks...). Es un cambio de rendering GLOBAL del WIP (fuentes/antialiasing), NO de
estos fixes: `login_screen.png` (no tocado) falla igual que los de tasks. No
regenerar como parte de estos fixes. `flutter analyze` limpio en `lib/`.

---

## 3. Detalle técnico por fix

### #1 — Pluralización (✅ COMPLETO)
- **Qué se hizo:** 5 claves con plural concatenado convertidas a plural ICU `one{}/other{}`
  (rumano `one{}/few{}/other{}`) en `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`:
  - `today_tasks_due` (línea ~328)
  - `today_tasks_done_today` (~333)
  - `members_pending_tasks` (~458)
  - `paywall_trial_badge` (~642)
  - `tasks_selection_count` (~1065)
- Regenerado con `flutter gen-l10n` (Windows). Verificado en emulador y MI_9: "1 tarea para hoy".
- **Nada pendiente.**

### #4 — Padding banner en form crear tarea (CÓDIGO HECHO, FALTA VERIFICAR)
- **Qué se hizo** en `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart`:
  - Añadido import: `import '../../../../shared/widgets/skins/main_shell_v2.dart';`
  - Cambiado el padding del `ListView` (body), antes:
    `AdAwareScaffold.bottomPaddingOf(context, ref)` → ahora:
    `MainShellV2.bottomContentPadding(context, ref)` (incluye safeBottom + navBar + **bannerSlot**).
- **Por qué:** el form es una pantalla push DENTRO del shell (hereda banner + NavBar).
  `AdAwareScaffold.bottomPaddingOf` (`lib/shared/widgets/ad_aware_scaffold.dart:33`) sólo
  devuelve `MediaQuery.padding.bottom` (safe area), no el alto del banner → el banner tapaba
  la última opción ("Si vence sin completar"). `MainShellV2.bottomContentPadding`
  (`lib/shared/widgets/skins/main_shell_v2.dart:74`) sí lo incluye.
- **Falta verificar:** abrir el form de crear tarea con **owner** (para que aparezca el FAB)
  y **banner visible** (hogar free o usuario no-pagador), scrollear al final y comprobar que
  "Si vence sin completar" queda **por encima** del banner.
- **Nota / posible ampliación:** el mismo patrón `AdAwareScaffold.bottomPaddingOf` lo usan
  `task_detail_screen_v2.dart` y `member_profile_screen_v2.dart`. Tienen el mismo riesgo.
  Considera arreglar la raíz: cambiar `AdAwareScaffold.bottomPaddingOf` para que delegue en
  `MainShellV2.bottomContentPadding` (arregla los 3 a la vez) en vez del cambio quirúrgico.

### #5 — Gracia intersticial en el 1er cambio de pestaña (NO HECHO)
- **Archivo:** `lib/shared/widgets/ad_interstitial_controller.dart`, método `maybeShow()` (línea 77).
- **Cambio:** añadir campo `bool _firstTabChangeSeen = false;` (junto a `_lastShownAt`, ~línea 45)
  y, justo después de `if (!_enabled) return;` (línea 80):
  ```dart
  // Gracia: no mostramos intersticial en el PRIMER cambio de pestaña de la sesión.
  if (!_firstTabChangeSeen) {
    _firstTabChangeSeen = true;
    unawaited(preload()); // aprovecha para precargar el siguiente
    return;
  }
  ```
- **Decisión / cap-interval:** se respetan igual (`shouldShowInterstitial` en
  `ad_interstitial_decision.dart`, cap=3/sesión, intervalo=210s).
- **Test:** `test/unit/shared/widgets/ad_interstitial_controller_test.dart` (ya existe, exhaustivo).
  Añadir: "no muestra en el primer maybeShow; el segundo sí (si la decisión lo permite)".

### #3 — Sección "Próximas" en Hoy (NO HECHO)
- **Archivos:**
  - `lib/features/tasks/application/today_view_model.dart`:
    - Cambiar el typedef `RecurrenceGroup` (línea 27-30) a
      `({List<TaskPreview> todos, List<TaskPreview> upcoming, List<DoneTaskPreview> dones})`.
    - En `groupByRecurrence` (línea 138-181): al recorrer `activeTasks` (línea 145), partir cada
      tarea con `TaskActionability.isActionable(task)` → si true va a `todos`, si false a `upcoming`.
      Importar `../domain/task_actionability.dart`. Ordenar ambas listas (mismo sort).
  - `lib/features/tasks/presentation/skins/widgets/today_task_section_v2.dart`:
    - Añadir parámetro `final List<TaskPreview> upcoming;`.
    - Renderizar un tercer bloque "Próximas" ENTRE el bloque `todos` (línea 53-71) y el bloque
      `dones` (línea 72-85), con `l10n.today_section_upcoming` y tarjetas `TodayTaskCardTodoV2`
      (las upcoming ya salen con "Hecho" deshabilitado por `TaskActionability`).
  - `lib/features/tasks/presentation/skins/today_screen_v2.dart` (línea ~102-114): pasar
    `upcoming: data.grouped[recType]!.upcoming` al `TodayTaskSectionV2`.
  - **i18n:** añadir `today_section_upcoming` ("Próximas" / "Upcoming" / ro "Următoarele") + metadata
    en los 3 ARB, junto a `today_section_todo`/`today_section_done` (~línea 338-341). `flutter gen-l10n`.
- **Tests:** `test/unit/features/tasks/today_view_model_test.dart` — actualizar los asserts que usan
  `result[...].todos` y añadir test de partición actionable/upcoming.
- **Detalle de actionability:** `lib/features/tasks/domain/task_actionability.dart:25` `isActionable`
  (overdue siempre actionable; futuras según ventana de recurrencia).

### #2 — Zona horaria del hogar en toda la UI (NO HECHO — el más delicado)
- **Hecho ya en el código (referencia):** el Detalle de tarea convierte correctamente a la zona del
  hogar usando `tz.TZDateTime.from(d, tz.getLocation(timezone))` en
  `lib/features/tasks/application/task_detail_view_model.dart:86-116` (timezone tomado de
  `RecurrenceRule.timezone`). **Replicar ese patrón** en las vistas que aún usan `.toLocal()`.
- **El timezone del hogar SÍ existe** en Firestore: `homes/{homeId}.timezone` (= "Europe/Madrid",
  puesto por backfill). Pero el modelo `lib/features/homes/domain/home.dart` NO lo expone aún.
  `TaskPreview` (en `home_dashboard.dart`) tampoco lleva timezone, sólo `nextDueAt` (instante).
  - **Paso 1:** exponer `timezone` en `Home` (leer el campo, default 'Europe/Madrid').
  - **Paso 2:** helper que dado `nextDueAt` (instante) + timezone del hogar devuelva
    `tz.TZDateTime.from(nextDueAt, tz.getLocation(homeTz))`. El instante se preserva aunque
    `nextDueAt` venga con `.toLocal()` (ver `home_dashboard.dart` fromMap línea ~30).
- **Sitios a cambiar (solo el FORMATEO, NO la actionability):**
  - `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart:87,89,101`
    (usa `widget.task.nextDueAt.toLocal()` + `TokaDates.timeShort/weekdayShort`).
  - `lib/features/tasks/presentation/widgets/task_card.dart:25-26` (`TokaDates.dayMonthTimeShort`).
  - `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart:189-191` ("Próxima vez",
    aún con `.toLocal()`). Las "Próximas fechas" (línea 221) YA están bien.
- **OJO:** NO tocar `task_actionability.dart` (la decisión de "es accionable hoy" es ortogonal y
  funciona por instante). Solo unificar la HORA mostrada. Los widgets de tarjeta necesitan el
  timezone del hogar vía `currentHomeProvider` (o pasarlo por parámetro desde today_view_model).
- **Helper de fechas:** `lib/core/utils/toka_dates.dart` (`timeShort` línea 17, `dayMonthTimeShort` 49).
- **Test:** verificar que con device-tz ≠ home-tz, la hora mostrada es la del hogar en lista/Hoy/detalle.

### #6 — Redirect del expulsado a estado sin-hogar (NO HECHO)
- **Síntoma:** al ser expulsado estando en una pantalla profunda (ej. detalle de evento), el usuario
  ve "Algo salió mal. Inténtalo de nuevo." (`history_event_detail_screen_v2.dart:38`) hasta navegar.
- **Cambio recomendado** en `lib/app.dart`, `RouterNotifier.redirect` (línea 113-178), rama
  `authenticated:` (línea 135-161): si `ref.read(currentHomeProvider).hasError` → devolver
  `AppRoutes.home` (el shell ya muestra el estado "sin hogar"). El router ya escucha
  `currentHomeProvider` (línea ~99 `ref.listen(... => notify())`).
- **Alternativa:** en `current_home_provider.dart` invalidar/forzar null cuando
  `userMembershipsProvider` deja de incluir el homeId actual (membership pasa a status=left;
  el repo ya filtra status left en `homes_repository_impl.dart:24-33`).
- **Test:** `test/unit/app_router_redirect_test.dart` (ya existe; cubre auth, no pérdida de hogar).
  Añadir: usuario en subpantalla + currentHome error/null → redirige a `/home`.

---

## 4. Estado del entorno (IMPORTANTE)

### Cuentas de prueba (Firebase prod toka-dd241)
- **Ana** — `toka.real.ana@tokatest.dev` / `TokaReal2024` — uid `jFNBvm25nWS2Ag4j35yFqrBHkWm1`
  - Owner de **Casa** (homeId `xBjacg2JdYhHTpX6NsI1`) y **CasaDos** (homeId `VFYGj84mhZc6S7LOR5no`).
  - Toka Plus: OFF (revertido).
- **Beto** — `toka.real.beto@tokatest.dev` / `TokaReal2024` — uid `3E1RQwmE1JgT0ZntGUHc6zfOjx23`
  - Member (status active) de Casa.
- Tareas en Casa: "Limpiar bano", "Fregar platos", "Sacar basura" (diarias, 09:00 Europe/Madrid).

### ⚠️ Estado premium a REVERTIR
- **Casa (`xBjacg2JdYhHTpX6NsI1`) quedó en premium `active`** (se puso para evitar intersticiales
  durante la navegación). **Revertir a free** al terminar:
  `node secrets/qa_set_state_for.js xBjacg2JdYhHTpX6NsI1 free`

### APK
- `build/app/outputs/flutter-apk/app-debug.apk` (main.dart → prod). Incluye **fix #1 + fix #4**.
  Instalado en ambos dispositivos.

### Dispositivos (al cerrar esta sesión)
- **Emulador (emulator-5554): APAGADO** (`adb emu kill`). Estaba muy inestable.
- **MI_9 (43340fd2):** se estaba haciendo **login de Ana** (email reescrito correctamente
  `toka.real.ana@tokatest.dev`, password introducida, pendiente de pulsar "Iniciar sesión").
  Estado real incierto — comprobar si Ana está logueada o sigue en login.

### Tooling
- Admin SDK: `secrets/toka-sa.json`. Scripts útiles en `secrets/`:
  - `qa_set_state_for.js <homeId> <free|active|rescue|cancelledPendingEnd|expiredFree|restorable> [horas]`
  - `qa_plus.js <email> <on|off>`
  - `qa_inspect_email.js <email>` (creado esta sesión; lista uid/hogares/membresías/plus)
- Captura+resize: `<scratchpad>/cap.sh` (usa adb.exe + magick.exe, deja PNG en `/mnt/c/tmp/`).
- adb.exe: `C:\Users\sebas\AppData\Local\Android\Sdk\platform-tools\adb.exe`
- Flutter Windows: `C:\Users\sebas\flutter\flutter\bin\flutter.bat`

---

## 5. Gotchas del entorno (LEER ANTES DE CONTINUAR)

1. **Emulador inestable hoy:** ANRs ("toka isn't responding"), pantallas negras, lentitud extrema.
   **Preferir el MI_9 físico.** Si se usa el emulador, force-stop + relanzar y esperar mucho.
2. **MIUI corrompe `adb input text`** en campos largos (el email se escribió "ta.real.a" en vez de
   "toka.real.ana"). **Escribir char-a-char**: un `input text "X"` por carácter con `sleep 0.12`.
3. **Los test-ads de AdMob son CLICKABLES:** un tap a ciegas sobre el banner/intersticial abre
   Chrome → ANR. **Nunca tap a ciegas cerca de un ad**; localizar botones con uiautomator dump.
4. **Evitar intersticiales durante navegación:** poner Casa **premium** (intersticial es beneficio
   colectivo: con hogar premium nadie lo ve). Para verificar el **banner** (#4) hay que estar en
   **free** (o usuario no-pagador). El banner ad y el intersticial sólo aparecen en free/no-Plus.
5. **Crear tarea (FAB) sólo lo tienen owner/admin.** Un member (Beto) NO ve el FAB → para verificar
   el form (#4) hace falta owner/admin.
6. **Build:** usar `flutter.bat` (Windows), no WSL. `flutter gen-l10n` antes si se tocan ARB.
   En `cmd.exe` el `cd /d <ruta>` SIN comillas. Compilar ~3 min.
7. **Tests:** `flutter pub get` de Windows deja `package_config.json` con rutas `/C:/...` que rompen
   `flutter test` en WSL → correr tests con `flutter.bat test ...` (Windows) o `flutter pub get` en WSL antes.

---

## 6. Plan recomendado para la próxima sesión

1. Revertir Casa a free (comando arriba) si no se va a verificar #4 de inmediato.
2. Confirmar/rehacer login de Ana en el MI_9.
3. **Verificar #4** (form crear tarea, owner Ana, Casa free → banner): última opción sobre el banner.
4. Implementar **#5, #3, #2, #6** uno por uno. Para cada uno: código → `flutter.bat test` del test
   relevante (verificación PRIMARIA, robusta) → build → verificación visual ligera en MI_9.
5. (Opcional) extender #4 a task_detail y member_profile (mismo patrón).
6. `flutter analyze` debe pasar. No commitear sin OK del usuario.

---

## 7. QA original — qué se probó y qué NO (referencia: HALLAZGOS.md)

**Probado (✅):** registro+login+validaciones+logout; onboarding completo; tareas (7 recurrencias,
completar+undo 10s, editar, congelar, borrar, límite Free recurrentes); miembros multi-dispositivo
(invitar por código, sync en vivo bidireccional, roles admin, expulsar+reincorporar, payer-locked);
rotación + pasar turno (impacto compliance); Hoy/Historial (filtros, gate Free); valoraciones (nota
privada, regla #8); suscripción (paywall 3 tiers, paywall Plus, rescate, downgrade planner);
gating premium/Plus (ads, roles, métricas, skin Océano); ajustes (idioma in-app, apariencia/skins,
notificaciones+notifyBefore, export GDPR, cambiar contraseña, eliminar cuenta); 2º hogar base.

**NO probado (pendiente para futuras sesiones):**
- Compra IAP real (no hay sandbox de pago configurado; los precios sí cargan).
- Tope de 3er hogar (requiere slot extra de pago) — sólo se verificó el 2º hogar base.
- **Flujo de Vacaciones** de miembro (congelar por vacaciones, fechas, razón) — no se llegó a probar.
- Panel de **Soporte/Diagnóstico** (`/support-diagnostics`, requiere custom claim `support`).
- **Login social Google/Apple** (requiere cuentas reales; sólo se probó email/password).
- Pantalla **all_tasks_screen** "Congeladas" (la pestaña Congeladas con tareas congeladas reales).
- **Reincorporar** se ejecutó pero no se verificó a fondo el estado resultante de las stats.
- Edición de **avatar/foto** (perfil y hogar) — el ImagePicker no se ejecutó.
- **Notificaciones reales push** (FCM) en background — sólo se dispararon las de "Probar".
- Cambio de **tema Claro/Oscuro** explícito (se vio dark en MI_9, light en emulador, pero no el toggle).
- **Métricas/radar** del perfil de miembro con datos reales abundantes.
- Escaneo **QR** del código de invitación (se usó el código manual, no la cámara).

---

## 8. Archivos modificados en esta sesión (sin commitear)

- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` — fix #1 (5 claves plural ICU c/u).
- `lib/l10n/app_localizations*.dart` — regenerados por `flutter gen-l10n` (fix #1).
- `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` — fix #4 (import + padding).
- `secrets/qa_inspect_email.js`, `secrets/qa_set_state_for.js` — tooling QA creado esta sesión.
- `toka_qa_session/2026-06-24-exhaustive/HALLAZGOS.md` — informe QA original.
- `toka_qa_session/2026-06-24-exhaustive/HANDOFF-FIXES.md` — este documento.

(Además, el árbol ya traía muchos cambios previos sin commitear de antes de esta sesión.)

---

## 9. Sesión 2026-06-25 — cierre de fixes + extensión #2 + QA sección 7

**Archivos modificados (sin commitear):**
- `lib/shared/widgets/ad_aware_scaffold.dart` — #4 raíz (delega en `MainShellV2.bottomContentPadding`).
- `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` — #4 consolidado (vuelve a `bottomPaddingOf`, quita import suelto).
- `lib/shared/widgets/ad_interstitial_controller.dart` — #5 (`_firstTabChangeSeen`).
- `lib/features/tasks/application/today_view_model.dart` — #3 (`RecurrenceGroup.upcoming`, `groupByRecurrence` con `now`+`timezone`) + cableado tz hogar.
- `lib/features/tasks/presentation/skins/widgets/today_task_section_v2.dart` — #3 (bloque "Próximas").
- `lib/features/tasks/presentation/skins/today_screen_v2.dart` — #3 (pasa `upcoming`).
- `lib/l10n/app_{es,en,ro}.arb` + `app_localizations*.dart` — #3 (`today_section_upcoming`).
- `lib/core/utils/toka_dates.dart` — #2 (`TokaDates.inZone`).
- `lib/features/homes/domain/home.dart` (+`home.freezed.dart`) — #2 (`timezone` `@Default('Europe/Madrid')`).
- `lib/features/homes/data/home_model.dart` — #2 (lee `timezone`).
- `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart` — #2 (`inZone` + tz a actionability/formatDue).
- `lib/features/tasks/presentation/widgets/task_card.dart` — #2 (param `homeTimezone`).
- `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart` — #2 (pasa `homeTimezone`).
- `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` — #2 ("Próxima vez" en tz hogar).
- `lib/features/tasks/domain/task_actionability.dart` — extensión #2 (`isActionable`/`formatDueForMessage` con `timezone`).
- `lib/app.dart` — #6 (redirect `currentHome.hasError`→/home).
- `lib/features/members/application/vacation_view_model.dart` (+`.freezed.dart`) — fix motivo vacaciones: `reason` en estado+getter, carga vía `ref.listen` (antes `watch`+`Future.microtask`, no testeable/no rehidrataba).
- `lib/features/members/presentation/skins/vacation_screen_v2.dart` — rehidrata el controller del motivo (flag `_reasonHydrated`).
- Tests: `vacation_view_model_test` (+1 caso rehidratación, 7/7).
- Tests: `ad_interstitial_controller_test`, `today_view_model_test`, `toka_dates_test`, `task_actionability_test`, `app_router_redirect_test`, `ad_aware_scaffold_test`, y 2 fixes de literal `RecurrenceGroup` en tests UI de tasks.

**Verificación:** `test/unit` completo = **911/911** (antes de la extensión actionability; +4 tests nuevos de actionability tz verdes después). `flutter analyze lib` limpio. ~52 goldens de `test/ui` fallan por rendering global del WIP (preexistente, NO de estos cambios). Verificación visual en emulador GMT + MI_9 Madrid (ver HALLAZGOS "Cierre de fixes" y "QA sección 7").

**Estado del entorno al cerrar:** Casa (`xBjacg2JdYhHTpX6NsI1`) y CasaDos en **free**. Ana sin vacaciones, tema en Sistema, "Sacar basura" descongelada. APK nuevo (con extensión actionability) instalado en emulador-5554 (Ana) y MI_9 (Beto). NADA commiteado (pendiente OK del usuario).

**Pendiente de futuras sesiones:** avatar/foto upload con imagen real en galería; soporte/diagnóstico (claim+AppCheck); QR (cámara); login social; IAP real; notificaciones push background.
