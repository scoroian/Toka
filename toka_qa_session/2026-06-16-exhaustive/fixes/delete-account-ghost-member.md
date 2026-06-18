# §3 — 🔴 Eliminar cuenta deja membresía fantasma

Estado: **RESUELTO** · Desplegado en prod (`toka-dd241`) y verificado end-to-end · Fecha: 2026-06-17

## Bug

Al eliminar la cuenta (Ajustes → Eliminar cuenta, tras reauth), la cuenta se
borraba de Firebase Auth (`currentUser.delete()` en
`lib/features/settings/presentation/settings_screen.dart:162`) **pero no había
ninguna limpieza de datos**: el documento `homes/{homeId}/members/{uid}` quedaba
con `status="active"` (miembro "fantasma" con cuenta inexistente),
`users/{uid}` seguía existiendo, las tareas asignadas quedaban con
`currentAssigneeUid` huérfano y los contadores del dashboard quedaban inflados.

## Causa raíz (bug real, confirmado en producción)

No existía ningún trigger ni callable que limpiara la huella del usuario al
borrar la cuenta. El cliente solo llamaba a `FirebaseAuth.currentUser.delete()`.

Reproducido en prod con `secrets/qa_inspect_home.js SMQRtCjrA09gPIr1wazD ZynuqUTlbtb1R1qBv74Wi7iEmuN2`:

```
=== MIEMBROS ===
  ZynuqUTlbtb1R1qBv74Wi7iEmuN2 role=admin status=active accountDeleted=- | Auth=NO (cuenta borrada)
  wwL0OTdrNeMZs2wTt6QtRDT1nb53 role=owner  status=active                  | Auth=SÍ
=== DASHBOARD counters ===
  totalMembers=2 | planCounters.activeMembers=2 totalAdmins=2
  memberPreview=[ZynuqUTlbtb1R1qBv74Wi7iEmuN2:active, wwL0OTdrNeMZs2wTt6QtRDT1nb53:active]
=== users/ZynuqUTlbtb1R1qBv74Wi7iEmuN2 === exists=true | memberships: SMQRtCjrA09gPIr1wazD:active
=== TAREAS activas con ZynuqU... === 3 tareas con currentAssigneeUid huérfano
```

Hallazgos colaterales (no detectados en la sesión QA, ahora cubiertos por el fix):
- El fantasma era **admin** → inflaba `planCounters.totalAdmins` (2 en vez de 1),
  lo que falsea el límite Free de admins.
- Tenía **3 tareas** con `currentAssigneeUid` apuntando a la cuenta borrada
  (`assignmentOrder` también lo incluía) → responsable huérfano.

## Estrategia elegida

**Trigger gen-1 `auth.user().onDelete`** (`functions/src/users/index.ts`) que
ejecuta una limpieza idempotente. Es el patrón canónico (la extensión oficial
"Delete User Data" usa exactamente esto) y, frente a las alternativas:

- **vs. callable que limpia antes de borrar**: el callable+`currentUser.delete()`
  tiene una ventana de medio-estado (si la limpieza corre y el `delete()` falla
  con `requires-recent-login`, el usuario queda con membresías borradas y cuenta
  viva). El trigger no: corre *después* del borrado, sin medio-estados.
- **vs. blocking function `beforeUserDeleted` (gen-2)**: exige Identity
  Platform/GCIP; el `onDelete` clásico funciona sobre Firebase Auth a secas.
- **Cobertura**: el trigger limpia el borrado por CUALQUIER vía (app, consola
  Firebase, Admin SDK), no solo desde la app.
- **Sin deploy coordinado**: el cliente NO cambia (sigue usando
  `currentUser.delete()`, preservando el `requires-recent-login` nativo de
  Firebase). Solo hay que desplegar Functions.

`firebase-functions@^6` mantiene el namespace v1 (`firebase-functions/v1`); se
verificó que `auth.user().onDelete` está disponible. Mezclar gen-1 y gen-2 en el
mismo codebase está soportado.

## Qué hace la limpieza (`functions/src/users/cleanup_user.ts`)

Para cada hogar del usuario (vía `users/{uid}/memberships`):

1. **Miembro → `status:"left"`** + `accountDeleted:true`, `leftReason:"accountDeleted"`,
   `leftAt`. Se **conserva** el documento como *snapshot* (nickname/foto/stats)
   para que el historial y las valoraciones de otros miembros sigan resolviendo
   nombre/foto sin romper la UI. El cliente ya filtra `status != 'left'`
   (`members_repository_impl.dart:27`) y el dashboard cuenta solo `status==active`.
2. **Owner borrado** → traspaso de propiedad a un sustituto
   (`pickReplacementOwner`: activo > congelado; admin > member; a igualdad, el
   más antiguo). Si **no queda nadie** → hogar huérfano: `premiumStatus:"purged"`
   + `ownerUid:null` (igual que `closeHome`, para que los crons lo ignoren).
