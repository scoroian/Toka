# §10 — 🟡 El avatar del hogar no se denormaliza al dashboard

Estado: **RESUELTO** · Cliente + backend (functions) · Verificado end-to-end en 2
dispositivos contra prod (`toka-dd241`) · Fecha: 2026-06-18

## Hallazgo

El avatar del hogar (`homes/{homeId}.photoUrl`) no llegaba a la pantalla Hoy ni
al selector de hogares:

- La **cabecera de Hoy** (`HomeSelectorWidget`) mostraba solo el nombre + flecha,
  **sin avatar** alguno.
- El **selector de hogares** y **"Mis hogares"** listaban cada hogar solo con su
  nombre (snapshot de la membership), sin foto.
- Solo **Ajustes del hogar** pintaba el avatar (lee `home.photoUrl` directamente).

El enunciado original lo atribuía a que `photoUrl` no se copia a `views/dashboard`
y "la pantalla Hoy lee solo el dashboard". Matiz importante: la **cabecera** de Hoy
NO lee el dashboard, lee `currentHomeProvider` (el documento del hogar, que desde
§5 es un **stream en vivo**). El dashboard solo alimenta el cuerpo (contadores y
tareas). Por eso la cabecera nunca necesitó el avatar denormalizado: le bastaba con
leer `home.photoUrl`.

## Decisión: Opción B (leer del modelo del hogar), NO denormalizar al dashboard

Se eligió **que la UI lea `photoUrl` del modelo del hogar**, en vez de copiar
`homePhotoUrl` al `views/dashboard`, porque:

1. **§5 ya convirtió `currentHomeProvider` en un stream en vivo** del documento
   `homes/{homeId}`. La cabecera ya consume ese provider (lee `currentHome.name`).
   Añadir `currentHome.photoUrl` refresca en vivo **gratis**, sin tocar backend.
2. Denormalizar al dashboard sería una **segunda fuente de verdad redundante** que
   la cabecera ni siquiera lee, y obligaría a reescribir el blob del dashboard en
   cada cambio de foto/nombre (más writes, más desfase ~10s del rebuild).
3. El dashboard se reconstruye con `set(...)` completo en cada completar/pasar;
   meter ahí la foto no aporta nada que el stream del hogar no dé ya antes.
4. El **selector** y **"Mis hogares"** NO listan el hogar actual sino **todos** los
   hogares del usuario, a través del snapshot por-membership
   (`users/{uid}/memberships/{homeId}`). El dashboard (que es por-hogar) no ayuda
   ahí. La pieza correcta es denormalizar la foto **en la membership**, igual que ya
   se hace con `homeNameSnapshot`.

## Causa raíz secundaria detectada (bug latente de §5/§10)

`homeNameSnapshot` se escribía **solo al crear/unirse** (3 sitios en
`functions/src/homes/index.ts`) y **nunca se re-sincronizaba**: no había trigger que
lo actualizara cuando el hogar se renombra. Resultado: renombrar un hogar dejaba el
**selector y "Mis hogares" con el nombre viejo** para todos los miembros hasta
re-unirse (la cabecera sí refrescaba porque lee el doc del hogar en vivo, no el
snapshot). Se aprovecha el fix para corregir también esto con un trigger de
re-sincronización.

## Fix

### Cliente

- **`lib/features/homes/presentation/widgets/home_avatar.dart`** (nuevo):
  `HomeAvatar` reutilizable (foto `NetworkImage` o inicial del nombre como
  fallback), misma semántica que el avatar grande de Ajustes del hogar.
- **`home_selector_widget.dart`**:
  - Cabecera de Hoy: `HomeAvatar(photoUrl: currentHome.photoUrl, …)` antes del
    nombre (key `home_selector_avatar`). El nombre pasa a `Flexible` con
    `ellipsis` para no desbordar junto al avatar.
  - Tiles del sheet "Cambiar hogar": `leading: HomeAvatar(photoUrl:
    membership.homePhotoSnapshot, …)`.
- **`my_homes_screen_v2.dart`**: mismo `leading: HomeAvatar(...)` en cada tile.
- **`home_membership.dart`**: nuevo campo `String? homePhotoSnapshot` (freezed).
- **`home_model.dart`**: `membershipFromFirestore` lee `homePhotoSnapshot`.

(Las skins v1 `MyHomesScreen`/`HomeSettingsScreen`/`TodayScreen` son solo wrappers
`SkinSwitch(v2: …)` sin implementación propia → v2 es la única skin activa.)

### Backend (`functions/src/homes/index.ts`)

- `createHome`, `joinHome`, `joinHomeByCode`: la membership creada incluye
  `homePhotoSnapshot` (en `createHome` es `null` —hogar recién creado sin foto—; al
  unirse, se toma `homes/{homeId}.photoUrl`).
- **`syncHomeSnapshotToMemberships`** (nuevo trigger `onDocumentUpdated
  "homes/{homeId}"`): cuando cambia `name` o `photoUrl`, propaga
  `homeNameSnapshot` + `homePhotoSnapshot` a la membership
  `users/{uid}/memberships/{homeId}` de cada miembro **vigente** (status
  `active`/`frozen`). Es el simétrico de `syncMemberProfile` (perfil de usuario →
  members); aquí la fuente es el hogar y el destino las membership cards. Updates
  individuales con `.catch` (patrón de `update_dashboard`) para que una membership
  inexistente no tumbe la sincronización del resto.

