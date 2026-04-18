# Spec: Toggle de estado premium para debug

**Fecha:** 2026-04-18
**Estado:** Aprobado
**Temporalidad:** Código debug — **eliminar antes de producción**

---

## Contexto

Durante el desarrollo necesitamos poder alternar rápidamente el estado premium de un hogar para validar la UI y los flujos condicionales sin depender de una compra real ni de cron jobs. Los estados `active`, `cancelledPendingEnd`, `rescue`, `expiredFree` y `restorable` exponen comportamientos muy distintos (anuncios, banners de rescate, downgrade, etc.) y hoy solo podemos llegar a ellos manipulando Firestore a mano o esperando transiciones automáticas.

Esta spec añade:

1. Una Cloud Function `debugSetPremiumStatus` (solo owner del hogar).
2. Una entrada visual en *Ajustes del hogar* que permite al owner elegir un estado concreto desde la app.

Todo el código debe estar envuelto en marcadores que permitan eliminarlo con un grep trivial antes del release a producción.

---

## Restricciones actuales

- `firestore.rules` prohíbe al cliente escribir `premiumStatus`, `premiumEndsAt`, `currentPayerUid` y `ownerUid` directamente sobre `homes/{homeId}`. Los cambios solo son posibles vía Cloud Functions (admin SDK).
- La UI se alimenta del documento `homes/{homeId}/views/dashboard` — en concreto del mapa `premiumFlags`. Actualizar `premiumStatus` sin propagar a `dashboard` dejaría la UI desincronizada hasta la próxima recomputación.

---

## Cloud Function: `debugSetPremiumStatus`

**Ubicación:** [functions/src/homes/index.ts](functions/src/homes/index.ts) (al final del archivo, entre marcadores de debug).
**Export:** se añade en [functions/src/index.ts](functions/src/index.ts) (entre marcadores).

**Input:**

```ts
{ homeId: string, status: PremiumStatus }
```

donde `PremiumStatus ∈ { "free", "active", "cancelledPendingEnd", "rescue", "expiredFree", "restorable" }`.

**Output:** `{ ok: true }`.

**Preconditions:**

- `request.auth` existe, si no `HttpsError("unauthenticated")`.
- `status` es uno de los 6 valores válidos, si no `HttpsError("invalid-argument")`.
- El caller es el `ownerUid` del hogar, si no `HttpsError("permission-denied")`.

**Efecto sobre `homes/{homeId}`:**

| `status` entrante   | `premiumStatus` | `premiumEndsAt`    | `restoreUntil`   | `autoRenewEnabled` | `premiumPlan` |
| ------------------- | --------------- | ------------------ | ---------------- | ------------------ | ------------- |
| `free`              | `free`          | `null`             | `null`           | `false`            | `null`        |
| `active`            | `active`        | `now + 30 días`    | `null`           | `true`             | `"debug"`     |
| `cancelledPendingEnd` | `cancelledPendingEnd` | `now + 10 días` | `null`         | `false`            | `"debug"`     |
| `rescue`            | `rescue`        | `now + 2 días`     | `null`           | `false`            | `"debug"`     |
| `expiredFree`       | `expiredFree`   | `now - 1 día`      | `null`           | `false`            | `null`        |
| `restorable`        | `restorable`    | `now - 2 días`     | `now + 20 días`  | `false`            | `null`        |

Todos los updates incluyen `updatedAt: FieldValue.serverTimestamp()`.

**Efecto sobre `homes/{homeId}/views/dashboard`:** actualiza `premiumFlags` en el mismo batch coherentemente con el nuevo estado:

```ts
const isPremium = status === "active"
               || status === "cancelledPendingEnd"
               || status === "rescue";

premiumFlags: {
  isPremium,
  showAds: !isPremium,
  canUseSmartDistribution: isPremium,
  canUseVacations: isPremium,
  canUseReviews: isPremium,
}
```

Adicionalmente, si `status === "rescue"` se fija `rescueFlags.isInRescue = true` y `rescueFlags.daysLeft = 2`; en cualquier otro caso se fija `isInRescue = false` y `daysLeft = null`.

**Logging:** `logger.info` con `homeId`, `uid`, `status`.

---

## Cliente — Capa de datos y dominio

### 1. `HomesRepository` — nuevo método

En [lib/features/homes/domain/homes_repository.dart](lib/features/homes/domain/homes_repository.dart), añadir (entre marcadores):

