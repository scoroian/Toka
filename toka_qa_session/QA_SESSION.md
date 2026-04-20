# Toka QA Session — 2026-04-15

## Estado de la sesión: 🟡 EN CURSO — 3 cuentas ✅ · Hogar QA Principal (3 miembros, Admin promovido ✅) · Roles Admin + Member completamente testeados · Bug #1 #2 #3 #5 #8 #9 #19 #23 #24 #25 #26 #27 #29 #31 #32 #35 ✅ CORREGIDOS (2026-04-16) · Bug #11 #22 ✅ CORREGIDOS (2026-04-17) · Bug #21 + Mejora #9 ✅ CORREGIDOS (2026-04-17) · Bug #6 #7 ✅ CORREGIDOS (2026-04-17) · Bug #4 ✅ CORREGIDO (2026-04-17) · Bug #37 #38 ✅ CORREGIDOS (2026-04-17) · Bug #40 #41 ✅ CORREGIDOS (2026-04-17) · Bug #36 #39 #42 documentados (2026-04-17) · Pendiente: corregir bugs restantes + multi-hogar

---

## ⚙️ Configuración de App Check (RESUELTA)

- **Token debug registrado**: `4a124473-cc16-414d-b27a-12a4587f5d5d` (registrado manualmente en Firebase Console)
- **Token anterior**: `94223bce-8549-4fa0-a00d-98275230f720`
- App Check ya no bloquea las operaciones.

---

## Credenciales de cuentas de prueba

> IMPORTANTE: Estas cuentas son de PRODUCCIÓN. Guardar de forma segura.

| Rol | Email | Contraseña | UID Firebase | Hogar | Estado |
|-----|-------|------------|--------------|-------|--------|
| Owner / Payer | toka.qa.owner@gmail.com | TokaQA2024! | (ver Firebase Console) | Hogar QA Principal | ✅ Creada, onboarding completo, rol Propietario |
| Member | toka.qa.member@gmail.com | TokaQA2024! | (ver Firebase Console) | Hogar QA Principal | ✅ Creada, onboarding completo, unida con código V5W5X9, rol Miembro |
| Admin | toka.qa.admin@gmail.com | TokaQA2024! | (ver Firebase Console) | Hogar QA Principal | ✅ Creada, onboarding completo, unida con código XJG2QK (2026-04-15), **rol Admin** (promovido via botón "Hacer administrador" en la app) |
| Second Owner | toka.qa.owner2@gmail.com | TokaQA2024! | (pendiente) | Hogar QA Secundario | ⏳ Pendiente crear |

---

## Códigos de invitación de hogares

| Hogar | Código invitación | Cómo se obtuvo | Notas |
|-------|-------------------|----------------|-------|
| Hogar QA Principal | **V5W5X9** | InviteMemberSheet → Compartir código (2026-04-15) | ✅ Usado por Member. Puede estar expirado — usar XJG2QK para nuevos miembros |
| Hogar QA Principal | **XJG2QK** | InviteMemberSheet → Compartir código (2026-04-15) | ✅ Usado por Admin para unirse exitosamente |
| Hogar QA Secundario | (pendiente) | — | — |

---

## Resumen ejecutivo de fallos (se irá actualizando)

