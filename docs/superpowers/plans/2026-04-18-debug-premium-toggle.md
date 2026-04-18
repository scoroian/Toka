# Debug Premium Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir al owner de un hogar cambiar manualmente `premiumStatus` desde *Ajustes del hogar* para probar flujos de UI asociados a cada estado (free, active, cancelledPendingEnd, rescue, expiredFree, restorable). Todo el código va marcado con `DEBUG PREMIUM` para eliminarlo antes de producción.

**Architecture:** Cloud Function `debugSetPremiumStatus` (solo owner) que actualiza `homes/{homeId}` y `homes/{homeId}/views/dashboard.premiumFlags` en un batch. Cliente: método nuevo en `HomesRepository` + entrada nueva en el ViewModel de ajustes del hogar + tile en `HomeSettingsScreen` que abre un bottom sheet con 6 `RadioListTile`.

**Tech Stack:** Flutter + Riverpod, Firebase Cloud Functions (Node.js 20, TS), cloud_functions SDK.

**Spec de referencia:** [docs/superpowers/specs/2026-04-18-debug-premium-toggle-design.md](../specs/2026-04-18-debug-premium-toggle-design.md)

---

## File Structure

- **Functions (backend):**
  - `functions/src/homes/index.ts` — añadir export `debugSetPremiumStatus` al final del archivo (entre marcadores).
  - `functions/src/index.ts` — **sin cambios** (ya hace `export * from "./homes"`).

- **Cliente (Dart):**
  - `lib/features/homes/domain/homes_repository.dart` — declarar método abstracto.
  - `lib/features/homes/data/homes_repository_impl.dart` — implementar llamada a la Callable.
  - `lib/features/homes/application/home_settings_view_model.dart` — exponer `premiumStatusCode`, `showDebugPremiumToggle` y `debugSetPremiumStatus(status)`.
  - `lib/features/homes/application/home_settings_view_model.g.dart` — regenerado por build_runner.
  - `lib/features/homes/presentation/home_settings_screen.dart` — tile nuevo + bottom sheet `_showDebugPremiumSheet`.

---

### Task 1: Cloud Function `debugSetPremiumStatus`

**Files:**
- Modify: `functions/src/homes/index.ts` (añadir al final)

- [ ] **Step 1: Añadir la función al final de `functions/src/homes/index.ts`**

Añadir exactamente este bloque al final del archivo (después de `transferOwnership`):

```ts
// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
// ---------------------------------------------------------------------------
// debugSetPremiumStatus
// Cambia `premiumStatus` de un hogar a uno de 6 valores válidos y propaga el
// cambio a `homes/{homeId}/views/dashboard.premiumFlags` de forma coherente.
// Solo el owner puede llamarla. Pensado exclusivamente para QA/desarrollo.
// Input:  { homeId: string, status: "free" | "active" | "cancelledPendingEnd"
//          | "rescue" | "expiredFree" | "restorable" }
// Output: { ok: true }
// ---------------------------------------------------------------------------
const DEBUG_VALID_STATUSES = [
  "free",
  "active",
  "cancelledPendingEnd",
  "rescue",
  "expiredFree",
  "restorable",
] as const;

type DebugPremiumStatus = typeof DEBUG_VALID_STATUSES[number];

export const debugSetPremiumStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string; status?: string };
  const homeId = data.homeId?.trim();
  const status = data.status?.trim();

  if (!homeId) {
    throw new HttpsError("invalid-argument", "homeId is required");
  }
  if (!status || !DEBUG_VALID_STATUSES.includes(status as DebugPremiumStatus)) {
    throw new HttpsError(
      "invalid-argument",
      `status must be one of: ${DEBUG_VALID_STATUSES.join(", ")}`
    );
  }

  const homeRef = db.collection("homes").doc(homeId);
  const dashboardRef = homeRef.collection("views").doc("dashboard");
  const homeDoc = await homeRef.get();

  if (!homeDoc.exists) {
    throw new HttpsError("not-found", "Home not found");
  }
  if (homeDoc.data()!["ownerUid"] !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the owner can use the debug premium toggle"
    );
  }

  const now = Date.now();
  const day = 24 * 60 * 60 * 1000;
  const typed = status as DebugPremiumStatus;

  let premiumEndsAt: admin.firestore.Timestamp | null = null;
  let restoreUntil: admin.firestore.Timestamp | null = null;
  let autoRenewEnabled = false;
  let premiumPlan: string | null = null;

  switch (typed) {
    case "free":
      break;
    case "active":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now + 30 * day);
      autoRenewEnabled = true;
      premiumPlan = "debug";
      break;
    case "cancelledPendingEnd":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now + 10 * day);
      premiumPlan = "debug";
      break;
    case "rescue":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now + 2 * day);
      premiumPlan = "debug";
      break;
    case "expiredFree":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now - 1 * day);
      break;
    case "restorable":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now - 2 * day);
      restoreUntil = admin.firestore.Timestamp.fromMillis(now + 20 * day);
      break;
  }

  const isPremium =
    typed === "active" ||
    typed === "cancelledPendingEnd" ||
    typed === "rescue";

  const batch = db.batch();
  batch.update(homeRef, {
    premiumStatus: typed,
    premiumEndsAt,
    restoreUntil,
    autoRenewEnabled,
    premiumPlan,
    updatedAt: FieldValue.serverTimestamp(),
  });
  batch.set(
    dashboardRef,
    {
      premiumFlags: {
        isPremium,
        showAds: !isPremium,
        canUseSmartDistribution: isPremium,
        canUseVacations: isPremium,
        canUseReviews: isPremium,
      },
      rescueFlags: {
        isInRescue: typed === "rescue",
        daysLeft: typed === "rescue" ? 2 : null,
      },
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  await batch.commit();

  logger.info(
    `debugSetPremiumStatus: home=${homeId} status=${typed} by owner=${uid}`
  );
  return { ok: true };
});
// END DEBUG PREMIUM
```

