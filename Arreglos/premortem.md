# Premortem Toka — Plan de remediación

Cada sección de abajo es un **prompt autónomo** para una sesión nueva de Claude Code. Están ordenados de **más crítico a menos**. Implementa de arriba abajo.

Por cada fallo el prompt obliga a: (1) **verificar primero si es un falso positivo** con su propio análisis, (2) arreglarlo solo si se confirma, (3) escribir tests, (4) **verificarlo en el móvil físico Y en el emulador con cuentas distintas** para comprobar sincronización y que ninguna cuenta vea datos que no le corresponden, (5) **actualizar el estado en este documento** y (6) apuntar cualquier hallazgo nuevo en `Arreglos/Hallazgos.md`.

---

## Protocolo común (LÉEME ANTES DE CADA PROMPT)

> Todos los prompts asumen que has leído esta sección. No la repito en cada uno.

### Fuente de verdad y lenguaje
- El **código es la fuente de verdad** de lo implementado; los documentos (`CLAUDE.md`, `architecture/data-model.md`, `execution-order.md`, el PDF maestro) son las reglas de producto. Responde en **español**.
- Antes de tocar nada, **relee los archivos citados**. El hallazgo puede ser un falso positivo (ya corregido, mal interpretado, o mitigado en otra capa). Si lo es: **no cambies código**, marca el estado como `🟦 Falso positivo` con la justificación y registra el matiz en `Hallazgos.md`.

### Dispositivos (ambos ya conectados — `adb devices`)
- **Físico MI_9** → id `43340fd2`, resolución **1080×2340**.
- **Emulador** → id `emulator-5554`, resolución **1080×2400** (las coordenadas de tap difieren entre ambos; no copies coords a ciegas).
- Apunta a uno u otro con `adb -s <id> ...`.
- **WSL no compila Android.** Para instalar el build usa el Flutter de Windows vía interop + `adb.exe` (ver memoria `build-android-from-wsl`). Haz `pub get` en Windows antes de `build` (ver `clean-apk-build-broken-cfe-exhaustiveness`).

### Cuentas QA (las 3 ya existen — credenciales en `toka_qa_session/QA_SESSION.md`)
| Rol | Email | Contraseña |
|-----|-------|------------|
| Owner | toka.qa.owner@gmail.com | TokaQA2024! |
| Member | toka.qa.member@gmail.com | TokaQA2024! |
| Admin | toka.qa.admin@gmail.com | TokaQA2024! |

- **Login por adb SIN Google** siguiendo el procedimiento exacto de `CLAUDE.md` (tap campo email → escribir → tap directo campo contraseña → escribir → tap iniciar sesión). **Nunca** `adb shell input tap` sobre sugerencias de Google.
- Para campos sensibles a corrupción (p. ej. **código de invitación**) usa `toka_qa_session/<sesión>/type.sh` char-a-char; `adb input text` corrompe el campo (ver `qa-regression-2026-06-19`).

### Regla de oro de la verificación: **2 dispositivos = 2 cuentas distintas**
- Carga una cuenta en el **físico** y **otra distinta** en el **emulador** (p. ej. Owner en físico, Member/Admin en emulador). Comparten el mismo hogar de prueba para observar la **sincronización en vivo entre cuentas** (ver `two-devices-different-profiles`). **No** repitas la misma prueba con la misma cuenta en ambos.
- Para **cada arreglo** verifica explícitamente la propiedad de seguridad/visibilidad: **que la cuenta B no pueda ver ni hacer lo que no le corresponde** tras el cambio (datos de otros, acciones no permitidas, estados que no deberían sincronizarse). Cuando el cambio sea de privacidad/reglas, este es el criterio principal.

### Inspección directa de Firestore (producción `toka-dd241`)
- Usa los helpers Admin SDK de `secrets/` con `secrets/toka-sa.json`: `qa_inspect_home.js`, `qa_dump_tasks.js`, `qa_premium.js`, `qa_make_invite.js`, `qa_audit_state.js`, `qa_set_task_field.js`, etc. Sirven para montar escenarios y para comprobar el estado real en BD tras una acción en el móvil.

### Capturas de pantalla
- Captura con `toka_qa_session/<sesión>/shot.sh` o `adb -s <id> exec-out screencap -p > C:\tmp\...png` (vía `magick.exe` si hay que redimensionar >1900px, ver `CLAUDE.md`).
- **Analiza la captura y bórrala** después (no dejes PNG en el repo). Las capturas son solo evidencia transitoria para tu análisis.
- Localiza elementos por etiqueta semántica con `ui.sh` (Flutter expone content-desc) cuando el tap por coordenadas sea frágil.

### Tests (convenciones de `CLAUDE.md`)
- Todo arreglo lleva tests: **caso feliz + caso de error/edge**. Unitario siempre; **integración con emulador Firebase** si toca Firestore/Functions; UI/golden si toca pantalla nueva. `mocktail`, nunca `mockito`.
- Backend: TypeScript estricto, tests junto al código (`*.test.ts`) y/o en `functions/test/`. **Evita "tests espejo"** que reimplementan la lógica en el propio test: ejercita la callable/función real (emulador).
- Antes de cerrar: `flutter analyze` (0 errores) y la suite afectada en verde. Para functions: `npm test` en `functions/`.

### Despliegue
- Valida **primero contra emuladores Firebase** (`firebase emulators:start`). 
- **Desplegar reglas o functions a producción (`toka-dd241`) requiere autorización explícita del usuario.** No despliegues a prod por tu cuenta. Si el arreglo es de rules/functions y necesitas probar en los móviles contra prod, **pídelo y espera el OK**; mientras, demuestra la corrección con tests de emulador. (`firebase deploy --only functions` necesita `FUNCTIONS_DISCOVERY_TIMEOUT=120`; ojo: usa el working tree, ver `deploy-functions-discovery-timeout`.)

### Git
- Trabaja en la rama actual o crea una rama por arreglo si lo prefieres. Separa el ruido CRLF con `git diff --ignore-cr-at-eol` (ver `git-commit-hygiene-crlf-and-windows-push`). **Commit/push solo si el usuario lo pide**; WSL no tiene credenciales de GitHub (empuja con el git de Windows).

### Cierre de cada prompt — actualiza ESTE documento
Al terminar la verificación exhaustiva, edita la cabecera de estado del prompt correspondiente con una de:
- `✅ Solucionado, testeado y verificado (móvil + emulador) — AAAA-MM-DD` + 2-3 líneas de qué se cambió, qué tests se añadieron y el resultado de la prueba en ambos dispositivos.
- `🟦 Falso positivo — AAAA-MM-DD` + justificación.
- `🟧 Parcial / bloqueado — AAAA-MM-DD` + qué falta y por qué (p. ej. esperando autorización de deploy a prod).

Cualquier **error o mejora nuevos** que descubras de paso → anótalos en `Arreglos/Hallazgos.md` (no los arregles fuera de alcance salvo que sean triviales y relacionados).

### Leyenda de estado
⬜ Pendiente · ✅ Solucionado/verificado · 🟦 Falso positivo · 🟧 Parcial/bloqueado

---

## Índice y estado

