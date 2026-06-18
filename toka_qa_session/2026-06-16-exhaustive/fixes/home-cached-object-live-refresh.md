# §5 — 🟠 El objeto `home` cacheado no refresca en vivo

Estado: **RESUELTO** · Solo cliente (no toca backend ni reglas) · Verificado end-to-end en 2 dispositivos contra prod (`toka-dd241`) · Fecha: 2026-06-17

## Bug

Los cambios en el documento `homes/{homeId}` NO se reflejaban en la UI en vivo;
solo tras reiniciar la app. Casos observados:

- (a) el avatar y el nombre del hogar no cambiaban tras actualizar `photoUrl`/`name`.
- (b) la tile Ajustes→Suscripción mostraba un plan obsoleto (p. ej. "Plan gratuito"
  con el hogar en premium).
- (c) los banners de estado premium (`cancelledPendingEnd`/`rescue`/`restorable`/
  `expiredFree`) no aparecían/desaparecían al cambiar `premiumStatus`.
- (d) tras "Abandonar hogar", la app seguía mostrando el hogar y sus tareas.

En cambio `views/dashboard` SÍ refrescaba en vivo (ads, contadores, tareas).

## Causa raíz (bug real)

`currentHomeProvider` (`lib/features/homes/application/current_home_provider.dart`)
leía el documento del hogar con **una lectura única** `repo.fetchHome(targetId)`
(`.get()`), y el provider es `@Riverpod(keepAlive: true)`. Resultado: el objeto
`Home` quedaba **cacheado** y solo se re-leía al invalidar el provider
(`switchHome`) o al reiniciar la app. Todos los consumidores de estado del hogar
(plan/banners en `subscriptionStateProvider`, avatar/nombre/rol en
`homeSettingsViewModel`, cabecera del selector, etc.) dependen de
`currentHomeProvider`, así que ninguno refrescaba.

El dashboard, por contraste, usa `docRef.snapshots()` (stream en vivo) — ese es el
patrón correcto que faltaba aplicar al documento del hogar.

## Fix (cliente)

Convertir la lectura del hogar en un **stream** del documento, manteniendo el tipo
público del provider (`AsyncNotifier<Home?>`) para no tocar a ningún consumidor:

1. **`homes_repository.dart` / `homes_repository_impl.dart`** — nuevo
   `Stream<Home?> watchHome(String homeId)` con
   `collection('homes').doc(homeId).snapshots()`. Emite `null` si el doc no existe
   (hogar cerrado). `fetchHome` (`.get()`) se conserva por compatibilidad.

2. **`current_home_provider.dart`** — `build()` sigue resolviendo el `targetId`
   (auth → membresías → `lastSelectedHomeId`) igual que antes, pero en vez de
   `return repo.fetchHome(targetId)` se **suscribe** a `repo.watchHome(targetId)`:
   la primera emisión resuelve el `Future` de `build` (estado inicial) y las
   siguientes se empujan a `state` (`AsyncData`/`AsyncError`). `ref.onDispose`
   cancela la suscripción al cambiar de hogar o al destruir el provider. Se mantiene
   `AsyncNotifier` (no se migra a `StreamNotifier`) precisamente para no cambiar la
   firma `Future<Home?> build()` que sobreescriben ~24 fakes de test.

3. **`home_model.dart`** — `fromFirestore` ahora tolera `createdAt`/`updatedAt`
   `null`. Con `.snapshots()`, la emisión optimista del dispositivo que **escribe**
   con `FieldValue.serverTimestamp()` llega antes de que el servidor resuelva el
   timestamp (latency compensation) → el cast `as Timestamp` crasheaba. Se cambió a
   `(... as Timestamp?)?.toDate() ?? DateTime.now()`.

4. **`dashboard_provider.dart` y `subscription_dashboard_provider.dart`** — observan
   ahora solo el id con
   `ref.watch(currentHomeProvider.select((h) => h.valueOrNull?.id))`. Como
   `currentHomeProvider` re-emite ante cualquier cambio de campo del hogar, sin el
   `.select` estos dos providers se reconstruirían en cada cambio: el dashboard
   re-suscribiría su snapshot **y re-invocaría la Cloud Function `refreshDashboard`**,
   y el de suscripción re-crearía su `combineLatest`. Solo deben reaccionar al cambio
   de hogar.

