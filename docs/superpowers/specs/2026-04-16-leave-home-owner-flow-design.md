# Spec: Flujo "Abandonar hogar" para propietarios

**Fecha:** 2026-04-16
**Estado:** Aprobado

---

## Contexto

Actualmente, cuando el propietario de un hogar pulsa "Abandonar hogar" en Ajustes, el backend rechaza la operación con `failed-precondition` y la UI muestra un Snackbar genérico de error. Esto es un callejón sin salida: el propietario no puede abandonar el hogar de ninguna manera.

La solución cubre cuatro casos según el estado de los demás miembros, y añade la Cloud Function `transferOwnership` que aún no existe en el backend.

---

## Lógica de clasificación

```
activeOthers  = members donde uid != self && status == active
frozenOthers  = members donde uid != self && status == frozen

Caso A: !isOwner              → flujo actual (confirmación genérica → leaveHome)
Caso B: isOwner && activeOthers.isNotEmpty   → TransferOwnershipDialog (solo activos)
Caso C: isOwner && activeOthers.isEmpty && frozenOthers.isEmpty → DeleteHomeDialog
Caso D: isOwner && activeOthers.isEmpty && frozenOthers.isNotEmpty → FrozenTransferDialog
```

La clasificación se hace con una lectura one-shot dentro del `onTap`:

```dart
final members = await ref
    .read(membersRepositoryProvider)
    .watchHomeMembers(homeId)
    .first;
```

---

## Casos de uso

### Caso A — No es owner

Sin cambios. Se muestra el `AlertDialog` genérico de confirmación y se llama a `leaveHome`.

### Caso B — Owner con miembros activos

**Dialog `_TransferOwnershipDialog`** (`StatefulWidget`):

- Título: *"Transferir propiedad del hogar"*
- Cuerpo: *"Para abandonar el hogar, selecciona quién será el nuevo propietario."*
- Lista scrolleable de `activeOthers`: cada ítem muestra avatar (foto o inicial) + nickname. Selección tipo radio (un solo ítem activo).
- Botones: `Cancelar` | `Confirmar` (deshabilitado mientras no haya selección)

Al confirmar:
1. `membersRepository.transferOwnership(homeId, selectedUid)`
2. `homesRepository.leaveHome(homeId, uid: uid)`
3. `ref.invalidate(currentHomeProvider)` → `context.go(AppRoutes.home)`

### Caso C — Owner único (sin otros miembros)

**Dialog simple** (`AlertDialog`):

- Título: *"Eliminar hogar"*
- Cuerpo: *"Eres el único miembro de este hogar. Al abandonarlo, el hogar se eliminará permanentemente y no podrá recuperarse."*
- Botones: `Cancelar` | `Eliminar` (en color `error`)

Al confirmar:
1. `homesRepository.closeHome(homeId)`
2. `ref.invalidate(currentHomeProvider)` → `context.go(AppRoutes.home)`

### Caso D — Owner con solo miembros congelados

**Dialog `_FrozenTransferDialog`** (`StatefulWidget`):

- Título: *"Abandonar hogar"*
- Cuerpo: *"Solo hay miembros congelados. Puedes transferir la propiedad a uno de ellos o eliminar el hogar permanentemente."*
- Lista scrolleable de `frozenOthers`: mismo estilo visual que Caso B (avatar + nickname), con selección opcional.
- Botones:
  - `Cancelar`
  - `Transferir` (habilitado solo si hay un miembro seleccionado) → misma secuencia que Caso B
  - `Eliminar hogar` (botón de texto en color `error`, siempre activo) → misma secuencia que Caso C

---

## Cloud Function `transferOwnership` (nueva)

**Archivo:** `functions/src/homes/index.ts`

**Input:** `{ homeId: string, newOwnerUid: string }`

**Validaciones:**
1. Caller autenticado.
2. Caller es el `ownerUid` actual del documento `homes/{homeId}`.
3. `newOwnerUid` tiene un doc en `homes/{homeId}/members/{newOwnerUid}` con `status` `active` o `frozen`.