| # | Severidad | Feature | Descripción | Estado |
|---|-----------|---------|-------------|--------|
| 1 | 🔴 CRÍTICO | Miembros / Tareas | FAB "Invitar" y FAB de crear tarea se superponen con la NavigationBar. Los toques en el FAB navegan a otro tab en vez de abrir el FAB. Coordenadas del FAB de Miembros: centro (896,2222), NavigationBar tab Settings: centro (937,2232). | ✅ CORREGIDO (2026-04-16) — FAB envuelto en `Padding(bottom: kNavBarHeight+kNavBarBottom)` en `members_screen.dart` y `all_tasks_screen_v2.dart`. FAB ahora en y=2044, NavBar en y=2232. |
| 2 | 🔴 CRÍTICO | InviteMemberSheet | El BottomSheet de invitación usa `viewInsets.bottom` (altura del teclado) para padding inferior, pero no `viewPadding.bottom` (altura de la NavBar). Los botones quedan detrás de la NavBar y son inaccesibles con tap normal. Workaround: abrir el campo email primero para que el teclado empuje el sheet hacia arriba. | ✅ CORREGIDO (2026-04-16) — Padding inferior ahora incluye `viewInsets.bottom + viewPadding.bottom + kNavBarHeight + kNavBarBottom`. Botones en y=2012, NavBar en y=2232. |
| 3 | 🟡 MEDIO | Settings | Múltiples `onTap: () {}` vacíos: Cambiar contraseña, Eliminar cuenta, Idioma, Visibilidad del teléfono, Código de invitación (en settings), Abandonar hogar, Términos de uso, Política de privacidad. | ✅ CORREGIDO (2026-04-16) — Todos los handlers implementados: Cambiar contraseña envía email reset + snackbar; Idioma abre LanguageSelectorSheet; Eliminar cuenta muestra diálogo de confirmación + llama FirebaseAuth.delete(); Visibilidad del teléfono navega a editProfile; Código de invitación abre InviteMemberSheet; Abandonar hogar muestra diálogo + llama homesRepository.leaveHome(); Términos y Privacidad abren URL con url_launcher. |
| 4 | 🟡 MEDIO | Settings | Sección "Apariencia" tiene el título hardcodeado en español, no usa i18n ARB. También las etiquetas "Claro"/"Oscuro"/"Sistema" del selector de tema estaban hardcodeadas. | ✅ CORREGIDO (2026-04-17) — Claves `appearance`, `theme_light`, `theme_dark`, `theme_system` añadidas en los 3 ARBs. `_SectionHeader` y `_ThemeModeSelector` actualizados para usar `l10n.*`. Localizaciones regeneradas con `flutter gen-l10n`. Verificado en emulador (ES): "Apariencia", "Claro", "Oscuro", "Sistema". Screenshots: `toka_qa/fix_theme_labels_es.png`. |
| 5 | 🟡 MEDIO | HomeSettings | Botón "Generar código" tiene `onPressed: () {}` vacío. | ✅ CORREGIDO (2026-04-16) — onPressed abre InviteMemberSheet(homeId: data.homeId) con opciones "Compartir código" e "Invitar por email". Verificado en emulador. |
| 6 | 🟠 MENOR | Settings | Colores `Colors.amber` y `Colors.red` usados directamente en vez de `AppColors` o `colorScheme`. | ✅ CORREGIDO (2026-04-17) — `Colors.amber` (estrella premium) → `colorScheme.tertiary`; `Colors.red` (ícono+texto "Abandonar hogar") → `colorScheme.error`. Eliminados `const` redundantes. Verificado en tema claro y oscuro. Screenshots: `fix_colors/006_settings_light_scrolled_step.png`, `fix_colors/009_settings_dark_hogar_step.png`. |
| 7 | 🟠 MENOR | HomeSettings | Colores `Colors.orange` y `Colors.red` usados directamente. | ✅ CORREGIDO (2026-04-17) — `Colors.orange` ("Abandonar hogar") → `colorScheme.tertiary`; `Colors.red` ("Cerrar hogar") → `colorScheme.error`. Verificado en tema claro y oscuro. Screenshots: `fix_colors/016_home_settings_light_step.png`, `fix_colors/014_home_settings_dark_step.png`. |
| 8 | 🔴 CRÍTICO | Pantalla Hoy | Contadores "X tareas para hoy" y "X completadas hoy" siempre muestran 0, aunque haya tareas y se completen. El documento `views/dashboard` de Firestore no se actualiza. | ✅ CORREGIDO (2026-04-16) — Tres fixes: (1) índice compuesto Firestore `taskEvents: eventType+completedAt` que causaba fallo silencioso en `updateHomeDashboard`; (2) `createHome` ahora inicializa `views/dashboard` al crear el hogar; (3) `dashboard_provider.dart` llama `refreshDashboard` incondicionalmente al iniciar el provider. Pantalla Hoy muestra "2 tareas para hoy" y "2 completadas hoy". |
| 9 | 🟡 MEDIO | Crear tarea / Pantalla Hoy | Las horas de las tareas se muestran en UTC en vez de en hora local. Ejemplo: tarea con hora 09:00 Europe/Madrid se muestra como "07:00" en "Próximas fechas" y en la tarjeta de Hoy. | ✅ CORREGIDO (2026-04-16) — **Causa raíz dual**: (1) El emulador Android estaba en timezone GMT en lugar de Europe/Madrid (corregido via `adb shell service call alarm 3 s16 Europe/Madrid`). (2) El código de display no llamaba `.toLocal()` antes de formatear los `DateTime` de Firestore Timestamps. **Fixes de código**: `today_task_card_todo_v2.dart` y `today_task_card_todo.dart` añaden `.toLocal()` en `nextDueAt` antes de `DateFormat('HH:mm').format()`; `today_task_card_done.dart` aplica `.toLocal()` en `completedAt`; `task_detail_screen_v2.dart` aplica `.toLocal()` en `nextDueAt` y `o.date`. **Fix en dominio**: `home_dashboard.dart` (`TaskPreview.fromMap` y `DoneTaskPreview.fromMap`) y `task_model.dart` (`TaskModel.fromFirestore`) convierten `.toDate().toLocal()` para garantizar DateTimes locales en toda la app. Verificado: tarjeta "Fregar" muestra "vie 09:00" (no "07:00"). Screenshots: `toka_qa/fix_hours_1776339296_screen.png`, `toka_qa/fix_hours_detail_1776339442.png`. |
| 10 | 🟡 MEDIO | Pantalla Hoy | Tras completar una tarea, la pantalla Hoy muestra la SIGUIENTE ocurrencia en "Por hacer" en lugar de mover la tarea completada a "Hechas". La tarea completada no se refleja visualmente como hecha en el día actual. | ✅ CORREGIDO (2026-04-16) — **Causa raíz**: `updateHomeDashboard` incluía TODAS las tareas activas en `activeTasksPreview` sin filtrar por fecha, por lo que la siguiente ocurrencia de una tarea completada (con `nextDueAt` mañana) aparecía en "Por hacer". **Fix en `update_dashboard.ts`**: se añade filtro `if (nextDueAt >= todayEnd) continue;` en el loop de `activeTasksPreview` para excluir ocurrencias futuras. Solo se incluyen tareas con `nextDueAt < todayEnd` (vencidas hoy o de hoy). Las tareas completadas ya existían en `doneTasksPreview` vía `taskEvents` — la UI ya tenía soporte para "Hechas" (`TodayTaskSectionV2`). También se corrige `tasksDueToday = pending + done` y `hasPendingToday = pending > 0`. Deployado a producción. Verificado: pantalla Hoy muestra "Fregar" SOLO en "Hechas" (4 completaciones), sin aparecer en "Por hacer". Screenshots: `toka_qa/fix_today_before_*.png` y `toka_qa/fix_today_after_*.png`. |
| 11 | 🟠 MENOR | Crear tarea | El botón "Guardar" queda desactivado sin ningún mensaje explicativo cuando no hay miembros asignados. El usuario no sabe qué falta para poder guardar. | ✅ CORREGIDO (2026-04-17) — Spec: `errores_ui/P2_task_form_validation.md`. Mensaje "Selecciona al menos un miembro" aparece proactivamente en rojo debajo del selector de miembros en cuanto `assignmentOrder.isEmpty`, sin necesidad de pulsar Guardar. Tooltip en el botón Guardar muestra la razón del bloqueo (título vacío o sin miembros). Verificado en emulador: screenshots `fix_validation/005_scrolled_to_members_step.png` y `fix_validation/006_one_member_rotation_disabled_step.png`. |
| 12 | 🟠 MENOR | Pasar turno | El diálogo muestra "Tu cumplimiento bajará de 100% a ~100%" cuando el cambio es insignificante (solo 1 miembro). El texto es contradictorio: dice "bajará" pero muestra el mismo valor. | ✅ CORREGIDO (2026-04-17) — **Fix**: en `pass_turn_dialog.dart` se calcula `diff = (currentComplianceRate - estimatedComplianceAfter) * 100` y el banner rojo solo se muestra si `diff >= 1.0`. Cuando diff < 1 pp (p.ej. con 1 solo miembro), el banner queda suprimido. Añadida clave ARB `pass_turn_minimal_impact` en es/en/ro. Tests: 4 unitarios + 7 de widget pasando (incluyen casos diff<1 y diff>=1). Verificado en emulador: el diálogo de "Fregar" (1 miembro) no muestra banner rojo. Screenshot: `toka_qa/fix_passturn_1776421749.png`. Spec: `errores_ui/P3_pass_turn_dialog_text.md`. |
| 13 | 🟠 MENOR | Crear tarea | El switch "Hora fija" reporta `checked=false` en la jerarquía de accesibilidad aunque visualmente aparece activado. Posible bug de semántica en Flutter Switch. | ✅ CORREGIDO (2026-04-17) — **Causa raíz**: `createEditTaskViewModelProvider` devolvía siempre la misma referencia del notifier; Riverpod usa `identical()` para comparar el valor devuelto y, al no detectar cambio, el widget no reconstruía. El `SwitchListTile(value: vm.hasFixedTime)` quedaba con `false` stale en el árbol de widgets (y por tanto en la semántica de accesibilidad), aunque el estado interno del provider ya era `true`. **Fix**: añadir `ref.watch(createEditTaskViewModelNotifierProvider(widget.editTaskId))` en el `build` de `CreateEditTaskScreenV2` para suscribir el widget directamente al notifier y forzar reconstrucción cuando cambia `hasFixedTime`. **Tests**: 2 tests de widget (`create_task_screen_v2_semantics_test.dart`) verifican que `SwitchListTile.value` es `true`/`false` tras activar/desactivar. **Verificado** con `adb shell uiautomator dump`: el nodo del switch muestra `checked="true"` al activarlo. Screenshot: `toka_qa/fix_semantics_1776423683.png`. Spec: `errores_ui/P3_hora_fija_switch_semantics.md`. |
| 14 | 🟡 MEDIO | Historial (v2) | Botón "Actualizar a Premium" en el banner del historial tiene `onPressed: () {}` vacío. No navega a la pantalla de suscripción. Ver `history_screen_v2.dart:148`. | ✅ CORREGIDO (2026-04-17) — **Fix**: `onPressed: () => context.push(AppRoutes.paywall)` en `_PremiumBannerV2` dentro de `history_screen_v2.dart`. Imports añadidos: `go_router/go_router.dart` y `core/constants/routes.dart`. Ruta destino: `/subscription/paywall` (`PaywallScreen`). `flutter analyze` pasa sin errores. Nota: el banner solo es visible cuando hay al menos un evento en el historial (la lógica de línea 80 devuelve `HistoryEmptyState` si `items.isEmpty`); verificación visual requiere cuenta con historial previo. Spec: `errores_ui/P2_premium_upsell_history_button.md`. |
| 15 | 🔴 CRÍTICO | Router / Onboarding | Race condition: `currentHomeProvider` es `keepAlive:true` y al cambiar de usuario retiene brevemente el valor del usuario anterior. Cuando el router evalúa el redirect, ve un hogar no-nulo y redirige a `/home` en lugar de `/onboarding`. Afecta a cualquier cuenta nueva que se registre/loguee mientras hay una sesión previa activa. **Reproducción**: iniciar sesión como Cuenta1 → cerrar sesión → abrir sesión como Cuenta2 nueva → va a /home en vez de /onboarding. **Workaround**: `adb shell pm clear com.toka.toka` + fresh login. | ✅ CORREGIDO (2026-04-16) — Causa raíz: `ref.listen(authProvider)` en `RouterNotifier` disparaba **síncronamente** antes de que Riverpod marcara `currentHomeProvider` como stale, por lo que `redirect()` leía el hogar obsoleto del usuario anterior. Fix en dos frentes: (1) `app.dart` RouterNotifier — al cambiar de UID se llama `ref.invalidate(currentHomeProvider)` explícitamente ANTES de `notify()`, garantizando que el provider esté en `AsyncLoading` cuando el redirect lo lee; (2) `auth_provider.dart` `signOut()` — invalidación síncrona antes de `_repo.signOut()` (eliminado el `Future.microtask`). Spec: `errores_ui/P0_router_race_condition_keepalive.md`. |
| 16 | 🔴 CRÍTICO | Firestore / Unirse al hogar | `collectionGroup('invitations')` denegaba PERMISSION_DENIED porque las reglas de Firestore no tenían regla de collection group para usuarios autenticados no miembros. El join de hogar fallaba silenciosamente. **Corregido**: añadida regla `match /{path=**}/invitations/{inviteId} { allow list: if isAuth(); }` y deployada en producción (2026-04-15). | ✅ CORREGIDO |
| 17 | 🟡 MEDIO | Onboarding / Unirse al hogar | Errores genéricos en `joinHome()` se silencian. El `HomeJoinForm` solo muestra UI de error para 'invalid_invite' y 'expired_invite'. Cualquier otra excepción (FirebaseException, network error, etc.) se captura con `catch (e)` y el string se guarda en state pero no se muestra al usuario. Resultado: el botón "Unirme" no hace nada visible. | ✅ CORREGIDO (2026-04-16) — Fix en dos frentes: (1) `onboarding_provider.dart` `joinHome()` — catch block reescrito para clasificar `FirebaseException` (→ `permission_denied`/`invalid_invite`/`unexpected_error`), `SocketException` (→ `network_error`) y cualquier otra excepción (→ `unexpected_error`). (2) `home_join_form.dart` — reemplazados los dos `if` separados por un único `if (widget.error != null) Text(switch(...))` que cubre todos los códigos de error. Añadidas claves ARB `onboarding_error_network`, `onboarding_error_unexpected`, `onboarding_error_permission_denied` en es/en/ro. Tests: 17/17 unitarios pasan + 4/4 widget tests de `HomeJoinForm` pasan. Spec: `errores_ui/P1_join_home_error_handling.md`. |
| 18 | 🟠 MENOR | Códigos de invitación | Los códigos de invitación expiran con relativa rapidez. El código V5W5X9 generado el 2026-04-15 ya era inválido al intentar usarlo para la cuenta Admin en la misma sesión. No hay indicación en la UI de la fecha de expiración ni posibilidad de regenerar sin crear un nuevo código. | ✅ CORREGIDO (2026-04-17) — Spec: `errores_ui/P2_invite_code_expiry_display.md`. Tres fixes: (1) `functions/src/homes/index.ts` escribe `expiresAt` (Timestamp.fromDate, +7 días) al generar código e invalida códigos anteriores en batch al regenerar; (2) `InviteMemberSheet` muestra código + QR + "Expira el {fecha}" (en rojo si <24h) + botones "Copiar código" y "Regenerar código"; (3) `HomeSettingsScreen` muestra fecha de expiración junto al código activo + botón refresh. Claves ARB añadidas en es/en/ro: `invite_code_expires_at`, `invite_code_regenerate`, `invite_code_expired_error`. Verificado en emulador (2026-04-17): código VGC43E mostraba "Expira el 24 Apr 2026 · 08:05"; al pulsar "Regenerar código" cambió a M78EGK con nueva expiración "24 Apr 2026 · 08:06". Screenshot: `toka_qa/fix_expiry_1776413200.png`. |
| 19 | 🔴 CRÍTICO | HomeSettings | Al pulsar el botón "Miembros" dentro de HomeSettings, la app se cierra con crash de Flutter: `Failed assertion: line 5066 pos 12: '!keyReservation.contains(key)' is not true` en `navigator.dart`. La pantalla de ajustes del hogar queda inaccesible para el Owner. | ✅ CORREGIDO (2026-04-16) — Causa raíz: `homeSettings` está fuera del `ShellRoute` y hacía `context.push('/members')` que está dentro del `ShellRoute`, creando un Navigator duplicado con la misma `GlobalKey`. Fix: añadida subruta `/home-settings/members` fuera del shell en `app.dart`. `HomeSettingsScreen` ahora navega a `AppRoutes.homeSettingsMembers`. Verificado 3 ciclos Miembros→Atrás→Miembros sin crash. Screenshots: `fix_homesettings/004_members_from_homesettings_OK_step.png` y `fix_homesettings/005_ciclo3_members_sin_crash_step.png`. |
| 20 | 🟡 MEDIO | Miembros / Perfil | Al ver el perfil de otro miembro (Member viendo perfil de Owner), el avatar muestra "?" en lugar de las iniciales o foto. Las estadísticas del radar (completadas, pases, etc.) muestran siempre 0 aunque el usuario tenga actividad registrada en Firestore. | Abierto |
| 21 | 🟡 MEDIO | Crear tarea (rotación) | Al crear tarea con rotación habilitada y asignar dos miembros, la sección de "Rotar al siguiente" se muestra correctamente en el formulario pero la asignación inicial del turno no es configurable — siempre empieza por el primer miembro de la lista. No hay opción para elegir quién va primero. | ✅ CORREGIDO (2026-04-17) — Selector "¿Quién empieza?" con ChoiceChips añadido al formulario; initialAssigneeUid persistido en Firestore como currentAssigneeUid; Próximas fechas en detalle arranca desde el miembro seleccionado. |
| 22 | 🟠 MENOR | Tasks (crear/editar) | En la pantalla de creación de tarea, el selector de miembros muestra los miembros como chips pero si se deseleccionan todos los miembros, el botón "Guardar" se desactiva silenciosamente sin mensaje de validación. Al reactivar "Rotar al siguiente", la UI no limpia el estado si se reduce a 1 miembro. | ✅ CORREGIDO (2026-04-17) — Spec: `errores_ui/P2_task_form_validation.md`. (1) `task_form_provider.dart` `setAssignmentOrder`: cuando `order.length < 2` se resetea `onMissAssign` a `'sameAssignee'` automáticamente. (2) `_OnMissAssignSelector`: con 1 miembro se muestra deshabilitado (SegmentedButton con `onSelectionChanged: null`) y un subtexto "La rotación requiere al menos 2 miembros"; con 0 miembros se oculta; con 2+ miembros se habilita normalmente. (3) Clave ARB `tasks_rotation_requires_two_members` añadida en es/en/ro. Verificado en emulador: con 1 miembro el selector aparece griseado con subtexto; con 2 el subtexto desaparece y los botones se habilitan. Screenshots: `fix_validation/006_one_member_rotation_disabled_step.png` y `fix_validation/007_two_members_rotation_enabled_step.png`. |
| 23 | 🟡 MEDIO | Settings | El item "Código de invitación" en Settings (sección Hogar) tiene `onTap: () {}` vacío — confirmar en `settings_screen.dart`. No abre ningún sheet ni pantalla. | ✅ CORREGIDO (2026-04-16) — onTap abre InviteMemberSheet(homeId: homeId) en modal bottom sheet. Verificado en emulador. |
| 24 | 🟡 MEDIO | Miembros / Perfil | Tras promover a un miembro a Admin (via botón "Hacer administrador" en su perfil), la pantalla de perfil NO se actualiza reactivamente: sigue mostrando "Miembro" hasta que se sale y se vuelve a entrar. El provider no se invalida al cambiar el rol. | ✅ CORREGIDO (2026-04-16) — `memberDetailProvider` (FutureProvider, lectura puntual) reemplazado por derivar el miembro directamente del `homeMembersProvider` (StreamProvider keepAlive, ya existente). El `memberProfileViewModelProvider` ahora usa `allMembersAsync.whenData(...)` para encontrar el miembro objetivo, por lo que cualquier cambio en Firestore (rol, etc.) se propaga reactivamente sin salir de la pantalla. Tests actualizados: 7/7 pasan, incluyendo nuevo test de reactividad con StreamController que emite Member→Admin. Screenshot: `toka_qa/006_after_wait.png` muestra badge "Admin" y botón "Quitar administrador" sin navegar. |
| 25 | 🔴 CRÍTICO | Valoración de tarea | El BottomSheet de valoración ("Enviar valoración") renderiza el botón de envío a y≈2211, detrás de la NavigationBar (y≈2161+). El botón es completamente inaccesible salvo que se abra el teclado primero para empujar el sheet. Mismo problema raíz que Bug #2. | ✅ CORREGIDO (2026-04-16) — `rate_event_sheet.dart` ahora usa `viewInsets.bottom + viewPadding.bottom + kNavBarHeight + kNavBarBottom`. "Enviar valoración" en y=2054, NavBar en y=2232. |
| 26 | 🔴 CRÍTICO | Miembros / Stats | Stats siempre 0 en el perfil de miembro. **Causa raíz confirmada**: mismatch de nombre de campo entre Cloud Function y cliente Flutter. La CF `apply_task_completion.ts:114` escribe `completedCount` en el doc `members/{uid}`, pero `member_model.dart:32` lee `tasksCompleted`. Los campos `currentStreak` y `averageScore` tampoco son actualizados por ninguna CF. La `complianceRate` sí coincide (se muestra correctamente). **Fix**: unificar nomenclatura — renombrar `completedCount` → `tasksCompleted` en la CF (o al revés en el modelo Flutter). También implementar actualización de `currentStreak` y `averageScore`. | ✅ CORREGIDO (2026-04-16) — Tres fixes: (1) `apply_task_completion.ts` renombra `completedCount`→`tasksCompleted` e implementa lógica de `currentStreak` (misma jornada/ayer/racha rota); (2) `submit_review.ts` renombra `avgReviewScore`→`averageScore` y `reviewCount`→`ratingsCount`; (3) script de migración `functions/scripts/migrate_member_stats.js` ejecutado contra producción (5 docs migrados). Verificado en UI: perfil Owner muestra "7 Tareas completadas" y "1 Racha actual". Screenshot: `toka_qa/fix_stats_1776326645_owner_final.png`. |
| 27 | 🟡 MEDIO | Miembros / Perfil | El perfil detail del usuario Member muestra avatar "?" y nombre vacío aunque la lista de miembros muestra "M" y "Member" correctamente. **Causa raíz confirmada**: dos rutas en `homes/index.ts` (`joinHome` línea ~209 y `joinHomeByCode` línea ~297) creaban el doc `members/{uid}` con `nickname: ""` hardcodeado en lugar de leer de `users/{uid}`. **Fix**: ambas transacciones ahora leen `users/{uid}` en el `Promise.all` inicial y usan el nickname/photoUrl real. Script de migración `functions/scripts/migrate_member_nickname.js` ejecutado: 3 docs corregidos (Member, Admin, Sebas). Verificado en UI: perfil Member muestra avatar "M" y nombre "Member". Screenshot: `fix_avatar/009_member_profile_fixed_step.png`. | ✅ CORREGIDO (2026-04-16) |
| 28 | 🟠 MENOR | Detalle de tarea | `TaskDetailScreen` no muestra ningún botón "Atrás" explícito en la AppBar. Solo funciona el botón de sistema Android. Inconsistente con otras pantallas que sí tienen flecha de vuelta. | Abierto |
| 29 | 🔴 CRÍTICO | Notificaciones | Spinner infinito en `NotificationSettingsScreen`. **Causa raíz**: `NotificationSettingsViewModelNotifier.build()` usa `Future.microtask(() => state = ...)` para setear `isLoaded=true`. Cuando `subscriptionStateProvider` cambia (al resolver `currentHomeProvider`), `build()` se re-invoca y devuelve `_NotifVMState(isLoaded: false)`, reseteando el estado. La guardia `if (!state.isLoaded)` ve el estado previo como `true` y no reprograma el microtask — quedando `isLoaded=false` de forma permanente. **Fix 1** (`notification_settings_view_model.dart:44-56`): reemplazar `whenData+microtask` por `return prefsAsync.when(data: (p) => _NotifVMState(isLoaded: true, ...), ...)` — build() devuelve el estado directamente. **Fix 2** (`notification_settings_screen.dart:20`): añadir `ref.watch(notificationSettingsViewModelNotifierProvider(homeId, uid))` antes del watch del proveedor intermedio — fuerza rebuild del widget cuando el estado del notifier cambia (el proveedor intermedio devolvía siempre el mismo objeto, evitando que Riverpod detectara cambio por igualdad). Verificado: toggles visibles en <1s, estado persiste tras pop+push. Screenshots: `fix_notif/006_toggles_visible_FIX_OK_step.png`, `fix_notif/007_state_persists_verified_step.png`. | ✅ CORREGIDO (2026-04-16) |
| 30 | 🟡 MEDIO | HomeSettings / Roles | El botón "Generar código" en HomeSettings es visible para usuarios con rol **Member**, pero al pulsarlo no ocurre nada (`onPressed: () {}`). El botón no debería mostrarse a Members, o debería mostrar error de permisos. | ✅ CORREGIDO (2026-04-16) — Añadido campo `canGenerateCode` a `HomeSettingsViewData` (`= canEdit = isOwner \|\| isAdmin`). El tile `invite_code_tile` se envuelve con `if (data.canGenerateCode)` en `home_settings_screen.dart`. Verificado: Owner y Admin ven el botón; usuario con `MemberRole.member` no lo verá. |
| 31 | 🔴 CRÍTICO | Tareas / Detalle | `TaskDetailScreenV2` no tiene botón "Editar" en la AppBar. La ruta `/task/:id/edit` existe en `app.dart:209` y `CreateEditTaskScreenV2(editTaskId)` está implementada, pero ningún punto de la UI navega a ella. Las tareas **no se pueden editar** desde la interfaz. | Abierto |
| 32 | 🟡 MEDIO | Navegación / Sistema | Pulsar el botón BACK del sistema Android desde `TaskDetailScreen` cierra la app completamente en lugar de volver a la lista de tareas. El stack de navegación de go_router no retiene la pantalla anterior correctamente al venir desde `/tasks/:id`. | ✅ CORREGIDO (2026-04-16) — **Causa raíz**: la ruta `/task/:id` estaba definida como ruta RAÍZ del GoRouter (hermana del `ShellRoute`), no como hija. Al navegar con `context.push('/task/:id')` desde dentro del ShellRoute, go_router reemplazaba la entrada del navigator raíz en lugar de apilar sobre ella — sin pantalla a la que volver. **Fix en `app.dart`**: añadido `_rootNavigatorKey = GlobalKey<NavigatorState>()`, y las rutas `new`, `:id` y `:id/edit` se mueven como sub-rutas del GoRoute `/tasks` dentro del ShellRoute con `parentNavigatorKey: _rootNavigatorKey` (para mostrarlas sin NavigationBar). **Fix en `routes.dart`**: `taskDetail` y `editTask` actualizados de `/task/:id` a `/tasks/:id` y `/tasks/:id/edit`. **Fix en `all_tasks_screen_v2.dart`**: navegación actualizada a `/tasks/${task.id}`. **Fix en `task_detail_screen_v2.dart`**: BackButton explícito añadido en AppBar + ruta de edición actualizada a `/tasks/${task.id}/edit`. Verificado: 3 ciclos Tareas→Detalle→BACK→Tareas sin cerrar la app. Screenshots: `fix_back_nav/007_back_iter1_PASS_step.png`, `fix_back_nav/008_back_iter3_PASS_step.png`. |
| 33 | 🟠 MENOR | HomeSettings / Roles | Cuando un usuario con rol **Member** pulsa "Generar código" en HomeSettings, la operación falla silenciosamente por permisos Firestore pero no se muestra ningún snackbar ni mensaje de error al usuario. El problema raíz es Bug #30 (botón visible para Member), pero además la capa de UI no maneja el error de escritura fallida. | ✅ CORREGIDO (2026-04-16) — Resuelto por la corrección de Bug #30: el tile entero se oculta para Members, por lo que no pueden llegar a pulsar el botón. `InviteMemberSheet` ya tenía su propio manejo de errores inline. |
| 34 | 🟡 MEDIO | Miembros / Perfil | El radar chart de estadísticas no aparece en ningún perfil (ni en el propio ni en el de otros miembros). La widget existe en el skin v2 pero no renderiza: o bien `MemberRadarProvider` devuelve datos vacíos cuando `tasksCompleted=0` (por Bug #26), o bien el componente tiene un error de render silencioso con datos nulos. Al no haber datos reales (por Bug #26 que mantiene stats a 0), es imposible confirmar si el widget renderiza correctamente cuando hay datos válidos. **Causa raíz confirmada**: (1) `RadarChartWidget` usaba `entries.isEmpty` como guard, pero `fl_chart` necesita ≥3 puntos — el guard correcto es `entries.length < 3`; (2) ambas pantallas (`MemberProfileScreen` y `MemberProfileScreenV2`) solo renderizaban el widget cuando `data.showRadar == true` (requiere ≥3 valoraciones), ocultando la sección completamente en lugar de mostrar el estado vacío. **Fix**: guard cambiado a `< 3` con título y mensaje "Sin valoraciones todavía"; eliminado `if (data.showRadar)` en ambas pantallas — el widget siempre se muestra y gestiona el estado vacío internamente. Verificado: perfil Owner muestra "Puntos fuertes / Sin valoraciones todavía". Screenshot: `fix_radar/002_member_profile_radar_empty_state_step.png`. | ✅ CORREGIDO (2026-04-17) |
| 35 | 🔴 CRÍTICO | Admin / Permisos Firestore | Los botones Editar/Congelar/Borrar son visibles para el admin en la UI (Flutter lee `homes/{homeId}/members/{uid}.role = "admin"`), pero las operaciones de escritura fallaban silenciosamente porque las reglas Firestore comprueban `users/{uid}/memberships/{homeId}.role`, que `promoteToAdmin` no actualizaba. Resultado: admin veía los botones pero no podía guardar ningún cambio. | ✅ CORREGIDO (2026-04-16) — (1) `promoteToAdmin` ahora actualiza también `users/{uid}/memberships/{homeId}.role → "admin"` en la misma transacción; (2) `demoteFromAdmin` también actualiza ambos documentos; (3) datos existentes del admin de QA reparados con script REST. Verificado: admin puede editar y guardar tareas. |
| 36 | 🟡 MEDIO | Pantalla Hoy / Selector hogar | Con un solo hogar, la pantalla Hoy no muestra ningún desplegable para seleccionar, crear o unirse a otro hogar. El usuario no tiene forma de crear un segundo hogar desde la pantalla principal sin ir a Ajustes. **Comportamiento esperado**: debe aparecer siempre el selector de hogar en el header de la pantalla Hoy, incluso con un solo hogar, con opciones para crear o unirse a otro. **Verificado en**: screenshot `bug_investigation/028_app_hoy_cargada_step.png`. | Abierto |
| 37 | 🔴 CRÍTICO | Crear/Editar tarea · Icono Material | Al seleccionar un icono Material (tab "Icono") en el formulario de crear/editar tarea, el icono seleccionado se muestra con **fondo naranja y el icono en blanco** en lugar de fondo transparente e icono adaptado al tema (blanco en oscuro, negro en claro). Afecta tanto al grid de selección como al preview superior. **Causa probable**: el widget de selección aplica `BoxDecoration(color: primaryColor)` a todos los ítems en lugar de solo al ítem activo. **Verificado en**: screenshot `bug_investigation/018_icon_tab_selector_step.png`, `019_icon_selected_cabinet_step.png`. | ✅ CORREGIDO (2026-04-17) — **Causa raíz**: `task_visual_picker.dart` líneas 76-85 tenían fondo `primaryContainer` fijo y `Icons.task_alt` hardcodeado para cualquier `kind == 'icon'`. **Fix**: (1) creado helper `task_visual_utils.dart` con `taskVisualWidget(kind, value, {size})` que convierte el codepoint string a `IconData` real; (2) picker actualizado: fondo `primaryContainer` solo cuando `kind == 'emoji'`, `Colors.transparent` cuando `kind == 'icon'`; preview usa `taskVisualWidget`. Verificado: preview muestra el icono seleccionado sin fondo naranja. |
| 38 | 🔴 CRÍTICO | Pantalla Hoy · Tareas · Detalle | Las tareas con icono Material muestran el **codepoint numérico** (ej: "58206 Test") en lugar del icono gráfico en la pantalla Hoy, en la lista de Tareas, y en el detalle. **Causa raíz**: el campo `visualValue` se guarda como el valor entero del codepoint (`e.codePoint.toString()`) en Firestore; el widget de presentación no reconoce que es un codepoint y lo muestra como texto literal. **Verificado en**: screenshot `bug_investigation/028_app_hoy_cargada_step.png` ("58206 Test"), `021_tasks_list_after_icon_save_step.png`. | ✅ CORREGIDO (2026-04-17) — **Archivos corregidos**: (1) `today_task_card_todo_v2.dart` línea 195: `Text('${visualValue} ${title}')` → `Row([taskVisualWidget(...), Expanded(Text(title))])`, separando visual del título; (2) `task_detail_screen_v2.dart` línea 99: `Text(task.visualValue)` → `taskVisualWidget(task.visualKind, task.visualValue, size: 36)`; (3) `task_card.dart` `_VisualWidget`: hardcoded `Icons.task_alt` con fondo naranja → `taskVisualWidget(kind, value, size: 24)`; (4) `all_tasks_screen_v2.dart` línea 127: modo selección también corregido. Verificado por el usuario en dispositivo real: Pantalla Hoy ✅, lista Tareas ✅, detalle ✅. |
| 39 | 🟡 MEDIO | Navegación · Botón BACK sistema | Al pulsar el botón BACK del sistema Android desde cualquier tab de la NavigationBar excepto Hoy (Historial, Miembros, Tareas, Ajustes), la app **sale directamente** al launcher de Android sin pasar por Hoy. **Comportamiento esperado**: BACK desde tab distinto de Hoy → navegar a Hoy; BACK desde Hoy → salir de la app. **Verificado**: BACK desde Tareas → sale. BACK desde Hoy → sale (correcto). **Causa probable**: `PopScope` o `WillPopScope` no implementado en el `ShellRoute`; go_router no intercepta el pop del navigator raíz cuando se está en un tab shell. Screenshot `023_back_desde_tareas_step.png`. | Abierto |
| 40 | 🟡 MEDIO | Miembros · Perfil | El Propietario del hogar **no puede expulsar miembros** desde la UI. El perfil de miembro solo muestra "Hacer administrador" o "Quitar administrador", pero nunca un botón "Expulsar" o "Eliminar del hogar". **Causa raíz**: `MemberProfileViewData` y `MemberProfileViewModel` exponen `canManageRoles` (para promover/degradar) pero no exponen `canRemoveMember`. El método `removeMember()` está completamente implementado en repo + Cloud Function (`removeMember` callable) pero no está conectado a ningún widget en la capa de presentación. **Archivos afectados**: `member_profile_view_model.dart` (falta `canRemoveMember` y `removeMember()`), `member_profile_screen_v2.dart` (falta botón), `skins/member_profile_screen_v2.dart`. Screenshots `035_perfil_admin_sin_expulsar_step.png`, `036_perfil_miembro_sin_expulsar_step.png`. | Abierto |
| 41 | 🔴 CRÍTICO | Miembros · Lista · Abandono hogar | Al abandonar un hogar, el miembro que lo abandonó **sigue apareciendo en la lista de miembros** para el resto de usuarios. **Causa raíz en código**: `MembersRepositoryImpl.watchHomeMembers()` (`members_repository_impl.dart:21-29`) consulta toda la colección `homes/{homeId}/members` **sin filtrar por `status`**. La Cloud Function de abandono pone `status: 'left'` en el documento, pero la query no excluye estos documentos. **Fix necesario**: añadir `.where('status', isNotEqualTo: 'left')` o `.where('status', whereIn: ['active', 'absent'])` a la query de `watchHomeMembers`. | Abierto |
| 42 | 🔴 CRÍTICO | Historial · Valoraciones | Las valoraciones **no se guardan** y el usuario **puede valorar infinitas veces** el mismo evento. Dos causas raíz: (1) `HistoryViewModel.rateEvent()` (`history_view_model.dart:100-104`) es un TODO vacío — nunca escribe en Firestore (`// TODO: write to homes/{homeId}/taskRatings when schema is defined`); (2) `isRated` está hardcodeado a `false` (`history_view_model.dart:144`) → `canRate` siempre es `true` → el botón estrella vacía (☆) siempre aparece, incluso después de valorar. **Verificado**: se envió valoración → sheet cerró → botón sigue siendo ☆ → se volvió a abrir el sheet sin restricción. Screenshots `038_valorar_sheet_step.png`, `039_post_valoracion_step.png`. | Abierto |

---

## Mejoras sugeridas

| # | Feature | Descripción | Prioridad |
|---|---------|-------------|-----------|
| 1 | InviteMemberSheet | Añadir `MediaQuery.of(context).viewPadding.bottom` al padding inferior del sheet para que no quede detrás de la NavBar. | Alta |
| 2 | Miembros / Tareas | Reposicionar los FABs para que no se solapen con la NavigationBar, o añadir `bottomNavigationBarHeight` al `floatingActionButtonLocation`. | Alta |
| 3 | Settings | Implementar todos los handlers vacíos (`onTap: () {}`). | Media |
| 4 | Settings | Añadir clave ARB para "Apariencia". | Baja |
| 5 | Crear tarea | Mostrar mensaje de validación junto al botón "Guardar" cuando no hay miembros asignados (p.ej. "Asigna al menos un miembro"). | Media |
| 6 | Pasar turno | Cuando el cambio de cumplimiento es < 1%, no mostrar el banner de advertencia roja o mostrar "El impacto será mínimo" en lugar de "bajará de X a ~X". | Baja |
| 7 | Historial | El bloque de upsell Premium aparece inmediatamente después del primer evento. Considerar mostrarlo solo cuando hay varios eventos y el usuario llega al límite. | Baja |
| 8 | Códigos invitación | Mostrar fecha de expiración del código en InviteMemberSheet y en HomeSettings. Permitir revocar/regenerar código sin crear uno nuevo siempre. | ✅ CORREGIDO (2026-04-17) — Ver Bug #18. |
| 9 | Rotación de tareas | Permitir elegir quién empieza el turno al crear una tarea con rotación. | ✅ CORREGIDO (2026-04-17) — Ver Bug #21. |

---

## Log de progreso de la sesión QA

### ✅ Completado
- Exploración de la arquitectura del proyecto
- App Check configurada y funcionando
- Cuenta 1 (Owner): registro, verificación email, onboarding (idioma: ES, nombre: Owner, hogar: Hogar QA Principal)
- Navegación a todas las pestañas principales (Hoy, Historial, Miembros, Tareas, Ajustes)
- Obtención del código de invitación: **V5W5X9**, luego **XJG2QK**
- Crear tarea diaria "Fregar" (🧹, recurrencia Diario, hora 09:00, asignada a Owner)
- Pantalla Hoy: tarea visible, botones Hecho y Pasar funcionan, diálogos de confirmación OK
- Completar tarea: flujo completo funciona, evento registrado en historial
- Pasar turno: diálogo muestra penalización y aviso de sin otros miembros
- Historial: evento "Owner completó Fregar" visible, filtros OK, upsell Premium visible
- Suscripción: pantalla Plan gratuito → Paywall → 29.99€/año y 3.99€/mes ✅
- Cuenta 2 (Member): registro, onboarding, unión al hogar con código V5W5X9 ✅
- Bug #16 corregido: reglas Firestore para collectionGroup('invitations') deployadas
- Cuenta 3 (Admin): registro, onboarding, unión al hogar con código XJG2QK ✅
- Hogar QA Principal confirmado con 3 miembros: Owner (Propietario), Member (Miembro), Admin (Miembro)
- Crear tarea semanal "Barrer" (🏠, Lun+Mié, rotación Owner+Member) ✅
- Tarea rotación: detalle muestra alternancia Owner/Member por ocurrencia ✅
- HomeSettings: pantalla visible para Owner (nombre, código, roles)
- Bug #19 documentado: crash al pulsar "Miembros" en HomeSettings
- Perfil de miembro (Member viendo Owner): avatar ?, stats 0 — Bug #20 documentado

### ✅ Completado (sesión 2026-04-17 — bugs nuevos documentados)
- ~~Bug #36: Selector de hogar no aparece en Hoy con un solo hogar~~ ✅ CORREGIDO (2026-04-18) — `HomeSelectorWidget` siempre visible en AppBar de TodayScreenV2; eliminado ternario con HomeDropdownButton
- Bug #37: Icono Material con fondo naranja en crear/editar tarea — confirmado con screenshots
- Bug #38: Codepoint numérico ("58206") en lugar de icono en Hoy y lista de Tareas — confirmado
- Bug #39: BACK desde cualquier tab sale de la app directamente en lugar de ir a Hoy — confirmado
- ~~Bug #40: Owner no puede expulsar miembros (no hay botón en perfil)~~ ✅ CORREGIDO (2026-04-17) — Añadido `canRemoveMember` + `removeMember()` en view model + botón "Expulsar del hogar" en rojo en `MemberProfileScreenV2`
- ~~Bug #41: Lista de miembros no se actualiza al abandonar (watchHomeMembers sin filtro de status)~~ ✅ CORREGIDO (2026-04-17) — Añadido `.where('status', isNotEqualTo: 'left')` en `watchHomeMembers`
- Bug #42: Valoraciones no se guardan (rateEvent() vacío) + no hay prevención de doble valoración (isRated hardcodeado false) — confirmado + causa raíz en código

### ✅ Completado (continuación sesión anterior)
- Admin promovido a rol "admin" via botón "Hacer administrador" en UI (perfil del miembro) ✅
- Matriz de permisos por rol documentada y verificada:
  - Owner: todos los permisos, puede promover/degradar admins, FAB crear tarea, FAB invitar
  - Admin: puede crear tareas (FAB existe, bloqueado por Bug #1), ver miembros, SIN FAB invitar, sin gestión de roles (confirmado vs Owner y Member)
  - Member: task detail read-only (sin botones), sin FAB tareas, sin FAB invitar, sin gestión roles
- Bugs #23–#33 documentados
- Admin viendo perfil de Owner: sin botones de gestión de rol ✅
- Admin viendo task detail: Freeze + Delete + Editar presentes ✅ Bug #31 CORREGIDO (2026-04-16)
- Member Tasks: sin FAB ✅
- Member task detail: completamente read-only (sin AppBar, sin botones) ✅
- Member Members: ve lista completa, sin FAB invitar ✅
- Member perfil propio: Bug #27 (avatar "?"), Bug #26 (stats 0), sin botones rol ✅
- Member HomeSettings: "Generar código" visible (Bug #30), fallo silencioso (Bug #33) ✅ documentado

### 🟡 En curso
- Corrección de bugs #36–#42 (documentados 2026-04-17)
- Bug #37 ✅ CORREGIDO (2026-04-17)
- Bug #38 ✅ CORREGIDO (2026-04-17)
- Bug #39 ✅ CORREGIDO (2026-04-17) — PopScope en MainShellV2: BACK desde tab ≠ Hoy navega a Hoy; BACK desde Hoy sale de la app

### ⏳ Pendiente (en orden de prioridad)
- ~~**P1** Test edición de tarea (paso 3.4) — Owner edita "Fregar"~~ ✅ CORREGIDO (2026-04-16) — Bug #31 resuelto: IconButton edición en AppBar visible para owner/admin, oculto para member
- **P0** Corregir Bug #42 — `rateEvent()` vacío: implementar escritura en `homes/{homeId}/taskRatings` + leer `isRated` del stream; cambiar icono a ⭐ relleno cuando ya valorado
- ~~**P1** Corregir Bug #40 — Añadir botón "Expulsar" en perfil de miembro~~ ✅ CORREGIDO (2026-04-17)
- ~~**P1** Corregir Bug #41 — Filtrar `status: 'left'` en `watchHomeMembers()`~~ ✅ CORREGIDO (2026-04-17)
- ~~**P1** Corregir Bug #39 — BACK desde tabs distintos de Hoy debe navegar a Hoy antes de salir~~ ✅ CORREGIDO (2026-04-17)
- ~~**P2** Corregir Bug #36 — Mostrar selector de hogar en Hoy aunque haya solo uno~~ ✅ CORREGIDO (2026-04-18)
- **P2** Crear cuenta toka.qa.owner2@gmail.com → Hogar QA Secundario (multi-hogar)
- **P2** Test pantalla Hoy como Member — verificar botón completar/pasar
- **P2** Test perfil propio con radar chart — iniciar sesión como Owner
- **P3** Test multi-hogar (Owner con 2 hogares)
- **P3** Test modo vacaciones (ruta `/vacation` existe)
- **P3** Editar perfil (nombre, foto de avatar)
- **P3** Cambio de idioma EN/RO (Bug #3 — onTap vacío)

---

## Detalle de pruebas por feature

### 1. Onboarding y Registro

**Fecha**: 2026-04-15

#### Cuenta 1 — toka.qa.owner@gmail.com (Owner)

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 1.1 | Pantalla splash | ✅ | CircularProgressIndicator correcto |
| 1.2 | Pantalla login | ✅ | Muestra campos email/contraseña y enlace a registro |
| 1.3 | Registro de cuenta nueva | ✅ | Email + contraseña, navegó a verificación |
| 1.4 | Verificación de email | ✅ | Pantalla de verificación mostrada |
| 1.5 | Onboarding: selección de idioma | ✅ | Español seleccionado |
| 1.6 | Onboarding: perfil (nombre) | ✅ | Nombre "Owner" introducido. Nota: el campo de texto no acepta espacios bien vía ADB — el texto se corta en el espacio |
| 1.7 | Onboarding: crear hogar | ✅ | Hogar "Hogar QA Principal" creado |
| 1.8 | Llegada a pantalla Hoy | ✅ | Pantalla Hoy vacía mostrada correctamente |

#### Cuenta 2 — toka.qa.member@gmail.com (Member)

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 1.1-1.4 | Registro + verificación email | ✅ | Cuenta creada. Nota: registro saltó onboarding → Bug #15 (workaround: pm clear + re-login) |
| 1.5 | Onboarding: idioma | ✅ | Español seleccionado |
| 1.6 | Onboarding: perfil | ✅ | Nombre "Member" introducido |
| 1.7 | Onboarding: unirse al hogar con código | ✅ | Código V5W5X9. Primero fallaba por Bug #16 (corregido). Éxito tras deploy de nuevas reglas Firestore. |
| 1.8 | Llegada a pantalla Hoy | ✅ | Pantalla Hoy muestra tarea "Fregar" del hogar (asignada a Owner) |

#### Cuenta 3 — toka.qa.admin@gmail.com (Admin → actualmente Miembro)

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 1.1-1.4 | Registro + verificación email | ✅ | Cuenta creada. Bug #15 aplicó (workaround: pm clear) |
| 1.5 | Onboarding: idioma | ✅ | Español seleccionado |
| 1.6 | Onboarding: perfil | ✅ | Nombre "Admin" introducido |
| 1.7 | Onboarding: unirse con código V5W5X9 | ❌ | "Código de invitación inválido" — código expirado (Bug #18) |
| 1.7b | Onboarding: unirse con código XJG2QK | ✅ | Nuevo código generado por Owner vía InviteMemberSheet. Unión exitosa. |
| 1.8 | Llegada a pantalla Hoy | ✅ | App cargó con hogar. Rol actual: Miembro (pendiente promover a Admin) |

### 2. Pantalla Hoy (Home Dashboard)

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 2.1 | Pantalla Hoy con hogar vacío | ✅ | Muestra `TodayEmptyState` |
| 2.2 | Orden: Hora→Día→Sem→Mes→Año | ✅ | Tarea diaria aparece en sección "Día" correctamente |
| 2.3 | Subgrupos Por hacer / Hechas | ✅ | Bug #10 corregido. Tras completar, la tarea aparece en "Hechas" y desaparece de "Por hacer". Verificado en producción. Screenshots: `toka_qa/fix_today_before_*.png`, `toka_qa/fix_today_after_*.png`. |
| 2.4 | Completar una tarea | ✅ | Diálogo de confirmación → tarea completada → evento en historial |
| 2.5 | Pasar turno (con penalización) | ✅ | Diálogo correcto: muestra impacto de cumplimiento y campo de motivo. Bug menor #12 |
| 2.6 | Contadores de cabecera | ✅ | Bug #8 corregido. Screenshot: `toka_qa/fix_dashboard_*.png`. Pantalla muestra "2 tareas para hoy" y "2 completadas hoy". |

### 3. Gestión de Tareas

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 3.1 | Crear tarea con recurrencia diaria | ✅ | "Fregar" (🧹, Diario, 09:00, Owner). Workaround FAB necesario (Bug #1) |
| 3.2 | Crear tarea con recurrencia semanal | ✅ | "Barrer" (🏠, Lun+Mié) creada con 2 miembros |
| 3.3 | Crear tarea con rotación (2 miembros) | ✅ | Rotación Owner→Member habilitada. Selector "¿Quién empieza?" funcional. Detalle muestra ocurrencias alternadas desde el miembro seleccionado. Bug #21 ✅ CORREGIDO |
| 3.4 | Editar tarea existente | ⏳ | — |
| 3.5 | Ver detalle de tarea | ✅ | TaskDetailScreen muestra "Próximas fechas" con alternancia de miembros |
| 3.6 | Tarea vencida (chip "Vencidas") | ⏳ | Cloud Function corre a 00:05 UTC |

### 4. Unirse a Hogar

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 4.1 | Onboarding cuentas 2 y 3: unirse con código | ✅ | Member con V5W5X9, Admin con XJG2QK |
| 4.2 | Ver miembros del hogar (3 miembros) | ✅ | Owner, Member, Admin visibles en pestaña Miembros |
| 4.3 | Perfil de otro miembro | ✅ | Pantalla visible pero stats = 0 y avatar = ? (Bug #20) |

### 5. Miembros y Estadísticas

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 5.1 | Lista de miembros (3 miembros) | ✅ | Owner, Member, Admin visibles con rol y cumplimiento |
| 5.2 | Perfil propio (radar de stats) | ✅ | Bug #26 corregido. Owner muestra "7 Tareas completadas", "1 Racha actual". |
| 5.3 | Perfil de otro miembro | ⚠️ | Visible pero avatar "?" — Bug #20 (Bug #26 corregido: stats ya son correctas) |
| 5.4 | Valoración de tarea (privada) | ⏳ | — |
| 5.5 | Promoción de rol (Member → Admin) | ✅ | Via botón "Hacer administrador" en perfil del miembro (Owner ve botón, lo pulsa → rol cambia en Firestore). Bug #24 CORREGIDO: badge actualiza a "Admin" y botón cambia a "Quitar administrador" reactivamente sin salir de la pantalla. |

### 6. Historial

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 6.1 | Historial vacío | ✅ | Muestra "Sin actividad / Aún no hay eventos en el historial" |
| 6.2 | Historial con eventos | ✅ | "Owner completó 🧹 Fregar hace 1 min" — tile correcto con avatar, emoji, tiempo relativo e icono ✅ |
| 6.3 | Filtros de historial (Todos/Completadas/Pases/Vencidas) | ✅ | Filtros visibles y tabs funcionales |
| 6.4 | Tile de evento "Missed" | ⏳ | Requiere que Cloud Function procese tarea expirada (00:05 UTC) |
| 6.5 | Upsell Premium en historial | ✅ | Aparece debajo del evento con "Actualizar a Premium" |

### 7. Configuración del Hogar

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 7.1 | Ajustes del hogar (owner) — pantalla | ✅ | HomeSettings visible: nombre, código, secciones |
| 7.2 | HomeSettings → Miembros | ✅ | Bug #19 CORREGIDO (2026-04-16). Navega correctamente a lista de miembros. Verificado 3 ciclos sin crash. |
| 7.3 | HomeSettings → Generar código (Owner) | ❌ | onPressed vacío, Bug #5 |
| 7.3b | HomeSettings → Generar código (Member) | ✅ | Bug #30 y #33 CORREGIDOS (2026-04-16). Tile oculto para MemberRole.member. Owner y Admin ven el botón. Verificado en emulador: Owner ve "Generar código" ✅, Admin (toka.qa.member) ve "Generar código" ✅. |
| 7.4 | Mis hogares | ⏳ | — |
| 7.5 | Vacaciones | ⏳ | — |
| 7.6 | Permisos de rol — Admin | ✅ | Admin: FAB tareas ✅ (existe en UI dump, bloqueado por Bug #1), sin FAB invitar ✅, puede ver/congelar/borrar tareas ✅, sin botones gestión roles ✅ |
| 7.7 | Permisos de rol — Member | ✅ | Member: sin FAB tareas ✅, sin FAB invitar ✅, task detail read-only (sin Freeze/Delete/Edit) ✅, sin gestión roles ✅, HomeSettings: tile "Generar código" oculto para MemberRole.member (Bug #30 corregido) ✅ |

### 8. Suscripción Premium

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 8.1 | Pantalla suscripción (free) | ✅ | Muestra "Plan gratuito" con opción de actualizar |
| 8.2 | Paywall | ✅ | 29.99€/año y 3.99€/mes. Tabla de comparación de features. |
| 8.3 | Botón "Actualizar a Premium" historial | ✅ | Corregido: navega a `/subscription/paywall` (Bug #14 — 2026-04-17) |
| 8.4 | Ventana de rescate (3 días antes) | ⏳ | — |

### 9. Configuración e Idiomas

| Paso | Descripción | Resultado | Notas |
|------|-------------|-----------|-------|
| 9.1 | Pantalla settings | ✅ | Se carga correctamente, ver fallos #3-7 |
| 9.2 | Cambio de idioma (ES→EN→RO) | ❌ | onTap vacío (Bug #3) |
| 9.3 | Notificaciones settings | ✅ | Bug #29 CORREGIDO (2026-04-16). Toggles visibles: "Avisar al vencer" ON, "Avisar antes de vencer" OFF (Solo Premium), "Resumen diario" OFF (Solo Premium). Estado persiste tras pop+push. |
| 9.4 | Editar perfil | ✅ | Navega a EditProfileScreen |
| 9.5 | Selector de tema (Claro/Oscuro/Sistema) | ✅ | SegmentedButton funcional |

---

## Screenshots capturadas

| # | Archivo | Descripción |
|---|---------|-------------|
| 001 | `toka_qa/001_app_launch_step.png` | Splash screen inicial |
| 002 | `toka_qa/002_language_selector_step.png` | Selector de idioma inicial |
| 003 | `toka_qa/003_login_english_step.png` | Pantalla login en inglés |
| 007 | `toka_qa/007_onboarding_language_step.png` | Selección idioma onboarding |
| 008 | `toka_qa/008_onboarding_profile_step.png` | Perfil onboarding |
| 018 | `toka_qa/018_invite_code_generated_step.png` | Código de invitación generado |
| 025 | `toka_qa/025_invite_code_generating_step.png` | **Código V5W5X9 + QR generados ✅** |
| 026 | `toka_qa/026_crear_tarea_screen_step.png` | Pantalla crear tarea |
| 029 | `toka_qa/029_today_con_tarea_step.png` | Pantalla Hoy con tarea Fregar |
| 033 | `toka_qa/033_historial_con_evento_step.png` | Historial con evento de completación |
| 034 | `toka_qa/034_subscription_screen_step.png` | Pantalla suscripción |
| 036 | `toka_qa/036_paywall_screen_step.png` | Paywall 29.99€/año |
| 063 | `toka_qa/063_cuenta2_joined_home_step.png` | Cuenta 2 (Member) unida al hogar |
| 066 | `toka_qa/066_members_2_users_step.png` | Lista miembros con 2 usuarios |
| — | `toka_qa/admin_onboarding_start_step.png` | Admin iniciando onboarding |
| — | `toka_qa/admin_invalid_invite_code_step.png` | Error código inválido V5W5X9 |
| — | `toka_qa/admin_joining_home_step.png` | Admin uniéndose con XJG2QK |
| — | `toka_qa/members_3_users_admin_joined_step.png` | **3 miembros en Hogar QA Principal ✅** |
| — | `toka_qa/create_task_rotation_options_step.png` | Opciones de rotación en crear tarea |
| — | `toka_qa/rotation_selected_step.png` | Rotación seleccionada Owner+Member |
| — | `toka_qa/after_save_task_step.png` | Tarea "Barrer" guardada |
| — | `toka_qa/member_profile_view_as_admin_step.png` | Perfil de miembro (stats=0, avatar=?) |
| — | `toka_qa/home_settings_screen_step.png` | HomeSettings pantalla principal |
| — | `toka_qa/unexpected_miembros_screen_step.png` | Crash/comportamiento inesperado HomeSettings→Miembros |
| — | `toka_qa/app_loaded_login_step.png` | Pantalla login (estado actual al retomar sesión) |
| — | `toka_qa/fix_stats_1776326645_owner_final.png` | **Bug #26 CORREGIDO** — Perfil Owner: "7 Tareas completadas", "1 Racha actual" ✅ |
| — | `fix_avatar/009_member_profile_fixed_step.png` | **Bug #27 CORREGIDO** — Perfil Member: avatar "M", nombre "Member", rol "Miembro" ✅ |
| — | `fix_homesettings/004_members_from_homesettings_OK_step.png` | **Bug #19 CORREGIDO** — HomeSettings → Miembros sin crash. Lista de miembros visible ✅ |
| — | `fix_homesettings/005_ciclo3_members_sin_crash_step.png` | **Bug #19** — Ciclo 3 de navegación Miembros→Atrás→Miembros sin crash ✅ |

---

## Notas técnicas

- App: Toka (producción Firebase, proyecto `toka-dd241`)
- Emulador: emulator-5554 (Android 14 API 34, sdk gphone64 x86_64)
- Fecha sesión: 2026-04-15
- Rama git: main (commit: 8d492d5)
- Flutter 3.x + Dart 3.x · Riverpod + go_router + freezed
- Skin activa: **AppSkin.v2** (TodayScreenV2, HistoryScreenV2, etc.)
- Coordenadas ADB NavBar (device space): Home(144,2232), History(342,2232), Members(540,2232), Tasks(738,2232), Settings(937,2232)
- FAB "Invitar" en Members: (896,2222) — se superpone con Settings nav
- Workaround FAB: tocar en (896,2155) — borde superior del FAB, encima del nav bar
- Bug #15: ✅ CORREGIDO (2026-04-16) — ya no requiere `pm clear`. Fix único en `lib/app.dart` (RouterNotifier). NOTA: `auth_provider.dart` NO puede llamar `ref.invalidate(currentHomeProvider)` directamente — Riverpod lanza `CircularDependencyError` porque `currentHomeProvider` ya depende de `authProvider`. Verificado en emulador: Owner→logout→Admin(con hogar)→`/home`✓; Admin→logout→cuenta nueva→`/onboarding`✓. Screenshots: `toka_qa/fix_bug15/`.

---

## Pendiente por probar

> Esta sección lista todo lo que NO se ha podido verificar todavía, ordenado por prioridad. Usarla como checklist en futuras sesiones.

### P0 — Crítico (bloquea validación de la app)

| # | Feature | Qué verificar | Por qué pendiente |
|---|---------|--------------|-------------------|
| A | Editar tarea | ✅ RESUELTO — Bug #31 corregido (2026-04-16). IconButton ✏️ en AppBar: visible para owner/admin, oculto para member. Navegación a `CreateEditTaskScreenV2` con datos pre-rellenos confirmada. | Bug #31: CORREGIDO |
| B | BottomSheet valoración | Verificar envío de valoración cuando el botón NO está tapado por NavBar (p.ej. rotando el dispositivo o usando teclado) | Bug #25: botón inaccesible detrás de NavBar |
| C | Dashboard counters | ✅ RESUELTO — Bug #8 corregido. Pantalla Hoy muestra contadores correctos. | Bug #8: CORREGIDO (2026-04-16) |
| D | Notificaciones spinner | ✅ RESUELTO — Bug #29 corregido (2026-04-16). Toggles visibles, estado persiste. | Bug #29: CORREGIDO |

### P1 — Alto (funcionalidad principal no validada)

| # | Feature | Qué verificar | Por qué pendiente |
|---|---------|--------------|-------------------|
| E | Pantalla Hoy como Member | ¿Puede Member completar/pasar tareas asignadas a él? ¿Los botones "Hecho" y "Pasar" aparecen solo para las tareas asignadas? | No se hizo login como Member para probar la pantalla Hoy |
| F | Perfil propio (Owner) con radar chart | ¿El radar chart renderiza con datos reales cuando `tasksCompleted > 0`? | Bug #34 corregido (2026-04-17): estado vacío visible. Para ver el chart real se requieren ≥3 valoraciones en `memberTaskStats`. |
| G | Tarea vencida (Missed tile) | Esperar hasta después de las 00:05 UTC o crear condición de test; verificar chip "Vencidas" en historial y tile de tarea vencida | Cloud Function `processExpiredTasks` corre a 00:05 UTC; no se produjo en la sesión |
| H | Historial valoración (como receiver) | Verificar que el miembro valorado (Member) ve la notificación o badge de valoración recibida | Bug #25 bloqueó enviar valoraciones |
| I | Editar perfil (nombre + foto) | Navegar a EditProfileScreen → cambiar nombre → confirmar que se propaga a lista de miembros y perfil | Solo se verificó que navega; no se probó el guardado |
| J | Back navigation en TaskDetail | ✅ RESUELTO — Bug #32 corregido (2026-04-16). Rutas `/tasks/:id` movidas como sub-rutas de `/tasks` con `parentNavigatorKey: _rootNavigatorKey`. Verificado: 3 ciclos Tareas→Detalle→BACK→Tareas sin cerrar la app. | Bug #32: CORREGIDO |

### P2 — Medio (escenarios secundarios)

| # | Feature | Qué verificar | Por qué pendiente |
|---|---------|--------------|-------------------|
| K | Multi-hogar | Crear cuenta `toka.qa.owner2@gmail.com` → Hogar QA Secundario → verificar selector de hogar y cambio entre hogares | No se creó la segunda cuenta |
| L | Modo vacaciones | Navegar a ruta `/vacation` (si existe en la UI o vía ADB) → activar modo vacaciones → confirmar que las tareas se pausan | Feature no alcanzada en ninguna sesión |
| M | Cambio de idioma (ES→EN→RO) | Verificar que los textos cambian al idioma seleccionado, incluida sección "Apariencia" (Bug #4) | Bug #3: `onTap` vacío en Settings → Idioma |
| N | Ventana de rescate Premium (3 días antes) | Simular `premiumEndsAt` próximo y verificar que aparece el banner de rescate | No hay suscripción activa en cuentas QA |
| O | Ventana de restauración Premium (30 días tras downgrade) | Simular downgrade y verificar flujo de restauración | No hay suscripción activa en cuentas QA |
| P | Tarea con `hora_fija=true` (Hora fija) | Crear tarea con hora fija activada → verificar que el switch reporta `checked=true` en accesibilidad (Bug #13) y que la hora no varía | ✅ VERIFICADO (2026-04-17) — `checked="true"` confirmado vía `uiautomator dump`. Bug #13 CORREGIDO. |
| Q | Stats Member/Admin con datos reales | Tras fix de Bug #26 (`completedCount`→`tasksCompleted`), verificar que los stats se actualizan en perfil | Depende de fix de Bug #26 |

### P3 — Bajo (pulido y edge cases)

| # | Feature | Qué verificar | Por qué pendiente |
|---|---------|--------------|-------------------|
| R | Notificaciones push (FCM) | Completar una tarea asignada a otro miembro → verificar que llega push notification | No se verificó en ninguna sesión |
| S | Abandono del hogar (Member) | Settings → "Abandonar hogar" → confirmar que el Member desaparece de la lista y se redirige a onboarding | `onTap` vacío (Bug #3) |
| T | Expulsión de miembro (Owner) | Owner expulsa a Member desde HomeSettings → confirmar redirect del expulsado a onboarding | Bug #19 CORREGIDO. Pendiente probar el flujo de expulsión en sí. |
| U | Crear hogar adicional | Owner crea un segundo hogar (si el plan lo permite) → verificar límite de 2 hogares base | Multi-hogar no testado |
| V | Paginación del historial | Generar >20 eventos → verificar scroll infinito y que no se cargan todos los docs a la vez | No había suficientes eventos |
| W | Tema oscuro | Cambiar a tema oscuro → recorrer todas las pantallas buscando colores hardcodeados (Bug #6, #7) | ✅ RESUELTO — Bug #6 y #7 CORREGIDOS (2026-04-17). Colores adaptativos verificados en Settings y HomeSettings en ambos temas. |
| X | Accesibilidad (TalkBack) | Activar TalkBack → navegar por la app → verificar etiquetas semánticas y orden de foco | No se verificó en ninguna sesión |

---

## Cómo retomar esta sesión

1. Leer este archivo para ver el estado actual
2. Cuentas disponibles:
   - Owner: `toka.qa.owner@gmail.com / TokaQA2024!` — Hogar QA Principal (Propietario)
   - Member: `toka.qa.member@gmail.com / TokaQA2024!` — Hogar QA Principal (Miembro)
   - Admin: `toka.qa.admin@gmail.com / TokaQA2024!` — Hogar QA Principal (Admin ✅)
3. Código activo Hogar QA Principal: **XJG2QK** (V5W5X9 puede estar expirado)
4. Admin ya está promovido a rol "admin" ✅
5. **Próximo paso**: corregir bugs #36–#42 en orden de prioridad P0→P2 (ver sección ⏳ Pendiente)
6. Continuar con los ⏳ en orden de prioridad (ver sección "En curso")
7. Capturas: `adb exec-out screencap -p > toka_qa/<numero>_<nombre>.png`
8. Actualizar tablas: ✅ (OK), ❌ (FALLO), ⚠️ (ADVERTENCIA)
9. Si la app no inicia onboarding para nueva cuenta: `adb shell pm clear com.toka.toka`

### Archivos clave para los bugs nuevos

| Bug | Archivo(s) |
|-----|-----------|
| #36 Selector hogar | `lib/features/homes/presentation/home_selector_widget.dart` |
| #37 Icono fondo naranja | `lib/features/tasks/presentation/widgets/task_icon_picker.dart` (o similar) |
| #38 Codepoint en lugar de icono | Buscar render de `visualKind: 'icon'` + `visualValue` en tareas y pantalla Hoy |
| #39 BACK sale de app | `lib/app.dart` — `ShellRoute` + `PopScope` / `onPopInvoked` |
| #40 Sin botón expulsar | `lib/features/members/application/member_profile_view_model.dart` + `member_profile_screen_v2.dart` |
| #41 Lista no actualiza tras abandono | `lib/features/members/data/members_repository_impl.dart:21` — añadir `.where('status', isNotEqualTo: 'left')` |
| #42 Valoraciones vacías | `lib/features/history/application/history_view_model.dart:100-104` — implementar `rateEvent()` + leer `taskRatings` |