```dart
// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
/// Cambia el estado premium del hogar a [status] invocando la Cloud
/// Function `debugSetPremiumStatus`. Solo el owner puede usarlo.
Future<void> debugSetPremiumStatus(String homeId, String status);
// END DEBUG PREMIUM
```

### 2. `HomesRepositoryImpl`

En [lib/features/homes/data/homes_repository_impl.dart](lib/features/homes/data/homes_repository_impl.dart), implementar llamando a `FirebaseFunctions.instance.httpsCallable('debugSetPremiumStatus')`.

---

## Cliente — ViewModel

En [lib/features/homes/application/home_settings_view_model.dart](lib/features/homes/application/home_settings_view_model.dart):

1. `HomeSettingsViewData` expone (entre marcadores) dos campos nuevos solo para debug:
   - `String premiumStatusCode` — el nombre del enum actual (ej: `"active"`).
   - `bool showDebugPremiumToggle` — `true` si y solo si `isOwner`.
2. Interfaz `HomeSettingsViewModel` añade (entre marcadores):
   ```dart
   Future<void> debugSetPremiumStatus(String status);
   ```
3. Implementación delega en `homesRepositoryProvider`.

---

## Cliente — Presentación

### Tile nuevo en `HomeSettingsScreen`

En [lib/features/homes/presentation/home_settings_screen.dart](lib/features/homes/presentation/home_settings_screen.dart), justo después del bloque `if (data.canManageSubscription) ListTile(...)`:

```dart
// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
if (data.showDebugPremiumToggle)
  ListTile(
    key: const Key('debug_premium_toggle_tile'),
    leading: const Icon(Icons.science, color: Colors.amber),
    title: const Text('🧪 DEBUG: Estado premium'),
    subtitle: Text('Actual: ${data.premiumStatusCode}'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _showDebugPremiumSheet(context, l10n, vm, data.premiumStatusCode),
  ),
// END DEBUG PREMIUM
```

### BottomSheet `_showDebugPremiumSheet`

Función privada del `_HomeSettingsScreenState` (entre marcadores). Muestra un `showModalBottomSheet` con:

- Título "🧪 Debug: cambiar estado premium".
- Lista de 6 `RadioListTile<String>` con los códigos de estado. El actual aparece preseleccionado.
- Al seleccionar un valor:
  1. Cierra el sheet.
  2. Llama a `vm.debugSetPremiumStatus(nuevoStatus)`.
  3. Si éxito: `SnackBar("Estado premium: $status")`.
  4. Si error: `SnackBar("Error: ${e.message ?? e}")`.

Sin strings en ARB — todo el texto es hardcoded porque es debug temporal.

---

## Marcadores de eliminación

Todos los bloques añadidos van envueltos en exactamente estas cadenas (útiles para `grep -rn "DEBUG PREMIUM"`):

- **Dart:** `// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION` … `// END DEBUG PREMIUM`
- **TypeScript:** `// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION` … `// END DEBUG PREMIUM`

Archivos afectados:

- [functions/src/homes/index.ts](functions/src/homes/index.ts)
- [functions/src/index.ts](functions/src/index.ts) (export de la Function)
- [lib/features/homes/domain/homes_repository.dart](lib/features/homes/domain/homes_repository.dart)
- [lib/features/homes/data/homes_repository_impl.dart](lib/features/homes/data/homes_repository_impl.dart)
- [lib/features/homes/application/home_settings_view_model.dart](lib/features/homes/application/home_settings_view_model.dart)
- [lib/features/homes/presentation/home_settings_screen.dart](lib/features/homes/presentation/home_settings_screen.dart)

---

## Tests

Al ser código de debug temporal, **no se añaden tests nuevos** más allá de garantizar que `flutter analyze` y el build TS de Functions pasan sin errores. Los tests existentes que ejercitan `HomeSettingsScreen` / `HomeSettingsViewModel` deben seguir pasando.

---

## Fuera de alcance

- Estado `purged` (ya cubierto por `closeHome`).
- Gating por flag de build (`--dart-define=DEBUG_PREMIUM=true`). No se añade: se confía en los marcadores para eliminar el bloque antes del release a producción.
- Permitir a admins (no-owner) usar el toggle.
- Traducciones (textos en ARB).
- Tests unitarios o de UI del toggle.