**Batch atómico (escrituras):**

| Documento | Campo | Valor |
|---|---|---|
| `homes/{homeId}` | `ownerUid` | `newOwnerUid` |
| `homes/{homeId}/members/{callerUid}` | `role` | `"member"` |
| `homes/{homeId}/members/{newOwnerUid}` | `role` | `"owner"` |
| `users/{callerUid}/memberships/{homeId}` | `role` | `"member"` |
| `users/{newOwnerUid}/memberships/{homeId}` | `role` | `"owner"` |

**Output:** vacío (void).

**Errores posibles:**
- `unauthenticated` — no hay sesión.
- `invalid-argument` — falta `homeId` o `newOwnerUid`.
- `not-found` — el hogar o la membership del nuevo owner no existen.
- `permission-denied` — el caller no es el owner actual.

---

## Textos nuevos (ARB)

| Clave | Español |
|---|---|
| `homes_transfer_ownership_title` | `Transferir propiedad del hogar` |
| `homes_transfer_ownership_body` | `Para abandonar el hogar, selecciona quién será el nuevo propietario.` |
| `homes_transfer_btn` | `Transferir` |
| `homes_delete_home_title` | `Eliminar hogar` |
| `homes_delete_home_body_sole` | `Eres el único miembro de este hogar. Al abandonarlo, se eliminará permanentemente y no podrá recuperarse.` |
| `homes_delete_btn` | `Eliminar` |
| `homes_frozen_only_title` | `Abandonar hogar` |
| `homes_frozen_only_body` | `Solo hay miembros congelados. Puedes transferir la propiedad a uno de ellos o eliminar el hogar permanentemente.` |

---

## Archivos afectados

| Archivo | Tipo de cambio |
|---|---|
| `functions/src/homes/index.ts` | Añadir `export const transferOwnership` |
| `lib/features/settings/presentation/settings_screen.dart` | Reemplazar bloque `onTap` + añadir 2 dialogs privados |
| `lib/l10n/app_es.arb` | 8 claves nuevas |
| `lib/l10n/app_en.arb` | 8 claves nuevas |
| `lib/l10n/app_ro.arb` | 8 claves nuevas |
| `lib/l10n/app_localizations.dart` | 8 getters abstractos nuevos |
| `lib/l10n/app_localizations_es.dart` | 8 implementaciones |
| `lib/l10n/app_localizations_en.dart` | 8 implementaciones |
| `lib/l10n/app_localizations_ro.dart` | 8 implementaciones |

No se crean archivos de dominio nuevos: `transferOwnership` ya existe en `MembersRepository` y `MembersRepositoryImpl`.

---

## Tests requeridos

### Unit tests (`test/unit/`)

Ninguno nuevo: la lógica de clasificación vive en la UI (no en un ViewModel) y se valida con tests de widget.

### Widget tests (`test/ui/features/settings/settings_screen_test.dart`)

| Test | Descripción |
|---|---|
| `owner con activos muestra TransferOwnershipDialog` | Mock con 1 miembro activo, verificar que aparece el dialog de transferencia |
| `owner sin miembros muestra DeleteHomeDialog` | Mock vacío, verificar dialog de eliminar |
| `owner con solo congelados muestra FrozenTransferDialog` | Mock con 1 miembro frozen, verificar el dialog combinado |
| `no-owner muestra confirmación genérica` | Verificar que el dialog de confirmación estándar aparece |

### Cloud Function tests (`functions/src/homes/`)

| Test | Descripción |
|---|---|
| `transferOwnership valida autenticación` | Sin auth → `unauthenticated` |
| `transferOwnership valida que caller es owner` | Caller no-owner → `permission-denied` |
| `transferOwnership valida que newOwner existe` | UID inválido → `not-found` |
| `transferOwnership cambia ownerUid y roles` | Happy path: verificar batch |