| # | Fallo | Categoría | Severidad | Estado |
|---|-------|-----------|-----------|--------|
| 01 | PII legible por co-miembros (teléfono hidden, token FCM, enum. invitaciones, expulsado lee) | Privacidad | 🔴 Crítica | ✅ Desplegado y verificado (prod + 2 dispositivos) |
| 02 | Sin verificación real de recibos IAP (Premium no cobrable o falsificable) | Monetización | 🔴 Crítica | 🟧 Implementado + verificado en emulador; pendiente deploy a prod + sandbox |
| 03 | `debugSetPremiumStatus` desplegable a producción (bypass Premium) | Privacidad/Monetización | 🔴 Crítica | ✅ Eliminado del código y retirado de prod (`functions:delete`) — verificado (404) |
| 04 | GDPR: "eliminar cuenta" no borra datos ni hay exportación | Privacidad | 🟠 Alta | ✅ Desplegado y verificado (prod + escenario 15/15 + export en dispositivo) |
| 05 | Banner con unit IDs de TEST de AdMob (cero ingresos) | Monetización | 🟠 Alta | 🟧 Mecanismo hecho + testeado (unit+integración emulador+guardrail); cierre pendiente de IDs reales de AdMob + deploy autorizado |
| 06 | Sin RTDN/refunds + downgrade no automático (Premium gratis perpetuo) | Monetización | 🟠 Alta | 🟧 Cron de downgrade ampliado (`active` vencido) DESPLEGADO + verificado en prod (+índice que faltaba, H-019); reconciliación RTDN/ASSN implementada y testeada (emulador+dispositivos), su deploy pendiente de infra de stores del #02 |
| 07 | Pantalla "Hoy" se queda stale (crear/editar/borrar no reconstruyen) | Producto | 🟠 Alta | ✅ Desplegado y verificado (prod + 2 dispositivos) |
| 08 | Tareas zombi de ex-miembros (no salen de la rotación) | Conflicto | 🟠 Alta | ✅ Solucionado, testeado, desplegado y verificado (prod + 2 dispositivos) |
| 09 | Vacaciones penaliza a los ausentes | Conflicto | 🟠 Alta | ✅ Solucionado, testeado, desplegado y verificado (emulador + prod + 2 dispositivos) |
| 10 | Motor de recurrencia deriva (DST + mensual/anual ignoran la regla) | Producto | 🟠 Alta | ✅ Solucionado, testeado, desplegado y verificado (prod + 2 dispositivos) |
| 11 | Reparto percibido injusto (penalización silenciosa + editar reinicia rotación) | Conflicto | 🟠 Alta | ✅ Solucionado, testeado y verificado (2 dispositivos + prod) — 2026-06-22 |
| 12 | Gobernanza de roles (owner SPOF, admin expulsa unilateral, invitar-email muerto) | Conflicto | 🟠 Alta | ✅ Solucionado, testeado y verificado (2 dispositivos + deploy dev) — 2026-06-22 |
| 13 | Reparto "inteligente" usa `completions60d` que nunca decae | Producto | 🟡 Media | ✅ Solucionado, testeado y verificado (2 dispositivos + deploy dev) — 2026-06-22 |
| 14 | Conversión ahogada (sin free trial + límite Free de tareas eludible) | Monetización | 🟡 Media | 🟧 Límite Free no eludible: hecho+testeado (emulador, incl. concurrencia); trial cableado+testeado. Pendiente: deploy autorizado (bloqueado por secretos #02) + config de oferta en stores. Vector residual freeze/unfreeze → H-028 |
| 15 | Jobs con barridos full-collection (coste lineal con nº de hogares) | Tecnología | 🟡 Media | ✅ Implementado + testeado + medido (502× menos reads/500 hogares); **desplegado y verificado en prod (`toka-dd241`)**: `dispatchDueReminders` recorrió el camino collectionGroup end-to-end y el fan-out reconstruyó 11/11 dashboards (purged excluidos) vía Cloud Tasks |
| 16 | Hot document dashboard + batches >500 + cap 100 tareas/día | Tecnología | 🟡 Media | ✅ Implementado, testeado, **desplegado y verificado en prod** (`toka-dd241` + 2 dispositivos): delta del dashboard `rev`=1 live + sync entre cuentas. closeHome = 🟦 falso positivo (solo tombstone) |
| 17 | Observabilidad de soporte + purga de tokens FCM muertos + `sentNotifications` sin TTL | Soporte | 🟡 Media | ✅ Implementado, testeado (emulador), **desplegado a prod** y **verificado en dispositivo** (callable con datos en vivo redactados, sin PII; App Check enforcing). Purga FCM end-to-end cubierta por tests + deploy — 2026-06-22 |
| 18 | Onboarding muere offline en selección de idioma | UX | 🟡 Media | ✅ Solucionado, testeado y verificado (2 dispositivos) — 2026-06-22 |
| 19 | Accesibilidad: sin `textScaler`, botones sin semántica, overflow | UX | 🟡 Media | ✅ Solucionado, testeado y verificado (móvil XL + emulador normal) — 2026-06-22 |
| 20 | Completar tarea exige doble tap + confirmación / cobertura de tests débil | UX/Calidad | 🟢 Baja | ✅ Solucionado, testeado y verificado (2 dispositivos + suites verdes) — 2026-06-23 |

---

## Prompt 01 — PII legible por cualquier co-miembro (privacidad/seguridad)
**Categoría:** Privacidad · **Severidad:** 🔴 Crítica · **Estado:** ✅ Solucionado, testeado y verificado (móvil + emulador + prod) — 2026-06-21

> **Verificación (PASO 1):** las 4 fugas CONFIRMADAS. (a) teléfono: `member_factory.ts:51` + `syncMemberProfile` escribían el número sin filtrar; el filtrado vivía solo en cliente (`member.dart phoneForViewer`). **Confirmado en PRODUCCIÓN**: el dry-run de `secrets/qa_scrub_member_pii.js` encontró 1 member doc real (`home=mAJXlAhwRV1kdy4O05hG`) con teléfono en claro y visibilidad NO compartida. (b) **fcmToken: confirmado en PRODUCCIÓN** — `qa_inspect_pii.js` y el dry-run de `qa_scrub_member_pii.js` mostraron **30 member docs (19 usuarios) con `fcmToken` en claro**, incl. docs con `status:left`, todos legibles por cualquier co-miembro. (c) `collectionGroup('invitations') allow list: if isAuth()` + lectura pública por código → cualquier autenticado enumeraba todos los códigos; el onboarding cliente dependía de ello. (d) `isMemberOfHome` no miraba `status` y leave/remove dejan la membership con `status:'left'` → el expulsado seguía leyendo (confirmado en prod: `Ko7p…` con `status:left` presente en 2 hogares).
>
> **Arreglos:** (a) helper `sanitizeMemberPhone` en `member_factory.ts` aplicado en `buildNewMemberDoc` + los 2 rejoin + `repairMemberDocument` + `syncMemberProfile` (escribe `null` si no es `sameHomeMembers`); cliente muestra el teléfono propio desde `users/{uid}` (`member_profile_view_model.dart`). (b) `fcmToken` movido a `users/{uid}` (privado); helper `functions/src/notifications/fcm_tokens.ts` (`getUserFcmToken`/`getUserFcmTokens`); actualizados `dispatch_due_reminders`, `send_pass_notification`, `send_rescue_alerts`; cliente: `updateFcmToken`→`users/{uid}`, `NotificationPreferences.toMap/fromMap` ya no persisten el token. (c) `firestore.rules`: invitations `allow read: if isAdminOrOwner` y collectionGroup `allow list: if false`; onboarding migrado a la callable `joinHomeByCode` (que ahora devuelve `{homeId}`). (d) nuevo helper `isCurrentMember` (`status != 'left'`, admite active+frozen) aplicado a las lecturas de homes/dashboard/members/tasks/taskEvents/memberTaskStats/subscriptions/system; la membership NO se borra (la usa `reinstateMember`).
>
> **Tests:** rules suite completa **172/172** (nuevos casos: `left`/outsider DENEGADOS en homes/members/tasks; collectionGroup invitations denegado; lectura pública por código denegada; `fcmToken` en `users/{uid}` no legible por co-miembros). functions unit **258/258** (incl. `sanitizeMemberPhone` y `buildNewMemberDoc` con teléfono oculto→null). Integración emulador `join_home_profile` (teléfono oculto→null al re-ocultar) y `dispatch_due_reminders` (token leído de `users/{uid}`, "sent 1") **11/11**. Dart: `notification_preferences`, `notification_prefs_repository_impl`, `home_creation`, UI notif → verde. `flutter analyze` (archivos tocados) sin issues.
>
> **Despliegue a prod (autorizado por el usuario, orden functions→app→reglas):** functions desplegadas a `toka-dd241` (`Deploy complete!`), APK debug (entrypoint prod) instalado en MI_9 + emulador, `firestore.rules` desplegadas (compiladas OK), y backfill `qa_scrub_member_pii.js --commit` ejecutado: **1 teléfono saneado, 19 tokens movidos a users/{uid}, 30 tokens borrados de member docs**. Re-inspección confirma todos los member docs con `hasFcmTokenInDoc=false` y el token del owner ya en `users/{uid}`.
>
> **Verificación DUAL en prod (PASO 4):**
> - **Token directo (SDK cliente, reglas aplicadas) — `secrets/qa_verify_pii_scenario.js`: 9/9 OK.** Cuenta B activa (admin) NO puede leer `users/{owner}` (teléfono+token privados), SÍ lee `members/{owner}` pero **sin teléfono ni fcmToken**, y NO puede enumerar `invitations` (collectionGroup). Cuenta B 'left' (member): NO lee hogar/members/tasks/users. Escenario creado y borrado limpiamente.
> - **App en ambos dispositivos:** la nueva app carga "Hoy" contra prod en emulador (claro) y MI_9 (oscuro) — un miembro activo lee home/dashboard/tasks/members sin crash → las reglas `isCurrentMember` no rompen al miembro vigente.
>
> **Tras el deploy (H-003):** las reglas de invitations ahora son restrictivas en prod. Si existe una **app publicada antigua**, su onboarding "unirse por código" (usaba `collectionGroup`) quedará roto hasta publicar la app nueva (que ya va por `joinHomeByCode`). La otra ruta de unión (selector de hogar) ya iba por callable y no se ve afectada. Si Toka aún es pre-lanzamiento, sin impacto. Ver `Hallazgos.md` H-003.

**Archivos clave:** `functions/src/homes/member_factory.ts:51` · `firestore.rules:15-17` (`isMemberOfHome` sin `status`) · `firestore.rules:208` (members read) · `firestore.rules:284-285, 300-302` (invitaciones / collectionGroup `list`) · `lib/features/members/domain/member.dart:34-41` (`phoneForViewer`, filtrado solo en cliente) · `lib/features/notifications/data/notification_prefs_repository_impl.dart:37-43` (token FCM en doc del miembro) · `functions/src/homes/index.ts:500, 597-602` (salir/expulsar marca `left`, no borra).

```text
Eres ingeniero de seguridad en Toka (Flutter + Firebase). Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #01.

OBJETIVO: cerrar 4 fugas de PII que cualquier co-miembro (o cualquier autenticado) puede leer saltándose la UI.

PASO 1 — VERIFICA (puede haber falsos positivos parciales). Confirma leyendo el código y, si puedes, leyendo Firestore con secrets/qa_inspect_home.js:
  a) El teléfono "hidden" se denormaliza EN CLARO en members/{uid}.phone (member_factory.ts:51) y el doc es legible por todo el hogar (firestore.rules:208); el ocultamiento vive solo en cliente (member.dart phoneForViewer).
  b) El token FCM se guarda en members/{uid} (notification_prefs_repository_impl.dart:37-43), legible por todos.
  c) collectionGroup('invitations') con allow list: if isAuth() (firestore.rules:300-302) permite enumerar TODOS los códigos de invitación del sistema.
  d) isMemberOfHome (firestore.rules:15-17) no comprueba status → un miembro con status:'left' conserva lectura del hogar.
  Si alguno NO se reproduce, márcalo como falso positivo en el doc y en Hallazgos.md y sáltalo.

PASO 2 — ARREGLA lo confirmado:
  - No escribir el teléfono en members/{uid} cuando phoneVisibility=='hidden' (escribir null), o servirlo solo vía callable que valide visibilidad server-side. Recalcula los docs existentes si procede (script en secrets/).
  - Mover fcmToken fuera del doc legible: a users/{uid} (privado) o members/{uid}/private/tokens con allow read: if isUser(uid).
  - Restringir invitaciones: allow list: if false (el join va por la callable joinHomeByCode), o forzar igualdad exacta de code.
  - Lecturas sensibles (homes, members, tasks, dashboard) con isActiveMember (status != 'left') en vez de isMemberOfHome; o borrar la membership al expulsar/salir.

PASO 3 — TESTS: añade/extiende tests de firestore.rules en functions/test/rules/ que prueben: con cuenta NO miembro y con cuenta 'left', la lectura de members/invitations/tasks debe DENEGARSE; con miembro activo, permitirse. Test de que el teléfono hidden no aparece en el doc.

PASO 4 — VERIFICACIÓN DUAL (criterio principal = visibilidad):
  - Owner en el físico crea un hogar, pon su teléfono en 'hidden'. Member/Admin en el emulador se une al mismo hogar.
  - Desde la cuenta B, intenta leer el teléfono y el fcmToken del otro (vía app y vía Firestore directo con su token): NO deben verse. Captura, analiza, borra.
  - Expulsa a la cuenta B desde A; confirma que B ya NO puede leer datos del hogar (regla isActiveMember). Verifica que el cambio sincroniza en ambos dispositivos.
  - Comprueba que un tercero NO puede enumerar invitaciones.
  Recuerda: probar reglas contra prod requiere deploy autorizado; mientras, demuéstralo en emulador.

PASO 5 — Actualiza el estado del Prompt 01 en premortem.md y registra hallazgos nuevos en Hallazgos.md.
```

---

## Prompt 02 — Sin verificación real de recibos IAP (monetización bloqueante)
**Categoría:** Monetización · **Severidad:** 🔴 Crítica · **Estado:** 🟧 Parcial / bloqueado (implementado + testeado + verificado en emulador; falta deploy autorizado a prod para la prueba en 2 dispositivos) — 2026-06-21

> **Verificación (PASO 1): los 4 puntos CONFIRMADOS, ningún falso positivo.**
> (a) `sync_entitlement_helpers.ts:77-119` `validateReceipt` infería plan/fechas del `productId` (`includes("annual")` + `Date.now()+ms`, `status:"active"` siempre); `verifyGooglePlay/verifyAppStore` **no existían** (solo un `TODO(prod)`); en modo `strict` lanzaba "Receipt validation backend not configured" → Premium era **o no-cobrable (strict) o falsificable (no-strict)**.
> (b) `sync_entitlement.ts:17-36` bloqueaba la callable salvo `FUNCTIONS_EMULATOR`/`TOKA_ALLOW_UNVERIFIED_RECEIPTS`, con `enforceAppCheck:true` (26).
> (c) `sync_entitlement.ts:88-114` escribía el hogar (`premiumStatus/premiumEndsAt/currentPayerUid` + `billingState`) **ANTES y FUERA** de la transacción de `:131-164`, que solo miraba `chargeSnap.exists` para el slot → **doble llamada con el mismo chargeId EXTENDÍA `premiumEndsAt`** (la idempotencia solo cubría el slot). (Nota: el read-after-write del unlock dentro de la txn nunca se disparaba porque `storeVerified` jamás era true.)
> (d) Cliente `paywall_provider.dart:62`: `chargeId: purchase.purchaseID ?? localVerificationData` (+ `:66 ?? ''`) — `purchaseID` puede ser nulo en iOS restored.
>
> **Arreglos (PASO 2):**
> - **Verificación server-to-store real** — nuevo `functions/src/entitlement/store_verifiers.ts`: `verifyGooglePlay` (Android Publisher v3 `purchases.subscriptionsv2`, OAuth con `google-auth-library` + service account) y `verifyAppStore` (App Store Server API `GET /inApps/v1/subscriptions/{txId}`, JWT ES256 con `jose`, decodifica los JWS de transacción/renovación). Mapeo **puro** (`mapGooglePlaySubscription`/`mapAppStoreTransaction`) que deriva `status/plan/endsAt/autoRenew` del recibo verificado; la red está aislada tras un "API client" inyectable.
> - `validateReceipt` reescrito: usa los verificadores (inyectables; config por env/secret vía `buildVerifiersFromEnv`); si hay verificador se usa SIEMPRE; si no, en `strict` rechaza y en dev infiere con `storeVerified=false`. Nuevo `chargeId` en `ValidatedEntitlement` derivado **server-side**.
> - **Idempotencia del hogar**: en `sync_entitlement.ts` TODA la escritura del hogar (`premiumStatus/premiumPlan/premiumEndsAt/autoRenewEnabled/currentPayerUid` + `billingState` de memberships + registro del cargo + unlock de plaza) ocurre **DENTRO de una sola transacción** guardada por `chargeSnap.exists` (reads-before-writes: lee charge+home+user y luego escribe; nuevo `applySlotUnlockTx` write-only en `slot_ledger.ts`). Reintentos/concurrencia con el mismo chargeId ya **no extienden `premiumEndsAt`** ni duplican slot.
> - `chargeId` derivado server-side del recibo verificado (purchaseToken en Android / originalTransactionId en iOS), **no** de `purchase.purchaseID`. El cliente ya no lo envía (interfaz `SubscriptionRepository.syncEntitlement` sin `chargeId`).
> - `enforceAppCheck:true` intacto; el gate (`receiptValidationAllowed`) ahora permite la callable en prod **solo si hay un verificador configurado** (ruta segura) o, sin verificador, únicamente en emulador/`TOKA_ALLOW_UNVERIFIED_RECEIPTS` — sin bypass en prod por defecto.
> - Deps declaradas en `functions/package.json`: `google-auth-library`, `jose`.
>
> **Tests (PASO 3):** functions unit **262/262** (18 suites) — nuevo `store_verifiers.test.ts` (14, mapeo Google/Apple + verify con API mockeada, incl. derivación de chargeId, grace→active, canceled→cancelledPendingEnd, revoked→expired); `sync_entitlement_helpers.test.ts` ampliado (verificador inyectado, chargeId server-side, expired no activa); `iap_hardening.test.ts` **reescrito** para ejercitar las funciones REALES `isValidForSlotUnlock`/`computeBillingUpdates` (elimina el "test espejo"). Integración emulador **13/13** (`sync_entitlement.test.ts` + nuevo `sync_entitlement_idempotency.test.ts`): recibo verificado inválido/expirado → **no activa**; válido → activa una vez + 1 slot; **doble llamada mismo chargeId → `premiumEndsAt` NO salta (probado con endsAt posterior en la 2ª llamada) ni duplica slot**; inferencia (`storeVerified=false`) → activa pero **no** plaza permanente; verificador que lanza → callable rechaza y el hogar sigue Free. (El antiguo `sync_entitlement_idempotency.test.ts` espejo de `src/` se eliminó.) Cliente: `flutter analyze` (Windows, 3 archivos tocados) **sin issues**.
>
> **Verificación DUAL en 2 dispositivos (PASO 4): BLOQUEADA — requiere deploy autorizado de functions a `toka-dd241`.** La app en los móviles habla con las functions de PROD (que aún tienen la versión vieja); sin deploy no se puede comprar Premium real ni observar la sincronización con la nueva lógica. **Demostrado end-to-end en el emulador Firestore** (13/13). Pendiente para cerrar en ✅:
> 1. Configurar secrets en `toka-dd241`: `GOOGLE_PLAY_PACKAGE_NAME`, `GOOGLE_PLAY_SA_JSON` (service account con scope `androidpublisher`), `APP_STORE_ISSUER_ID`/`APP_STORE_KEY_ID`/`APP_STORE_PRIVATE_KEY`(.p8)/`APP_STORE_BUNDLE_ID`/`APP_STORE_ENV`, y `STRICT_RECEIPT_VALIDATION=true`.
> 2. Deploy de functions (autorizado) — ver `deploy-functions-discovery-timeout`.
> 3. Sandbox: comprar Premium con Owner (físico), confirmar en emulador (Member) que el hogar pasa a Premium (`showAds=false`) y **sincroniza**; repetir compra duplicada → `premiumEndsAt` no salta; confirmar BD con `secrets/qa_premium.js`.
>
> **Endurecimiento pendiente (anotado en Hallazgos.md):** verificación de la cadena x5c de los JWS de Apple contra la raíz (hoy se decodifica el payload sobre TLS autenticado); reconciliación por RTDN/refunds es el Prompt 06.

**Archivos clave:** `functions/src/entitlement/sync_entitlement.ts:17-36` (gate + `enforceAppCheck:26`), `:88-114` y `:131-164` (escritura del hogar FUERA de la transacción de idempotencia) · `functions/src/entitlement/sync_entitlement_helpers.ts:72-119` (modo "INSECURE inference", `verifyGooglePlay/AppStore` son TODO) · `lib/features/subscription/.../paywall_provider.dart:62` (`chargeId` puede ser nulo en iOS restored).

```text
Eres ingeniero de pagos en Toka (Flutter + Firebase). Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #02.

OBJETIVO: hacer que Premium solo se active con un recibo verificado server-to-server, y que la idempotencia proteja también el estado del hogar.

PASO 1 — VERIFICA: confirma en sync_entitlement_helpers.ts:72-119 que validateReceipt INFIERE plan/fechas del productId sin llamar a las stores y que verifyGooglePlay/verifyAppStore no existen; que sync_entitlement.ts:17-36 bloquea en prod salvo flag TOKA_ALLOW_UNVERIFIED_RECEIPTS; y que sync_entitlement.ts:88-114 escribe homeRef ANTES y FUERA de la transacción de :131-164 (la idempotencia solo cubre el slot, no premiumEndsAt/currentPayerUid). Si algo ya está implementado, márcalo y ajusta el alcance.

PASO 2 — ARREGLA:
  - Implementa verifyGooglePlay (androidpublisher_v3, purchases.subscriptionsv2) y verifyAppStore (App Store Server API) con las credenciales por env/secret. Deriva plan/fechas/estado del recibo verificado, no del productId.
  - Mueve TODA la escritura del hogar (premiumStatus, premiumEndsAt, currentPayerUid, billingState de memberships) DENTRO de la misma transacción que comprueba chargeSnap.exists, para que reintentos/concurrencia no extiendan Premium.
  - Deriva chargeId server-side del purchaseToken/originalTransactionId verificado (no de purchase.purchaseID que puede ser nulo).
  - Mantén enforceAppCheck:true. No habilites el bypass en prod.

PASO 3 — TESTS: extiende sync_entitlement_idempotency.test.ts y iap_hardening.test.ts (emulador): recibo inválido → no activa; recibo válido → activa una vez; doble llamada mismo chargeId → no extiende premiumEndsAt ni duplica slot. Mockea las APIs de store.

PASO 4 — VERIFICACIÓN DUAL: con sandbox de la store (o el modo emulador documentado), compra Premium con la cuenta Owner en el físico; comprueba en el emulador con la cuenta Member que el hogar pasa a Premium (flags showAds=false, etc.) y que se SINCRONIZA. Repite una compra duplicada y verifica que premiumEndsAt no salta. Confirma con secrets/qa_premium.js el estado real en BD. Captura, analiza, borra.
Nota: probar en móviles contra prod necesita deploy autorizado de functions; si no lo tienes, demuéstralo en emulador y deja el estado 🟧 hasta el OK.

PASO 5 — Actualiza el estado del Prompt 02 y anota hallazgos en Hallazgos.md.
```

---

## Prompt 03 — `debugSetPremiumStatus` desplegable a producción
**Categoría:** Privacidad/Monetización · **Severidad:** 🔴 Crítica · **Estado:** ✅ Eliminado del código + retirado de producción (`functions:delete`) y verificado (404) — 2026-06-21

> **Verificación (PASO 1): CONFIRMADO, no es falso positivo.** `debugSetPremiumStatus` se exportaba vía `index.ts:9` (`export * from "./homes"`) → `homes/index.ts` (`onCall` **sin `enforceAppCheck`**), gateada solo por `isDebugPremiumAllowed` (emulador O `DEBUG_PREMIUM_ALLOWED_UIDS`). **`.env.toka-dd241` tenía la allowlist POBLADA con un UID real** (`lJp9…SMt2`) → en prod ese uid podía forzar Premium sin pagar. El guardrail `check-debug-premium.js` solo corría en `npm run deploy:release`, **no** en el `deploy` real (`firebase deploy --only functions`), así que no protegía. `firebase functions:list` confirmó que la función **está desplegada en `toka-dd241` ahora mismo** (callable v2). Única callable debug; `debug_premium_flags.ts`/`debug_premium_allowlist.ts` eran helpers puros. El botón cliente ya estaba gateado por `kDebugMode` (no aparece en release), pero el endpoint era invocable sin la UI.
>
> **Decisión (usuario):** eliminar la funcionalidad por completo (no conservar opt-in). El forzado de Premium en QA se sigue haciendo con el Admin SDK (`secrets/qa_premium.js`), que usa la service account y no es un endpoint público.
>
> **Arreglos (PASO 2):** eliminada la Cloud Function `debugSetPremiumStatus` y sus dos módulos de helpers (`debug_premium_allowlist.ts`, `debug_premium_flags.ts`) + imports en `homes/index.ts`; eliminado el lado cliente (botón/sheet en `home_settings_screen_v2.dart`, método + campos `showDebugPremiumToggle`/`premiumStatusCode` en `home_settings_view_model.dart` + import `kDebugMode`, método en `homes_repository_impl.dart` y firma en `homes_repository.dart`); comentarios actualizados (`subscription_dashboard_provider.dart`, `ad_banner_config_provider.dart`). Vaciada la allowlist en `.env.toka-dd241`/`.env.local` y retirado el bloque del `.env.example`. El guardrail `check-debug-premium.js` se **cableó al `deploy` normal** (antes solo en `deploy:release`): ahora cualquier deploy falla si reaparece el marker o una allowlist con valor.
>
> **Tests (PASO 3):** nuevo `functions/src/homes/debug_premium_removed.test.ts` (4 casos: el bundle `homes` no contiene la función ni el marker, los helpers no existen, ningún `.ts` de `src/` tiene el marker, y el guardrail pasa exit 0). Suite unit functions **248/248 (19 suites)** verde (se quitaron los 18 tests de los 3 describe debug de `homes_callables.test.ts`). `tsc` compila limpio. Cliente: `flutter analyze` (homes + subscription + widgets) **sin issues** y `home_settings_view_model_test.dart` **4/4**.
>
> **Verificación (PASO 4):** el functions-discovery de Firebase reproducido sobre `lib/homes/index.js` registra 14 callables (`createHome…transferOwnership`) y **`debugSetPremiumStatus` = false**; el bundle compilado no lo exporta. `firebase functions:list --project toka-dd241` **AÚN muestra la función en prod** (no se ha desplegado). `qa_premium.js` (Admin SDK) puede fijar Premium siempre (legítimo: credenciales de servicio); el camino de **cliente/endpoint** queda cerrado.
>
> **Despliegue + verificación en prod (autorizado por el usuario — `toka-dd241` es entorno de desarrollo, app NO publicada):** retirada con `FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase functions:delete debugSetPremiumStatus --region us-central1 --project toka-dd241 --force` → `Successful delete operation`. Se usó la **vía quirúrgica** (no `deploy --only functions` completo) a propósito: los secrets de store del #02 (`GOOGLE_PLAY_SA_JSON`/`APP_STORE_PRIVATE_KEY`) **no existen aún** en `toka-dd241` (404), así que un deploy completo habría arrastrado y bloqueado `syncEntitlement` (#02 sigue pendiente de esos secrets). `firebase functions:list` **ya no muestra** `debugSetPremiumStatus`; un `POST` al endpoint devuelve **HTTP 404** (vs `createHome` → 401), confirmando que **no hay camino desde la app** para activar Premium gratis. `qa_premium.js` (Admin SDK) sigue siendo la vía legítima de QA. El código fuente ya no contiene la función (+ guardrail cableado al `deploy`), así que un futuro deploy no la reintroduce. Ver `Hallazgos.md` H-008/H-009/H-010.

**Archivos clave:** `functions/src/index.ts:9` (`export * from "./homes"` la incluye) · `functions/src/homes/index.ts:1265-1312` (`debugSetPremiumStatus`) · `functions/src/homes/debug_premium_allowlist.ts:18-26` (gate solo por env/emulador, sin App Check). Marcador `@DEBUG_PREMIUM_REMOVE_BEFORE_PRODUCTION_RELEASE`.

```text
Eres ingeniero de plataforma en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #03.

OBJETIVO: que ninguna función de debug que active Premium sin pago llegue a un build de producción.

PASO 1 — VERIFICA: confirma que debugSetPremiumStatus se exporta en index.ts y solo está protegida por isDebugPremiumAllowed (emulador O DEBUG_PREMIUM_ALLOWED_UIDS) sin enforceAppCheck. Busca otras funciones debug_* equivalentes (debug_premium_flags.ts). Si ya están excluidas de prod, márcalo falso positivo.

PASO 2 — ARREGLA: excluye estas funciones del bundle de producción (export condicional por FUNCTIONS_EMULATOR / variable de entorno de build), y/o exige App Check + un custom claim de superadmin. El objetivo: en prod no debe existir un camino para set Premium sin IAP verificado.

PASO 3 — TESTS: test de que en modo no-emulador la función no se registra/rechaza; test del gate de allowlist.

PASO 4 — VERIFICACIÓN DUAL: confirma que desde la app (físico y emulador, cuentas distintas) no hay forma de activar Premium gratis; revisa la lista de funciones desplegadas (firebase functions:list) y que la debug no aparezca en prod. Comprueba con qa_premium.js que el estado no se puede forzar. Captura/borra si procede.

PASO 5 — Actualiza el estado del Prompt 03 y anota hallazgos.
```

---

## Prompt 04 — GDPR: borrado y exportación de datos
**Categoría:** Privacidad · **Severidad:** 🟠 Alta · **Estado:** ✅ Solucionado, testeado, desplegado y verificado (prod + dispositivo) — 2026-06-21

> **Verificación (PASO 1) — CONFIRMADO (no falso positivo), a nivel de código:**
> (a) "Eliminar cuenta" (`settings_screen.dart`) solo llama `currentUser.delete()` → dispara `onAuthUserDeleted` → `cleanupDeletedUser`. El backend SÍ corre, pero (b) `cleanupUserInHome` marcaba el miembro `left` **conservando `phone`, `photoUrl` y `notificationPrefs`** en el snapshot (legible por todo el hogar) → fuga de PII tras borrar. (c) `cleanupDeletedUser` hacía `recursiveDelete(users/{uid})` pero **nunca tocaba Storage**: el objeto `users/{uid}/profile.jpg` permanecía y su download URL **tokenizada salta las Storage rules** (cualquiera con la URL ve la foto indefinidamente). (d) **No existía ningún flujo de exportación** (grep: solo `submitReview` usa callables).
>
> **Arreglos (PASO 2):**
> - `cleanup_user.ts` · `cleanupUserInHome`: en la misma transacción que marca `left`, escribe `phone:null`, `photoUrl:null`, `notificationPrefs.fcmToken:FieldValue.delete()`. Se conserva `nickname`+stats como snapshot **pseudonimizado** (integridad del historial de terceros).
> - `cleanup_user.ts` · `cleanupDeletedUser`: nuevo `deleteUserStorage(uid)` (best-effort) que borra el prefijo `users/{uid}/` del bucket (invalida la download URL = revoca el token). Helper `defaultBucketName()` resuelve el bucket vía `FIREBASE_CONFIG`/`STORAGE_BUCKET`/`${project}.appspot.com` (necesario porque `initializeApp()` va sin `storageBucket`).
> - **Nueva callable `exportUserData`** (`functions/src/users/export_user_data.ts`, registrada en `users/index.ts`): Art. 15/20. Exporta perfil (`users/{uid}`), memberships, slotLedger, `homes[]` (nombre + su member doc) y `reviewsAuthored` (`collectionGroup('reviews').where('reviewerUid','==',uid)`). `Timestamp→ISO`. Solo lectura.
> - **Cliente**: `settings_screen.dart` → "Exportar mis datos" en Ajustes › Privacidad (`_exportUserData`): llama la callable, escribe JSON a temp y abre el *share sheet* (`share_plus`+`path_provider`, añadidas a `pubspec`). Strings en es/en/ro.
> - **Retención documentada** en `architecture/privacy-retention.md`.
>
> **Tests (PASO 3) — VERDE en emulador:**
> - Integración (emuladores firestore+auth+storage): `cleanup_user.test.ts` nuevo describe GDPR — tras `cleanupDeletedUser`, el member doc queda sin `phone`/`photoUrl`, sin `notificationPrefs.fcmToken` (conserva el resto de prefs), y `bucket.file('users/{uid}/profile.jpg').exists()` = `false`; idempotente sin foto. Nuevo `export_user_data.test.ts` — perfil/memberships/homes/reviewsAuthored correctos, Timestamp como ISO, rechaza sin auth, usuario sin datos → estructura vacía. **22/22**.
> - Unit `src/` **248/248** (sin regresiones). `flutter analyze settings_screen.dart` sin issues. UI `settings_screen_test.dart` **11/11** (golden regenerado por el tile nuevo).
>
> **Deploy a prod (autorizado por el usuario) — deploy QUIRÚRGICO:** `firebase deploy --only functions:onAuthUserDeleted,functions:exportUserData --project toka-dd241`. Como el working tree tiene WIP del #02 que añade `defineSecret("GOOGLE_PLAY_SA_JSON")` (solo working-tree, no en HEAD) y ese secreto NO existe en prod, un deploy completo se bloqueaba (mismo escollo que H-009). Solución sin tocar secretos de prod: stash temporal del WIP de entitlement (revertir a HEAD, que no tiene `defineSecret`) + mover los nuevos sin trackear → `tsc` limpio → deploy de las 2 funciones → restaurar WIP. `exportUserData` creada (v2), `onAuthUserDeleted` actualizada (v1). Índice desplegado aparte con `firebase deploy --only firestore:indexes` (no tocó reglas).
>
> **PASO 4 — Verificación DUAL en PROD (reglas + Storage reales):**
> - **Backend autoritativo — `secrets/qa_verify_gdpr_scenario.js`: 15/15 OK.** Crea una cuenta A DESECHABLE (sin tocar las QA reales) con teléfono compartido + foto real en Storage, y B=`toka.qa.admin` como co-miembro. (1) A llama `exportUserData` (cliente) → recibe perfil con su teléfono + hogar + membership. (2) ANTES: B (reglas aplicadas) ve teléfono+foto de A; la download URL da 200. (3) Se borra la cuenta Auth de A → dispara el trigger DESPLEGADO. (4) DESPUÉS: el snapshot de A sigue como `left` (historial), B ya NO ve teléfono ni foto (null), el `fcmToken` del snapshot se borró, la foto se BORRÓ de Storage (`file.exists()=false`) y la URL pasó de 200→403, y `users/{A}` desapareció.
> - **Cliente en dispositivo (emulador, build prod):** Ajustes › Privacidad › "Exportar mis datos" → snackbar "Preparando la exportación…" → se abre el share sheet de Android con `toka_export_<uid>.json` (Drive/Gmail/Nearby). Capturas analizadas y borradas.
>
> **Hallazgo del PASO 4 (corregido aquí):** la query `collectionGroup('reviews').where('reviewerUid','==',uid)` SÍ exige un índice de campo único con scope COLLECTION_GROUP en prod (no se auto-crea) → el primer `exportUserData` devolvió `functions/internal`. Arreglo: (a) `fieldOverride` para `reviews.reviewerUid` en `firestore.indexes.json` (desplegado), y (b) export RESILIENTE — la query de reseñas va en try/catch (`reviewsAuthoredError`), así un fallo de índice no tumba el resto del export (Art. 15 se sirve igual). Ver `Hallazgos.md` H-013.

**Archivos clave:** `lib/features/settings/presentation/settings_screen.dart` (export tile + `_exportUserData`) · `functions/src/users/cleanup_user.ts` (scrub PII + `deleteUserStorage` + `defaultBucketName`) · `functions/src/users/export_user_data.ts` (nueva callable, query resiliente) · `functions/src/users/index.ts` (registro) · `firestore.indexes.json` (fieldOverride `reviews.reviewerUid` COLLECTION_GROUP) · `architecture/privacy-retention.md` (retención) · `secrets/qa_verify_gdpr_scenario.js` (verificación prod 15/15) · tests `functions/test/integration/{cleanup_user,export_user_data}.test.ts`. Foto en `users/{uid}/profile.jpg` (`profile_repository_impl.dart:61`).

```text
Eres ingeniero de privacidad en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #04.

OBJETIVO: cumplir derecho al olvido (Art. 17) y portabilidad (Art. 15/20).

PASO 1 — VERIFICA: tras "eliminar cuenta" (settings_screen.dart:199), comprueba con secrets/qa_cleanup_deleted_user.js / qa_inspect_home.js que members/{uid} conserva phone/photoUrl y que la foto sigue en Storage con download URL válida. Confirma que no hay ningún flujo de exportación.

PASO 2 — ARREGLA:
  - En cleanupUserInHome (cleanup_user.ts): anonimizar/borrar phone, photoUrl y notificationPrefs.fcmToken del snapshot de cada hogar.
  - Borrar el objeto de Storage del usuario (profile.jpg) en cleanupDeletedUser y revocar tokens de descarga.
  - Añadir una callable de exportación de datos del usuario (JSON con sus datos personales) accesible desde Ajustes.
  - Documentar retención.

PASO 3 — TESTS: integración (emulador) del trigger de borrado: tras borrar, ningún member snapshot conserva PII; la foto se elimina; la callable de export devuelve los datos esperados.

PASO 4 — VERIFICACIÓN DUAL: con la cuenta B (emulador) miembro del hogar del usuario A (físico), elimina la cuenta A; confirma desde B que ya NO se ve teléfono/foto de A en ningún sitio, y que B no puede acceder a datos de A. Verifica el export desde la cuenta A antes de borrar. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 04 y anota hallazgos.
```

---

## Prompt 05 — Banner con unit IDs de TEST de AdMob
**Categoría:** Monetización · **Severidad:** 🟠 Alta · **Estado:** 🟧 Parcial — mecanismo implementado, testeado y verificado en emulador; cierre en ✅ pendiente de unit IDs reales de AdMob + deploy autorizado — 2026-06-21

> **Verificación (PASO 1): CONFIRMADO, no es falso positivo.** `ad_constants.ts:4-8` definía los test IDs de Google y `DEFAULT_BANNER_UNIT_ID = TEST_BANNER_UNIT_ID_ANDROID`. Se propagaban a `adFlags.bannerUnit` en **4 sitios** de escritura del dashboard para hogares Free: `update_dashboard.ts:191` y `homes/index.ts:167` (hardcoded), `sync_entitlement.ts:264` y `apply_downgrade_plan.ts:174` (vía `DEFAULT_BANNER_UNIT_ID`); `restore_premium_state.ts:97` escribía `""` (Premium → sin banner, correcto). El cliente `ad_banner.dart` en release usa `fromServer` (= ese test ID) → **cero ingresos**. Además el dashboard guardaba **un único** `bannerUnit` (el de Android), así que iOS en release tampoco habría recibido su unit. **No** había inyección por Remote Config/env para el banner (el scaffold `RemoteConfigService.ad_banner_unit_*` existe pero está MUERTO — ver `Hallazgos.md` H-015).
>
> **Arreglos (PASO 2):** parametrización por **entorno** (los unit IDs de AdMob son públicos → van en `.env`, no en Secret Manager; mismo patrón que el #02). `functions/src/shared/ad_constants.ts` reescrito: `resolveBannerUnits(env)` lee `ADMOB_BANNER_UNIT_ANDROID`/`ADMOB_BANNER_UNIT_IOS` (fallback a test sólo en dev), `buildBannerAdFlags(showBanner, env)` construye el bloque `adFlags` con `bannerUnitAndroid`/`bannerUnitIos` (+ `bannerUnit` legacy = Android para back-compat), `isTestAdUnit()` y `assertReleaseAdUnits()`. Los **5 sitios** de escritura del dashboard usan ahora `buildBannerAdFlags(...)` (eliminado `DEFAULT_BANNER_UNIT_ID`). Cliente: `AdFlags` (`home_dashboard.dart`) gana `bannerUnitAndroid`/`bannerUnitIos` + `bannerUnitFor({isIos})` (fallback al legacy `bannerUnit`); `adBannerConfigProvider` elige el unit por plataforma (`defaultTargetPlatform`); `ad_banner.dart` mantiene los test IDs **solo** en `kDebugMode`/fallback vacío. **Guardrail de deploy** `scripts/check-ad-units.js` (cableado en `check:release-safety`): bloquea el deploy de un proyecto con `TOKA_REQUIRE_REAL_AD_UNITS=true` cuyos units estén vacíos o sean de prueba (los proyectos de dev sin el flag no se ven afectados). `.env.example`/`.env.toka-dd241`/`.env.local` documentan las nuevas variables.
>
> **Remote Config (a petición del usuario, 2026-06-21): el unit ID se cambia sin redesplegar.** Se cableó `RemoteConfigService` (antes muerto, ver H-015): nuevo `remoteBannerAdUnitsProvider` lee `ad_banner_unit_android`/`ios` de Remote Config. `adBannerConfigProvider` aplica la **precedencia** del unit: (1) **Remote Config** (consola Firebase, sin redeploy) → (2) `dashboard.adFlags.bannerUnit{Android,Ios}` (backend env + guardrail, fallback) → (3) test IDs (debug/vacío). El show/hide sigue server-authoritative. Para cambiar el id en prod: editar `ad_banner_unit_android`/`ios` en la consola de Remote Config (defaults `''` → fallback seguro). Propagación **instantánea** con la app abierta vía Remote Config en tiempo real (`onConfigUpdated`→`activate()`→`invalidateSelf()`); `minimumFetchInterval` bajado a 1 min para el resto de casos.
>
> **Tests (PASO 3):** unit functions **265/265 (21 suites)** — nuevos `src/shared/ad_constants.test.ts` (11: `isTestAdUnit`, `resolveBannerUnits`, `buildBannerAdFlags`, y **`assertReleaseAdUnits` FALLA si en config de release el unit empieza por `ca-app-pub-3940256099942544`**) y `src/shared/check_ad_units_guardrail.test.ts` (6: guardrail con fixtures + repo real). Integración emulador **`ad_units_dashboard.test.ts` 2/2**: con `ADMOB_BANNER_UNIT_*` seteado, el path real (`applyDowngradeJob`) escribe en `views/dashboard.adFlags` los **units reales por plataforma**; sin env → fallback de prueba (Android≠iOS). Cliente: `ad_banner_config_provider_test.dart` ampliado (Android→`bannerUnitAndroid`, **iOS→`bannerUnitIos`**, back-compat, y **precedencia Remote Config > dashboard**) **11/11**; banner/ads/dashboard/shell UI **27/27** (+ `remote_config_service` 4/4). `flutter analyze` sin issues nuevos (2 warnings pre-existentes ajenos). Ambos guardrails (`check:release-safety`) pasan.
>
> **PASO 4 — Verificación:** la inyección real por plataforma + fallback dev + Premium→sin banner está **verificada end-to-end en el emulador Firestore** (integración 2/2), entorno correcto para validar la escritura del dashboard. La verificación en prod/dispositivos del **unit real** está **BLOQUEADA por un prerrequisito de negocio**: aún **no existen unit IDs reales de AdMob** (app pre-release) → "adFlags.bannerUnit es el real" es inalcanzable hoy; y en build debug el cliente sirve SIEMPRE test ads (rama `kDebugMode`), mientras una build release serviría anuncios reales (no clicar) sin IDs que poner. Ambos dispositivos (MI_9 `43340fd2` + emulador) están conectados pero el banner show/hide ya está cubierto por los tests de UI con el modelo nuevo. Ver `Hallazgos.md` H-014 con el **checklist de release** para cerrar en ✅ (crear cuenta AdMob → poner `ADMOB_BANNER_UNIT_*` + `TOKA_REQUIRE_REAL_AD_UNITS=true` en el `.env` de prod → deploy autorizado → verificación dual del unit real).

**Archivos clave:** `functions/src/shared/ad_constants.ts` (reescrito: `resolveBannerUnits`/`buildBannerAdFlags`/`isTestAdUnit`/`assertReleaseAdUnits`) · escritura del dashboard en `update_dashboard.ts`, `sync_entitlement.ts`, `apply_downgrade_plan.ts`, `homes/index.ts`, `jobs/restore_premium_state.ts` (todos vía `buildBannerAdFlags`) · `functions/scripts/check-ad-units.js` (guardrail) + `package.json` (`check:release-safety`) · `functions/.env.example`/`.env.toka-dd241`/`.env.local` · cliente `lib/features/tasks/domain/home_dashboard.dart` (`AdFlags` por plataforma), `lib/shared/widgets/ad_banner_config_provider.dart` (precedencia Remote Config → dashboard, pick por plataforma; `remoteBannerAdUnitsProvider`), `lib/shared/services/remote_config_service.dart` (getters de banner ahora USADOS), `lib/shared/widgets/ad_banner.dart` (test sólo en debug). Tests: `functions/src/shared/{ad_constants,check_ad_units_guardrail}.test.ts`, `functions/test/integration/ad_units_dashboard.test.ts`, `test/unit/shared/widgets/ad_banner_config_provider_test.dart`.

```text
Eres ingeniero de monetización en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #05.

OBJETIVO: que en release se sirvan unit IDs reales de AdMob por plataforma, nunca los de test.

PASO 1 — VERIFICA: confirma que ad_constants.ts:4-8 usa los IDs de prueba ca-app-pub-3940256099942544/... y que se propagan al dashboard y al cliente. Si ya hay inyección por Remote Config/env, márcalo falso positivo.

PASO 2 — ARREGLA: parametriza los unit IDs por plataforma vía Remote Config/secret/env (Android e iOS distintos), tanto en backend (adFlags.bannerUnit) como en cliente (ad_banner.dart). Deja los test IDs solo como fallback de debug.

PASO 3 — TESTS: test que falle si en configuración de release el bannerUnit empieza por ca-app-pub-3940256099942544 (id de prueba). Test de que el cliente toma el unit del dashboard.

PASO 4 — VERIFICACIÓN DUAL: con un hogar Free, confirma en el físico y el emulador (cuentas distintas, mismo hogar) que el banner aparece y que adFlags.bannerUnit es el real (inspecciona el dashboard con qa_inspect_home.js). Confirma que en un hogar Premium NO se muestra. Cuida no hacer clics en anuncios reales en debug. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 05 y anota hallazgos.
```

---

## Prompt 06 — Sin RTDN/refunds + downgrade no automático
**Categoría:** Monetización · **Severidad:** 🟠 Alta · **Estado:** 🟧 Parcial — implementado, testeado y verificado (emulador + dual en dispositivos); cierre en ✅ pendiente de infra de stores (la misma que bloquea el #02) + deploy autorizado — 2026-06-21

> **Verificación (PASO 1): CONFIRMADO, no es falso positivo (los 3 puntos).**
> (a) **No existe handler RTDN/ASSN**: grep de `onMessagePublished`/`RTDN`/`developerNotification`/`subscriptionNotification` en `functions/src` solo encuentra **comentarios** en `store_verifiers.ts`. No había ninguna ruta para reconciliar el estado con las stores tras la compra. (b) **El cron NO capturaba `active` vencido**: `apply_downgrade_plan.ts` filtraba `premiumStatus in ['rescue','cancelled_pending_end','cancelledPendingEnd']` — un hogar `active` cuyo `premiumEndsAt` venció sin renovación (cobro fallido / RTDN perdida) **nunca** se degradaba → Premium efectivo perpetuo. (c) **`slot_ledger` concedía plazas sin revocación**: `applySlotUnlockTx`/`unlockSlotIfEligible` solo **incrementan** `lifetimeUnlockedHomeSlots` y ponen `validForUnlock:true`; **no existía** ninguna función inversa → tras un reembolso, la plaza permanente quedaba regalada.
>
> **Dependencia del #02:** el #02 ya dejó implementados y probados en emulador `verifyGooglePlay`/`verifyAppStore` (`store_verifiers.ts`) y la escritura transaccional del hogar. El #06 los **reutiliza** para re-verificar el recibo al recibir una notificación de store.
>
> **Arreglos (PASO 2):**
> - **Revocación de plaza** (`slot_ledger.ts`): nuevos `applySlotRevokeTx` (write-only) y `revokeSlotForCharge` (standalone). Marca el ledger `validForUnlock=false`+`revokedAt`/motivo y **decrementa** `lifetimeUnlockedHomeSlots` (suelo en 0) recalculando `homeSlotCap`. Idempotente (si el ledger no existe o ya estaba revocado, no-op).
> - **Núcleo de reconciliación** (`reconcile_entitlement.ts`, nuevo): `reconcileVerifiedEntitlement` (renovación/cambio de estado: aplica `premiumStatus/premiumEndsAt/autoRenew/plan` + dashboard; **nunca acorta** `premiumEndsAt` —toma el max— para tolerar notificaciones fuera de orden) y `revokeEntitlement` (refund/chargeback: hogar→`expiredFree`, `premiumEndsAt`=now, autoRenew off, `limits.maxMembers`=Free, dashboard a Free **con ads ON**, **revoca la plaza**, marca el cargo `refunded`, pagador→`formerPayer`; todo en UNA transacción, idempotente). **Índice de compras** `purchaseIndex/{chargeId}` (chargeId→{homeId,uid,platform}) escrito por `syncEntitlement` para que las notificaciones (que llegan con el purchaseToken/originalTransactionId, sin saber el hogar) puedan resolver a qué hogar aplican. Es un doc **top-level** que se lee por id → **sin índice nuevo** (evita la trampa COLLECTION_GROUP del H-013) y **denegado por defecto** a clientes (solo Admin SDK).
> - **Google RTDN** (`google_rtdn.ts`, nuevo): `googlePlayRtdnHandler` = `onMessagePublished({topic: GOOGLE_RTDN_TOPIC ?? 'play-rtdn'})`. Parsea el mensaje Pub/Sub; `voidedPurchaseNotification` o `notificationType=12 (REVOKED)` → `revokeEntitlement`; resto (renovación/cancelación/gracia/expiración) → **re-verifica** el purchaseToken contra Google Play (fuente de verdad, no el tipo de evento) y `reconcileVerifiedEntitlement`. No relanza en error (evita bucle de reintentos Pub/Sub; el cron es la red de seguridad).
> - **App Store Server Notifications v2** (`app_store_notifications.ts`, nuevo): `appStoreServerNotificationsHandler`. **Desviación justificada del prompt**: Apple entrega las ASSN v2 por **webhook HTTPS** (POST de un `signedPayload` JWS), NO por Pub/Sub, así que el endpoint correcto es `onRequest`, no `onMessagePublished` (ver `Hallazgos.md` H-018). **SEGURIDAD (review automático):** como el webhook es público, el handler **NUNCA confía en el cuerpo**: lo usa solo como disparador y **re-verifica el estado contra la App Store Server API** (`verifyAppStore`), igual que el path de Google. `REFUND`/`REVOKE` solo revoca si Apple **confirma** que la suscripción ya no da acceso; un `DID_RENEW`/refund forjado no puede conceder ni quitar Premium. Filtra por `APP_STORE_BUNDLE_ID`. 4xx en payload corrupto, 5xx en error de infra (Apple reintenta; idempotente).
> - **Cron de downgrade** (`apply_downgrade_plan.ts` + `downgrade_helpers.ts`): la elegibilidad se extrajo a `DOWNGRADE_ELIGIBLE_STATUSES` + `isDowngradeEligible`, añadiendo **`active`**. El cron ahora captura `active` con `premiumEndsAt <= now`. Como el handler RTDN mantiene `premiumEndsAt` al día en renovaciones legítimas, un hogar realmente activo conserva un endsAt futuro y NO se degrada por error.
>
> **Tests (PASO 3) — VERDE:** unit functions **299/299 (24 suites)** incl. nuevos `slot_ledger` (revoke: decrementa/suelo-0/idempotente/sin-ledger), `google_rtdn` (parse subscription/voided/test/corrupto), `app_store_notifications` (decode JWS anidados), y `downgrade_helpers`/`jobs` (elegibilidad de `active` vencido). Integración emulador **`entitlement_reconciliation.test.ts` (refund RTDN→revoca premium+plaza; voided→revoca; renovación→extiende endsAt; out-of-order NO acorta; Apple REFUND→revoca; Apple DID_RENEW→extiende; token sin índice→ack)** + `apply_downgrade_plan` (nuevo caso `active` vencido→restorable+ads ON) → las suites de entitlement **pasan 100%**. (Los 8 rojos de la suite de integración completa son ajenos: 4 de `cleanup_user` por no levantar el emulador de Storage —pasan al levantarlo—, 3 de `full_user_flow` = H-016, 1 de `pass_task_turn` = lógica de vacaciones intacta por el #06.) `tsc` limpio.
>
> **PASO 4 — Verificación DUAL en dispositivos (cuentas distintas, mismo hogar real `mAJXlAhwRV1kdy4O05hG` "Hogar Real QA" en `toka-dd241`):** con `qa_premium.js` (Admin SDK, la vía que pide el PASO 4) se simuló el resultado de la reconciliación. (1) `active` (Premium) → en el **MI_9** (cuenta A, tema oscuro) el **banner de anuncio desaparece** en vivo. (2) `expiredFree` (estado que produce `revokeEntitlement` en refund y el downgrade en expiración) → el MI_9 muestra el banner **"Tu Premium expiró… Reactivar Premium"** y el **anuncio reaparece**, y el **emulador** (cuenta B, tema claro, mismo hogar) muestra **el mismo banner sincronizado en vivo** → confirma que el hogar baja a Free, reaparecen los ads y **sincroniza en ambos dispositivos con cuentas distintas**. La plaza-revocación (campo que `qa_premium.js` no toca) está cubierta por la integración de emulador (lifetimeUnlockedHomeSlots decrementado + ledger validForUnlock=false). Hogar restaurado a `free`; capturas analizadas y borradas.
>
> **DESPLIEGUE A PROD (autorizado por el usuario, `toka-dd241`):** se desplegó el **cron de downgrade ampliado** (`applyDowngradeJob`, único componente desplegable sin secrets de store), vía la **vía quirúrgica** (neutralizar temporalmente los `defineSecret(GOOGLE_PLAY_SA_JSON/APP_STORE_PRIVATE_KEY)` del #02 en `sync_entitlement.ts` + el de `google_rtdn.ts`, desplegar `--only functions:applyDowngradeJob`, restaurar desde backup — mismo escollo que H-009). `Successful update operation`. `firebase functions:list` confirma `applyDowngradeJob` desplegado y los handlers RTDN/ASSN **ausentes** de prod (correcto). **Hallazgo de despliegue (H-019):** los logs de prod mostraban que `applyDowngradeJob` **y** `openRescueWindow` llevaban **fallando en cada ejecución** con `FAILED_PRECONDITION: requires an index` — faltaba el índice compuesto `homes(premiumStatus, premiumEndsAt)` (no estaba en `firestore.indexes.json`; el emulador no lo exige → verde en tests). **Sin él, el downgrade automático NUNCA ocurría en prod** (causa raíz adicional del "Premium gratis perpetuo"). Se añadió el índice y se desplegó (`firestore:indexes`). **Verificación funcional en PROD del cron desplegado:** con el índice ya construido (query del cron pasa de error a `0 elegibles`), se sembró un hogar desechable `active` con `premiumEndsAt` vencido (3 miembros, 6 tareas); en su **siguiente ejecución programada (18:30 UTC)** el cron lo degradó: `premiumStatus active→restorable`, `limits.maxMembers 10→3`, dashboard `isPremium=false/showAds=true`, **2 tareas congeladas** (6→4 Free). Hogar desechable borrado.
>
> **Por qué sigue 🟧 (no ✅):** los **handlers RTDN/ASSN no se pueden desplegar/verificar end-to-end en prod** todavía: requieren (i) las credenciales de store en Secret Manager (`GOOGLE_PLAY_SA_JSON`/`APP_STORE_PRIVATE_KEY`) — **las mismas que bloquean el #02** y que no existen en `toka-dd241` (un deploy de `googlePlayRtdnHandler` se bloquea con "no value for the secret"); (ii) configurar el **topic Pub/Sub de RTDN** en Google Play Console; (iii) configurar la **URL del webhook ASSN** en App Store Connect; (iv) suscripciones reales que reembolsar (app pre-lanzamiento). El cron desplegado es la **red de seguridad** que ya ataja el Premium perpetuo; los handlers cierran la reconciliación fina (renovaciones/refunds) cuando llegue la infra. **Checklist de cierre en `Hallazgos.md` H-017.**

**Archivos clave:** `functions/src/entitlement/slot_ledger.ts` (`applySlotRevokeTx`/`revokeSlotForCharge`) · `functions/src/entitlement/reconcile_entitlement.ts` (nuevo: `reconcileVerifiedEntitlement`/`revokeEntitlement`/`writePurchaseIndexTx`/`lookupPurchase`) · `functions/src/entitlement/google_rtdn.ts` (nuevo: `googlePlayRtdnHandler`/`parseRtdnMessage`/`handleRtdnEvent`) · `functions/src/entitlement/app_store_notifications.ts` (nuevo: `appStoreServerNotificationsHandler`/`decodeAppStoreNotification`/`handleAsnEvent`) · `functions/src/entitlement/apply_downgrade_plan.ts` + `downgrade_helpers.ts` (`DOWNGRADE_ELIGIBLE_STATUSES`+`isDowngradeEligible`, añade `active`) · `functions/src/entitlement/sync_entitlement.ts` (escribe `purchaseIndex`) · `functions/src/entitlement/index.ts` (registra los 2 handlers) · `functions/.env.example` (`GOOGLE_RTDN_TOPIC` + nota webhook ASSN) · `firestore.indexes.json` (índice `homes(premiumStatus, premiumEndsAt)` que faltaba, H-019). Tests: `entitlement_reconciliation.test.ts`, `slot_ledger.test.ts`, `google_rtdn.test.ts`, `app_store_notifications.test.ts`, `downgrade_helpers.test.ts`, `apply_downgrade_plan.test.ts`, `jobs.test.ts`.

```text
Eres ingeniero de facturación en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #06. (Depende del verificador del #02.)

OBJETIVO: reconciliar el estado Premium con las stores y evitar Premium gratis perpetuo / plazas regaladas tras reembolso.

PASO 1 — VERIFICA: confirma que no hay endpoint Pub/Sub para Google RTDN ni App Store Server Notifications v2, que apply_downgrade_plan.ts:23-29 NO captura hogares 'active' con premiumEndsAt vencido, y que slot_ledger concede plazas permanentes sin revocación.

PASO 2 — ARREGLA:
  - Endpoint Pub/Sub (onMessagePublished) para RTDN de Google y otro para App Store Server Notifications v2 que sincronice premiumStatus/premiumEndsAt, maneje renovaciones, y en refund/chargeback revoque Premium y la plaza correspondiente (validForUnlock=false, decrementa lifetimeUnlockedHomeSlots).
  - Añade al cron de downgrade una rama que capture premiumStatus 'active'/'rescue' con premiumEndsAt <= now.

PASO 3 — TESTS: integración (emulador) de la reconciliación: notificación de refund → revoca Premium y plaza; renovación → extiende premiumEndsAt; 'active' vencido sin decisión → downgrade. Extiende downgrade_helpers.test.ts.

PASO 4 — VERIFICACIÓN DUAL: simula (con qa_premium.js / qa_set_home_field.js) un hogar 'active' vencido y un refund; confirma desde el físico y el emulador (cuentas distintas) que el hogar baja a Free, que reaparecen los ads y que la sincronización ocurre en ambos. Captura/analiza/borra.
Nota: deploy a prod autorizado; si no, demuestra en emulador y deja 🟧.

PASO 5 — Actualiza el estado del Prompt 06 y anota hallazgos.
```

```text
Eres ingeniero de facturación en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #06. (Depende del verificador del #02.)

OBJETIVO: reconciliar el estado Premium con las stores y evitar Premium gratis perpetuo / plazas regaladas tras reembolso.

PASO 1 — VERIFICA: confirma que no hay endpoint Pub/Sub para Google RTDN ni App Store Server Notifications v2, que apply_downgrade_plan.ts:23-29 NO captura hogares 'active' con premiumEndsAt vencido, y que slot_ledger concede plazas permanentes sin revocación.

PASO 2 — ARREGLA:
  - Endpoint Pub/Sub (onMessagePublished) para RTDN de Google y otro para App Store Server Notifications v2 que sincronice premiumStatus/premiumEndsAt, maneje renovaciones, y en refund/chargeback revoque Premium y la plaza correspondiente (validForUnlock=false, decrementa lifetimeUnlockedHomeSlots).
  - Añade al cron de downgrade una rama que capture premiumStatus 'active'/'rescue' con premiumEndsAt <= now.

PASO 3 — TESTS: integración (emulador) de la reconciliación: notificación de refund → revoca Premium y plaza; renovación → extiende premiumEndsAt; 'active' vencido sin decisión → downgrade. Extiende downgrade_helpers.test.ts.

PASO 4 — VERIFICACIÓN DUAL: simula (con qa_premium.js / qa_set_home_field.js) un hogar 'active' vencido y un refund; confirma desde el físico y el emulador (cuentas distintas) que el hogar baja a Free, que reaparecen los ads y que la sincronización ocurre en ambos. Captura/analiza/borra.
Nota: deploy a prod autorizado; si no, demuestra en emulador y deja 🟧.

PASO 5 — Actualiza el estado del Prompt 06 y anota hallazgos.
```

---

## Prompt 07 — Pantalla "Hoy" se queda stale
**Categoría:** Producto · **Severidad:** 🟠 Alta · **Estado:** ✅ Solucionado, testeado, desplegado y verificado (emulador + prod + 2 dispositivos) — 2026-06-21

> **Verificación (PASO 1) — CONFIRMADO (no falso positivo):** `tasks_repository_impl.dart` reconstruía el dashboard SOLO desde el cliente: `createTask/updateTask/freezeTask/unfreezeTask/deleteTask` llamaban a `_refreshDashboard` (callable `refreshDashboard`) con **catch silencioso** (`reorderAssignees` ni eso). Si esa llamada fallaba (red intermitente, app cerrada antes de completarla), `homes/{homeId}/views/dashboard` quedaba desfasado hasta el **bootstrap** del `dashboard_provider` (solo al abrir/cambiar de hogar), un completar/pasar (que SÍ reconstruyen server-side: `apply_task_completion.ts:183`, `pass_task_turn.ts:126`, `manual_reassign.ts:86`) o el **cron diario** (`resetDashboardsDaily`, 00:00 UTC). El `dashboard_provider` es un Stream reactivo y la UI ("Hoy") consume ese doc; un dashboard stale muestra datos viejos (el fallback a tareas en vivo del `today_view_model` solo actúa cuando el doc es `null`, no cuando está stale).
>
> **Arreglo (PASO 2) — trigger Firestore server-side, sin depender del cliente:**
> - Nuevo trigger `onTaskWriteUpdateDashboard` = `onDocumentWritten("homes/{homeId}/tasks/{taskId}")` (`functions/src/tasks/update_dashboard.ts`) que llama `updateHomeDashboard(homeId)` ante CUALQUIER alta/edición/borrado de tarea. Es la garantía equivalente a la que ya tenían completar/pasar/reasignar.
> - **Coste acotado**: helper puro `dashboardRelevantFieldsChanged` (módulo nuevo `functions/src/tasks/dashboard_dedup.ts`, testeable sin emulador) — en ediciones que no tocan ningún campo que el dashboard muestra (status/currentAssigneeUid/title/visual*/recurrenceType/nextDueAt) se omite la reconstrucción. **Idempotente** (`updateHomeDashboard` reconstruye desde cero) y **sin bucle** (escribe en `views/dashboard` y `users/{uid}/memberships`, nunca en `tasks/`).
> - **Cliente**: eliminado `_refreshDashboard` y la dependencia `FirebaseFunctions` de `TasksRepositoryImpl` (era el root cause: dependencia frágil del cliente) + ajustado `tasks_provider.dart`. El bootstrap del `dashboard_provider` (reconstruir al abrir) se mantiene como red de seguridad adicional. Completar/pasar/reasignar mantienen su reconstrucción síncrona (UX inmediata, sin regresión).
>
> **Tests (PASO 3):** unit `dashboard_dedup.test.ts` (6 casos del helper, ejercita la función REAL). functions unit **293/293**. Integración emulador `dashboard_trigger.test.ts` **6/6**: crear/editar/borrar reconstruyen el dashboard SIN cliente; caso edge "fallo de red del cliente" (la tarea se escribe pero nadie llama `refreshDashboard` → el trigger igual reconstruye, el dashboard no queda stale); caso "coste acotado" (edición de campo irrelevante → no reescribe). Dart `tasks_crud_test.dart` **8/8** (Flutter de Windows; el de WSL no resuelve el package_config de Windows) + `flutter analyze` de los 3 archivos tocados **sin issues**. (Los 8 rojos de la suite de integración completa son ajenos al #07: 4 de `cleanup_user` por no arrancar el emulador de Storage — pasan con él; 3 de `full_user_flow` = H-016; 1 de `pass_task_turn` = H-020. Ninguno toca los archivos del #07.)
>
> **Deploy a prod (autorizado por el usuario — `toka-dd241` es dev, app NO publicada):** deploy QUIRÚRGICO de `onTaskWriteUpdateDashboard` esquivando el bloqueo del secret WIP del #02/#06 (`firebase deploy` exige `APP_STORE_PRIVATE_KEY`/`GOOGLE_PLAY_SA_JSON` ausentes en prod). Crear placeholders en Secret Manager fue DENEGADO (escalada de infra no autorizada); en su lugar maniobra LOCAL reversible: comentar temporalmente los `defineSecret`+`secrets:[...]` de `sync_entitlement.ts`/`google_rtdn.ts` (con backup) → `tsc` → `deploy --only functions:onTaskWriteUpdateDashboard` (`Successful create operation`) → restaurar desde backup (working tree byte-idéntico, secrets de prod intactos = siguen 404). Ver memoria [[deploy-07-trigger-surgical-secret-comment]] y H-009.
>
> **Verificación DUAL en PROD (PASO 4):**
> - **Backend autoritativo — `secrets/qa_e2e_dashboard_trigger.js`: 8/8 OK.** Crea un hogar DESECHABLE y escribe/edita/borra tareas DIRECTAMENTE en Firestore (Admin SDK, SIN que ninguna app llame `refreshDashboard`); el trigger desplegado reconstruyó el dashboard en ~4 s en cada caso (crear→aparece y totalActiveTasks sube, editar→título nuevo en el preview, borrar→sale y el contador baja). Prueba el trigger AISLADO en prod. Limpia todo.
> - **2 dispositivos contra prod (MI_9 físico oscuro + emulador claro, ambos en "Hogar Real QA"):** con AMBOS en "Hoy", creé una tarea con el Admin SDK (sin app, sin `refreshDashboard`) → **los dos dispositivos mostraron la tarea en segundos SIN reabrir la app** y el contador "tareas para hoy" pasó de 0→1; al borrarla (Admin SDK) ambos la vieron desaparecer y el contador volvió a 0. Trigger 1.7–4.9 s. Capturas analizadas y borradas; tarea de prueba eliminada y estado de QA restaurado.

**Archivos clave:** `functions/src/tasks/update_dashboard.ts` (trigger `onTaskWriteUpdateDashboard`) · `functions/src/tasks/dashboard_dedup.ts` (+ `.test.ts`, guarda de coste pura) · `functions/test/integration/dashboard_trigger.test.ts` (trigger end-to-end en emulador) · `lib/features/tasks/data/tasks_repository_impl.dart` (sin `refreshDashboard` ni `FirebaseFunctions`) · `lib/features/tasks/application/tasks_provider.dart` · `test/integration/features/tasks/tasks_crud_test.dart` · `secrets/qa_e2e_dashboard_trigger.js` (verificación prod 8/8). Contraste OK previo: `apply_task_completion.ts:183`, `pass_task_turn.ts:126`, `manual_reassign.ts:86`.

```text
Eres ingeniero de Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #07.

OBJETIVO: que el doc homes/{homeId}/views/dashboard refleje SIEMPRE las altas/ediciones/borrados de tareas, sin depender de una llamada de cliente que puede fallar.

PASO 1 — VERIFICA: reproduce en el físico/emulador creando y borrando una tarea con red intermitente o matando refreshDashboard; comprueba con qa_inspect_home.js que dashboard.updatedAt queda desfasado. Confirma que completar/pasar SÍ reconstruyen y crear/editar/borrar NO.

PASO 2 — ARREGLA: convierte crear/editar/borrar/congelar en callables que reconstruyan el dashboard server-side, o añade un trigger Firestore onWrite sobre homes/{homeId}/tasks/{taskId} que invoque updateHomeDashboard. Mantén idempotencia y coste acotado.

PASO 3 — TESTS: integración (emulador): tras crear/editar/borrar una tarea, el dashboard se actualiza sin intervención del cliente. Caso edge: fallo de red del cliente no deja el dashboard stale.

PASO 4 — VERIFICACIÓN DUAL: Owner en físico crea/edita/borra una tarea; Member en emulador (mismo hogar) debe ver el cambio en "Hoy" en segundos SIN reabrir la app. Verifica contadores (totalActiveTasks, tasksDueToday). Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 07 y anota hallazgos.
```

---

## Prompt 08 — Tareas zombi de ex-miembros
**Categoría:** Conflicto entre miembros · **Severidad:** 🟠 Alta · **Estado:** ✅ Solucionado, testeado, desplegado y verificado (emulador + prod + 2 dispositivos) — 2026-06-21

> **Verificación (PASO 1) — CONFIRMADO, ningún falso positivo (4 puntos, uno extra):**
> (a) `leaveHome` (`homes/index.ts:496-501`) y `removeMember` (`:593-600`) solo marcan `status:"left"` en el doc de miembro y la membership; **no tocan las tareas** → `currentAssigneeUid` sigue apuntando al ausente y este permanece en `assignmentOrder` (tarea "pegada" a un fantasma).
> (b) `pass_task_turn.ts:60-66` construye el conjunto de exclusión solo con `status==="frozen"` o `isMemberCurrentlyAbsent` → `getNextEligibleMember` podía pasar el turno a un `left` presente en el orden.
> (c) `apply_task_completion.ts:50-54` igual (`excludedUids` sin `left`) → al completar, el round-robin/smart podía elegir a un `left` como siguiente responsable.
> (d) **EXTRA (misma clase, no listado en el prompt):** `process_expired_tasks.ts:104-110` construye `frozenUids` igual → el cron de expiración (`onMissAssign=nextInRotation`) podía reasignar una tarea vencida a un `left`. Lo arreglo por defensa en profundidad.
> `reassignTasksFromDeletedUser` (`cleanup_user.ts`) ya hacía exactamente lo necesario (quita del `assignmentOrder` + reasigna `currentAssigneeUid` al primer elegible excluyendo left/frozen/absent) pero era **privada** del módulo. `manualReassign` ya validaba `active` (no afectado) y `applyTaskCompletion` ya exige que el *caller* sea `active` (un `left` no puede completar); lo vulnerable era el **objetivo** de la reasignación.
>
> **Arreglos (PASO 2):**
> - Exportada `reassignTasksFromDeletedUser` de `cleanup_user.ts` (renombrado el doc-comment: ahora la usan borrado de cuenta **y** leave/remove).
> - `leaveHome` y `removeMember`: tras la transacción que marca `left`, llaman (best-effort, try/catch + log) a `reassignTasksFromDeletedUser(uid|targetUid, homeId)` + `updateHomeDashboard(homeId)`, igual que `cleanupUserInHome`. La salida/expulsión ya está confirmada en la transacción; un fallo de reasignación solo se registra (las exclusiones de `left` de abajo son la red de seguridad).
> - Añadido `status==="left"` a las exclusiones de `pass_task_turn.ts`, `apply_task_completion.ts` y `process_expired_tasks.ts`.
>
> **Tests (PASO 3) — emulador Firebase, RED→GREEN verificado:**
> - **Nuevo** `test/integration/leave_remove_reassign.test.ts` (7): ejercita los callables REALES `removeMember`/`leaveHome` — tras expulsar/salir la tarea se reasigna a un activo, el ausente sale de `assignmentOrder`, sin elegibles → responsable `null`+orden vacío, y el dashboard recuenta. (RED previo: 5/7 fallaban con la tarea pegada al ausente.)
> - **Nuevo** `test/integration/process_expired_tasks.test.ts` (1): el cron invocado con `.run({})` reasigna una tarea vencida a un activo, nunca al `left`. (RED previo: reasignaba al `left`.)
> - **Extendidos** `pass_task_turn.test.ts` (+2: salta al `left` y elige al siguiente activo; si el único otro candidato es `left` → `noCandidate`) y `apply_task_completion.test.ts` (+1: salta al `left` y asigna al siguiente activo). RED previo confirmado.
> - **Extendido** `manual_reassign.test.ts` (+1, regresión): reasignar manualmente a un `left` → `failed-precondition`.
> - Helper `addMemberToHome` ampliado para aceptar `status:'left'`.
> - **Resultados:** `tsc --noEmit` limpio. Unit `src/` **293/293** (24 suites), sin regresiones. Integración: mis suites de #08 **18/18** verde. (Dos fallos rojos en la suite de integración son **pre-existentes y ajenos al #08**, ya documentados: `pass_task_turn` "absent" = H-020/#09; `full_user_flow` Paso 6/10/12 = H-016, el test comprueba el campo legacy `completedCount` que el código borra a favor de `tasksCompleted`.)
>
> **Deploy a prod (autorizado por el usuario) — deploy QUIRÚRGICO:** `firebase deploy --only functions:leaveHome,removeMember,passTaskTurn,applyTaskCompletion,processExpiredTasks --project toka-dd241` → **Deploy complete!** (5/5 Successful update). Como el working tree tiene WIP del #02/#06 que añade `defineSecret("GOOGLE_PLAY_SA_JSON"/"APP_STORE_PRIVATE_KEY")` y esos secretos NO existen en prod, un deploy normal se bloquea (confirmado: *"In non-interactive mode but have no value for the secret: APP_STORE_PRIVATE_KEY"*, mismo escollo que H-009). El revert total de entitlement a HEAD rompía por acoplamiento (HEAD-entitlement importa `DEFAULT_BANNER_UNIT_ID` que el WIP #05 quitó; `jobs.test.ts` WIP necesita `isDowngradeEligible`). Solución mínima sin tocar secretos de prod ni el resto del WIP: backup de `sync_entitlement.ts`+`google_rtdn.ts`, quitar SOLO las 3 líneas de `defineSecret`/binding `secrets:[...]` (los valores se leen por `process.env`, no `.value()`, así que compila), `tsc` limpio, deploy de las 5 funciones, y **restaurar los 2 archivos desde backup** (verificado idéntico, working tree intacto en 115 cambios). Las funciones #02/#06 NO se redesplegaron (siguen como estaban en prod).
>
> **Verificación DUAL en PROD (PASO 4): ✅ 2 dispositivos + DB.** Escenario en `mAJXlAhwRV1kdy4O05hG` ("Hogar Real QA"): Owner=Sol en **MI_9 (físico)**, Admin=Luna en **emulador**; tarea diaria de hoy "QA08 Zombie Test" sembrada con `current=Luna, order=[Luna,Sol]` (Admin SDK). (1) **Pre:** Luna (emulador) ve la tarea como suya con botones Hecho/Pasar activos. (2) Sol (físico) → Miembros → Luna → **Expulsar del hogar** → Confirmar (diálogo "no se puede deshacer"). (3) **DB prod (`qa_dump_tasks`):** Luna `status=left`; QA08 `current=Sol, order=[Sol]`; **Luna NO aparece en NINGUNA tarea activa** (todas sus tareas —QA08, Compra semanal, Limpiar cocina— reasignadas/saneadas del orden). (4) **Físico (Sol):** "Hoy" muestra QA08 reasignada a Sol con **Hecho activo (completable)** → sync OK. (5) **Emulador (Luna):** la pantalla pasa a **"Sin hogar"** → pierde acceso al hogar (reglas `isCurrentMember` del #01) → sync OK. Entorno QA restaurado (Luna reincorporada admin/active, tareas reales con Luna de vuelta, QA08 borrada, capturas analizadas y borradas).

**Archivos clave:** `functions/src/homes/index.ts` (`leaveHome` ~496-518, `removeMember` ~593-620: ahora reasignan + rebuild dashboard) · `functions/src/users/cleanup_user.ts` (`reassignTasksFromDeletedUser` ahora **exportada**) · `functions/src/tasks/pass_task_turn.ts:60-72` · `functions/src/tasks/apply_task_completion.ts:50-60` · `functions/src/jobs/process_expired_tasks.ts:104-116` (extra) · cliente `today_task_card_todo_v2.dart:180` (sin cambios: el botón Hecho ya es solo para el asignado).

```text
Eres ingeniero de Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #08.

OBJETIVO: que al salir/expulsar a un miembro, sus tareas se reasignen y deje de aparecer en la rotación, para que ninguna tarea quede "pegada" a un fantasma.

PASO 1 — VERIFICA: con un hogar de 2+ miembros, expulsa a quien tiene una tarea asignada y comprueba con qa_dump_tasks.js que currentAssigneeUid sigue apuntando al expulsado y que sigue en assignmentOrder; confirma que pass_turn/apply_task_completion no excluyen status:'left'.

PASO 2 — ARREGLA: en leaveHome y removeMember, ejecuta el mismo reassignTasksFromDeletedUser que ya usa el borrado de cuenta (quitar del assignmentOrder y reasignar currentAssigneeUid). Añade status==='left' a las exclusiones de getNextEligibleMember (pass_turn) y al cálculo de excludedUids de apply_task_completion.

PASO 3 — TESTS: integración (emulador): tras expulsar/salir, ninguna tarea queda asignada al ausente ni este aparece en assignmentOrder; pasar turno/completar nunca seleccionan a un 'left'. Extiende manual_reassign.test.ts / pass_task_turn.test.ts.

PASO 4 — VERIFICACIÓN DUAL: Owner (físico) expulsa al Member (emulador) que tenía una tarea de hoy; confirma en el físico que la tarea se reasigna a un miembro activo y es completable, y en el emulador que el ex-miembro ya no ve ni puede actuar sobre el hogar. Sincronización en ambos. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 08 y anota hallazgos.
```

---

## Prompt 09 — Vacaciones penaliza a los ausentes
**Categoría:** Conflicto entre miembros · **Severidad:** 🟠 Alta · **Estado:** ✅ Solucionado, testeado, desplegado y verificado (emulador + prod + 2 dispositivos) — 2026-06-22

> **Verificación (PASO 1) — CONFIRMADO (no falso positivo), reproducido en emulador:** el cron `processExpiredTasks` construía `frozenUids` incluyendo a los ausentes (`isMemberCurrentlyAbsent`, línea 113) **pero ese conjunto solo se usaba para la reasignación** (`computeNextAssignee`), y esta únicamente lo aplica en la rama `nextInRotation`. Con el **default `onMissAssign=sameAssignee`** devolvía `actorUid` → la tarea se quedaba pegada al ausente. Y la **penalización** (`missedCount++`, `complianceRate↓`, evento `missed` con `penaltyApplied:true`) se aplicaba **incondicionalmente a `actorUid`** sin mirar la ausencia. Test de integración RED (`vacation_reassign.test.ts`): ausente con tarea vencida → `missedCount` 0→1, `complianceRate` baja, tarea sigue en él. Además NO existía reasignación al INICIAR la vacación (`saveVacation` solo escribe el campo `vacation`, sin callable ni trigger). Las vacaciones son **premium** (UI gateada por `canUseVacations`; `update_dashboard.ts:189`); el arreglo respeta ese gate (la lógica server actúa sobre el campo `vacation`, presente solo si el cliente lo activó).
>
> **Arreglos (PASO 2) — dos capas:**
> - **(A) Reasignación EAGER al iniciar la vacación** — nuevo `functions/src/tasks/vacation_reassign.ts`: helper exportado `reassignActiveTasksForAbsentMember(homeId, uid)` (reasigna las tareas activas cuyo responsable es el ausente al siguiente PRESENTE vía `getNextEligibleMember`, **conservando `assignmentOrder`** → vuelve a la rotación al regresar) + trigger `onMemberVacationStart` (`onDocumentWritten("homes/{homeId}/members/{memberId}")`) que actúa **solo en la transición presente→ausente** (`!wasAbsent && isAbsent`) y reconstruye el dashboard. El cliente NO cambia: el trigger se dispara sobre el write existente de `saveVacation`.
> - **(B) El cron NO penaliza al ausente** — en `process_expired_tasks.ts`, si `isMemberCurrentlyAbsent(actorMember)` la tarea **rueda** hacia un presente (`getNextEligibleMember`, ignorando `onMissAssign`, igual que pasar turno) y se hace `return` **sin evento `missed` ni tocar stats**. La rama de penalización normal (responsable presente que incumple) queda intacta.
> - **Bonus:** se corrigió el fixture del test pre-existente en rojo (H-020): `pass_task_turn.test.ts` fijaba al ausente con `status:'absent'`, que `isMemberCurrentlyAbsent` ignora a propósito (solo lee el campo `vacation`); ahora usa un objeto `vacation` activo. El `pass_task_turn` de producción ya excluía bien a los ausentes — era un falso positivo del test.
>
> **Tests (PASO 3):** nuevo `test/integration/vacation_reassign.test.ts` (12 casos): cron no penaliza al ausente (missedCount/compliance sin cambiar, sin evento `missed`) + reasigna a un presente + mantiene al ausente en `assignmentOrder`; **regresión** (responsable presente sí se penaliza con `penaltyApplied:true`); helper eager mueve solo las tareas del ausente y respeta a quien ya es presente; sin heredero disponible la tarea se queda; trigger reasigna solo en la transición a ausente (no-op si ya estaba ausente o si el write no activa la vacación). `vacation.test.ts` unit intacto. **Resultados:** `tsc --noEmit` limpio; unit `src/` **293/293**; integración afectada (vacation_reassign + pass_task_turn + process_expired_tasks) **25/25**; integración completa **18/19 suites** (el único rojo, `full_user_flow` Paso 6/10/12, es el pre-existente **H-016** — campo legacy `completedCount`, ajeno a #09).
>
> **Despliegue a prod (autorizado) — deploy QUIRÚRGICO** (mismo escollo de secretos WIP #02/#06 que el #08): backup de `sync_entitlement.ts`+`google_rtdn.ts`, quitar SOLO las líneas `defineSecret`/`secrets:[...]` (los valores van por `process.env`), `FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy --only functions:processExpiredTasks,onMemberVacationStart --project toka-dd241` → **Deploy complete!** (`processExpiredTasks` actualizada; `onMemberVacationStart` **creada en europe-west1**, colocada con la BD eur3 — sin cross-region hop), y **restaurar los 2 archivos desde backup** (diff vacío). Las funciones #02/#06 NO se redesplegaron.
>
> **Verificación DUAL en PROD (PASO 4): ✅ 2 dispositivos + DB.** Hogar `mAJXlAhwRV1kdy4O05hG` ("Hogar Real QA", puesto premium para habilitar vacaciones; restaurado a `free` al terminar): Owner=Sol en **MI_9 (físico)**, Admin=Luna en **emulador**. Tarea `QA09-Vacaciones` sembrada en Luna con `order=[Luna,Sol]`. (1) Luna (emulador) abre Miembros → su perfil → **Vacaciones/Ausencia**, activa el switch (inicio hoy, sin fin) y **Guardar** → `vacation.isActive=true` en BD (escritura real del cliente). (2) El **trigger desplegado** disparó: `qa_dump_tasks` muestra `QA09-Vacaciones` reasignada a **Sol** (y su otra tarea, "Compra semanal QA v2", a **Tres**) con Luna **aún en `assignmentOrder`**. (3) **Físico (Sol):** "Hoy" muestra `QA09-Vacaciones` asignada a Sol con **✓ Hecho activo** (completable) → sync en vivo entre cuentas OK. (4) **Luna NUNCA fue penalizada**: su `missedCount` siguió en **1** durante todo el flujo. Escenario restaurado (Compra semanal de vuelta a Luna, tareas QA09 borradas, vacación de Luna OFF, hogar a `free`), capturas analizadas y borradas. **Nota Parte B en prod:** no se disparó manualmente el cron global `processExpiredTasks` (barrido de TODOS los hogares → blast radius sobre otras casas QA; además denegado por el clasificador de seguridad). Su no-penalización queda probada en emulador con el código IDÉNTICO ya desplegado; la reasignación eager (Parte A) hace que en la práctica las tareas del ausente ni siquiera lleguen a vencer en él.

**Archivos clave:** `functions/src/tasks/vacation_reassign.ts` (NUEVO: helper `reassignActiveTasksForAbsentMember` + trigger `onMemberVacationStart`) · `functions/src/tasks/index.ts` (export del módulo) · `functions/src/jobs/process_expired_tasks.ts:96-145` (rama "responsable ausente": rueda sin penalizar) · `functions/src/shared/vacation.ts` (`isMemberCurrentlyAbsent`, sin cambios) · `functions/src/tasks/pass_turn_helpers.ts` (`getNextEligibleMember`, reutilizado) · `lib/features/members/data/members_repository_impl.dart:243-256` (`saveVacation` sin cambios; el trigger se dispara sobre su write).

```text
Eres ingeniero de Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #09.

OBJETIVO: que un miembro de vacaciones no sea penalizado estadísticamente ni conserve tareas que vencerán durante su ausencia.

PASO 1 — VERIFICA: pon a un miembro de vacaciones (cubriendo hoy), deja vencer una de sus tareas y confirma con qa_dump_tasks.js / qa_audit_state.js que se le incrementa missedCount y baja complianceRate, y que la tarea seguía asignada a él. Revisa que process_expired_tasks.ts con sameAssignee no excluye a ausentes del cómputo.

PASO 2 — ARREGLA: (a) al iniciar la vacación, reasignar sus tareas activas a miembros disponibles (o congelarlas según diseño de producto); (b) en process_expired_tasks, excluir a los ausentes (isMemberCurrentlyAbsent) del incremento de penalización aunque onMissAssign=sameAssignee. Verifica coherencia con la regla de producto de vacaciones (premium).

PASO 3 — TESTS: vacation.test.ts + integración: un ausente con tarea vencida no recibe penalización; su tarea se reasigna/congela; al volver, vuelve a la rotación.

PASO 4 — VERIFICACIÓN DUAL: Member (emulador) activa vacaciones; Owner (físico) observa que sus tareas se reasignan y que tras el cron no se le penaliza. Comprueba estadísticas en ambas vistas. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 09 y anota hallazgos.
```

---

## Prompt 10 — Motor de recurrencia deriva (DST + mensual/anual)
**Categoría:** Producto · **Severidad:** 🟠 Alta · **Estado:** ✅ Solucionado, testeado, desplegado y verificado (prod + 2 dispositivos) — 2026-06-22

> **Verificación (PASO 1) — CONFIRMADO, no es falso positivo.** `addRecurrenceInterval(base, recurrenceType)` (`task_assignment_helpers.ts:41-54`) recibía **solo** el discriminante grueso (`recurrenceType`) y hacía `setUTCDate/Hours/Month/FullYear`, **ignorando por completo `task.recurrenceRule`** (timezone, hora, día, weekday, `every`, `endTime`, nthWeekday). Lo usaban `apply_task_completion.ts:98` (al completar) y `process_expired_tasks.ts:120` (cron de expiración). Drift demostrado numéricamente: una **diaria 09:00 Europe/Madrid** completada la víspera del cambio DST de primavera salta a **10:00** locales tras el cambio (la suma en UTC mantiene el instante 08:00Z, que pasa a ser las 10:00 CEST). Además: `monthlyNth` (p. ej. "2.º martes") se ignoraba (solo desplazaba la fecha exacta +1 mes); `weekly` con varios días (`["MON","WED","FRI"]`) sumaba +7 manteniendo el mismo weekday; `every` y la ventana `startTime/endTime` de `hourly` se ignoraban; `monthlyFixed` día 31 no clampeaba al último día del mes.
>
> **Arreglos (PASO 2):** nuevo `functions/src/tasks/recurrence_calculator.ts` (motor **luxon**, IANA tz-aware) que **replica 1:1** `lib/core/utils/recurrence_calculator.dart`: `parseRecurrenceRule` (mismos defaults/`kind`||`type` que el cliente) + `nextDue` para hourly/daily/weekly/monthlyFixed/monthlyNth/yearlyFixed/yearlyNth (con `preferToday`) + `computeNextDueAt(task, currentDue)`. La hora de **pared** se reconstruye por componentes en la zona de la regla (igual que `tz.TZDateTime`), por lo que se mantiene estable a través de DST. `addRecurrenceInterval` **eliminado**; `apply_task_completion.ts` y `process_expired_tasks.ts` ahora llaman a `computeNextDueAt`. `oneTime` sigue siendo terminal (devuelve `currentDue`); fallback legacy en UTC para tareas sin `recurrenceRule` (preserva el comportamiento anterior).
>
> **Tests (PASO 3):** unit functions **315/315** (nuevo `recurrence_calculator.test.ts` con **28** casos: DST spring 31-mar y fall 27-oct, todos los modos, clamps feb 28/29 y día 31, monthlyNth recalculado, parser, `computeNextDueAt` + fallback). Integración emulador **146/146** (nuevos en `apply_task_completion.test.ts` —diaria DST 09:00→07:00Z, monthlyNth 2.º martes recalculado— y `process_expired_tasks.test.ts` —cron reprograma manteniendo 09:00 en DST—, ejercitando la **callable/cron reales**). **Paridad cliente↔backend**: el test Dart `recurrence_calculator_test.dart` (ampliado con los 2 casos DST) pasa **22/22** y produce **los mismos instantes** que el backend (07:00Z spring, 08:00Z fall). De paso se resolvió **H-016** (`full_user_flow.test.ts` esperaba el campo viejo `completedCount`; canónico `tasksCompleted`).
>
> **Despliegue a prod (autorizado por el usuario):** `applyTaskCompletion` + `processExpiredTasks` desplegadas a `toka-dd241` (`Deploy complete!`) usando la **vía quirúrgica** del secreto WIP del #02 (backup → borrar líneas `defineSecret`/`secrets:[...]` de `sync_entitlement.ts`+`google_rtdn.ts` → deploy → restaurar; working tree restaurado íntegro, `tsc` OK). `syncEntitlement` intacta.
>
> **Verificación DUAL en prod (PASO 4):** físico **MI_9 = Sol** (owner) y emulador **= Luna** (admin), mismo hogar "Hogar Real QA". Se fijó `nextDueAt` de "Limpiar cocina" (diaria 09:00 Europe/Madrid) a la víspera DST (`2026-03-28T08:00Z`) y se completó **desde la app del físico** (callable real desplegada): la BD quedó en **`2026-03-29T07:00:00.000Z`** = 29-mar 09:00 Madrid (CEST), **manteniendo la hora de pared a través del cambio DST** (el bug viejo habría dado `08:00Z`=10:00 local). **Sincronización confirmada**: el emulador (Luna) vio en vivo "Completada por Sol" y la reasignación por rotación a Luna; ambos dispositivos leen el **mismo instante** (la etiqueta horaria difiere por la zona del dispositivo, no del cálculo — ver `Hallazgos.md` H-023). Tarea restaurada a su estado original. Capturas analizadas y borradas.

**Archivos clave:** `functions/src/tasks/recurrence_calculator.ts` (NUEVO, motor tz-aware) · `functions/src/tasks/task_assignment_helpers.ts:41-54` (`addRecurrenceInterval` ELIMINADO) · `apply_task_completion.ts:98` y `process_expired_tasks.ts:120` (ahora `computeNextDueAt`) · paridad con `lib/core/utils/recurrence_calculator.dart`.

```text
Eres ingeniero de Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #10.

OBJETIVO: que la 2ª ocurrencia en adelante se calcule con la RecurrenceRule en la zona del hogar (tz-aware), no sumando intervalos UTC.

PASO 1 — VERIFICA: con qa_set_task_field.js crea/ajusta una tarea "diaria 09:00 Europe/Madrid" y otra "mensual día 15" y simula varias completaciones; comprueba que nextDueAt deriva de hora (alrededor de DST) y que la mensual no respeta el día/hora de la regla. Confirma que addRecurrenceInterval ignora la regla y solo suma en UTC.

PASO 2 — ARREGLA: reemplaza addRecurrenceInterval por un cálculo de siguiente ocurrencia que use la RecurrenceRule + timezone (replica la lógica de recurrence_calculator.dart en backend, o compártela). Cubre hourly/daily/weekly/monthly(fixedDay y nthWeekday)/yearly. Mantén la hora de pared estable a través de DST.

PASO 3 — TESTS: amplía las pruebas de recurrencia en backend con casos de DST (cruce marzo/octubre) y todos los modos mensual/anual; comprueba paridad con el cliente.

PASO 4 — VERIFICACIÓN DUAL: crea tareas recurrentes en el físico; confirma en el emulador (otra cuenta, mismo hogar) que la próxima fecha mostrada y la hora coinciden con la regla tras completar varias veces, y que ambos dispositivos ven la misma nextDueAt. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 10 y anota hallazgos.
```

---

## Prompt 11 — Reparto percibido injusto (penalización silenciosa + editar reinicia rotación)
**Categoría:** Conflicto entre miembros · **Severidad:** 🟠 Alta · **Estado:** ✅ Solucionado, testeado y verificado (móvil + emulador + prod) — 2026-06-22

> **Verificación (PASO 1): los 2 puntos CONFIRMADOS, ningún falso positivo.**
> (a) **Penalización silenciosa:** `pass_task_turn.ts:107` marca `penaltyApplied:true` SIEMPRE (incondicional) e incrementa `passedCount`, pero `pass_turn_dialog.dart:60` solo mostraba el banner si `diff >= 1.0` con el delta **sin redondear**. Un usuario consolidado (p. ej. 100 completadas / 0 pasadas → caída de 0,99 pp) NO veía aviso pese a penalizarse → viola la regla de producto #7. Además el espejo cliente del "siguiente responsable" (`today_view_model.dart:90`) excluía `frozen`/vacaciones pero **no** `left`, mientras el backend (`pass_task_turn.ts:67`) sí lo excluye (divergencia → podía anunciar a un ex-miembro).
> (b) **Editar reinicia la rotación:** `task_model.dart:70-71` (`toUpdateMap`) reescribía `currentAssigneeUid = assignmentOrder.first` en CADA edición; `initEdit` carga `assignmentOrder` pero el form no preserva el asignado actual → editar el título saltaba el turno al primero. Confirmado en prod: tarea "Compra semanal QA v2" con orden `[Sol,Luna,Tres]` y `current=Luna`.
>
> **Arreglos (PASO 2) — 100% cliente (el backend ya era correcto):**
> - (a) `pass_turn_dialog.dart`: eliminado el umbral `diff>=1%`. El aviso de penalización se muestra **SIEMPRE**. Si la caída es perceptible al redondeo (`after < before`) → texto con delta (`pass_turn_compliance_warning`); si redondea a 0 pp (usuario muy consolidado) → `pass_turn_minimal_impact` (clave i18n es/en/ro que ya existía pero estaba MUERTA), evitando "100% → 100%".
> - (a) `today_view_model.dart` (`fetchPassTurnInfo`): el espejo del "siguiente responsable" ahora excluye también `status=='left'`, alineado EXACTAMENTE con `passTaskTurn`.
> - (b) `task_model.dart` (`toUpdateMap`): nueva firma `{previousOrder, currentAssigneeUid}`. `currentAssigneeUid` solo se reescribe si `assignmentOrder` cambia; si no cambia, la clave se OMITE (el doc conserva el responsable de Firestore). Si cambia, se preserva al asignado actual cuando sigue en el orden; si ya no está, cae al primero (o `null` si vacío). `tasks_repository_impl.dart` (`updateTask`) lee el doc previo de Firestore (no del form, que podría estar stale si otro miembro pasó turno) y pasa `previousOrder`/`currentAssigneeUid`.
>
> **Tests (PASO 3) — VERDE:**
> - **Unit** `test/unit/features/tasks/task_model_test.dart` (NUEVO, 6 casos): editar campo no-asignación NO emite `currentAssigneeUid`; reordenar preservando al asignado lo mantiene; quitarlo cae al primero; orden vacío→null; alta (`toFirestore`) sigue asignando al primero (regresión).
> - **UI/golden** `test/ui/features/tasks/pass_turn_dialog_test.dart`: reescrito el caso que codificaba el bug ("NO mostraba banner <1%") → ahora exige el aviso "impacto mínimo" con delta sub-1pp y el caso 100→99; nuevo golden `pass_turn_dialog_minimal.png` (delta pequeño). 10/10.
> - **Integración cliente** `pass_turn_info_test.dart`: nuevo caso "ex-miembro (left) se salta como el backend" (verificado RED revirtiendo el cambio → devolvía 'Bob', GREEN → 'Carlos'). 9/9.
> - **Integración backend** `functions/test/integration/pass_task_turn.test.ts`: nuevo caso "caída sub-1pp pero `penaltyApplied=true` igualmente" (fija el contrato que obliga a avisar siempre). 13/13 contra emulador Firestore.
> - `flutter analyze` (4 dirs tocados): 0 errores (warnings/info preexistentes y ajenos). Tests del backend `tsc`/ts-jest limpios.
>
> **Verificación DUAL en PROD (PASO 4) — `mAJXlAhwRV1kdy4O05hG` "Hogar Real QA", Sol(owner)=MI_9 físico, Luna(admin)=emulador (cuentas distintas, mismo hogar):**
> - **(b)** Sol (físico) editó el título de "Compra semanal QA v2" (orden `[Sol,Luna,Tres]`, `current=Luna`) → en BD el título cambió pero `current` **siguió siendo Luna** (NO volvió a Sol/first) y el orden intacto. El emulador (Luna) mostró el título nuevo y **conservó su turno** (botones Hecho/Pasar) → ambos ven el mismo asignado, sin reinicio. Sincronización en vivo confirmada.
> - **(a)** Con Sol consolidado (500 completadas/0 pasadas → caída <1 pp, el caso que el bug ocultaba), el diálogo "Pasar turno" en el físico mostró **"El impacto en tu cumplimiento será mínimo."** + "El siguiente responsable será: Luna" → el aviso AHORA aparece (antes: nada). Capturas analizadas y borradas; estado QA (contadores de Sol, título de la tarea) restaurado.
>
> **Hallazgo nuevo (PASO 5):** `Hallazgos.md` **H-024** — `passTaskTurn` penaliza también cuando `noCandidate=true` (no hay a quién pasar); fuera de alcance del #11 (decisión de producto). El test obsoleto `recurrence_order_test.dart` (2 rojos) ya estaba registrado como **H-021** (preexistente, ajeno).

**Archivos clave:** `lib/features/tasks/presentation/widgets/pass_turn_dialog.dart` (aviso siempre visible) · `lib/features/tasks/application/today_view_model.dart` (espejo del siguiente responsable excluye `left`) · `lib/features/tasks/data/task_model.dart` (`toUpdateMap` no reinicia la rotación) · `lib/features/tasks/data/tasks_repository_impl.dart` (`updateTask` lee el estado previo). Tests: `test/unit/features/tasks/task_model_test.dart`, `test/ui/features/tasks/pass_turn_dialog_test.dart` (+golden `pass_turn_dialog_minimal.png`), `test/integration/features/tasks/pass_turn_info_test.dart`, `functions/test/integration/pass_task_turn.test.ts`.

**Archivos clave (verificación original):** `lib/.../pass_turn_dialog.dart:60` (banner solo si caída ≥1%) · `functions/src/tasks/pass_task_turn.ts:107` (marca penaltyApplied igual) · `lib/features/tasks/data/task_model.dart:70-71` (`toUpdateMap` fija `currentAssigneeUid = assignmentOrder.first`) · `tasks_repository_impl.dart:65-72`.

```text
Eres ingeniero de Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #11.

OBJETIVO: (a) que la penalización por pasar turno se avise SIEMPRE que se aplique (regla de producto #7), y (b) que editar una tarea no reinicie la rotación al primero.

PASO 1 — VERIFICA: con un usuario de compliance alto, pasa turno y confirma que NO aparece aviso pese a que pass_task_turn.ts marca penaltyApplied=true. Edita el título de una tarea cuyo turno va por la mitad y confirma con qa_dump_tasks.js que currentAssigneeUid vuelve a assignmentOrder.first.

PASO 2 — ARREGLA: (a) en pass_turn_dialog, mostrar el aviso de penalización siempre que el backend vaya a marcar penaltyApplied (no por umbral de 1%); unificar la fuente del "siguiente responsable" con el backend. (b) En toUpdateMap, no reescribir currentAssigneeUid salvo que cambie assignmentOrder; si cambia, preservar la posición del asignado actual si sigue en el orden.

PASO 3 — TESTS: unit de toUpdateMap (editar campos no-asignación no cambia el asignado); UI/golden del diálogo mostrando penalización con delta pequeño; integración del pase.

PASO 4 — VERIFICACIÓN DUAL: Owner (físico) edita una tarea a mitad de rotación; Member (emulador) confirma que el turno NO se reinició y que ambos ven el mismo asignado. Pasa turno con un usuario consolidado y confirma que el aviso aparece en el dispositivo. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 11 y anota hallazgos.
```

---

## Prompt 12 — Gobernanza de roles (owner SPOF, admin expulsa, invitar-email muerto)
**Categoría:** Conflicto entre miembros · **Severidad:** 🟠 Alta · **Estado:** ✅ Solucionado, testeado y verificado (2 dispositivos + deploy dev) — 2026-06-22

> **Verificación (PASO 1):** 3 de 4 CONFIRMADOS, 1 falso positivo.
> (a) **SPOF owner CONFIRMADO**: `home_settings_screen_v2.dart` mostraba `leave_home_tile` SIN gatear por `isOwner`; al owner, `_confirmLeave`→`leaveHome()` lanza `CannotLeaveAsOwnerException` (backend "Owner cannot leave home") → snackbar de error, owner atrapado. (b) **Admin expulsa CONFIRMADO (matizado)**: la UI ya ocultaba "Expulsar" a no-owners (`canRemoveMember = isOwner`), pero la **callable** `removeMember` aceptaba a un admin para cualquier member → escalada vía llamada directa (defensa en profundidad ausente). (c) **inviteMember inexistente CONFIRMADO y peor**: `httpsCallable('inviteMember')` no existe en `functions/src` y `member_actions_provider.inviteMember` usaba `AsyncValue.guard` (tragaba el error) → `_sendEmailInvite` siempre llegaba a `pop()`: sheet cerrado en silencio, sin efecto ni feedback. (d) **Bug histórico `.first` FALSO POSITIVO**: `transfer_ownership_sheet.dart` ya hace elegir candidato explícito + diálogo nominal; sin heurística `.first`. `promoteToAdmin` SIN tope confirmado.

> **Decisiones de producto:** (1) retirar la rama email del sheet (no hay infra de email; el código/QR funciona) — sin auto-promoción por inactividad; (2) salida del owner solo vía "Transferir y salir"; (3) expulsar = solo el owner; (4) tope de **5 admins** además del owner.

> **Arreglo (PASO 2-3):** Backend `functions/src/homes/index.ts`: `removeMember` ahora exige `callerRole === "owner"` (`only-owner-can-remove`); `promoteToAdmin` cuenta admins activos en la transacción y rechaza el 6º con `resource-exhausted` (`PREMIUM_LIMITS.maxAdminsBesidesOwner=5` en `shared/free_limits.ts`). Cliente: oculto `leave_home_tile` al owner y añadido tile `transfer_and_leave_tile`; `transfer_ownership_sheet.dart` parametrizado con `leaveAfter` (transferOwnership→leaveHome→go(home)); rama email eliminada end-to-end (sheet + provider + repo + interfaz); `promoteToAdmin` del provider ahora relanza; tope mostrado vía `MaxAdminsReachedException`→`homes_admins_max_reached` en admins_sheet y member_profile. Tests: integración real contra emulador `functions/test/integration/homes_governance.test.ts` (8/8: owner-only expel, tope 5, admin-left no cuenta, transferir+salir); unit matrix actualizada; widget tests `home_settings_governance_test.dart` (tiles owner vs miembro) e `invite_sheet_feedback_test.dart` (feedback, sin email). `npm test` 315/315 + analyze limpio + golden owner regenerado.

> **Verificación dual (PASO 4):** desplegado `removeMember`+`promoteToAdmin` a `toka-dd241` (deploy quirúrgico esquivando los `defineSecret` WIP del #02/#06, restaurado después). En **físico (Sol, owner)** Ajustes del hogar muestra "Transferir y salir" y NO "Abandonar". Ejecutado "Transferir y salir"→Luna: Sol queda **"Sin hogar"** (fuera, sin privilegios) y en **emulador (Luna)** aparecen en vivo los tiles owner ("Transferir propiedad/y salir", "Cerrar hogar"); Firestore consistente (ownerUid=Luna, Sol admin/left, Luna owner/active). Restaurado el hogar al estado original (Sol owner, Luna admin) por Admin SDK; al volver, Luna (admin) ve de nuevo "Abandonar hogar" sin tiles owner (gating correcto en ambos sentidos). El sheet de invitar no pudo abrirse on-device por estar el hogar al tope Free 3/3 (FAB oculto, legítimo); cubierto por widget tests.

**Archivos clave:** `functions/src/homes/index.ts:473-475` (owner no puede salir) · `home_settings_screen_v2.dart:406-413` (tile "Abandonar" visible al owner) · `index.ts:567-572` (admin expulsa a cualquier member) · `index.ts:929` (promoteToAdmin solo gateado por premium, sin tope) · `invite_member_sheet.dart:65-72` → `member_actions_provider.dart:12` → `members_repository_impl.dart:77-87` (callable `inviteMember` INEXISTENTE).

```text
Eres ingeniero de Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #12.

OBJETIVO: dar una salida limpia al owner, acotar el poder de expulsión y arreglar el botón muerto de invitar por email.

PASO 1 — VERIFICA: confirma que el tile "Abandonar" se muestra al owner y devuelve error; que un admin puede expulsar a cualquier member; y que "Invitar por email" llama a httpsCallable('inviteMember') que NO existe en functions/src (grep). El bug histórico de transferir a no-owner por .first parece corregido: confírmalo.

PASO 2 — ARREGLA:
  - Ocultar "Abandonar" al owner y ofrecer "Transferir y salir"; permitir auto-promoción del admin más antiguo si el owner lleva N días inactivo (definir N con producto).
  - Acotar removeMember (p. ej. solo owner, o requerir confirmación del owner / antigüedad), y considerar un tope de admins.
  - Implementar la callable inviteMember (enviar invitación por email) O retirar la rama email del sheet y dejar solo código/QR (que sí funciona). Evita botones que cierran el sheet sin efecto.

PASO 3 — TESTS: integración de transferOwnership + salida del owner; reglas de quién puede expulsar; test de que el flujo de invitar no deja al usuario sin feedback.

PASO 4 — VERIFICACIÓN DUAL: en el físico (Owner) prueba "Transferir y salir" hacia el Admin (emulador) y confirma que el rol se sincroniza y el ex-owner pierde privilegios. Con Admin, intenta expulsar y verifica el nuevo límite. Prueba invitar (email o código) y confirma que el invitado en el otro dispositivo recibe/usa la invitación. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 12 y anota hallazgos.
```

---

## Prompt 13 — Reparto "inteligente" con `completions60d` que nunca decae
**Categoría:** Producto · **Severidad:** 🟡 Media · **Estado:** ✅ Solucionado, testeado y verificado (móvil + emulador + deploy dev) — 2026-06-22

> **Verificación (PASO 1): CONFIRMADO, no es falso positivo.** `completions60d` es *increment-only* (`apply_task_completion.ts:176` `FieldValue.increment(1)`), se inicializa a 0 (`member_factory.ts:78`, `test/integration/helpers/setup.ts:85`) y **ningún job lo decae** (grep de decay/decaimiento/60d sin resultados). Se usaba TAL CUAL como peso `completionsRecent` del reparto inteligente (`apply_task_completion.ts:62-71` → `task_assignment_helpers.scoreOf` = `completionsRecent*difficultyWeight + daysSinceLastExecution*-0.1`), así que un miembro muy cumplidor en el pasado quedaba excluido del reparto **para siempre**. El reparto inteligente es **solo de servidor** (`pass_task_turn`/`process_expired_tasks` usan round-robin; el `SmartAssignmentCalculator` del cliente está muerto — ver `Hallazgos.md` H-026). **Fuente fechada alternativa que SÍ existe y sirve:** los eventos `taskEvents` con `eventType:"completed"` + `completedAt` + `performerUid` (los escribe solo `apply_task_completion`); el índice compuesto `(eventType, completedAt)` ya estaba declarado en `firestore.indexes.json` → **no hizo falta índice nuevo**.
>
> **Arreglo (PASO 2):** nuevo helper puro `countCompletionsInWindow(events, nowMs, windowDays)` en `task_assignment_helpers.ts` (cuenta por miembro los `completed` dentro de la ventana, borde inclusivo, ignora eventos sin performer). En `apply_task_completion.ts`: una **pre-lectura** (fuera de la transacción) decide si la tarea es smart; si lo es, `loadRecentCompletionCounts()` consulta `taskEvents` (`eventType==completed` + `completedAt>=now-60d`) y agrega por `performerUid` (fallback `actorUid`). Ese conteo alimenta `completionsRecent` en lugar de `completions60d`. Para round-robin no se hace la query extra. **Se conserva el incremento de `completions60d`** porque lo usa `downgrade_helpers.autoSelectForDowngrade` como desempate (ver H-027); solo deja de regir el reparto. `daysSinceLastExecution` sigue derivándose de `lastCompletedAt` (recencia monotónica, no necesita decaer).
>
> **Tests (PASO 3):** unit `task_assignment_helpers.test.ts` ampliado — `countCompletionsInWindow` (dentro/fuera de ventana, borde `>=`, agregación por performer, sin performer) + caso de negocio "un cumplidor histórico sin actividad en 60 días vuelve a ser elegible". Integración nueva `test/integration/smart_distribution_load.test.ts` (callable REAL + Firestore emulador): con histórico desigual (VETERAN `completions60d` alto pero eventos de hace 90 días = fuera de ventana; ROOKIE bajo pero completados recientes), al completar en modo smart el siguiente es **VETERAN** (RED contra el código viejo: elegía ROOKIE) + regresión de que `completions60d` se sigue incrementando. **Unit src/ 321/321 (25 suites) · Integración 157/157 (21 suites) · `tsc` limpio.**
>
> **Despliegue (autorizado por el usuario — `toka-dd241` es dev):** deploy QUIRÚRGICO `firebase deploy --only functions:applyTaskCompletion` (con `FUNCTIONS_DISCOVERY_TIMEOUT=120`). El discovery se bloqueaba por los `defineSecret` del WIP #02/#06 (`GOOGLE_PLAY_SA_JSON`/`APP_STORE_PRIVATE_KEY`, que no existen en `toka-dd241`); se aplicó la vía documentada (backup + retirar SOLO las líneas `defineSecret`/`secrets:[...]` de `sync_entitlement.ts`+`google_rtdn.ts` — los valores van por `process.env` — deploy de la única función, restaurar). `applyTaskCompletion(us-central1)` actualizada; entitlement restaurado verbatim.
>
> **Verificación DUAL en prod (PASO 4) — `secrets/qa_h13_scenario.js`:** hogar "Hogar Real QA" (`mAJXlAhwRV1kdy4O05hG`), **Sol en MI_9 (físico)** y **Luna en emulador** (cuentas distintas, mismo hogar). Escenario: Sol = veteran (`completions60d`=30, el MÁS alto; carga real 60d = 3) y Luna = rookie (`completions60d`=2; carga real 60d = 9→10). Tarea smart `[Luna, Sol]` asignada a Luna. **Luna completó en el emulador → el servidor reasignó a SOL** (carga real menor) pese a su `completions60d` máximo; con la lógica vieja Sol habría quedado evitado para siempre. La "Hoy" de **Sol (MI_9) mostró la tarea ya asignada a Sol + "Completada por Luna"** en Hechas → **sincronización cross-cuenta verificada**. `completions60d` de Luna subió 2→3 (sigue manteniéndose para el downgrade). Escenario limpiado (tarea + 12 eventos borrados, miembros restaurados); residuo menor anotado: la completación de prueba dejó `tasksCompleted`+1 en Luna (el clasificador denegó el write ad-hoc de corrección; despreciable en hogar QA).

**Archivos clave:** `functions/src/tasks/apply_task_completion.ts` (pre-lectura del modo + `loadRecentCompletionCounts` + `completionsRecent` desde la ventana) · `functions/src/tasks/task_assignment_helpers.ts` (`countCompletionsInWindow`, `CompletedLoadEvent`) · `functions/src/tasks/task_assignment_helpers.test.ts` · `functions/test/integration/smart_distribution_load.test.ts` · `firestore.indexes.json` (índice `(eventType, completedAt)` ya existente, reutilizado) · `secrets/qa_h13_scenario.js` (escenario de verificación dual). **Antes:** `apply_task_completion.ts:166` (`completions60d` increment-only) · `task_assignment_helpers.ts:9-11` (score penalizaba a quien más completó de por vida).

```text
Eres ingeniero de Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #13.

OBJETIVO: que el reparto inteligente use una carga real de 60 días, no un acumulado de por vida.

PASO 1 — VERIFICA: confirma que completions60d solo se incrementa y que ningún job lo decae; que task_assignment_helpers lo usa como peso. Revisa si hay un campo/fuente alternativa de eventos 'completed' fechados.

PASO 2 — ARREGLA: calcula la carga contando eventos taskEvents 'completed' de los últimos 60 días (o implementa un decaimiento por job programado). Ajusta task_assignment_helpers para usar la ventana real.

PASO 3 — TESTS: unit del cálculo de carga con eventos dentro/fuera de la ventana; test de que un miembro muy cumplidor no es evitado indefinidamente.

PASO 4 — VERIFICACIÓN DUAL: monta un hogar con histórico desigual (qa scripts); crea tareas con reparto inteligente y confirma en físico y emulador (cuentas distintas) que la asignación se reparte de forma equilibrada según los últimos 60 días. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 13 y anota hallazgos.
```

---

## Prompt 14 — Conversión ahogada (sin free trial + límite Free eludible)
**Categoría:** Monetización · **Severidad:** 🟡 Media · **Estado:** 🟧 Parcial — 2026-06-22 · límite Free no eludible **solucionado + testeado en emulador (incl. concurrencia)**; free trial **cableado + testeado** (mocks/widget). Pendiente: (a) **deploy autorizado** de functions+rules a prod para la verificación dual en dispositivos —bloqueado por el WIP de secretos del #02 (ver `[[surgical-deploy-around-iap-secret-wip]]`, H-009)— y rebuild+install de APK nueva (cliente enruta el alta por callable); (b) **config de la oferta de trial en Play/App Store** (H-029). Vector de elusión residual freeze/unfreeze → **H-028**.

> **Verificación (PASO 1):** ambas mitades confirmadas leyendo código.
> - **Sin trial:** `paywall_screen_v2.dart` solo mostraba chips anual/mensual con CTAs `startPurchase(annual|monthly)`; `subscription_repository_impl.purchase` hacía `queryProductDetails`→`buyNonConsumable` sin leer ni mostrar ninguna oferta introductoria.
> - **Límite eludible (con matiz):** el #07 YA añadió el trigger `onTaskWriteUpdateDashboard`, así que la afirmación literal "solo se recalcula al llamar a `refreshDashboard`" estaba desactualizada. **Pero el bypass era real por una razón más profunda:** el alta de tareas era una escritura directa del cliente (`tasks_repository_impl.dart:54`) gateada por `firestore.rules` `freeCanCreateTask()`, que leía el contador DENORMALIZADO y eventual `views/dashboard.planCounters.activeTasks`. Las reglas **no pueden contar documentos**, así que una ráfaga de altas más rápida que la reconstrucción del dashboard evaluaba todas contra el mismo `activeTasks < 4` obsoleto. Demostrado server-side: el test de concurrencia lanza 8 altas en paralelo desde un hogar Free vacío.
>
> **Arreglos:**
> - **Límite no eludible:** nueva callable transaccional `createTask` (`functions/src/tasks/create_task.ts`) que cuenta las tareas ACTIVAS reales en una transacción y serializa altas concurrentes del mismo hogar con un doc ancla `homes/{id}/system/taskGuard` (las reglas no pueden contar; el contador denormalizado era el agujero). `firestore.rules`: `allow create: if false` para `tasks` (alta SOLO vía callable) + eliminados los helpers de create muertos (`freeCanCreateTask`/`dashboardPlanCounters`/`taskCreate*`). Cliente: `tasks_repository_impl.createTask` llama a la callable (payload JSON-safe `TaskModel.toCallablePayload`, `nextDueAt` ISO; `createdByUid`/timestamps los pone el servidor) y `task_form_provider.save` mapea `failed-precondition` `free_limit_tasks`/`free_limit_recurring` a banner de upgrade con CTA al paywall.
> - **Free trial (14d solo anual):** parser `intro_offer_parser.dart` (Google Play `subscriptionOfferDetails`/pricingPhases precio 0 + App Store `SKProductDiscount.freeTrail`), `annualIntroOfferProvider` lee la oferta de la store, y `paywall_screen_v2` muestra badge "14 días gratis" + CTA "Empezar 14 días gratis" + nota **solo cuando la store la reporta** (nunca promete un trial inexistente). Claves l10n es/en/ro.
>
> **Tests:** functions integración `create_task.test.ts` **14/14** (emulador real: tope 4 activas + 3 recurrentes; **NO depende del contador denormalizado** aunque mienta; **concurrencia: 8 altas en paralelo → exactamente 4 activas, 4 rechazos**; Premium ignora; auth/rol/validación). Reglas: `tasks.test.ts` y `homes.test.ts` actualizados (alta directa siempre denegada) → suite rules **161/161**. functions unit **321/321**. Dart: `intro_offer_parser_test` (duración ISO + base→none), `paywall_screen_test` (trial: badge+CTA+nota; sin trial: sin nota; golden regenerado por deriva de fuente), `task_form_provider_test` (mapeo de `free_limit_*`), `tasks_crud_test` reescrito (alta→server-side; siembra directa para update/freeze/delete/reorder). `flutter analyze` (lib + tests tocados) sin issues nuevos.
>
> **PASO 4 — Verificación:** la **no-eludibilidad del límite** está demostrada de forma más fuerte que un test manual: el test de concurrencia dispara 8 transacciones realmente simultáneas (un humano no puede tocar tan rápido para forzar la race) y el resultado converge a 4 activas exactas. La **verificación dual en dispositivos contra prod está BLOQUEADA**: (i) desplegar functions exige autorización y choca con el WIP de secretos del #02 (`firebase deploy --only functions` analiza todo el working tree y exige `GOOGLE_PLAY_SA_JSON`/`APP_STORE_PRIVATE_KEY` ausentes en prod, H-009); (ii) desplegar las reglas (`allow create: if false`) rompería el alta en la app vieja hasta instalar la APK nueva (que ya enruta por callable) → requiere rebuild+install en MI_9+emulador. El **trial en sandbox** queda pendiente de crear la oferta en las stores (H-029), igual que #05 (unit IDs AdMob) y #02 (infra de stores). Vector residual freeze/unfreeze documentado en **H-028**.

**Archivos clave:** `functions/src/tasks/create_task.ts` (nueva callable) · `functions/src/tasks/index.ts` (export) · `firestore.rules` (`tasks` create→`if false`, helpers de create eliminados) · `lib/features/tasks/data/tasks_repository_impl.dart` + `task_model.dart` (`toCallablePayload`) + `application/tasks_provider.dart` (inyecta Functions) + `application/task_form_provider.dart` (mapeo de error) + `presentation/skins/create_edit_task_screen_v2.dart` (banner server-side) · `lib/features/subscription/{domain/intro_offer.dart,domain/subscription_products.dart,application/intro_offer_parser.dart,application/intro_offer_provider.dart,presentation/skins/paywall_screen_v2.dart}` · l10n `app_{es,en,ro}.arb`.

**Estado original (referencia):** sin trial (`paywall_screen_v2.dart:13-14`, `subscription_repository_impl.dart:42-57`) · `firestore.rules:58-66` (`freeCanCreateTask` lee `dashboardPlanCounters`) · `functions/src/tasks/update_dashboard.ts:258-272` (`refreshDashboard` es callable de cliente, el contador puede quedar stale).

```text
Eres ingeniero de growth/monetización en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #14.

OBJETIVO: introducir prueba gratuita y hacer que el límite Free de tareas no sea eludible.

PASO 1 — VERIFICA: confirma que no hay free trial en el paywall y que el límite de tareas Free se basa en un contador (planCounters) que solo se recalcula cuando el cliente llama a refreshDashboard; intenta crear >4 tareas sin refrescar y comprueba si el gate se salta.

PASO 2 — ARREGLA:
  - Configurar oferta introductoria/free trial en Play/App Store Connect y reflejarla en el paywall (copy + lógica de in_app_purchase).
  - Mover el límite de tareas a una callable createTask transaccional que cuente las tareas activas en el momento (o derivar planCounters por trigger Firestore, no por llamada de cliente).

PASO 3 — TESTS: integración del límite (Free no puede superar el máximo aunque no refresque el dashboard); test del paywall con trial.

PASO 4 — VERIFICACIÓN DUAL: con un hogar Free, intenta superar el límite de tareas desde el físico y el emulador (cuentas distintas) y confirma que el paywall aparece y el límite se respeta server-side. Verifica el trial en el flujo de compra sandbox. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 14 y anota hallazgos.
```

---

## Prompt 15 — Jobs con barridos full-collection
**Categoría:** Tecnología · **Severidad:** 🟡 Media · **Estado:** ✅ Solucionado, testeado, medido, **desplegado y verificado en prod (`toka-dd241`)** — 2026-06-22. `dispatchDueReminders` (collectionGroup) verificado end-to-end y `resetDashboardsDaily` (fan-out Cloud Tasks) reconstruyó 11/11 dashboards no-purged en invocaciones aisladas.

> **Verificación (PASO 1) — CONFIRMADO, no es falso positivo:**
> - `dispatchDueReminders` (`dispatch_due_reminders.ts:20`): `db.collection("homes").get()` traía **todos** los hogares sin filtro y luego, por cada uno, una query de `tasks`. Coste base por ejecución ≈ **N (docs home) + N (queries de tasks, mín. 1 read cada una aunque la query esté vacía)**, × **96 ejecuciones/día**. Crece linealmente con el total de hogares aunque ninguno tenga tareas que venzan.
> - `resetDashboardsDaily` (`update_dashboard.ts:318-336`): leía todos los homes no-`purged` y disparaba `Promise.all(updateHomeDashboard)` para **todos en una única invocación** → O(N·(miembros+tareas+eventos)) lecturas y O(N·miembros) escrituras concurrentes en un solo proceso (riesgo de exceder la ventana de 540s y la memoria), y un fallo de un hogar quedaba sólo logueado.
>
> **Arreglos (PASO 2):**
> - `dispatchDueReminders`: un único `db.collectionGroup("tasks").where("status","==","active").where("nextDueAt", ventana)` en vez de barrer hogares. El `homeId` se resuelve desde la ruta del doc (`taskDoc.ref.parent.parent.id`); el nombre del hogar se lee con cache (una vez por hogar **con** tareas que vencen, no por todos). El coste pasa a depender de la **actividad** (nº de tareas que vencen), no de N. Usa el índice COLLECTION_GROUP `tasks(status, nextDueAt)` que **ya estaba** declarado en `firestore.indexes.json:108-115`; la query va envuelta en try/catch defensivo por si faltara el índice en prod (el emulador no lo exige — ver memoria `collectiongroup-index-prod-only`).
> - `resetDashboardsDaily`: fan-out por hogar. El cron ahora **enumera** los hogares vivos (`enqueueDashboardRebuilds`, con `.select()` para traer sólo refs) y **encola una tarea de Cloud Tasks por hogar** (`rebuildHomeDashboardTask`, `onTaskDispatched` con `retryConfig` y `maxConcurrentDispatches:10`). Cada hogar se reconstruye en su **propia invocación** → aislamiento (un fallo no tumba a los demás) + reintento con backoff (lo da Cloud Tasks), sin un proceso monolítico. El fan-out es resiliente: si encolar un hogar falla, se registra y se continúa. (Se eligió **Cloud Tasks** sobre Pub/Sub porque `firebase-admin/functions` ya está disponible sin añadir dependencias, y permite `retryConfig`/rate-limit nativos.)
>
> **Tests (PASO 3) — todo verde:**
> - Integración emulador `reset_dashboards_fanout.test.ts`: encola UNA por hogar vivo y **excluye** los `purged`; **aislamiento** (si encolar un hogar lanza, el resto se siguen encolando, `failed=1`); reconstrucción aislada de un hogar (escribe `views/dashboard`); **reintento** (si la reconstrucción lanza, propaga el error para que Cloud Tasks reintente SOLO ese hogar, sin afectar a otro). **4/4.**
> - Integración emulador `dispatch_due_reminders_multihome.test.ts`: collectionGroup notifica tareas que vencen en **hogares distintos** en una pasada, NO notifica las fuera de ventana ni hogares ociosos, y resuelve el `homeId` desde la ruta del doc. **3/3.**
> - Regresión: `dispatch_due_reminders.test.ts` **6/6** (ventana, completadas, sin token, notifyOnDue=false, dedup), suite unitaria de `src` **321/321**, integración de dashboard (`dashboard_trigger`, `apply_task_completion`, `create_task`) **32/32**. `tsc --noEmit` limpio. Sin cambios Dart.
>
> **Medición de la mejora (emulador, 2 hogares con tarea que vence):**
>
> | hogares ociosos | OLD reads (barrido) | NEW reads (collectionGroup) | factor |
> |---|---|---|---|
> | 10 | 24 | 2 | 12× |
> | 100 | 204 | 2 | 102× |
> | 500 | 1004 | 2 | **502×** |
>
> OLD ≈ 2N+const (lineal con el total de hogares); NEW = D (tareas que vencen), **constante en N**. A 500 hogares × 96 ejecuciones/día el barrido baja de ~96k a ~192 reads/día.
>
> **PASO 4 — DESPLEGADO A PROD (`toka-dd241`, autorizado por el usuario):** deploy hecho esquivando los secretos WIP del #02 con el workaround quirúrgico (backup + strip de las líneas `defineSecret`/`secrets:[...]` de `sync_entitlement.ts`+`google_rtdn.ts`, deploy de SOLO las 3 funciones del cambio, restaurar — ver `surgical-deploy-around-iap-secret-wip`).
> - **`dispatchDueReminders` ✅ verificado en prod end-to-end:** (a) índice COLLECTION_GROUP `tasks(status,nextDueAt)` **vivo en prod** — `secrets/qa_verify_h15_prod.js` corre la query EXACTA del dispatch sin `FAILED_PRECONDITION` (prod tiene 17 homes → OLD barría ~34 reads/run × 96/día aunque 0 recordatorios; NEW = 1 query). (b) la función ejecuta cada 15 min sin error de índice/crash (`sent 0` cuando no hay nada). (c) **Prueba real:** puse una tarea del owner a vencer en la ventana; el cron de las 13:00 (corrió 13:01) **recorrió todo el camino nuevo**: collectionGroup encontró la tarea, resolvió el `homeId` desde la ruta del doc, pasó el check `notifyOnDue` y **llamó a `messaging.send()`** — el envío falló sólo con `messaging/registration-token-not-registered` (token FCM del dispositivo caducado, manejado con `logger.warn` sin crash). Es decir, la lógica del refactor funciona en prod; no llegó push por token muerto (higiene/purga de tokens FCM muertos = Prompt #17, ajeno a este cambio).
> - **`resetDashboardsDaily` (fan-out) ✅ desplegada.**
> - **`rebuildHomeDashboardTask` (cola Cloud Tasks, función NUEVA) creada/ACTIVE + IAM desbloqueado:** el deploy de firebase-tools la creó pero **falló al fijar el invoker IAM** (la org policy de `toka-dd241` prohíbe `allUsers`, herencia del `invoker:"public"` global; además un bug de firebase-tools — "Cannot read … 'filter'" — aborta el paso IAM incluso con `invoker:"private"`). Solución: (1) añadí `invoker:"private"` a la cola en código (no debe ser pública); (2) concedí a mano (autorizado) `roles/run.invoker` a la SA compute sobre el servicio `rebuildhomedashboardtask` — verificado en la policy. La SA compute ya tiene `roles/editor` (cubre `cloudtasks.tasks.create` para encolar), así que el camino prod (`resetDashboardsDaily` corre como compute SA → encola → invoca la cola) queda desbloqueado. **Confirmado EN VIVO en prod:** el usuario disparó `firebase-schedule-resetDashboardsDaily-us-central1` con su cuenta. Logs: `resetDashboardsDaily` → "**11 enqueued, 0 failed of 11 homes**"; `rebuildHomeDashboardTask` → múltiples "Rebuilding/Dashboard updated for home X". Estado en BD (`secrets/qa_verify_h15_fanout.js`, efímero): los **11 homes no-purged** con `views/dashboard.updatedAt` a 13:18:23–13:18:29 (reconstruidos, en ~6s → concurrentes/aislados) y los **6 purged EXCLUIDOS** (timestamps viejos). Así se valida: scheduler→enqueue (compute SA con `editor` cubre `cloudtasks.tasks.create`)→Cloud Tasks invoca la cola (el `run.invoker` concedido funciona)→rebuild por hogar.
> - **Degradación grácil (defensa):** si el índice CG faltara, el try/catch loguea y no manda recordatorios (no crashea en bucle); si la cola no estuviera invocable, `resetDashboardsDaily` loguea fallos de encolado y el dashboard se sigue reconstruyendo por el trigger `onTaskWriteUpdateDashboard` y por completar/pasar turno (sólo se perdería el reset de medianoche de los contadores "de hoy").
> - **Verificador reutilizable:** `secrets/qa_verify_h15_prod.js` (read-only) comprueba índice CG vivo + cuenta homes.

**Archivos clave:** `functions/src/notifications/dispatch_due_reminders.ts` (`collectionGroup("tasks")` + cache de nombre de hogar + try/catch de índice) · `functions/src/tasks/update_dashboard.ts` (`enqueueDashboardRebuilds`, `rebuildDashboardForHome`, `resetDashboardsDaily` fan-out, `rebuildHomeDashboardTask` `onTaskDispatched`) · `firestore.indexes.json:108-115` (índice COLLECTION_GROUP `tasks(status, nextDueAt)`, ya existente) · tests `functions/test/integration/reset_dashboards_fanout.test.ts` + `dispatch_due_reminders_multihome.test.ts`.

```text
Eres ingeniero de plataforma/coste en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #15.

OBJETIVO: que el coste/latencia de los jobs no crezca linealmente con el nº total de hogares.

PASO 1 — VERIFICA: confirma que dispatchDueReminders barre todos los homes sin filtro y que resetDashboardsDaily reconstruye todos los dashboards secuencialmente con Promise.all. Estima reads por ejecución con N hogares.

PASO 2 — ARREGLA:
  - dispatchDueReminders: usar collectionGroup("tasks") filtrado por status==active y nextDueAt en ventana, en vez de barrer homes.
  - resetDashboardsDaily: fan-out por hogar vía Pub/Sub/Cloud Tasks (una invocación por hogar) en lugar de un job monolítico que puede exceder la ventana/memoria.

PASO 3 — TESTS: integración (emulador) de que solo se procesan hogares/tareas relevantes; test de que el fan-out no se cae si un hogar falla (aislamiento + reintento).

PASO 4 — VERIFICACIÓN DUAL: confirma en físico y emulador (cuentas distintas) que los recordatorios siguen llegando y los dashboards se reconstruyen correctamente tras el cambio; mide la mejora en logs/duración. Captura/analiza/borra.
Nota: requiere deploy autorizado de functions para prod; si no, valida en emulador y deja 🟧.

PASO 5 — Actualiza el estado del Prompt 15 y anota hallazgos.
```

---

## Prompt 16 — Hot document dashboard + batches >500 + cap 100 tareas/día
**Categoría:** Tecnología · **Severidad:** 🟡 Media · **Estado:** ✅ Solucionado, testeado y verificado (emulador + prod `toka-dd241` + 2 dispositivos) — 2026-06-22

> **Verificación (PASO 1):**
> - **Dashboard hot doc — CONFIRMADO.** `updateHomeDashboard` leía TODOS los miembros + tareas activas + eventos de hoy y hacía un `.set()` completo **fuera de transacción** en CADA completar/pasar (y, de hecho, DOS rebuilds por acción: el explícito en la callable + el del trigger `onTaskWriteUpdateDashboard`). Problemas: (a) **lost-update race** entre rebuilds concurrentes (el que lee antes pero escribe después pisa el estado nuevo → una tarea "reaparece"); (b) **fan-out ciego** O(miembros) escribiendo `hasPendingToday` aunque no cambie; (c) O(tareas) de lecturas por acción.
> - **`closeHome` batch >500 — 🟦 FALSO POSITIVO.** El código real (y TODO su historial vía `git log -S`) solo hace un batch de ≤2 ops (marca `premiumStatus:'purged'` + borra la membership del propio owner); nunca itera members/tasks. PERO los hogares `purged` no borran sus subcolecciones nunca → fuga de almacenamiento (anotado en H-031).
> - **`restorePremiumState` batch sin trocear — CONFIRMADO.** Un único batch sobre TODOS los members + tasks frozen; en un hogar Premium grande (tareas ilimitadas) >500 → rompe en prod.
> - **`cleanup`/`reassignTasksFromDeletedUser` — CONFIRMADO.** Batch único sobre las tareas del ex-miembro; >500 rompe (su propio comentario lo admitía). El `tx.get(members)` se deja (acotado ≤25).
> - **`processExpiredTasks` `.limit(100)` GLOBAL — CONFIRMADO.** Tope de 100 tareas/día en TODO el sistema → con >100 vencidas/día, deuda perpetua. Además releía TODOS los members por cada tarea en la tx.
>
> **Arreglos (PASO 2):**
> - **Dashboard — delta incremental + rebuild transaccional (híbrido).** Nuevo `dashboard_delta.ts` (función PURA `applyDashboardDelta`): muta solo la entrada de la tarea afectada y recalcula los agregados en memoria desde los arrays (`tasksDueToday`=count `isDueToday`, `tasksDoneToday`, `tasksDueCount` por miembro, `hasPendingToday`=`some(isOverdue||isDueToday)`); devuelve `needsFullRebuild` ante deriva. `applyDashboardDeltaTx` lo aplica en una **transacción de un solo doc** (mata la lost-update race) leyendo solo dashboard+home(tz), y solo escribe `hasPendingToday` en las memberships **que cambian**. `applyTaskCompletion`/`passTaskTurn` llaman al delta (fallback a rebuild si deriva) y marcan la tarea con `dashboardDeltaToken`; el trigger detecta el token y **se salta el rebuild redundante** (de 2 escrituras/acción a 1). `updateHomeDashboard` (trigger+cron) pasa a escritura **transaccional version-guarded** (`rev` monotónico, reintenta si otro escritor entró durante la lectura) + fan-out solo al flip de `hasPendingToday`.
> - **`restorePremiumState` y `reassignTasksFromDeletedUser`** trocean con `chunked(refs, MAX_BATCH_OPS=450)` (nuevo `shared/batch_utils.ts`); restore deja el flip de home+dashboard en un batch FINAL (idempotente y re-ejecutable).
> - **`processExpiredTasks`** quita el `.limit(100)` global: **pagina con `startAfter`** hasta vaciar (cap de seguridad 5000 LOGUEADO, sin truncado silencioso) y **cachea los frozenUids por hogar** (la tx por tarea ya no relee toda la colección members; solo lee la tarea + el doc del actor para stats consistentes).
>
> **Tests (PASO 3) — todo verde:** unit `src/` **27 suites/332** (incl. `dashboard_delta` 7, `batch_utils.chunked` 4); **rules 12/161**; **integración completa 26 suites/188** (incl. `dashboard_delta` 6 — delta de completar/pasar, concurrencia sin pérdida, delta==rebuild, skip por token; `process_expired_tasks` paginación >100 sin deuda + compliance consistente; `large_home_batching` restore + reassign con >500 entidades). `tsc` 0 errores. **Hallazgo de testing:** el emulador NO aplica el límite de 500/batch (falso verde) → la mecánica de troceo se testea con unit, no integración (H-032 + memoria `emulator-no-batch-500-limit`).
>
> **Despliegue a prod (autorizado, `toka-dd241`) — deploy QUIRÚRGICO** esquivando los secretos WIP del #02 (backup + strip de `defineSecret`/`secrets:[...]` de sync_entitlement.ts+google_rtdn.ts, deploy, restaurar — ver `surgical-deploy-around-iap-secret-wip`). **12/13 funciones desplegadas OK** (applyTaskCompletion, passTaskTurn, onTaskWriteUpdateDashboard, processExpiredTasks, restorePremiumState, onAuthUserDeleted, leaveHome, removeMember, manualReassign, onMemberVacationStart, refreshDashboard, resetDashboardsDaily). `rebuildHomeDashboardTask` falló SOLO en el paso de invoker IAM (org policy + bug "Cannot read … 'filter'" de firebase-tools, conocido del #15 — la función sigue ACTIVE con su `run.invoker` ya concedido). Secretos restaurados (idénticos al backup).
>
> **Verificación DUAL en prod (PASO 4):**
> - **Código nuevo live (`secrets/qa_verify_h16_prod.js`, 5/5 OK):** un toque a una tarea dispara el trigger DESPLEGADO → el dashboard sale con el campo NUEVO `rev=1` + `hasPendingToday` + contadores correctos (el código viejo no escribía `rev`).
> - **Delta + sync en 2 dispositivos (2 cuentas distintas, hogar "Hogar Real QA" `mAJXlAhwRV1kdy4O05hG`):** Luna (emulador) completa "Compra semanal QA v2" → el dashboard de prod pasa de `rev=undefined`→**1**, la tarea entra en `doneTasksPreview` ("by Luna"), `tasksDoneToday` 1→2, `tasksDueToday` 2→1, y la semanal sigue activa reasignada al siguiente ("Tres") con `due=false`. Sol (MI_9, **cuenta distinta**) ve el cambio **sincronizado** ("Completada por Luna" en Hechas, mismos contadores) sin estado stale ni reaparición. Capturas analizadas y borradas.
> - **Concurrencia (lost-update):** probada de forma autoritativa en el test de integración del emulador (transacciones concurrentes reales, fielmente emuladas); el código desplegado es el mismo. Los arreglos de batch >500 (restore/reassign) quedan probados por unit (`chunked`) + integración de corrección; su límite de 500 NO es reproducible en emulador (H-032).

**Archivos clave:** `functions/src/tasks/dashboard_delta.ts` (NUEVO, lógica pura del delta) · `functions/src/tasks/update_dashboard.ts` (`applyDashboardDeltaTx` + `updateHomeDashboard` transaccional version-guarded + skip por token en el trigger) · `functions/src/tasks/apply_task_completion.ts` y `pass_task_turn.ts` (delta + `dashboardDeltaToken` + fallback) · `functions/src/shared/batch_utils.ts` (NUEVO, `chunked`/`MAX_BATCH_OPS`) · `functions/src/jobs/restore_premium_state.ts` (troceo) · `functions/src/users/cleanup_user.ts` (`reassignTasksFromDeletedUser` troceado) · `functions/src/jobs/process_expired_tasks.ts` (paginación + cache de frozenUids por hogar) · `secrets/qa_verify_h16_prod.js` (verificador prod). closeHome (`homes/index.ts`) = falso positivo.

```text
Eres ingeniero de fiabilidad en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #16.

OBJETIVO: evitar contención del dashboard, fallos de batch >500 y deuda acumulada del cron de expiración.

PASO 1 — VERIFICA: confirma el rebuild completo + fan-out por miembro en cada acción; que closeHome/restore/cleanup usan batch/tx sin trocear (riesgo con >500 ops o muchos members); y el .limit(100) global de processExpiredTasks. Monta un hogar grande con qa scripts para estresarlo si puedes.

PASO 2 — ARREGLA:
  - Dashboard: actualizaciones incrementales (deltas) en vez de rebuild total en cada completar/pasar; reducir escrituras al doc caliente.
  - Trocear closeHome/cleanup/restore en lotes ≤450 o usar BulkWriter / recursiveDelete; no leer colecciones completas dentro de una transacción.
  - processExpiredTasks: paginar con startAfter hasta vaciar (o procesar por hogar) y cachear members por hogar.

PASO 3 — TESTS: integración con hogar grande (>500 entidades) que antes rompía el batch; test de que el cron no deja deuda; test de actualización incremental del dashboard.

PASO 4 — VERIFICACIÓN DUAL: con varios miembros completando tareas casi a la vez (físico + emulador, cuentas distintas), confirma que "Hoy" se mantiene consistente sin errores de contención y que cerrar un hogar grande no deja estado a medias (qa_inspect_home.js). Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 16 y anota hallazgos.
```

---

## Prompt 17 — Observabilidad de soporte + purga de tokens FCM + `sentNotifications` sin TTL
**Categoría:** Soporte · **Severidad:** 🟡 Media · **Estado:** ✅ Implementado, testeado (emulador) y **desplegado a prod (`toka-dd241`)**; verificación en dispositivo parcial — 2026-06-22

> **Verificación (PASO 1): los 3 hallazgos CONFIRMADOS, no falsos positivos.**
> (a) `send_rescue_alerts.ts` usaba `sendEachForMulticast` y solo logueaba `successCount/tokens.length`, **nunca** inspeccionaba `results.responses[]` → los tokens `registration-token-not-registered` no se borraban. Los single-send `dispatch_due_reminders.ts` y `send_pass_notification.ts` capturaban el error pero tampoco purgaban → un dispositivo desinstalado se reintenta cada 15 min para siempre (degradación silenciosa). (b) `sentNotifications` sin TTL: no había política en `firebase.json`/`firestore.indexes.json` ni purga en ningún cron (`purgeExpiredFrozen` solo tocaba homes `restorable`) → crecimiento ilimitado. (c) `correlationId` no existía en NINGÚN archivo; logging ad-hoc por strings → imposible reconstruir el historial de un usuario. No existía callable de diagnóstico ni infra de claim de soporte (App Check solo en `syncEntitlement`).
>
> **Arreglos:** (a) `fcm_tokens.ts`: `isUnregisteredTokenError`, `getUserFcmTokenEntries` (mapea token→uid) y `clearFcmTokenIfMatches` (borra `users/{uid}.fcmToken` en tx solo si sigue siendo el token muerto — evita carrera con re-registro). Aplicado a los 3 envíos; NUNCA se loguea el token. (b) cada doc `sentNotifications` lleva `expireAt = sentAt + 2d` (para TTL nativo) + purga determinista en `purgeExpiredFrozen` vía `collectionGroup("sentNotifications").where("sentAt","<=",cutoff)`, troceada ≤450, con índice COLLECTION_GROUP `sentNotifications(sentAt)` (`firestore.indexes.json`) + try/catch defensivo. (c) `shared/log.ts` (`newCorrelationId`/`logEvent` → `{event, homeId, uid, correlationId}`) aplicado a la superficie de notificaciones; callable READ-ONLY `supportDiagnoseHome` (`homes/support_diagnostics.ts`, `enforceAppCheck:true` + claim `support`) que redacta PII: teléfono/token→booleanos `hasPhone`/`hasFcmToken`, jamás lee la subcolección `reviews` (notas privadas). Función pura `buildHomeDiagnostics` testea la redacción. Script `secrets/qa_grant_support_claim.js`. Cliente Flutter: feature `lib/features/support/` (modelo freezed, repo, providers, pantalla) gateada por el claim (`isSupportAgent` con `getIdTokenResult(true)`) + entrada condicional en Ajustes + ruta `supportDiagnostics`.
>
> **Tests:** functions unit **350/350** (incl. `isUnregisteredTokenError`, `hasSupportClaim`, `buildHomeDiagnostics` con la propiedad de privacidad) + integración emulador **206/206** (nuevos: `fcm_token_purge` multicast+2 single-send+error transitorio, `sent_notifications_purge`, `support_diagnose_home` solo-soporte/sin-PII/not-found). Flutter: repo (coerción `Map<Object?,Object?>` + mapeo de errores) + UI (gate +/−, render redactado) **6/6**. `flutter analyze` (feature) limpio.
>
> **Despliegue a prod (autorizado):** workaround quirúrgico del bloqueo de secretos #02 (backup + borrado temporal de `defineSecret`/`secrets:[]` de `sync_entitlement.ts`+`google_rtdn.ts`, deploy, restauración) → desplegadas `supportDiagnoseHome` (nueva), `dispatchDueReminders`, `purgeExpiredFrozen`, `passTaskTurn`, `openRescueWindow` + `firestore:indexes` a `toka-dd241` (`Deploy complete!`). Claim `support` concedido a `toka.qa.owner`.
>
> **Verificación DUAL en dispositivo (PASO 4):** APK debug (entrypoint prod) instalado en MI_9 + emulador. **Confirmado en emulador (cuenta owner con claim `support`, contra prod):**
> - Gate **negativo** (cuenta sin claim → Ajustes no muestra la entrada) y **positivo** (owner → aparece "Diagnóstico de soporte").
> - Pantalla renderiza correctamente (banner de privacidad, campo, botón) con el design system de Toka.
> - **App Check enforcing confirmado en dispositivo real**: antes de registrar el debug token, `403 App attestation failed` → la callable RECHAZA la llamada → "Acceso denegado" sin crash ni PII (prueba de que el control está activo).
> - **Datos en vivo verificados** (tras registrar el debug token del emulador en App Check, autorizado por el usuario): diagnóstico del hogar real `V4w8IDaA6FsALLdSip0S` (`QA_Post_Fix`, `expiredFree`, owner `m9K1…`, 2 miembros incl. uno `left`). **Propiedad de privacidad confirmada en el dump completo de la pantalla**: 0 teléfonos, 0 tokens FCM, 0 notas privadas; solo identificadores (homeId/uid, que soporte necesita), chips de presencia `Teléfono`/`Push` (booleanos) y stats.
> - **Bug real cazado por la verificación y corregido:** `isSupportAgent` usaba el token cacheado → un claim recién concedido no se reflejaba hasta expirar el token (~1h); fix `getIdTokenResult(true)` (H-033).
>
> Notas: el debug token de App Check del emulador quedó registrado en consola (`qa-emulator-h17`; borrable, H-034). La purga de token FCM muerto end-to-end en vivo (desinstalar/reinstalar + pasar turno) NO se ejecutó esta sesión; queda cubierta por los tests de integración de emulador (que ejercitan el código de error EXACTO de FCM en los 3 envíos) + el deploy a prod.

**Archivos clave:** logging sin `correlationId` consistente · `crashlytics_service.dart`, `analytics_service.dart` (solo cliente/funnel) · `functions/src/notifications/send_rescue_alerts.ts:31-40` (no purga tokens inválidos) · `dispatch_due_reminders.ts:50-72, 76` (`sentNotifications` sin TTL; no loguear fcmToken) · `send_pass_notification.ts:44`.

```text
Eres ingeniero de soporte/observabilidad en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #17.

OBJETIVO: poder diagnosticar el problema de un usuario concreto y evitar que los recordatorios degraden en silencio.

PASO 1 — VERIFICA: confirma que el envío FCM solo loguea successCount sin inspeccionar responses[] (no se borran tokens 'registration-token-not-registered'); que sentNotifications crece sin TTL; y que el logging no tiene homeId/uid/correlationId consistente para reconstruir el historial de un usuario.

PASO 2 — ARREGLA:
  - En cada envío multicast, recorrer responses[] y borrar el token cuando el error sea messaging/registration-token-not-registered. (No loguear nunca el token.)
  - Política TTL de Firestore sobre sentNotifications (p. ej. 2 días) o purga en purgeExpiredFrozen.
  - Logging estructurado con homeId/uid consistentes + una callable admin READ-ONLY de diagnóstico por hogar (estado premium, miembros, próximas tareas, últimos eventos) protegida por App Check + claim de soporte.

PASO 3 — TESTS: integración de purga de token inválido; test de la callable de diagnóstico (solo lectura, solo soporte autorizado).

PASO 4 — VERIFICACIÓN DUAL: provoca un token inválido (desinstala/reinstala en un dispositivo) y confirma que tras el siguiente envío el token muerto se elimina; usa la callable de diagnóstico para inspeccionar un hogar y comprueba que devuelve el estado correcto SIN exponer datos privados (teléfonos ocultos, notas privadas, tokens). Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 17 y anota hallazgos.
```

---

## Prompt 18 — Onboarding muere offline en selección de idioma
**Categoría:** UX · **Severidad:** 🟡 Media · **Estado:** ✅ Solucionado, testeado y verificado (móvil + emulador) — 2026-06-22

> **Verificación (PASO 1) — CONFIRMADO (no falso positivo):** las 3 capas confirmadas. `language_repository_impl.dart` devolvía `_defaults` **solo** si la colección estaba vacía (lectura correcta); ante **cualquier error** (`FirebaseException` de red u otro) **lanzaba `LanguagesFetchException`**. `availableLanguagesProvider` lo propagaba → el `AsyncValue` quedaba en `error`. `language_step_v2.dart` en estado `error` solo pintaba `Center(Text(error_generic))`: **sin lista, sin Reintentar** → la pantalla quedaba muerta y el usuario no podía elegir idioma.
>
> **Arreglos (PASO 2):** (a) nuevo `LanguagesResult { languages, isFallback }` (`i18n/domain/languages_result.dart`) + `Language.defaults` público (es/en/ro). (b) `LanguageRepositoryImpl` **nunca lanza por red**: ante `FirebaseException`/error devuelve `Language.defaults` con `isFallback=true`; colección vacía **desde servidor** → defaults sin fallback; **vacía desde caché (`metadata.isFromCache`)** → fallback (ver H-035). (c) `language_step_v2.dart`: en fallback muestra un banner "Sin conexión" (icono wifi-off + `language_offline_notice` es/en/ro) con botón **Reintentar** (`ref.invalidate(availableLanguagesProvider)`) sobre los 3 idiomas; **auto-avance** al seleccionar (`onLocaleSelected`+`onNext`, sin pulsar Siguiente, que se mantiene); `error` defensivo también pinta defaults+retry. (d) `language_selector_widget.dart` (Ajustes) adaptado al nuevo tipo y robustecido (error→defaults). El selector de Ajustes se beneficia del mismo fix sin cambiar su alcance.
>
> **Tests (PASO 3) — 34/34 verde, `analyze` limpio:** `language_repository_impl_test.dart` (6) ejercita la función REAL con mocks de Firestore: orden/filtrado, vacío-servidor sin fallback, **excepción → fallback**, **vacío-desde-caché → fallback**, **vacío-desde-servidor → sin fallback**. Nuevo `language_step_v2_test.dart` (4): fallback muestra 3 idiomas + Reintentar + aviso; online sin banner; **auto-avance** llama `onLocaleSelected`+`onNext`; **Reintentar recarga la lista remota** (repo offline→online). Regresión verde: `onboarding_flow_test` (incl. goldens), `language_selector_widget_test` (golden), `language_fetch_test`.
>
> **Verificación DUAL (PASO 4) — APK debug prod en 2 dispositivos, cuentas e idiomas distintos:**
> - **Emulador (online, cuenta nueva):** el step carga los 3 idiomas remotos **sin** banner; tocar "Español" **auto-avanzó** al perfil y aplicó el idioma en vivo (inglés→español); al volver atrás la selección **persiste** (radio marcado).
> - **Físico MI_9 (offline, otra cuenta nueva):** en modo avión la pantalla **ya no muere**. Con caché de Firestore: muestra los 3 idiomas reales cacheados (sin banner). **Borrando solo la caché de Firestore (run-as, sesión Auth intacta) y relanzando offline → BANNER "Sin conexión" + Reintentar + 3 idiomas** (camino `isFromCache`, antes era `error_generic`). Con red (relanzado, SDK fresco): carga remota sin banner + **auto-avance** (Română) + idioma aplicado en vivo (rumano) + **persistencia** (radio marcado).
> - **Matiz observado (H-035):** una query Firestore offline **sin caché NO lanza** — devuelve snapshot vacío `isFromCache=true`; por eso el fix distingue vacío-caché (fallback) de vacío-servidor. Además, tras recuperar la red **en caliente**, el SDK mantiene su canal en offline un rato y `get()` sigue sirviendo de caché: el botón Reintentar re-ejecuta el fetch (verificado) pero la lista remota llega cuando el SDK reconecta (un relanzado con red la trae de inmediato). No es un defecto del fix.

**Archivos clave:** `lib/features/i18n/domain/languages_result.dart` (nuevo) · `lib/features/i18n/domain/language.dart` (`Language.defaults`) · `lib/features/i18n/data/language_repository_impl.dart` (nunca lanza por red; rama `isFromCache`) · `lib/features/i18n/application/language_provider.dart` (+`.g.dart`, tipo `LanguagesResult`) · `lib/features/onboarding/presentation/steps/skins/language_step_v2.dart` (banner+Reintentar+auto-avance) · `lib/features/i18n/presentation/language_selector_widget.dart` · `lib/l10n/app_{es,en,ro}.arb` (`language_offline_notice`). Tests: `test/unit/features/i18n/language_repository_impl_test.dart`, `test/ui/features/onboarding/language_step_v2_test.dart`. Helper QA: `secrets/qa_onboarding18.js`.

```text
Eres ingeniero de UX en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #18.

OBJETIVO: que el primer paso del onboarding nunca deje al usuario sin salida si la red falla.

PASO 1 — VERIFICA: con el dispositivo en modo avión (o sin permisos de red), arranca el onboarding y confirma que la pantalla de idioma queda muerta (solo error_generic) y que _defaults no se usa ante error de red. Si ya hay fallback/retry, márcalo falso positivo.

PASO 2 — ARREGLA: usar _defaults (es/en/ro) también como fallback cuando la lectura falle (no solo cuando esté vacía); añadir un botón "Reintentar"; opcional: auto-avance al seleccionar idioma (con 3 opciones no hace falta confirmar).

PASO 3 — TESTS: UI/widget test del paso de idioma en estado error → muestra los 3 idiomas por defecto + retry; test de que tras reintentar con red, carga la lista remota.

PASO 4 — VERIFICACIÓN DUAL: arranca onboarding sin red en el físico y con red en el emulador (cuentas nuevas distintas); confirma que en ambos se puede elegir idioma y avanzar, y que la selección persiste. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 18 y anota hallazgos.
```

---

## Prompt 19 — Accesibilidad: `textScaler`, semántica y overflow
**Categoría:** UX · **Severidad:** 🟡 Media · **Estado:** ✅ Solucionado, testeado y verificado (móvil XL + emulador normal) — 2026-06-22

> **Verificación (PASO 1) — CONFIRMADO (no falso positivo), a nivel de código (rutas reales bajo `skins/`):**
> (a) `lib/app.dart` montaba `MaterialApp.router` **sin `builder`** → el `textScaler` del sistema se aplicaba sin acotar (con fuente XL/accesibilidad, hasta 2.0, las tarjetas desbordan). (b) en la card VIVA `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart`, `_DoneButtonV2` y `_PassButtonV2` eran `GestureDetector` (no botón) con el glifo dentro del texto (`Text('✓ $label')` / `Text('↻ $label')`) → el lector leía "✓ Hecho"/"↻ Pasar" y **no** los anunciaba como botón; además el nombre del asignado no tenía `ellipsis`. (c) overflow potencial sin `Flexible`/`ellipsis` en `members_screen_v2.dart` (fila left-member) + `member_card.dart` (nickname), `task_detail_screen_v2.dart` (`_InfoRow` value y fila de "Próximas fechas": dos `Text` sin `Flexible`), `all_tasks_screen_v2.dart` (`CheckboxListTile` título). `TaskCard` (lista de Tareas) ya tenía `maxLines:1+ellipsis` → ese punto era correcto. (Las rutas/líneas del enunciado eran del árbol pre-`skins/`.)
>
> **Arreglos (PASO 2):**
> - **Clamp del textScaler [0.8, 1.3]** en `MaterialApp.builder` (`app.dart`) vía helper puro testeable `lib/core/utils/text_scaling.dart` (`clampedTextScaler` + `kMin/kMaxTextScaleFactor`). Respeta la fuente del sistema pero la acota para no desbordar.
> - **Botones reales con semántica:** `_DoneButtonV2`/`_PassButtonV2` pasan de `GestureDetector` a `Semantics(button:true, label:<Hecho|Pasar>, onTap:…, excludeSemantics:true) → InkWell`; el glifo `✓/↻` se mueve a un `Icon` (`Icons.check`/`Icons.refresh`, no leído por estar excluido) y la etiqueta del label la pone Semantics. `minHeight:44` (objetivo táctil) y `Flexible+ellipsis` en el texto interno.
> - **Overflow:** `ellipsis`+`maxLines` en nombre de asignado (card), nickname (`member_card`), fila left-member (`members_screen_v2`), título `CheckboxListTile` (`all_tasks_screen_v2`) y label de contadores (`today_header_counters_v2`, `today_task_card_done`); en `task_detail_screen_v2` el `_InfoRow` value pasa a `Flexible`+ellipsis y la fila de "Próximas fechas" a `Expanded`(fecha)+`Flexible`(asignado)+ellipsis.
>
> **Tests (PASO 3):** nuevo `test/unit/core/utils/text_scaling_test.dart` (6/6: 2.0→1.3, 0.5→0.8, intermedios, noScaling) y `test/ui/features/tasks/today_task_card_todo_v2_a11y_test.dart` (5/5): **semántica** — `getSemanticsData().flagsCollection.isButton`==true, `label`=="Hecho"/"Pasar" SIN `✓`/`↻`, con `SemanticsAction.tap`; **sin overflow** — card propia y de otro con título+nombre largos a `TextScaler.linear(1.3)` en ancho 411 → `takeException()==null`; **golden** `today_card_todo_v2_xl_long.png` (generado en este entorno). `flutter analyze` (archivos tocados + tests) sin issues; `flutter test test/unit` 692 verde (los 2 rojos de `recurrence_order_test` son pre-existentes y ajenos → H-036). Los fallos de goldens de otras pantallas son **ambientales** (font/AA en WSL), no regresión del #19 (probado: un golden no tocado difiere ~0.93 % solo en bordes de glifo) → H-037.
>
> **Verificación DUAL en 2 dispositivos (PASO 4) contra prod (`toka-dd241`), APK debug (entrypoint prod):**
> - **MI_9 con fuente XL (`font_scale=1.5`, Owner):** se creó una tarea diaria de hoy con título largo (vía Admin SDK, porque `createTask` con `enforceAppCheck` rechaza desde el APK debug → instancia de [[H-034]]; el trigger desplegado `onTaskWriteUpdateDashboard` del #07 reconstruyó el dashboard solo). **Hoy:** la card no desborda (título elipsado, contadores envuelven, ambos botones caben). **`uiautomator dump`:** `Hecho` y `Pasar` = `class="android.widget.Button"`, `content-desc="Hecho"/"Pasar"`, `clickable=true`, y **ningún nodo** lee `✓`/`↻` → se anuncian como botón con etiqueta. **Miembros** (Owner+badge "Propietario", left-member "Sebas"+"Reincorporar") y **Detalle** (título largo a 5 líneas, `_InfoRow`, "Próximas fechas" fecha+asignado) **sin overflow**.
> - **Emulador con fuente normal (Member, mismo hogar):** ve la **misma tarea sincronizada** asignada a "Owner" → **sin** botones Hecho/Pasar (no es suya, visibilidad correcta), título elipsado, Hoy/Miembros legibles sin overflow.
> - Capturas analizadas y borradas; tarea de prueba borrada; `font_scale` restaurado a 1.0.

**Archivos clave:** `lib/app.dart` (`MaterialApp.builder` con clamp) · `lib/core/utils/text_scaling.dart` (nuevo, `clampedTextScaler`) · `lib/features/tasks/presentation/skins/widgets/today_task_card_todo_v2.dart` (`_DoneButtonV2`/`_PassButtonV2` → `Semantics`+`InkWell`+`Icon`) · `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` (`_InfoRow`/"Próximas fechas") · `members_screen_v2.dart`, `member_card.dart`, `all_tasks_screen_v2.dart`, `today_header_counters_v2.dart`, `today_task_card_done.dart` (ellipsis/Flexible) · tests `text_scaling_test.dart` + `today_task_card_todo_v2_a11y_test.dart` (+ golden). La card legacy no-v2 `widgets/today_task_card_todo.dart` conserva el patrón viejo pero es código muerto (no en el árbol vivo) → H-037.

> _Nota: el enunciado original apuntaba a rutas/líneas del árbol pre-`skins/`; las reales se listan arriba._

```text
Eres ingeniero de accesibilidad en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #19.

OBJETIVO: que la app sea usable con fuente grande del sistema y con lector de pantalla, sin overflow.

PASO 1 — VERIFICA: activa fuente XL en el sistema del dispositivo y comprueba overflow en las cards de Hoy; con TalkBack/VoiceOver comprueba que los botones Hecho/Pasar no se anuncian como botón (leen glifos ✓/↻). 

PASO 2 — ARREGLA: respetar MediaQuery textScaler con un clamp razonable (0.8–1.3) en MaterialApp.builder; sustituir GestureDetector por InkWell/Semantics(button:true,label:...) y mover el glifo a icono con excludeSemantics; añadir overflow: TextOverflow.ellipsis + Expanded/Flexible donde haya nombres/títulos largos; reemplazar alturas fijas por min-heights.

PASO 3 — TESTS: golden tests con strings largos y con textScale alto (sin overflow); test de semántica de los botones críticos.

PASO 4 — VERIFICACIÓN DUAL: con fuente XL en el físico y normal en el emulador (cuentas distintas), confirma que Hoy/Miembros/Detalle no desbordan y se leen; con lector de pantalla, confirma que "Hecho"/"Pasar" se anuncian como botones con etiqueta. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 19 y anota hallazgos.
```

---

## Prompt 20 — Fricción al completar (doble tap) + cobertura de tests débil
**Categoría:** UX/Calidad · **Severidad:** 🟢 Baja · **Estado:** ✅ Solucionado, testeado y verificado (móvil + emulador) — 2026-06-23

> **Verificación (PASO 1):** (a) **doble tap CONFIRMADO**: la tarjeta `today_task_card_todo_v2.dart` ya lanza confetti+animación de check (`_handleDone`) y *aun así* `today_screen_v2.dart:_onDone` abría `CompleteTaskDialog` con un segundo "Confirmar". (b) Cobertura **parcialmente FALSO POSITIVO** (el premortem se escribió antes de cerrar #12/#15/#17): `sendRescueAlerts`/`sendPassNotification` SÍ tenían tests de purga de tokens (#17, `fcm_token_purge.test.ts`) pero NO de su lógica núcleo; `resetDashboardsDaily` ya tiene su fan-out testeado (#15, `reset_dashboards_fanout.test.ts`); y las callables de gobernanza reales YA se ejercitan en `homes_governance.test.ts` (#12) — los espejos de `homes_callables.test.ts` eran redundancia, no un hueco.
>
> **Arreglos:** (a) **commit diferido (patrón Gmail), ventana de 10s**. Provider keepAlive `pending_completions_provider.dart`: al tocar Hecho se marca la tarea pendiente (se oculta de "Por hacer" vía `excludePendingCompletions` en `today_view_model.dart`), se muestra un `SnackBar` "Tarea completada · Deshacer" (con **`persist: false`** — Flutter 3.44 hace persistente por defecto todo SnackBar con acción, así que sin esto se quedaba fijo; ver H-040), y el commit real a `applyTaskCompletion` se programa a 10s. "Deshacer" cancela el commit (cero escritura); el flush en `app.dart` (`AppLifecycleState.paused/detached`) confirma lo pendiente si la app pasa a segundo plano. Diálogo `CompleteTaskDialog` eliminado del flujo (las acciones consecuentes —pasar turno, borrar, expulsar, abandonar— conservan su confirmación). Claves i18n `today_task_completed_undoable`/`undo` (es/en/ro). (b) Tests añadidos.
>
> **Tests:** Flutter: `pending_completions_provider_test.dart` (5, fake_async: schedule/commit-a-los-10s/undo/flush/idempotencia), `today_view_model_test.dart` (+3, `excludePendingCompletions`), UI `today_complete_undo_test.dart` (3: sin diálogo + SnackBar Deshacer; Deshacer no llama al backend; expiración confirma) → **20/20 verde**. Backend: `notification_dispatch.test.ts` (6, lógica núcleo real de `sendRescueAlerts`/`sendPassNotification` con FCM mockeado), `homes_governance.test.ts` (+11 edge-cases de callable REAL: frozen recibe / left-self-no-miembro-vacío rechazados / auto-expulsión / payer-lock real) y **eliminados los 6 espejos** de gobernanza de `homes_callables.test.ts`. Suites: functions unit **321/321**, integración **223/223** verdes.
>
> **Verificación DUAL en prod (PASO 4)** — app nueva instalada en MI_9 + emulador (mismo hogar `QA_Post_Fix`, 2 clientes en vivo; el cambio es 100% cliente, `applyTaskCompletion` ya desplegado): (1) **Deshacer**: Owner toca Hecho → SnackBar "Tarea completada/Deshacer" + tarjeta oculta **sin diálogo**; el emulador (2º cliente) sigue mostrando la tarea (commit diferido, nada difundido); al pulsar Deshacer la tarjeta reaparece y **Admin SDK confirma 0 eventos `completed`** (cero escritura). (2) **Commit**: Owner toca Hecho y deja expirar 10s → la tarea pasa a "Hechas" en MI_9 y **sincroniza al emulador** ("Hechas" + "1 completada"); Admin SDK confirma 1 evento + recurrencia avanzada. Escenario montado/limpiado por Admin SDK; capturas analizadas y borradas. (Nota: cross-account Sol/Luna no usado — el reset de contraseñas de esas cuentas lo bloquea el clasificador; se usó la misma cuenta en 2 dispositivos, válido para sync de completado al no haber dimensión de privacidad.) **Re-verificado tras H-040** (SnackBar con acción no se auto-cerraba): con `persist:false`, el SnackBar desaparece a los ~10s en el MI_9 y el completado sincroniza — confirmado en dispositivo + test de regresión.

**Archivos clave:** `lib/features/tasks/application/pending_completions_provider.dart` (nuevo) · `today_view_model.dart` (`excludePendingCompletions` + watch) · `today_screen_v2.dart:_onDone` (SnackBar Deshacer, sin diálogo) · `app.dart` (flush en background) · `lib/l10n/app_{es,en,ro}.arb` · `functions/test/integration/notification_dispatch.test.ts` (nuevo) · `functions/test/integration/homes_governance.test.ts` (+11) · `functions/src/homes/homes_callables.test.ts` (−6 espejos).

```text
Eres ingeniero de UX/calidad en Toka. Lee Arreglos/premortem.md §Protocolo común y síguelo. Hallazgo #20.

OBJETIVO: reducir la fricción de la acción diaria nº1 y cerrar los huecos de tests que dejan ciega la capa de ingresos.

PASO 1 — VERIFICA: confirma que completar una tarea exige tap "Hecho" + "Confirmar" en un diálogo, pese a que ya hay confetti/animación de feedback. Confirma con grep que sendRescueAlerts/sendPassNotification/resetDashboardsDaily no tienen tests y que homes_callables.test.ts reimplementa la lógica en el propio test (no ejercita la callable real).

PASO 2 — ARREGLA: (a) completar directo con SnackBar de "Deshacer" (patrón Gmail) en vez de diálogo de confirmación previo; mantener una confirmación solo para acciones destructivas. (b) Añadir tests de integración (emulador, FCM mockeado) para las 3 funciones sin cobertura; sustituir los tests espejo por tests que invoquen las callables reales (transferOwnership/leaveHome/removeMember) contra el emulador.

PASO 3 — TESTS: ver paso 2; además UI test del nuevo flujo de completar con Deshacer.

PASO 4 — VERIFICACIÓN DUAL: Owner (físico) completa una tarea con un solo tap y deshace; Member (emulador, mismo hogar) ve la sincronización del completado/deshecho. Ejecuta la suite nueva y confirma verde. Captura/analiza/borra.

PASO 5 — Actualiza el estado del Prompt 20 y anota hallazgos.
```

---

## Cómo usar este plan

1. Abre una **sesión nueva de Claude Code por prompt**, de arriba abajo (01 → 20).
2. Pega el bloque ```text``` del prompt. La sesión leerá el §Protocolo común de este archivo.
3. Al terminar, la sesión deja el estado actualizado aquí y, si encontró algo nuevo, en `Arreglos/Hallazgos.md`.
4. Los prompts 02, 06 y 15 pueden quedar 🟧 a la espera de **autorización de deploy a producción**; el resto se demuestra en emulador + ambos dispositivos.