`flutter analyze` limpio en los archivos tocados. `.g.dart` regenerado (el tipo del
provider no cambia; solo el hash).

## Tests

- `test/unit/features/homes/current_home_provider_test.dart`
  - Stubs migrados de `fetchHome` → `watchHome`.
  - **Nuevo** `re-emits live when the home document changes (BUG-05)`: con un
    `StreamController`, la 1ª emisión resuelve el estado inicial y una 2ª emisión
    (nombre/foto/premium cambiados) actualiza `state` sin reiniciar.
- `test/unit/features/homes/homes_repository_test.dart` — nuevo grupo
  `HomesRepositoryImpl.watchHome` con `FakeFirebaseFirestore` contra el impl real:
  - re-emite cuando el doc cambia (nombre + photoUrl + premiumStatus);
  - emite `null` si el doc no existe;
  - tolera timestamps de servidor pendientes (`updatedAt`/`createdAt` null) sin crash.

Suites `test/unit/features/{homes,subscription,tasks,members}` → **324 + nuevos
tests en verde**. Sin regresiones: las suites UI `home_selector`/`home_settings`/
`premium_state_banner`/`rescue_banner` dan el **mismo conjunto de fallos en baseline
y con el fix** (`+14 -9` idéntico) — son goldens de otra máquina + entorno shader,
no regresiones (verificado con `git stash`).

## Verificación en 2 dispositivos (prod `toka-dd241`)

Hogar `SMQRtCjrA09gPIr1wazD` ("Hogar QA Noche"). MI_9 `43340fd2` logueado como owner
(N2), emulador `5554` como **member** → ambos observando el mismo hogar pero con
roles distintos. Cambios aplicados con la app abierta vía Admin SDK
(`[ADMIN SDK]`), sin reiniciar, propagación ~5-7 s:

- **Nombre** (`qa_set_home_field.js name`): el header de Hoy pasó de "Hogar QA
  Noche" → "QA Noche EN VIVO" **en ambos** en vivo.
- **Banner premium** (`qa_premium.js … cancelledPendingEnd`): apareció el banner
  "No se renovará tras el 27/06/2026 · Reactivar renovación" en Hoy **en ambos**.
- **Tile Suscripción** (`qa_premium.js … free`): "Plan Premium" → "Plan gratuito"
  **en ambos** (estando en Ajustes).
- **Avatar** (`qa_set_home_field.js photoUrl …`): el avatar del hogar pasó de la
  inicial a la foto **en ambos**; al borrar `photoUrl` revirtió a la inicial en vivo.
- **Rol/membresía (caso d):** owner ve campo de nombre editable + Transferir/Cerrar
  hogar; member ve nombre de solo lectura y menos opciones → la membresía propia se
  deriva en vivo de `userMembershipsProvider` (que `build` observa). El header de
  Hoy y el nombre de solo lectura del member reflejaron cada cambio.

Estado del hogar **restaurado** al original (`name="Hogar QA Noche"`, sin
`photoUrl`, `premiumStatus=active`) y capturas borradas al terminar.

## Notas / hallazgos

- **No es bug:** el `TextFormField` "Nombre del hogar" de Ajustes del hogar (vista
  owner) mantiene su buffer y no se re-siembra al cambiar el doc en vivo — es el
  comportamiento esperado de un campo editable (no pisar lo que el usuario escribe).
  La cabecera de Hoy y el nombre de solo lectura del member (`Text`) sí refrescan.
- **Caso (d) "Abandonar hogar"** queda cubierto por diseño: `build` observa
  `userMembershipsProvider` (stream); al salir, la membresía deja `status` activo,
  se recalcula el `targetId` (otro hogar o `null`) y la UI se actualiza. No se forzó
  un abandono destructivo sobre el hogar QA de producción; se validó el mecanismo vía
  el render diferenciado por rol y la reactividad de membresías.
- Tooling añadido: `secrets/qa_set_home_field.js <homeId> <field> <value|__DELETE__>`
  para setear/borrar campos escalares del hogar (name/photoUrl) en QA.
- Relación con §9 (tile Suscripción) y §10 (avatar al dashboard): el estado de la
  tile dependía de reiniciar — eso queda resuelto aquí.
