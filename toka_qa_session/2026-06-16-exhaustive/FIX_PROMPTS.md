# Prompts de corrección por hallazgo — QA 2026-06-16

Un prompt autónomo por cada hallazgo de `RESULTS.md`, listo para pegar en una **nueva sesión de Claude Code** (abierta en la raíz del repo). Cada prompt empieza diciéndole a la sesión que lea **§0 (Contexto + Protocolo estándar)** de este mismo documento, así que cada bloque es corto pero completo.

> Sugerencia: abre la sesión nueva en `…/Proyectos/Toka`, pega **un solo** bloque ``` de los de abajo, y deja que trabaje. Cada uno es independiente.

---

## §0 — Contexto común y Protocolo estándar (lo lee cada sesión)

### Entorno
- Repo Flutter + Cloud Functions. Proyecto Firebase **producción**: `toka-dd241`. Cliente en `lib/`, backend en `functions/src/`, reglas en `firestore.rules`.
- **Compilar Android**: WSL no tiene SDK Android. Usar el Flutter de Windows: `cmd.exe /c "cd /d C:\Users\sebas\OneDrive\Escritorio\Proyectos\Toka && C:\Users\sebas\flutter\flutter\bin\flutter.bat pub get && ...flutter.bat build apk --debug"`. Tras compilar en Windows, correr `flutter pub get` en WSL para restaurar rutas Linux.
- **Dos dispositivos** (usar `adb.exe -s <serial>`, NO el MCP): MI_9 físico USB `43340fd2` (1080x2340, Madrid, teclado Facemoji), emulador `emulator-5554` (1080x2400, GMT, Gboard). Instalar APK: `adb.exe -s <serial> install -r -g <ruta-windows-del-apk>`.
- **Input por adb**: el teclado del MI_9 destroza `adb input text` (autocompletado) → escribir **carácter a carácter** con `toka_qa_session/2026-06-16-exhaustive/type.sh <serial> <texto>`. El emulador acepta texto normal. Helpers en esa carpeta: `shot.sh <serial> <nombre>` (captura→redimensiona ≤1900px→devuelve ruta para Read), `ui.sh <serial>` (vuelca UI como `bounds :: texto/content-desc`; los checkboxes/radios son nodos `clickable="true"` aparte en el XML crudo). Navbar: emulador y≈2221, MI_9 y≈2166.
- **Admin SDK** (rol runtime, lectura/escritura; firebase-admin en `functions/node_modules`): `secrets/toka-sa.json`. Scripts: `secrets/qa_audit_state.js` (auditoría), `secrets/qa_premium.js <homeId> <ownerUid> <free|active|cancelledPendingEnd|rescue|expiredFree|restorable> [horas]` (fuerza estado premium), `secrets/qa_setup_accounts.js` (crea/asegura cuentas QA con `emailVerified=true`).
- **Cuentas QA** (password `TokaQA2024!`): `toka.qa.n2@tokatest.dev` (uid `wwL0OTdrNeMZs2wTt6QtRDT1nb53`), `toka.qa.n3@tokatest.dev`, `toka.qa.owner@gmail.com`, `toka.qa.member@gmail.com`, `toka.qa.admin@gmail.com`. **N1** (`toka.qa.n1@…`) fue borrada en la sesión; recréala con `node secrets/qa_setup_accounts.js`. Login por adb sin Google (campos email≈(540,1043), pass≈(540,1241), botón≈(540,1450) en MI_9; cerrar teclado antes de pulsar).
- **Hogar de pruebas**: `SMQRtCjrA09gPIr1wazD` "Hogar QA Noche" (owner N2). Hay un **miembro huérfano de N1** (`status=active`, cuenta borrada) — útil para el bug de borrado. Para probar "Hecho" hay que forzar `nextDueAt` al pasado (en el doc de la tarea **y** en `views/dashboard.activeTasksPreview`) vía Admin SDK.
- **Tests**: `flutter test test/unit/`, `flutter test test/integration/` (requiere emuladores Firebase locales: `firebase emulators:start`), `flutter test test/ui/`. Mocks con `mocktail`. La suite tiene **57 fallos pre-existentes** verificados (2026-06-18), todos en `test/ui/` — no son regresiones. Recuento y desglose por causa en `PREEXISTING_TEST_FAILURES.md`: **45 golden mismatch** (imágenes de otra máquina; el shader `ink_sparkle.frag` NO aparece en la corrida), 4 timezone sin init, ~3 GoRouter, 2 timeouts, ~3 layout.

### Protocolo estándar (aplícalo en CADA prompt)
1. **Reproduce y diagnostica**: confirma si es bug real o **falso positivo** (p. ej. artefacto de automatización por adb — en ese caso pruébalo con un toque/flujo manual real y déjalo documentado). Lee el código relacionado y entiende la causa raíz. Mira si hay **causas o casos relacionados no detectados** en la sesión QA.
2. **Arregla** la causa raíz (cliente y/o backend y/o reglas). Mantén el estilo del código vecino. Nada de hardcodear texto UI (usar ARB).
3. **Tests**: añade/actualiza cobertura que falle antes del fix y pase después — unitarios (caso feliz + edge), integración con emuladores si toca Firestore/Functions, y UI/golden si es pantalla. `flutter analyze` sin errores; backend con `tsc` estricto si tocas `functions/`.
4. **Verifica en los DOS dispositivos** (USB `43340fd2` + emulador `emulator-5554`): compila e instala el build, reproduce el flujo end-to-end en ambos, usa Admin SDK para preparar estado si hace falta (deja constancia con `[ADMIN SDK]`), toma **capturas**, analízalas contra el comportamiento esperado y **bórralas al terminar**.
5. **Documenta** en `toka_qa_session/2026-06-16-exhaustive/fixes/<slug>.md`: si era falso positivo (por qué), la causa raíz, el fix, los tests añadidos, evidencia de las 2 verificaciones, y **cualquier mejora u otro fallo detectado** durante el trabajo (con su propia mini-repro).
6. **No** marques como resuelto si los tests fallan o la verificación en dispositivo no confirma el arreglo.

---

## §1 — 🔴 Diálogos de acción de miembro no responden a toques

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG: En la pantalla de perfil de un miembro (Miembros → tocar un miembro), al pulsar "Hacer administrador", "Quitar administrador" (y probablemente "Expulsar del hogar") aparece el diálogo de confirmación, pero NI "Cancelar" NI el botón de confirmar reaccionan a los toques. Tocar la zona SUPERIOR del diálogo (barrier) sí lo cierra; los botones de la mitad inferior no responden → parece un overlay/scrim por encima del diálogo capturando los toques. Otros diálogos de la app (Completar/Pasar tarea, Eliminar tarea, Cerrar sesión) SÍ responden con el mismo método → es específico del perfil de miembro.
REPRO: emulador, hogar SMQRtCjrA09gPIr1wazD (premium para que admin esté disponible: `node secrets/qa_premium.js SMQRtCjrA09gPIr1wazD wwL0OTdrNeMZs2wTt6QtRDT1nb53 active`). Verificado con `input tap` y `input motionevent DOWN/UP` sobre el centro exacto de los botones.
PISTAS DE CÓDIGO: lib/features/members/presentation/skins/member_profile_screen_v2.dart, lib/features/members/application/member_actions_provider.dart, lib/features/members/application/member_profile_view_model.dart. Backend: functions/src/homes/index.ts (promoteToAdmin línea ~781, demoteFromAdmin ~848, removeMember ~494). Revisa cómo se hace showDialog (¿Navigator anidado? ¿useRootNavigator? ¿barrier/overlay del propio perfil que queda por encima? ¿el perfil es un sheet o un route?).
OJO: confirma primero si es bug real con un TOQUE MANUAL en el dispositivo (no solo adb). Si el dialog real sí funciona con dedo, documenta que era artefacto de automatización y por qué. Si es real, es ALTA severidad (bloquea gestión de roles y expulsión). Cubre los 3 diálogos (promover/degradar/expulsar) en el fix y en los tests.
```