3. **Pagador borrado** (`currentPayerUid==uid`) → `currentPayerUid:null`,
   `autoRenewEnabled:false`, `lastPayerUid:uid`. El periodo Premium ya pagado se
   **respeta** (`premiumStatus`/`premiumEndsAt` intactos); el cron de downgrade
   hace el resto al expirar. (No aplica el payer-lock: la cuenta ya no existe.)
4. **Tareas** → quita al usuario de `assignmentOrder`; si era el responsable
   actual, reasigna al siguiente elegible (`computeTaskReassignment`, salta
   left/frozen/absent) o `null` si no queda nadie. Deja un evento auditable
   `auto_reassign` (reason `member_account_deleted`).
5. **Dashboard** → `updateHomeDashboard(homeId)` recuenta `totalMembers`,
   `planCounters.totalAdmins`, `memberPreview` y asignaciones.
6. **`users/{uid}`** → `recursiveDelete` (borra doc + `memberships` + `rateLimits`).
   Las valoraciones/estadísticas viven bajo `homes/` y se conservan como
   snapshot pseudonimizado (uid + nickname congelado).

Idempotente: re-ejecutarla sobre una cuenta ya limpiada es no-op (no encuentra
memberships → no toca hogares; `recursiveDelete` no-op).

## Archivos

Nuevos:
- `functions/src/users/cleanup_user.ts` — `cleanupDeletedUser(uid)` + lógica con efectos.
- `functions/src/users/cleanup_user_helpers.ts` — helpers puros (`pickReplacementOwner`, `computeTaskReassignment`).
- `functions/src/users/index.ts` — trigger `onAuthUserDeleted`.
- `functions/src/users/cleanup_user.test.ts` — 12 tests unitarios de helpers puros.
- `functions/test/integration/cleanup_user.test.ts` — 12 tests de integración (emulador).
- `secrets/qa_cleanup_deleted_user.js` — utilidad de reparación (reutiliza la lógica compilada): `scan` | `fix <uid>` | `fix-all`.
- `secrets/qa_inspect_home.js` — diagnóstico (solo lectura).

Modificados:
- `functions/src/index.ts` — `export * from "./users";`

Cliente: **sin cambios** (la limpieza es 100% backend; se preserva el flujo y el
`requires-recent-login` nativo).

## Tests

- Unitarios (helpers puros): **12/12 PASS** (`npx jest src/users/cleanup_user.test.ts`).
- Integración (emulador Firestore): **12/12 PASS** — cubre: miembro normal
  (left + borrado de user + reasignación + evento + recuento dashboard), owner+pagador
  con sustituto (traspaso a admin, liberar payer, respetar periodo), owner único →
  hogar purged, e idempotencia.
- Suite unitaria completa del backend: **199/199 PASS** (sin regresiones).
- `tsc` estricto: sin errores.
- `flutter analyze`: sin cambios Dart (estado pre-existente del repo).

## Acciones en producción (hechas, con autorización explícita del usuario)

1. **Ghost existente reparado.** `node secrets/qa_cleanup_deleted_user.js fix ZynuqUTlbtb1R1qBv74Wi7iEmuN2`
   (el escaneo confirmó que era el ÚNICO ghost). Verificado con `qa_inspect_home.js`:
   ```
   ZynuqU... role=admin status=left accountDeleted=true | Auth=NO
   wwL0...   role=owner status=active                   | Auth=SÍ
   DASHBOARD: totalMembers 2→1 · totalAdmins 2→1 · memberPreview=[wwL0...]
   users/ZynuqU... exists=false · 0 tareas huérfanas (reasignadas al owner)
   ```
2. **Function desplegada** (el SA de Admin SDK no tiene permisos de deploy; se
   usó la cuenta `sebastiancoroian@gmail.com` con `firebase login`):
   `FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy --only functions:onAuthUserDeleted --project toka-dd241`
   → `✔ functions[onAuthUserDeleted(us-central1)] Successful create operation.`
   (gen-1 / Node.js 20). Nota WSL: la *discovery* tardaba >10s cargando
   node_modules desde `/mnt/c`; se sube el límite con `FUNCTIONS_DISCOVERY_TIMEOUT`.
3. **Verificación end-to-end real** del trigger ya desplegado
   (`secrets/qa_e2e_delete_trigger.js`): se crea cuenta+hogar+tarea desechables,
   se borra la cuenta con `admin.auth().deleteUser()` (dispara el trigger en
   prod) y, en ~6s, se confirma:
   ```
   ✅ member.status=left accountDeleted=true · task.assignee=owner order=[owner] · users/{uid} borrado
   ```
   Datos desechables limpiados tras la prueba.

## Notas

- El trigger es **asíncrono**: marca el miembro `left` en la primera transacción
  y luego reasigna tareas + borra `users/{uid}`. Para verificar "completado" hay
  que esperar a la señal terminal (borrado de `users/{uid}`), no al cambio de
  estado del miembro (que ocurre antes).
- No se hizo verificación en los 2 dispositivos físicos porque el flujo de
  cliente NO cambió (sigue siendo `currentUser.delete()`); la lógica nueva es
  100% backend y se validó end-to-end contra el trigger desplegado en prod.