- [ ] **Step 2: Build de TypeScript para validar**

Run: `cd functions && npm run build`
Expected: build OK, sin errores de TS.

- [ ] **Step 3: Commit**

```bash
git add functions/src/homes/index.ts
git commit -m "feat(debug): add debugSetPremiumStatus Cloud Function"
```

---

### Task 2: Contrato en `HomesRepository`

**Files:**
- Modify: `lib/features/homes/domain/homes_repository.dart`

- [ ] **Step 1: Añadir declaración del método al final de la interfaz**

Dentro de `abstract interface class HomesRepository { ... }`, justo antes de la llave de cierre (después de `updateHomeName`), añadir:

```dart
  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  /// Cambia el estado premium del hogar a [status] invocando la Cloud
  /// Function `debugSetPremiumStatus`. Solo el owner puede usarlo.
  /// [status] debe ser uno de: free, active, cancelledPendingEnd, rescue,
  /// expiredFree, restorable.
  Future<void> debugSetPremiumStatus(String homeId, String status);
  // END DEBUG PREMIUM
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/homes/domain/homes_repository.dart
git commit -m "feat(debug): declare debugSetPremiumStatus in HomesRepository"
```

---

### Task 3: Implementación en `HomesRepositoryImpl`

**Files:**
- Modify: `lib/features/homes/data/homes_repository_impl.dart`

- [ ] **Step 1: Añadir el método al final de la clase**

Justo antes de la llave de cierre de `class HomesRepositoryImpl`, después de `updateHomeName`:

```dart
  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  @override
  Future<void> debugSetPremiumStatus(String homeId, String status) async {
    final callable = _functions.httpsCallable('debugSetPremiumStatus');
    await callable.call<void>({'homeId': homeId, 'status': status});
  }
  // END DEBUG PREMIUM
```

- [ ] **Step 2: Verificar que compila**

Run: `flutter analyze lib/features/homes/data/homes_repository_impl.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/homes/data/homes_repository_impl.dart
git commit -m "feat(debug): implement debugSetPremiumStatus in HomesRepositoryImpl"
```

---

### Task 4: ViewModel — estado + método

**Files:**
- Modify: `lib/features/homes/application/home_settings_view_model.dart`
- Regenerate: `lib/features/homes/application/home_settings_view_model.g.dart` (build_runner)

- [ ] **Step 1: Añadir campos a `HomeSettingsViewData`**