`flutter analyze` limpio en los archivos tocados; `tsc` estricto en `functions`
limpio; `.g.dart`/`.freezed.dart` regenerados (el tipo del provider/modelo no
cambia salvo el campo nuevo).

## Tests

- **Unit cliente** `test/unit/features/homes/homes_repository_test.dart`: dos casos
  nuevos para `membershipFromFirestore` — lee `homePhotoSnapshot` cuando está
  presente y es `null` cuando falta. (15/15 verde.)
- **UI cliente** `test/ui/features/homes/home_selector_widget_test.dart`: dos casos
  nuevos — la cabecera muestra `home_selector_avatar` con la inicial sin foto; cada
  tile del sheet tiene un `HomeAvatar` (3 = cabecera + 2 tiles). Golden
  `home_selector_3_homes.png` regenerado (el layout ahora lleva avatares en las
  tiles).
- **Integración backend** `functions/test/integration/sync_home_snapshot.test.ts`
  (nuevo, contra el emulador de Firestore, 5/5 verde):
  - el trigger propaga nombre+foto nuevos a memberships `active`/`frozen`;
  - **no** toca la membership de un miembro que abandonó (`status=left`);
  - al borrar la foto deja `homePhotoSnapshot=null`;
  - es no-op si solo cambia un campo irrelevante (`premiumStatus`);
  - `joinHomeByCode` denormaliza la foto del hogar en la membership al unirse.
- Sin regresiones: `join_home_profile` + `home_creation` siguen verde tras añadir
  `homePhotoSnapshot` a las callables; suite `test/unit/features/homes` 45/45.

> Falso positivo conocido (NO regresión): `home_selector_widget_test`
> "con un hogar muestra el nombre sin flecha de selector" falla **también en
> baseline** (verificado con `git stash`): el widget siempre renderiza la flecha;
> la expectativa del test es obsoleta. No tocado aquí.

## Verificación en 2 dispositivos (prod `toka-dd241`)

Hogar `SMQRtCjrA09gPIr1wazD` ("Hogar QA Noche"). MI_9 `43340fd2` = owner N2 (2
hogares: "Hogar QA Noche" + "Hogar 2 QA"); emulador `5554` = member (1 hogar).
APK debug recompilado e instalado en ambos.

1. **Cabecera Hoy — inicial:** sin foto, la cabecera muestra el avatar con la
   inicial **"H"** junto a "Hogar QA Noche ▼" en ambos (antes no había avatar).
2. **Cabecera Hoy — foto en vivo:** `[ADMIN SDK]`
   `qa_set_home_field.js SMQRtCjrA09gPIr1wazD photoUrl https://i.pravatar.cc/300?img=12`
   con la app abierta → la inicial "H" pasó a la **foto** en la cabecera de **ambos
   dispositivos sin reiniciar** (stream del hogar de §5 + el avatar nuevo).
3. **Selector de hogares:** el sheet "Cambiar hogar" pinta un avatar por tile. En
   MI_9, tras sembrar `homePhotoSnapshot` solo en "Hogar QA Noche" `[ADMIN SDK]`
   (réplica del efecto del trigger): esa tile muestra la **foto** y "Hogar 2 QA"
   queda con la **inicial "H"** → fallback por-hogar correcto. En el emulador, la
   tile "Hogar QA Noche · Miembro" muestra la **foto**.
4. **Ajustes del hogar:** ya pintaba el avatar desde `home.photoUrl` (sin cambios
   míos); verificado en vivo en §5.

5. **Trigger desplegado y verificado en prod (end-to-end real):** se desplegó
   `firebase deploy --only functions:syncHomeSnapshotToMemberships,createHome,joinHome,joinHomeByCode`
   a `toka-dd241` (con `FUNCTIONS_DISCOVERY_TIMEOUT=120` — la carga del código
   fuente tarda ~6.5s y el discovery por defecto de 10s daba timeout). Resultado:
   `syncHomeSnapshotToMemberships` creado; las 3 callables actualizadas. Con la app
   abierta en ambos dispositivos: al setear `home.photoUrl` `[ADMIN SDK]`, el
   **trigger desplegado** propagó `homePhotoSnapshot` a las dos memberships en **~2s**
   y el selector pasó a mostrar la **foto** en vivo (MI_9: "Hogar QA Noche" con foto,
   "Hogar 2 QA" con inicial; emulador: "Hogar QA Noche · Miembro" con foto). Al
   **borrar** `photoUrl`, el trigger revirtió `homePhotoSnapshot=null` en ~2s.

Estado del hogar **restaurado** al original: `photoUrl` borrado, `homePhotoSnapshot`
revertido a null por el propio trigger. Capturas borradas.

## Hallazgos / mejoras detectadas

- **Bug latente corregido de paso:** `homeNameSnapshot` no se re-sincronizaba al
  renombrar el hogar (selector/"Mis hogares" mostraban el nombre viejo). El nuevo
  trigger lo arregla junto con la foto.
- El test `home_selector_widget_test` "con un hogar … sin flecha" es un **falso
  positivo pre-existente** (la flecha es incondicional en el widget); conviene
  actualizar la expectativa del test o el widget en una limpieza futura.