---

## §2 — 🔴 "Pasar turno" desinforma (sin candidato / sin penalización)

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG: El diálogo de "Pasar turno" SIEMPRE muestra "No hay otro miembro disponible, seguirás siendo el responsable" aunque exista un siguiente responsable válido, y NUNCA muestra el siguiente responsable ni el aviso de penalización de cumplimiento. Sin embargo, el SERVIDOR sí pasa el turno correctamente al otro miembro (evento `passed` con `to=<otro>`, `noCandidate=false`). Es decir: el cálculo cliente de "siguiente elegible" está roto y desinforma. VIOLA la regla de negocio #7 ("Pasar turno genera penalización estadística VISIBLE antes de confirmar").
REPRO: tarea con 2 miembros asignados (orden [A,B]); el responsable actual abre "Pasar" en su dispositivo → el diálogo dice que no hay candidato y no muestra penalización; tras confirmar, el backend pasa el turno a B (verificable con secrets/qa_audit_state.js o leyendo homes/{id}/taskEvents). Reproducido en AMBOS dispositivos con datos totalmente cargados (no es carrera de sync).
PISTAS DE CÓDIGO: lib/features/tasks/presentation/widgets/pass_turn_dialog.dart (lógica cliente de next-eligible y de compliance: `PassTurnDialog.calcEstimatedCompliance`, mensaje `pass_turn_no_candidate` vs `pass_turn_next_assignee`/`pass_turn_compliance_warning`). lib/features/tasks/application/task_pass_provider.dart. Backend correcto de referencia: functions/src/tasks/pass_task_turn.ts y functions/src/tasks/pass_turn_helpers.ts (`getNextEligibleMember`). El cliente probablemente pasa mal los argumentos (lista de miembros / uid actual / frozenUids) o usa una fuente distinta a `assignmentOrder`. Alinea la lógica cliente con la del backend y muestra el nombre del siguiente responsable + la penalización estimada (completed/(completed+passed+1)).
```

---

## §3 — 🔴 Eliminar cuenta deja membresía fantasma

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG: Al eliminar la cuenta (Ajustes → Eliminar cuenta, tras reauth), la cuenta se borra de Firebase Auth, pero el documento de miembro del usuario en sus hogares queda con `status=active` (miembro "fantasma" con cuenta inexistente). En el hogar SMQRtCjrA09gPIr1wazD quedó así el usuario uid ZynuqUTlbtb1R1qBv74Wi7iEmuN2 (cuenta ya borrada) como evidencia.
REPRO: crea una cuenta de prueba (node secrets/qa_setup_accounts.js o Admin SDK), úsala para unirse a un hogar, y elimina la cuenta desde la app (requiere re-login reciente). Comprueba con Admin SDK que homes/{homeId}/members/{uid}.status sigue "active" y users/{uid}/memberships/{homeId} sigue existiendo.
PISTAS DE CÓDIGO: el borrado vive en Ajustes/auth (busca `FirebaseAuth.instance.currentUser?.delete()` y la clave i18n `settings_delete_account`). Lo correcto: o bien una Cloud Function `functions/src/...` con trigger `auth.user().onDelete` (o `beforeUserDeleted`) que limpie membresías (poner `status=left`/`removed`, borrar `users/{uid}/memberships/*`, decrementar contadores de miembros del dashboard, y manejar el caso owner/pagador), o un callable que limpie ANTES de borrar la cuenta. Decide la mejor estrategia. Considera el caso en que el borrado deje un hogar sin owner o sin pagador premium.
EXTRA: revisa también qué pasa con tareas asignadas al usuario borrado (currentAssigneeUid huérfano) y con su histórico/valoraciones (deben conservarse como snapshot, pero sin romper la UI de otros miembros).
```

---

## §4 — 🔴 Teléfono y visibilidad no se propagan al doc de miembro

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG: Un usuario que en el onboarding/perfil pone teléfono y activa "Mostrar mi teléfono a miembros del hogar" (queda en users/{uid}.phone y users/{uid}.phoneVisibility="sameHomeMembers") al UNIRSE a un hogar genera un doc de miembro con `phone:null` y `phoneVisibility:"hidden"`. El nickname y la foto SÍ se propagan al doc de miembro, pero el teléfono y su visibilidad NO → otros miembros no ven el teléfono aunque el usuario haya optado por compartirlo. Confirmado: el perfil del miembro visto por otro no muestra teléfono.
REPRO: con una cuenta nueva, onboarding con teléfono + visibilidad ON, unirse a un hogar por código; comparar users/{uid} vs homes/{homeId}/members/{uid} con Admin SDK; abrir su perfil desde otro miembro.
PISTAS DE CÓDIGO: functions/src/homes/index.ts → `joinHome` (~178), `joinHomeByCode` (~285) y el helper que construye el doc de miembro (`buildNewMemberDoc`); y `syncMemberProfile` (~898, trigger que sincroniza nickname/photo). Propaga también `phone` y `phoneVisibility` desde users/{uid}. Decide la semántica correcta (¿la visibilidad es global del usuario o por hogar? — alinéalo con cómo lo lee MemberProfileViewData.visiblePhone en lib/features/members/application/member_profile_view_model.dart). Asegúrate de que al editar el perfil después también se re-sincroniza.
```

---

## §5 — 🟠 El objeto `home` cacheado no refresca en vivo

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG (patrón de sync): Los cambios en el documento homes/{homeId} NO se reflejan en la UI en vivo; solo tras reiniciar la app. Casos observados: (a) avatar del hogar seguía mostrando la inicial tras subir la foto (home.photoUrl ya guardado); (b) la tile Ajustes→Suscripción mostraba "Plan gratuito" estando el hogar en premium; (c) los banners de estado premium (cancelledPendingEnd/rescue/restorable/expiredFree) no aparecían tras cambiar premiumStatus; (d) tras "Abandonar hogar", la app seguía mostrando el hogar y sus tareas con botones. En cambio, el documento views/dashboard SÍ refresca en vivo (ads, contadores, tareas). 
REPRO: con la app abierta en un dispositivo, cambiar vía Admin SDK home.photoUrl o premiumStatus (node secrets/qa_premium.js …) y observar que la UI no cambia hasta reiniciar; comparar con un cambio en el dashboard que sí refresca.
PISTAS DE CÓDIGO: el provider/stream del home actual (busca `currentHomeProvider`, el repositorio de homes `lib/features/homes/data/...`, y dónde se hace el `snapshots()`/listener de homes/{homeId}). Probablemente se lee con `.get()` una vez o el provider no re-emite, o se cachea el objeto Home. Conviértelo en un stream del documento (como el dashboard) e invalida correctamente al cambiar de hogar (`ref.onDispose`). Verifica que avatar, nombre, estado premium, banners y membresía propia se actualizan en vivo en los DOS dispositivos.
```

---

## §6 — 🟡 Errores de validación no se limpian al corregir el campo

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG (UX): Varios formularios muestran el error de validación en rojo y NO lo limpian aunque el usuario corrija el campo; el error persiste hasta el siguiente submit. Casos: login (email inválido → escribir email válido y el error sigue), onboarding perfil ("El apodo es obligatorio" sigue tras escribir), unirse por código ("Código de invitación inválido" sigue tras corregir).
PISTAS DE CÓDIGO: lib/features/auth/presentation/... (EmailAuthForm), lib/features/onboarding/presentation/... (paso perfil), formulario de unirse a hogar. Revisa `autovalidateMode` (probablemente onUserInteraction pero el error de submit no se re-evalúa onChanged) y la gestión de mensajes de error en los view models. Que el error se borre al teclear/onChanged cuando el valor pasa a ser válido. Añade tests de widget.
```

---

## §7 — 🟡 Banner de AdMob visible en "Crear tarea" pese a premium

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG: Con el hogar en premium (dashboard.premiumFlags.showAds=false), la pantalla "Crear tarea" SIGUE mostrando el banner de AdMob de prueba, mientras que la pantalla Hoy sí lo oculta. La pantalla de creación no respeta el flag premium para ads.
REPRO: `node secrets/qa_premium.js SMQRtCjrA09gPIr1wazD wwL0OTdrNeMZs2wTt6QtRDT1nb53 active`, reiniciar app, abrir Tareas → "+" → ver el banner abajo.
PISTAS DE CÓDIGO: lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart (widget de ad). Compara con cómo Hoy decide mostrar ads (premium_feature_gate / dashboard premiumFlags.showAds o adFlags). Haz que el ad de "Crear tarea" (y revisa otras pantallas: Tareas, Miembros, Historial) respete `showAds`. Revisa TODAS las pantallas que pintan banner.
```

---

## §8 — 🟡 "Distribución inteligente" habilitada por flag pero sin UI

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG/GAP: Con premium, dashboard.premiumFlags.canUseSmartDistribution=true, pero el formulario de crear/editar tarea NO ofrece ningún selector de "Distribución inteligente" (assignmentMode basicRotation/smartDistribution). Solo existe rotación básica + "Si vence sin completar" (Mantener/Rotar). La feature está en el backend pero sin punto de entrada en UI.
PISTAS DE CÓDIGO: lib/features/tasks/presentation/widgets/assignment_form.dart, lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart, lib/features/tasks/application/task_form_provider.dart (campo assignmentMode). Backend: functions/src/tasks/task_assignment_helpers.ts (`getNextAssigneeSmart`). Decide si añadir el toggle basic/smart (con gate premium: si free, mostrar candado/paywall) o si la feature debe retirarse. Si se añade, persiste assignmentMode y verifica que la rotación real usa smart (carga reciente/dificultad) con ≥2 miembros y datos de carga distintos. Tests del helper y de la UI.
```

---

## §9 — 🟡 Tile Ajustes → Suscripción no navega

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG: En Ajustes, la tile "Suscripción · Plan Premium/gratuito" no navega a ninguna pantalla de gestión al tocarla (solo hace scroll de la lista). El acceso al flujo premium queda solo por los banners. Se esperaba que navegara a la pantalla de gestión de suscripción (AppRoutes.subscription).
PISTAS DE CÓDIGO: lib/features/settings/presentation/... (SettingsScreen, tile de suscripción y su onTap). Comprueba que el ListTile tiene onTap → context.push/go(AppRoutes.subscription) y que la ruta existe y muestra la gestión (SubscriptionManagementScreen). Revisa también "Restaurar compras". (Relacionado con §5: el estado mostrado en la tile dependía de reiniciar; confírmalo de paso.)
```

---

## §10 — 🟡 Avatar del hogar no se denormaliza al dashboard

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

MEJORA/BUG: El avatar del hogar (home.photoUrl) no se copia al documento views/dashboard (no hay `homePhotoUrl`), por lo que la pantalla Hoy (que lee solo el dashboard) no puede mostrar la foto del hogar en su cabecera. 
DECISIÓN: o denormalizar `homePhotoUrl` (y `homeName`) al dashboard cuando cambian, o que la cabecera de Hoy lea home.photoUrl del provider del home. Implementa una de las dos de forma coherente y verifica que la foto del hogar aparece donde deba (cabecera Hoy, selector de hogares, ajustes del hogar) en los dos dispositivos.
PISTAS DE CÓDIGO: functions/src/tasks/update_dashboard.ts (construcción del dashboard), lib/features/tasks/presentation/skins/today_screen_v2.dart (cabecera), lib/features/homes/.../home_settings (subida de avatar: `updateHomePhoto`). (Relacionado con §5.)
```

---

## §11 — 🟡 Botón "Valorar" no se actualiza en vivo tras valorar

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG (UX menor): En Historial, tras enviar una valoración de un evento completado, el botón/estrella "Valorar" del evento NO cambia a estado "valorado" en vivo (sigue mostrando "Valorar"); solo se actualiza al salir y reentrar (al reentrar abre el detalle con la valoración existente, lo cual sí es correcto).
REPRO: premium; Historial; valorar un evento "completado" de otro miembro; observar que el botón no cambia hasta reentrar.
PISTAS DE CÓDIGO: lib/features/history/presentation/... (HistoryScreenV2, history_event_tile.dart), lib/features/history/application/... (history view model, `rateEvent`/submitReview, member_reviews_provider). Tras `submitReview`, invalida/actualiza el provider de la lista para que el evento se marque como valorado (`isRated`). Test de widget.
```

---

## §12 — 🟡 Payer-lock bloquea pero sin mensaje claro

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

BUG (UX): El "payer-lock" funciona (el pagador no puede transferir propiedad / abandonar mientras hay premium activo: el backend rechaza), pero el usuario NO recibe un mensaje claro de por qué falló (no se observó snackbar; la acción simplemente no surte efecto y vuelve a Ajustes). 
REPRO: N2 es owner+pagador de SMQRtCjrA09gPIr1wazD en premium active; Ajustes → Abandonar hogar → "Transferir propiedad" → seleccionar a otro → Transferir → no pasa nada visible (owner sigue siendo N2). Verifica con Admin SDK que no cambió.
PISTAS DE CÓDIGO: backend lanza `failed-precondition` con "payer-cannot-leave-or-be-removed-while-premium-active" (functions/src/homes/index.ts en leaveHome/removeMember/transferOwnership). Cliente: lib/features/homes/.../home_settings y el flujo de transferir/abandonar (settings). Mapea ese error a un SnackBar/diálogo con la clave i18n `members_error_payer_locked` (o similar) explicando que debe cancelar/esperar el fin del premium. Cubre los 3 caminos (abandonar, expulsar al pagador, transferir).
```

---

## §13 — 🟡 Verificar contador "tareas para hoy" (tasksDueToday)

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo.

A VERIFICAR (posible bug): La cabecera de Hoy mostró "0 tareas para hoy" mientras había una tarea activa listada con vencimiento "hoy". Puede ser correcto (la próxima ocurrencia caía al día siguiente por zona horaria) o un fallo de cómputo de `counters.tasksDueToday`.
TAREA: determina la definición correcta de "due today" (por zona horaria del hogar/dispositivo) y comprueba que `counters.tasksDueToday` cuenta exactamente las tareas activas cuyo próximo vencimiento cae en el día actual. Crea casos con tareas cuyo nextDueAt cae hoy (varias zonas horarias) y valida el contador.
PISTAS DE CÓDIGO: functions/src/tasks/update_dashboard.ts (cálculo de `counters.tasksDueToday`/`tasksDoneToday`), lib/features/tasks/domain/home_dashboard.dart, today_screen_v2.dart (header counters). Cuidado con TZ: el emulador está en GMT y el MI_9 en Madrid; documenta en qué zona se considera "hoy". Tests unitarios del builder del dashboard con fechas fijas (pásalas por parámetro, no `DateTime.now()`).
```

---

## §14 — 💄 Limpieza visual/UX menor (agrupado)

```
Trabajas en el repo Toka. Lee toka_qa_session/2026-06-16-exhaustive/FIX_PROMPTS.md §0 (Contexto + Protocolo estándar) y aplícalo. Son retoques menores; agrúpalos en un solo PR.

ITEMS:
1. El subformulario "Crear hogar" (onboarding y "Añadir hogar") conserva el título de la pantalla anterior "¿Qué quieres hacer?" y deja mucho espacio vertical vacío arriba. Darle un título propio (p. ej. "Crea tu hogar") y mejor distribución vertical. Pistas: lib/features/onboarding/presentation/... (HomeChoiceStep) y el sheet de crear hogar desde el selector de hogares.
2. No se puede ELIMINAR una tarea desde su pantalla de DETALLE (solo Editar/Congelar); el borrado solo está en swipe-izquierda de la lista. Añadir acción de borrar (con confirmación) en el detalle. Pistas: lib/features/tasks/presentation/skins/task_detail_screen_v2.dart.
3. El borrado de tarea es lógico (status="deleted") pero no guarda `deletedAt`. Añadir `deletedAt: serverTimestamp()` para auditoría/limpieza futura. Pistas: el repositorio/callable de borrado de tareas.
4. Revisar el desfase de ~10s del rebuild del dashboard tras completar/pasar (functions update_dashboard.ts / applyTaskCompletion) — ver si se puede acelerar o dar feedback optimista en UI.
Verifica visualmente en los dos dispositivos y borra las capturas al terminar.
```

---

### Orden sugerido
Alta primero: **§1, §2, §3, §4, §5**. Luego §7, §9, §12 (rápidos y visibles), §6, §8, §10, §11, §13, §14. Cada uno es independiente; pueden ir en paralelo en ramas separadas salvo §9/§10/§5 que tocan zonas relacionadas (suscripción/home) — coordínalos.