Dentro de `class HomeSettingsViewData`, añadir al final del constructor y como campos:

Localizar este bloque:

```dart
class HomeSettingsViewData {
  const HomeSettingsViewData({
    required this.homeId,
    required this.homeName,
    required this.planLabel,
    required this.canEdit,
    required this.canManageSubscription,
    required this.isOwner,
    required this.canGenerateCode,
    required this.uid,
  });

  final String homeId;
  final String homeName;
  final String planLabel;
  final bool canEdit;
  final bool canManageSubscription;
  final bool isOwner;
  final bool canGenerateCode;
  final String uid;
}
```

Reemplazarlo por:

```dart
class HomeSettingsViewData {
  const HomeSettingsViewData({
    required this.homeId,
    required this.homeName,
    required this.planLabel,
    required this.canEdit,
    required this.canManageSubscription,
    required this.isOwner,
    required this.canGenerateCode,
    required this.uid,
    // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
    required this.premiumStatusCode,
    required this.showDebugPremiumToggle,
    // END DEBUG PREMIUM
  });

  final String homeId;
  final String homeName;
  final String planLabel;
  final bool canEdit;
  final bool canManageSubscription;
  final bool isOwner;
  final bool canGenerateCode;
  final String uid;
  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  final String premiumStatusCode;
  final bool showDebugPremiumToggle;
  // END DEBUG PREMIUM
}
```

- [ ] **Step 2: Añadir método abstracto a la interfaz**

Dentro de `abstract class HomeSettingsViewModel { ... }`, justo antes de la llave de cierre, después de `void clearError();`:

```dart
  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  Future<void> debugSetPremiumStatus(String status);
  // END DEBUG PREMIUM
```

- [ ] **Step 3: Implementar método en `_HomeSettingsViewModelImpl`**

Dentro de `class _HomeSettingsViewModelImpl`, justo antes de la llave de cierre (después de `void clearError() {}`):

```dart
  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  @override
  Future<void> debugSetPremiumStatus(String status) async {
    final homeId = viewData.valueOrNull?.homeId;
    if (homeId == null) return;
    await ref
        .read(homesRepositoryProvider)
        .debugSetPremiumStatus(homeId, status);
  }
  // END DEBUG PREMIUM
```

- [ ] **Step 4: Rellenar los nuevos campos en el provider `homeSettingsViewModel`**

Localizar el bloque `return HomeSettingsViewData(...)` dentro de `viewData.whenData` y reemplazarlo por:

```dart
    return HomeSettingsViewData(
      homeId: home.id,
      homeName: home.name,
      planLabel: _planLabel(home, l10n),
      canEdit: canEdit,
      canManageSubscription: isOwner || isCurrentPayer,
      isOwner: isOwner,
      canGenerateCode: canEdit,
      uid: uid,
      // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
      premiumStatusCode: home.premiumStatus.name,
      showDebugPremiumToggle: isOwner,
      // END DEBUG PREMIUM
    );
```

- [ ] **Step 5: Regenerar código con build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: OK, regenera `home_settings_view_model.g.dart`.

- [ ] **Step 6: Verificar analyze**

Run: `flutter analyze lib/features/homes/application/home_settings_view_model.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/features/homes/application/home_settings_view_model.dart lib/features/homes/application/home_settings_view_model.g.dart
git commit -m "feat(debug): expose premium status + toggle in HomeSettingsViewModel"
```

---

### Task 5: UI — Tile y bottom sheet en `HomeSettingsScreen`

**Files:**
- Modify: `lib/features/homes/presentation/home_settings_screen.dart`

- [ ] **Step 1: Añadir el tile al `ListView`**

En el método `build`, dentro del `ListView(children: [...])`, justo después del bloque:

```dart
              if (data.canManageSubscription)
                ListTile(
                  key: const Key('manage_subscription_tile'),
                  title: Text(l10n.homes_manage_subscription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.subscription),
                ),
```

añadir:

```dart
              // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
              if (data.showDebugPremiumToggle)
                ListTile(
                  key: const Key('debug_premium_toggle_tile'),
                  leading: const Icon(Icons.science, color: Colors.amber),
                  title: const Text('🧪 DEBUG: Estado premium'),
                  subtitle: Text('Actual: ${data.premiumStatusCode}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDebugPremiumSheet(
                    context,
                    vm,
                    data.premiumStatusCode,
                  ),
                ),
              // END DEBUG PREMIUM
```

- [ ] **Step 2: Añadir el método `_showDebugPremiumSheet` al `_HomeSettingsScreenState`**

Justo antes del método `build`, añadir:

```dart
  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  Future<void> _showDebugPremiumSheet(
    BuildContext context,
    HomeSettingsViewModel vm,
    String currentStatus,
  ) async {
    const statuses = <String>[
      'free',
      'active',
      'cancelledPendingEnd',
      'rescue',
      'expiredFree',
      'restorable',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '🧪 Debug: cambiar estado premium',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...statuses.map((s) => RadioListTile<String>(
                      key: Key('debug_premium_option_$s'),
                      value: s,
                      groupValue: currentStatus,
                      title: Text(s),
                      onChanged: (v) => Navigator.of(ctx).pop(v),
                    )),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == currentStatus) return;

    try {
      await vm.debugSetPremiumStatus(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado premium: $selected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  // END DEBUG PREMIUM
```

- [ ] **Step 3: Verificar analyze**

Run: `flutter analyze lib/features/homes/presentation/home_settings_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/homes/presentation/home_settings_screen.dart
git commit -m "feat(debug): add premium status toggle tile + sheet in HomeSettings"
```

---

### Task 6: Verificación completa

- [ ] **Step 1: Flutter analyze del proyecto entero**

Run: `flutter analyze`
Expected: `No issues found!` (o, como máximo, warnings no relacionados preexistentes).

- [ ] **Step 2: Build TypeScript de Functions**

Run: `cd functions && npm run build`
Expected: OK.

- [ ] **Step 3: Tests existentes**

Run: `flutter test test/unit/features/homes/`
Expected: todos los tests siguen pasando.

Si algún test de `HomeSettingsViewData` construye el objeto directamente, habrá que añadirle los dos campos nuevos (`premiumStatusCode`, `showDebugPremiumToggle`). Localizarlos con:

Run: `grep -rn "HomeSettingsViewData(" test/`

Añadir en cada invocación:

```dart
premiumStatusCode: 'free',
showDebugPremiumToggle: false,
```

- [ ] **Step 4: Smoke test manual**

En el emulador Android (con emuladores Firebase corriendo):

1. Iniciar sesión con `toka.qa.owner@gmail.com`.
2. Ajustes → Ajustes del hogar.
3. Verificar que aparece el tile "🧪 DEBUG: Estado premium" y el estado actual.
4. Pulsar → seleccionar "active" → ver SnackBar y el tile actualizado a "Actual: active".
5. Cambiar a "rescue" → ver SnackBar.
6. Ir a pantalla Hoy y comprobar que `isPremium` se refleja en la UI (por ejemplo, desaparición del banner de anuncios).
7. Volver a "free" para dejar el hogar como estaba.
8. Cerrar sesión, entrar con `toka.qa.member@gmail.com` y verificar que el tile **no** aparece (no es owner).

---

## Pruebas manuales requeridas

- [ ] Owner ve el tile "🧪 DEBUG: Estado premium" en Ajustes del hogar.
- [ ] Member / admin **no** ven el tile.
- [ ] Cada uno de los 6 estados (`free`, `active`, `cancelledPendingEnd`, `rescue`, `expiredFree`, `restorable`) se aplica y se refleja en el subtítulo del tile.
- [ ] Activar "active" o "rescue" desactiva banners de anuncios en pantalla Hoy.
- [ ] Activar "rescue" muestra el banner de rescate correspondiente (si existe).
- [ ] Llamar a la Cloud Function desde un usuario que **no es owner** devuelve `permission-denied` y la UI muestra el SnackBar de error.

---

## Nota para producción

Antes del release a producción, ejecutar:

```bash
grep -rn "DEBUG PREMIUM" functions/src lib
```

y eliminar todos los bloques entre `// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION` y `// END DEBUG PREMIUM`. Después, regenerar con `dart run build_runner build --delete-conflicting-outputs` y verificar con `flutter analyze` + `npm run build` en `functions/`.
