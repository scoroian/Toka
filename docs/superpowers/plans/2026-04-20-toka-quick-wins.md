# Toka Quick Wins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corregir en una tanda los hallazgos de la auditoría que no requieren decisiones externas: endurecer 4 puntos de seguridad en Cloud Functions, hacer funcionar AdMob real en 4 pantallas del cliente, y limpiar inconsistencias de código (rutas hardcodeadas, `new Date()` server-side, duplicación en creación de miembros).

**Architecture:** Backend cambios quirúrgicos en Cloud Functions (TS + Jest). Cliente Flutter con Riverpod + freezed: un widget `AdBanner` compartido en `lib/shared/widgets/` que consume un provider de configuración derivado del dashboard. Regla especial de upsell en History usando `LayoutBuilder` para calcular items ocultos.

**Tech Stack:** Flutter 3 + Riverpod + go_router + google_mobile_ads; Cloud Functions TS + Jest + firebase-admin.

**Spec origen:** `docs/superpowers/specs/2026-04-18-toka-quick-wins-design.md`

---

## File Structure

### Archivos a crear

- `functions/src/shared/ad_constants.ts` — Test unit IDs de AdMob para Android/iOS.
- `functions/src/homes/member_factory.ts` — `buildNewMemberDoc` reutilizable.
- `functions/src/homes/member_factory.test.ts` — Tests del factory.
- `functions/src/entitlement/sync_entitlement_idempotency.test.ts` — Test de idempotencia con doble `chargeId`.
- `functions/src/tasks/manual_reassign.test.ts` — Tests de validación de `newAssigneeUid`.
- `lib/shared/widgets/ad_banner.dart` — Widget `AdBanner` con `BannerAd` real.
- `lib/shared/widgets/ad_banner_config_provider.dart` — Provider de `adBannerConfig`.
- `lib/shared/widgets/ad_banner_config_provider.g.dart` — Generado por `build_runner`.
- `test/unit/shared/widgets/ad_banner_test.dart` — Widget tests.

### Archivos a modificar

- `functions/src/homes/index.ts` — Gate debug, payer protection, usar `buildNewMemberDoc`, `Timestamp.now()`.
- `functions/src/homes/homes_callables.test.ts` — Tests de gate debug y payer protection.
- `functions/src/entitlement/sync_entitlement.ts` — Transacción única + `adFlags` sync.
- `functions/src/entitlement/slot_ledger.ts` — Refactor `unlockSlotIfEligible` para aceptar `tx` externa.
- `functions/src/entitlement/apply_downgrade_plan.ts` — `adFlags` sync.
- `functions/src/jobs/restore_premium_state.ts` — `adFlags` sync.
- `functions/src/jobs/process_expired_tasks.ts` — `Timestamp.now()`.
- `functions/src/notifications/dispatch_due_reminders.ts` — `Timestamp.now()`.
- `functions/src/tasks/apply_task_completion.ts` — `Timestamp.now()`.
- `functions/src/tasks/update_dashboard.ts` — `Timestamp.now()`.
- `functions/src/tasks/manual_reassign.ts` — Validación `newAssigneeUid`.
- `lib/main.dart` — `MobileAds.instance.initialize()`.
- `ios/Runner/Info.plist` — `GADApplicationIdentifier`.
- `lib/features/tasks/presentation/today_screen.dart` — Reemplazar placeholder por `AdBanner`.
- `lib/features/tasks/presentation/all_tasks_screen.dart` — Añadir `AdBanner` al pie.
- `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart` — Ídem.
- `lib/features/history/presentation/history_screen.dart` — Upsell diferido + `AdBanner`.
- Pantallas de miembros (todas las que listan miembros) — Añadir `AdBanner`.
- `lib/features/tasks/presentation/task_detail_screen.dart` — Ruta `AppRoutes.editTask`.
- `lib/features/tasks/presentation/all_tasks_screen.dart` — Ruta `AppRoutes.taskDetail`.
- `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart` — Ruta `AppRoutes.taskDetail`.
- `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` — Ruta `AppRoutes.editTask`.
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` — Clave `members_error_payer_locked`.

---

## BLOQUE 1 — Seguridad backend

### Task 1: Gate `debugSetPremiumStatus` por emulador

**Files:**
- Modify: `functions/src/homes/index.ts` (inicio del handler `debugSetPremiumStatus`)
- Modify: `functions/src/homes/homes_callables.test.ts` (añadir tests)

- [ ] **Step 1.1: Escribir el test del gate**

Añadir al final de `functions/src/homes/homes_callables.test.ts`:

```typescript
describe("debugSetPremiumStatus — gate por emulador", () => {
  function isEmulatorEnv(envValue: string | undefined): boolean {
    return envValue === "true";
  }

  it("FUNCTIONS_EMULATOR==='true' → permitido", () => {
    expect(isEmulatorEnv("true")).toBe(true);
  });
  it("FUNCTIONS_EMULATOR===undefined → denegado", () => {
    expect(isEmulatorEnv(undefined)).toBe(false);
  });
  it("FUNCTIONS_EMULATOR==='false' → denegado", () => {
    expect(isEmulatorEnv("false")).toBe(false);
  });
  it("FUNCTIONS_EMULATOR==='1' → denegado (solo 'true' exacto)", () => {
    expect(isEmulatorEnv("1")).toBe(false);
  });
});
```

- [ ] **Step 1.2: Ejecutar tests y ver que pasan**

```bash
cd functions && npm test -- --testPathPattern=homes_callables
```

Esperado: todos los tests pasan (el helper todavía no está en el handler, pero la lógica pura ya se testea).

- [ ] **Step 1.3: Añadir el gate al handler `debugSetPremiumStatus`**

En `functions/src/homes/index.ts`, localiza `export const debugSetPremiumStatus = onCall(...)` y añade como PRIMER chequeo dentro del handler, antes de la validación de `request.auth`:

```typescript
export const debugSetPremiumStatus = onCall(async (request) => {
  if (process.env.FUNCTIONS_EMULATOR !== "true") {
    throw new HttpsError(
      "permission-denied",
      "Debug operations only available in emulator"
    );
  }

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  // ... resto del handler existente ...
});
```

- [ ] **Step 1.4: Verificar compilación TypeScript**

```bash
cd functions && npm run build
```

Esperado: `tsc` compila sin errores.

- [ ] **Step 1.5: Commit**

```bash
git add functions/src/homes/index.ts functions/src/homes/homes_callables.test.ts
git commit -m "fix(security): gate debugSetPremiumStatus por FUNCTIONS_EMULATOR"
```

---

### Task 2: Transacción única `syncEntitlement` + unlock de slot

**Files:**
- Modify: `functions/src/entitlement/sync_entitlement.ts`
- Modify: `functions/src/entitlement/slot_ledger.ts`
- Create: `functions/src/entitlement/sync_entitlement_idempotency.test.ts`

- [ ] **Step 2.1: Escribir test de idempotencia**

Crear `functions/src/entitlement/sync_entitlement_idempotency.test.ts`:

```typescript
// Testea que la lógica de unlock-por-chargeId es idempotente:
// dos invocaciones del mismo chargeId NUNCA incrementan el slot dos veces.

describe("syncEntitlement — idempotencia de unlock", () => {
  type ChargeState = { exists: boolean };
  type UserState = { lifetimeUnlockedHomeSlots: number; homeSlotCap: number };

  function processCharge(
    charge: ChargeState,
    user: UserState,
    status: string
  ): { unlocked: boolean; userAfter: UserState } {
    if (charge.exists) {
      return { unlocked: false, userAfter: user };
    }
    const validForUnlock = status === "active";
    if (!validForUnlock) {
      return { unlocked: false, userAfter: user };
    }
    if (user.lifetimeUnlockedHomeSlots >= 3) {
      return { unlocked: false, userAfter: user };
    }
    return {
      unlocked: true,
      userAfter: {
        lifetimeUnlockedHomeSlots: user.lifetimeUnlockedHomeSlots + 1,
        homeSlotCap: user.homeSlotCap + 1,
      },
    };
  }

  it("primera invocación: charge nuevo + status active → desbloquea", () => {
    const res = processCharge(
      { exists: false },
      { lifetimeUnlockedHomeSlots: 0, homeSlotCap: 2 },
      "active"
    );
    expect(res.unlocked).toBe(true);
    expect(res.userAfter.lifetimeUnlockedHomeSlots).toBe(1);
  });

  it("segunda invocación con mismo chargeId → NO desbloquea otra vez", () => {
    const res = processCharge(
      { exists: true },
      { lifetimeUnlockedHomeSlots: 1, homeSlotCap: 3 },
      "active"
    );
    expect(res.unlocked).toBe(false);
    expect(res.userAfter.lifetimeUnlockedHomeSlots).toBe(1);
  });

  it("status cancelled → no desbloquea", () => {
    const res = processCharge(
      { exists: false },
      { lifetimeUnlockedHomeSlots: 0, homeSlotCap: 2 },
      "cancelled"
    );
    expect(res.unlocked).toBe(false);
  });

  it("ya tiene 3 unlocks → no desbloquea más", () => {
    const res = processCharge(
      { exists: false },
      { lifetimeUnlockedHomeSlots: 3, homeSlotCap: 5 },
      "active"
    );
    expect(res.unlocked).toBe(false);
  });
});
```

- [ ] **Step 2.2: Ejecutar test**

```bash
cd functions && npm test -- --testPathPattern=sync_entitlement_idempotency
```

Esperado: 4/4 pasan.

- [ ] **Step 2.3: Refactorizar `unlockSlotIfEligible` para aceptar `tx` externa**

En `functions/src/entitlement/slot_ledger.ts`, cambiar la firma para aceptar una transacción existente. Nueva firma:

```typescript
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

export async function unlockSlotIfEligibleTx(
  tx: admin.firestore.Transaction,
  firestore: admin.firestore.Firestore,
  uid: string,
  chargeId: string
): Promise<boolean> {
  const userRef = firestore.collection("users").doc(uid);
  const userSnap = await tx.get(userRef);
  const current = (userSnap.data()?.["lifetimeUnlockedHomeSlots"] as number | undefined) ?? 0;

  if (current >= 3) {
    return false;
  }

  tx.update(userRef, {
    lifetimeUnlockedHomeSlots: FieldValue.increment(1),
    homeSlotCap: FieldValue.increment(1),
    lastUnlockedChargeId: chargeId,
    lastUnlockedAt: FieldValue.serverTimestamp(),
  });
  return true;
}
```

Mantén la función antigua `unlockSlotIfEligible` como wrapper deprecated que abre su propia transacción, por si otros sitios la usan. Si no hay callers fuera de `sync_entitlement.ts`, elimínala.

- [ ] **Step 2.4: Refactorizar `syncEntitlement` a transacción única**

En `functions/src/entitlement/sync_entitlement.ts`, localiza el bloque que hace `chargeRef.set({...}, { merge: true })` seguido de `unlockSlotIfEligible(...)`. Reemplazar por:

```typescript
// Todo en UNA transacción para prevenir race condition.
const unlocked = await db.runTransaction(async (tx) => {
  const chargeSnap = await tx.get(chargeRef);
  if (chargeSnap.exists) {
    return false;
  }

  tx.set(chargeRef, {
    amount,
    currency,
    platform,
    processedAt: FieldValue.serverTimestamp(),
    sourceReceiptHash: receiptHash,
  });

  if (status !== "active") {
    return false;
  }

  return await unlockSlotIfEligibleTx(tx, db, uid, chargeId);
});

if (unlocked) {
  logger.info("Slot unlocked", { uid, chargeId });
}
```

Adapta los nombres de variables locales (`db`, `chargeRef`, `chargeId`, `amount`, etc.) al código existente sin cambiar su semántica.

- [ ] **Step 2.5: Build + tests existentes**

```bash
cd functions && npm run build && npm test
```

Esperado: `tsc` OK y todos los tests pasan (nuevos + existentes).

- [ ] **Step 2.6: Commit**

```bash
git add functions/src/entitlement/sync_entitlement.ts \
        functions/src/entitlement/slot_ledger.ts \
        functions/src/entitlement/sync_entitlement_idempotency.test.ts
git commit -m "fix(security): transaccion unica en syncEntitlement + unlock de slot"
```

---

### Task 3: Proteger `currentPayerUid` en `removeMember` y `leaveHome`

**Files:**
- Modify: `functions/src/homes/index.ts`
- Modify: `functions/src/homes/homes_callables.test.ts`
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`

- [ ] **Step 3.1: Escribir tests de protección del payer**

Añadir al final de `functions/src/homes/homes_callables.test.ts`:

```typescript
describe("payer protection — removeMember/leaveHome", () => {
  const PROTECTED_STATUSES = ["active", "cancelledPendingEnd", "rescue"];

  function isPayerLocked(
    targetUid: string,
    currentPayerUid: string | null,
    premiumStatus: string
  ): boolean {
    if (targetUid !== currentPayerUid) return false;
    return PROTECTED_STATUSES.includes(premiumStatus);
  }

  it("target === payer + status active → bloqueado", () => {
    expect(isPayerLocked("u1", "u1", "active")).toBe(true);
  });
  it("target === payer + status cancelledPendingEnd → bloqueado", () => {
    expect(isPayerLocked("u1", "u1", "cancelledPendingEnd")).toBe(true);
  });
  it("target === payer + status rescue → bloqueado", () => {
    expect(isPayerLocked("u1", "u1", "rescue")).toBe(true);
  });
  it("target === payer + status free → permitido", () => {
    expect(isPayerLocked("u1", "u1", "free")).toBe(false);
  });
  it("target === payer + status expiredFree → permitido", () => {
    expect(isPayerLocked("u1", "u1", "expiredFree")).toBe(false);
  });
  it("target !== payer → permitido", () => {
    expect(isPayerLocked("u2", "u1", "active")).toBe(false);
  });
  it("currentPayerUid null → permitido", () => {
    expect(isPayerLocked("u1", null, "active")).toBe(false);
  });
});
```

- [ ] **Step 3.2: Ejecutar tests**

```bash
cd functions && npm test -- --testPathPattern=homes_callables
```

Esperado: los 7 tests nuevos pasan.

- [ ] **Step 3.3: Añadir guard en `removeMember`**

En `functions/src/homes/index.ts`, dentro del handler `removeMember`, tras cargar el documento del hogar y antes de eliminar al miembro, insertar:

```typescript
const PROTECTED_STATUSES = ["active", "cancelledPendingEnd", "rescue"];
const currentPayerUid = homeData["currentPayerUid"] as string | null | undefined;
const premiumStatus = homeData["premiumStatus"] as string | undefined;

if (
  targetUid === currentPayerUid &&
  premiumStatus &&
  PROTECTED_STATUSES.includes(premiumStatus)
) {
  throw new HttpsError(
    "failed-precondition",
    "payer-cannot-leave-or-be-removed-while-premium-active"
  );
}
```

Adapta `homeData` y `targetUid` a los nombres locales del handler.

- [ ] **Step 3.4: Añadir guard en `leaveHome`**

En el mismo archivo, dentro del handler `leaveHome`, antes de marcar el membership como `left`, insertar el mismo guard (usando `uid` — el caller — como `targetUid`):

```typescript
const PROTECTED_STATUSES = ["active", "cancelledPendingEnd", "rescue"];
const currentPayerUid = homeData["currentPayerUid"] as string | null | undefined;
const premiumStatus = homeData["premiumStatus"] as string | undefined;

if (
  uid === currentPayerUid &&
  premiumStatus &&
  PROTECTED_STATUSES.includes(premiumStatus)
) {
  throw new HttpsError(
    "failed-precondition",
    "payer-cannot-leave-or-be-removed-while-premium-active"
  );
}
```

- [ ] **Step 3.5: Añadir traducciones**

En `lib/l10n/app_es.arb` (y equivalentes en `app_en.arb`, `app_ro.arb`), añadir:

`app_es.arb`:
```json
"members_error_payer_locked": "No puedes expulsar ni salir del hogar mientras seas el pagador de la suscripción Premium activa. Cancela la suscripción primero o espera a que expire."
```

`app_en.arb`:
```json
"members_error_payer_locked": "You cannot be removed or leave while you are the active Premium payer. Cancel the subscription first or wait for it to expire."
```

`app_ro.arb`:
```json
"members_error_payer_locked": "Nu poți fi eliminat sau părăsi casa cât timp ești plătitorul abonamentului Premium activ. Anulează abonamentul sau așteaptă expirarea."
```

- [ ] **Step 3.6: Mapear el error en el cliente**

En los sitios que manejan errores de `removeMember` y `leaveHome` (probablemente en `lib/features/members/application/` y `lib/features/homes/application/`), si el error tiene `code == 'failed-precondition'` y el mensaje contiene `payer-cannot-leave-or-be-removed-while-premium-active`, mostrar `l10n.members_error_payer_locked` en el snackbar.

Busca los sitios:
```bash
grep -n "removeMember\|leaveHome" lib/features/members/application/ lib/features/homes/application/
```

En cada sitio que atrape el `FirebaseFunctionsException`, añadir:

```dart
if (e.code == 'failed-precondition' &&
    (e.message ?? '').contains('payer-cannot-leave-or-be-removed-while-premium-active')) {
  return l10n.members_error_payer_locked;
}
```

- [ ] **Step 3.7: Regenerar l10n**

```bash
flutter gen-l10n
```

Esperado: se regenera `lib/l10n/app_localizations*.dart` sin errores.

- [ ] **Step 3.8: Verificar build Flutter**

```bash
flutter analyze
```

Esperado: sin errores nuevos.

- [ ] **Step 3.9: Commit**

```bash
git add functions/src/homes/index.ts functions/src/homes/homes_callables.test.ts \
        lib/l10n/ lib/features/members/ lib/features/homes/
git commit -m "fix(security): proteger currentPayerUid frente a expulsion/salida"
```

---

### Task 4: Validar `newAssigneeUid` en `manualReassign`

**Files:**
- Modify: `functions/src/tasks/manual_reassign.ts`
- Create: `functions/src/tasks/manual_reassign.test.ts`

- [ ] **Step 4.1: Escribir test de validación**

Crear `functions/src/tasks/manual_reassign.test.ts`:

```typescript
describe("manualReassign — validación de newAssigneeUid", () => {
  type MemberDoc = { exists: boolean; status?: string };

  function validateNewAssignee(member: MemberDoc): { ok: boolean; code?: string } {
    if (!member.exists) return { ok: false, code: "new-assignee-not-in-home" };
    if (member.status !== "active") return { ok: false, code: "new-assignee-not-active" };
    return { ok: true };
  }

  it("miembro activo → ok", () => {
    expect(validateNewAssignee({ exists: true, status: "active" })).toEqual({ ok: true });
  });
  it("miembro inexistente → not-in-home", () => {
    const res = validateNewAssignee({ exists: false });
    expect(res.ok).toBe(false);
    expect(res.code).toBe("new-assignee-not-in-home");
  });
  it("miembro frozen → not-active", () => {
    const res = validateNewAssignee({ exists: true, status: "frozen" });
    expect(res.ok).toBe(false);
    expect(res.code).toBe("new-assignee-not-active");
  });
  it("miembro left → not-active", () => {
    const res = validateNewAssignee({ exists: true, status: "left" });
    expect(res.ok).toBe(false);
    expect(res.code).toBe("new-assignee-not-active");
  });
});
```

- [ ] **Step 4.2: Ejecutar test**

```bash
cd functions && npm test -- --testPathPattern=manual_reassign
```

Esperado: 4/4 pasan.

- [ ] **Step 4.3: Añadir validación en el handler**

En `functions/src/tasks/manual_reassign.ts`, dentro del `runTransaction`, tras obtener el `taskSnap` y antes del `tx.update(taskRef, ...)`:

```typescript
const newAssigneeRef = db
  .collection("homes")
  .doc(homeId)
  .collection("members")
  .doc(newAssigneeUid);
const newAssigneeSnap = await tx.get(newAssigneeRef);

if (!newAssigneeSnap.exists) {
  throw new HttpsError("not-found", "new-assignee-not-in-home");
}
const newAssigneeStatus = newAssigneeSnap.data()?.["status"] as string | undefined;
if (newAssigneeStatus !== "active") {
  throw new HttpsError("failed-precondition", "new-assignee-not-active");
}
```

- [ ] **Step 4.4: Build + tests**

```bash
cd functions && npm run build && npm test
```

Esperado: OK.

- [ ] **Step 4.5: Commit**

```bash
git add functions/src/tasks/manual_reassign.ts functions/src/tasks/manual_reassign.test.ts
git commit -m "fix(security): validar newAssigneeUid como miembro activo en manualReassign"
```

---

## BLOQUE 2 — AdMob real

### Task 5: Inicializar SDK + constantes compartidas (backend & cliente)

**Files:**
- Create: `functions/src/shared/ad_constants.ts`
- Modify: `lib/main.dart`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 5.1: Crear constantes compartidas en backend**

Crear `functions/src/shared/ad_constants.ts`:

```typescript
// Test unit IDs oficiales de Google AdMob.
// Seguros de usar en desarrollo — no generan revenue ni infracciones.
// TODO producción: reemplazar con unit IDs reales por plataforma antes de release.
export const TEST_BANNER_UNIT_ID_ANDROID = "ca-app-pub-3940256099942544/6300978111";
export const TEST_BANNER_UNIT_ID_IOS = "ca-app-pub-3940256099942544/2934735716";

// Por ahora Firestore guarda un único bannerUnit; el cliente override por plataforma.
export const DEFAULT_BANNER_UNIT_ID = TEST_BANNER_UNIT_ID_ANDROID;
```

- [ ] **Step 5.2: Inicializar MobileAds en `main.dart`**

En `lib/main.dart`, tras el `Firebase.initializeApp(...)` y antes de otras inicializaciones de Remote Config / Crashlytics:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ... dentro de main() ...

await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// Inicializar AdMob. No bloquea la UI más de ~100ms y permite que los
// BannerAd se carguen correctamente en cuanto se construya la primera pantalla.
unawaited(MobileAds.instance.initialize());
```

Importar `dart:async` para `unawaited` si no está.

- [ ] **Step 5.3: Añadir `GADApplicationIdentifier` a iOS**

En `ios/Runner/Info.plist`, dentro del `<dict>` raíz, añadir:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

(Este es el App ID de test de iOS. Android ya está configurado en `AndroidManifest.xml`.)

- [ ] **Step 5.4: Verificar build Flutter**

```bash
flutter analyze
```

Esperado: sin errores nuevos.

- [ ] **Step 5.5: Commit**

```bash
git add functions/src/shared/ad_constants.ts lib/main.dart ios/Runner/Info.plist
git commit -m "feat(admob): inicializar SDK + constantes de test unit IDs"
```

---

### Task 6: Sincronizar `adFlags` desde backend

**Files:**
- Modify: `functions/src/entitlement/sync_entitlement.ts`
- Modify: `functions/src/entitlement/apply_downgrade_plan.ts`
- Modify: `functions/src/jobs/restore_premium_state.ts`

- [ ] **Step 6.1: Actualizar `sync_entitlement.ts`**

En `functions/src/entitlement/sync_entitlement.ts`, localiza el bloque que actualiza `premiumFlags` en `homes/{homeId}/views/dashboard`. Añade en el MISMO `set` el campo `adFlags`:

```typescript
import { DEFAULT_BANNER_UNIT_ID } from "../shared/ad_constants";

// ... dentro del update del dashboard, junto a premiumFlags ...
await dashRef.set(
  {
    premiumFlags: {
      isPremium,
      showAds: !isPremium,
      canUseSmartDistribution: isPremium,
      canUseVacations: isPremium,
      canUseReviews: isPremium,
    },
    adFlags: {
      showBanner: !isPremium,
      bannerUnit: isPremium ? "" : DEFAULT_BANNER_UNIT_ID,
    },
  },
  { merge: true }
);
```

- [ ] **Step 6.2: Actualizar `apply_downgrade_plan.ts`**

En `functions/src/entitlement/apply_downgrade_plan.ts`, donde se escribe `premiumFlags: { isPremium: false, showAds: true, ... }`, añadir `adFlags` en el mismo `batch.set` o `batch.update`:

```typescript
import { DEFAULT_BANNER_UNIT_ID } from "../shared/ad_constants";

// ... junto al premiumFlags existente ...
adFlags: {
  showBanner: true,
  bannerUnit: DEFAULT_BANNER_UNIT_ID,
},
```

- [ ] **Step 6.3: Actualizar `restore_premium_state.ts`**

En `functions/src/jobs/restore_premium_state.ts`, donde se escribe `premiumFlags: { isPremium: true, showAds: false, ... }`, añadir:

```typescript
adFlags: {
  showBanner: false,
  bannerUnit: "",
},
```

- [ ] **Step 6.4: Build**

```bash
cd functions && npm run build && npm test
```

Esperado: `tsc` OK, tests existentes pasan.

- [ ] **Step 6.5: Commit**

```bash
git add functions/src/entitlement/sync_entitlement.ts \
        functions/src/entitlement/apply_downgrade_plan.ts \
        functions/src/jobs/restore_premium_state.ts
git commit -m "feat(admob): sincronizar adFlags en backend junto a premiumFlags"
```

---

### Task 7: Crear provider `adBannerConfig`

**Files:**
- Create: `lib/shared/widgets/ad_banner_config_provider.dart`

- [ ] **Step 7.1: Crear el provider**

Crear `lib/shared/widgets/ad_banner_config_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';

part 'ad_banner_config_provider.g.dart';

class AdBannerConfig {
  const AdBannerConfig({required this.show, required this.unitId});
  final bool show;
  final String unitId;
}

@Riverpod(keepAlive: true)
AdBannerConfig adBannerConfig(AdBannerConfigRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  return AdBannerConfig(
    show: dashboard?.adFlags.showBanner ?? false,
    unitId: dashboard?.adFlags.bannerUnit ?? '',
  );
}
```

Nota: si el package name no es `toka`, ajusta el import según `pubspec.yaml`.

- [ ] **Step 7.2: Generar código Riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Esperado: se genera `ad_banner_config_provider.g.dart`.

- [ ] **Step 7.3: Commit**

```bash
git add lib/shared/widgets/ad_banner_config_provider.dart \
        lib/shared/widgets/ad_banner_config_provider.g.dart
git commit -m "feat(admob): provider adBannerConfig derivado del dashboard"
```

---

### Task 8: Crear widget `AdBanner`

**Files:**
- Create: `lib/shared/widgets/ad_banner.dart`
- Create: `test/unit/shared/widgets/ad_banner_test.dart`

- [ ] **Step 8.1: Escribir test del widget**

Crear `test/unit/shared/widgets/ad_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

void main() {
  testWidgets('AdBanner renderiza SizedBox.shrink cuando show=false', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adBannerConfigProvider.overrideWithValue(
            const AdBannerConfig(show: false, unitId: 'x'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdBanner())),
      ),
    );
    expect(find.byType(SizedBox), findsWidgets);
    // No hay AdWidget en el árbol cuando show=false.
  });

  testWidgets('AdBanner renderiza SizedBox.shrink cuando unitId vacío', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adBannerConfigProvider.overrideWithValue(
            const AdBannerConfig(show: true, unitId: ''),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdBanner())),
      ),
    );
    expect(find.byType(SizedBox), findsWidgets);
  });
}
```

- [ ] **Step 8.2: Crear `ad_banner.dart`**

Crear `lib/shared/widgets/ad_banner.dart`:

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_banner_config_provider.dart';

// Test unit IDs oficiales de Google. Nunca generan revenue y son seguros
// de usar en dev. En producción se sobreescriben por el unitId del dashboard.
const String _kTestBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
const String _kTestBanneriOS = 'ca-app-pub-3940256099942544/2934735716';

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  String _effectiveUnitId(String fromServer) {
    if (kDebugMode) {
      return Platform.isIOS ? _kTestBanneriOS : _kTestBannerAndroid;
    }
    if (fromServer.isEmpty) {
      return Platform.isIOS ? _kTestBanneriOS : _kTestBannerAndroid;
    }
    return fromServer;
  }

  void _loadBanner(String unitId) {
    _banner?.dispose();
    _banner = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _banner = null;
            _loaded = false;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(adBannerConfigProvider);

    if (!config.show || config.unitId.isEmpty) {
      return const SizedBox.shrink();
    }

    final effective = _effectiveUnitId(config.unitId);
    if (_banner == null) {
      _loadBanner(effective);
    }

    if (!_loaded || _banner == null) {
      return const SizedBox(height: 50); // reserva espacio equivalente al banner
    }

    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
```

- [ ] **Step 8.3: Ejecutar tests**

```bash
flutter test test/unit/shared/widgets/ad_banner_test.dart
```

Esperado: 2/2 pasan.

- [ ] **Step 8.4: `flutter analyze`**

```bash
flutter analyze lib/shared/widgets/
```

Esperado: sin errores.

- [ ] **Step 8.5: Commit**

```bash
git add lib/shared/widgets/ad_banner.dart test/unit/shared/widgets/ad_banner_test.dart
git commit -m "feat(admob): widget AdBanner compartido con BannerAd real"
```

---

### Task 9: Integrar `AdBanner` en Today

**Files:**
- Modify: `lib/features/tasks/presentation/today_screen.dart`

- [ ] **Step 9.1: Reemplazar `_AdBannerPlaceholder`**

En `lib/features/tasks/presentation/today_screen.dart`, localizar `_AdBannerPlaceholder` (L139-154) y el sitio donde se usa (~L124-129). Eliminar la clase `_AdBannerPlaceholder`. En el sitio de uso reemplazar:

```dart
if (data.showAdBanner) _AdBannerPlaceholder(...)
```

por:

```dart
const AdBanner(),
```

Añadir import:

```dart
import 'package:toka/shared/widgets/ad_banner.dart';
```

Asegurarse de que `AdBanner` está en un `Column` con `Expanded` envolviendo la lista scrollable, para que el banner quede siempre visible al pie y el último item del scroll no quede oculto. Si la estructura ya es `Column`, simplemente añadir `AdBanner` como último hijo.

- [ ] **Step 9.2: Verificar con analyze**

```bash
flutter analyze lib/features/tasks/presentation/today_screen.dart
```

Esperado: sin errores.

- [ ] **Step 9.3: Commit**

```bash
git add lib/features/tasks/presentation/today_screen.dart
git commit -m "feat(admob): integrar AdBanner en Today y eliminar placeholder"
```

---

### Task 10: Integrar `AdBanner` en All Tasks (v1 y v2)

**Files:**
- Modify: `lib/features/tasks/presentation/all_tasks_screen.dart`
- Modify: `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart`

- [ ] **Step 10.1: Envolver `ListView` en `Column` + `Expanded` + `AdBanner` (v1)**

En `lib/features/tasks/presentation/all_tasks_screen.dart`, localizar el `ListView` del contenido. Si el `body` del Scaffold es directamente el `ListView`, cambiarlo a:

```dart
body: Column(
  children: [
    Expanded(child: /* ListView existente */),
    const AdBanner(),
  ],
),
```

Añadir import `package:toka/shared/widgets/ad_banner.dart`.

- [ ] **Step 10.2: Mismo cambio en v2**

En `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart`, mismo patrón. Añadir `AdBanner` al pie del `Column` que envuelve la lista.

- [ ] **Step 10.3: Analyze**

```bash
flutter analyze lib/features/tasks/presentation/
```

Esperado: sin errores.

- [ ] **Step 10.4: Commit**

```bash
git add lib/features/tasks/presentation/all_tasks_screen.dart \
        lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart
git commit -m "feat(admob): integrar AdBanner al pie de All Tasks (v1 y v2)"
```

---

### Task 11: Upsell diferido + `AdBanner` en Historial

**Files:**
- Modify: `lib/features/history/presentation/history_screen.dart`

- [ ] **Step 11.1: Refactorizar estructura a Column + Expanded**

En `lib/features/history/presentation/history_screen.dart`, localizar la sección del `body` (Column con filter chips + Expanded con ListView.builder). El cambio consiste en:

1. Sacar el `_PremiumBanner` del `itemBuilder` del `ListView`.
2. Dejar que el upsell se añada como último item del `ListView` solo cuando se cumpla la regla.
3. Añadir `AdBanner` como hermano debajo del `Expanded`, fuera del scroll.

Código nuevo para el body (mantén imports, controllers, etc. existentes):

```dart
Column(
  children: [
    HistoryFilterChips(
      current: vm.activeFilter,
      onChanged: (f) => vm.applyFilter(f),
    ),
    Expanded(
      child: vm.items.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (items) {
          if (items.isEmpty) {
            return const HistoryEmptyState();
          }
          final isPremium = vm.isPremium;
          final showLoadMore = vm.hasMore;

          return LayoutBuilder(
            builder: (context, constraints) {
              const kHistoryItemApproxHeight = 88.0;
              final visibleCount =
                  (constraints.maxHeight / kHistoryItemApproxHeight).floor();
              final hiddenCount = items.length - visibleCount;
              final showUpsell = !isPremium && hiddenCount >= 5;

              final extraItems =
                  (showUpsell ? 1 : 0) + (showLoadMore ? 1 : 0);

              return ListView.builder(
                key: const Key('history_list'),
                controller: _scrollController,
                itemCount: items.length + extraItems,
                itemBuilder: (context, index) {
                  if (index < items.length) {
                    return _buildEventTile(items[index]);
                  }
                  final extra = index - items.length;
                  if (showUpsell && extra == 0) {
                    return _PremiumBanner(l10n: l10n);
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: TextButton(
                        key: const Key('btn_load_more'),
                        onPressed: () =>
                            ref.read(historyViewModelProvider).loadMore(),
                        child: Text(l10n.history_load_more),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ),
    const AdBanner(),
  ],
)
```

Añadir import `package:toka/shared/widgets/ad_banner.dart`.

- [ ] **Step 11.2: Analyze**

```bash
flutter analyze lib/features/history/presentation/history_screen.dart
```

Esperado: sin errores.

- [ ] **Step 11.3: Commit**

```bash
git add lib/features/history/presentation/history_screen.dart
git commit -m "feat(admob): upsell diferido + AdBanner al pie en Historial"
```

---

### Task 12: Integrar `AdBanner` en pantallas de Miembros

**Files:**
- Modify: pantallas que listan miembros en `lib/features/members/presentation/`

- [ ] **Step 12.1: Localizar las pantallas con lista de miembros**

```bash
grep -rn "ListView" lib/features/members/presentation/ | head -20
```

Identificar cada pantalla con lista scrollable de miembros (probablemente `members_screen.dart` y su variante `skins/members_screen_v2.dart`).

- [ ] **Step 12.2: Aplicar el patrón Column + Expanded + AdBanner**

Para cada pantalla encontrada, envolver el `ListView` en `Expanded` dentro de un `Column` y añadir `const AdBanner()` al pie.

Añadir import `package:toka/shared/widgets/ad_banner.dart`.

No tocar `member_profile_screen` ni similares — son pantallas de detalle, no listas.

- [ ] **Step 12.3: Analyze**

```bash
flutter analyze lib/features/members/presentation/
```

Esperado: sin errores.

- [ ] **Step 12.4: Commit**

```bash
git add lib/features/members/presentation/
git commit -m "feat(admob): integrar AdBanner en pantallas de Miembros"
```

---

## BLOQUE 3 — Code quality

### Task 13: `new Date()` → `Timestamp.now()` en functions

**Files:**
- Modify: `functions/src/homes/index.ts` (L192, L269)
- Modify: `functions/src/jobs/process_expired_tasks.ts` (L49)
- Modify: `functions/src/notifications/dispatch_due_reminders.ts` (L16)
- Modify: `functions/src/tasks/apply_task_completion.ts` (L78, L115)
- Modify: `functions/src/tasks/update_dashboard.ts` (L60)

- [ ] **Step 13.1: Reemplazar ocurrencias**

En cada archivo listado, sustituir las comparaciones de tipo:

```typescript
if (expiresAt && new Date() > expiresAt) { ... }
```

por:

```typescript
if (expiresAt && admin.firestore.Timestamp.now().toDate() > expiresAt) { ... }
```

Verifica que `admin` (`firebase-admin`) está importado; si no, añadir:

```typescript
import * as admin from "firebase-admin";
```

**Importante:** no cambiar comparaciones donde `new Date()` sirve para generar un timestamp de *escritura* a Firestore (esos deben usar `FieldValue.serverTimestamp()` si aún no lo hacen, pero ese es otro cambio). Solo tocar comparaciones de momento actual.

- [ ] **Step 13.2: Build + tests**

```bash
cd functions && npm run build && npm test
```

Esperado: OK.

- [ ] **Step 13.3: Commit**

```bash
git add functions/src/
git commit -m "refactor(functions): usar Timestamp.now() en comparaciones de tiempo"
```

---

### Task 14: Rutas hardcodeadas → `AppRoutes`

**Files:**
- Modify: `lib/features/tasks/presentation/task_detail_screen.dart:91`
- Modify: `lib/features/tasks/presentation/all_tasks_screen.dart:174`
- Modify: `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart:151`
- Modify: `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart:78`

- [ ] **Step 14.1: `task_detail_screen.dart:91`**

Reemplazar:

```dart
context.push('/task/$taskId/edit')
```

por:

```dart
context.push(AppRoutes.editTask.replaceAll(':id', taskId))
```

Añadir import si falta:

```dart
import 'package:toka/core/constants/routes.dart';
```

- [ ] **Step 14.2: `all_tasks_screen.dart:174`**

Reemplazar:

```dart
context.go('/task/${task.id}')
```

por:

```dart
context.go(AppRoutes.taskDetail.replaceAll(':id', task.id))
```

- [ ] **Step 14.3: `all_tasks_screen_v2.dart:151`**

Reemplazar:

```dart
context.push('/tasks/${task.id}')
```

por:

```dart
context.push(AppRoutes.taskDetail.replaceAll(':id', task.id))
```

- [ ] **Step 14.4: `task_detail_screen_v2.dart:78`**

Reemplazar:

```dart
context.push('/tasks/${task.id}/edit')
```

por:

```dart
context.push(AppRoutes.editTask.replaceAll(':id', task.id))
```

- [ ] **Step 14.5: Analyze + smoke tests**

```bash
flutter analyze
flutter test test/unit/ test/ui/
```

Esperado: sin errores; tests de navegación (si existen) pasan.

- [ ] **Step 14.6: Commit**

```bash
git add lib/features/tasks/
git commit -m "refactor(routes): centralizar rutas de tasks via AppRoutes"
```

---

### Task 15: Extraer `buildNewMemberDoc`

**Files:**
- Create: `functions/src/homes/member_factory.ts`
- Create: `functions/src/homes/member_factory.test.ts`
- Modify: `functions/src/homes/index.ts`

- [ ] **Step 15.1: Escribir test del factory**

Crear `functions/src/homes/member_factory.test.ts`:

```typescript
import { buildNewMemberDoc, type NewMemberRole } from "./member_factory";

describe("buildNewMemberDoc", () => {
  const base = {
    uid: "u1",
    nickname: "Alice",
    role: "member" as NewMemberRole,
  };

  it("genera campos default correctos", () => {
    const doc = buildNewMemberDoc(base);
    expect(doc["uid"]).toBe("u1");
    expect(doc["nickname"]).toBe("Alice");
    expect(doc["role"]).toBe("member");
    expect(doc["status"]).toBe("active");
    expect(doc["tasksCompleted"]).toBe(0);
    expect(doc["passedCount"]).toBe(0);
    expect(doc["complianceRate"]).toBe(1.0);
    expect(doc["currentStreak"]).toBe(0);
    expect(doc["averageScore"]).toBe(0);
    expect(doc["phoneVisibility"]).toBe("hidden");
  });

  it("incluye opcionales si se proporcionan", () => {
    const doc = buildNewMemberDoc({
      ...base,
      photoUrl: "https://x.y/p.jpg",
      phone: "+34600111222",
      bio: "Hola",
    });
    expect(doc["photoUrl"]).toBe("https://x.y/p.jpg");
    expect(doc["phone"]).toBe("+34600111222");
    expect(doc["bio"]).toBe("Hola");
  });

  it("role owner se preserva", () => {
    const doc = buildNewMemberDoc({ ...base, role: "owner" });
    expect(doc["role"]).toBe("owner");
  });
});
```

- [ ] **Step 15.2: Crear el factory**

Crear `functions/src/homes/member_factory.ts`:

```typescript
import { FieldValue } from "firebase-admin/firestore";

export type NewMemberRole = "owner" | "admin" | "member";

export interface NewMemberParams {
  uid: string;
  nickname: string;
  role: NewMemberRole;
  photoUrl?: string;
  phone?: string;
  bio?: string;
}

export function buildNewMemberDoc(p: NewMemberParams): Record<string, unknown> {
  return {
    uid: p.uid,
    nickname: p.nickname,
    role: p.role,
    status: "active",
    photoUrl: p.photoUrl ?? null,
    phone: p.phone ?? null,
    bio: p.bio ?? null,
    phoneVisibility: "hidden",
    tasksCompleted: 0,
    passedCount: 0,
    complianceRate: 1.0,
    currentStreak: 0,
    averageScore: 0,
    joinedAt: FieldValue.serverTimestamp(),
  };
}
```

**IMPORTANTE:** antes de reemplazar en `index.ts`, abre los 3 sitios actuales (`createHome` L79-93, `joinHome` L215-233, `joinHomeByCode` L308-326) y compara los campos que escriben hoy con los que produce `buildNewMemberDoc`. Si detectas un campo adicional que ya se guarda (ej. `invitedBy`, `homeId`, un timestamp extra), añádelo al interface `NewMemberParams` y al retorno del factory. No elimines silenciosamente ningún campo.

- [ ] **Step 15.3: Ejecutar tests**

```bash
cd functions && npm test -- --testPathPattern=member_factory
```

Esperado: 3/3 pasan.

- [ ] **Step 15.4: Reemplazar en `createHome`**

En `functions/src/homes/index.ts`, localizar el bloque L79-93 donde se construye el objeto del owner. Reemplazar por:

```typescript
import { buildNewMemberDoc } from "./member_factory";

// ...
const ownerDoc = buildNewMemberDoc({
  uid,
  nickname: ownerNickname,
  role: "owner",
  photoUrl: ownerPhotoUrl,
});
```

Luego `tx.set(ownerMemberRef, ownerDoc)`.

- [ ] **Step 15.5: Reemplazar en `joinHome`**

En el bloque L215-233, reemplazar por:

```typescript
const memberDoc = buildNewMemberDoc({
  uid,
  nickname,
  role: "member",
  photoUrl,
});
```

- [ ] **Step 15.6: Reemplazar en `joinHomeByCode`**

En el bloque L308-326, ídem:

```typescript
const memberDoc = buildNewMemberDoc({
  uid,
  nickname,
  role: "member",
  photoUrl,
});
```

- [ ] **Step 15.7: Build + tests completos**

```bash
cd functions && npm run build && npm test
```

Esperado: todos los tests pasan (nuevos + los de `homes_callables.test.ts` existentes).

- [ ] **Step 15.8: Commit**

```bash
git add functions/src/homes/member_factory.ts \
        functions/src/homes/member_factory.test.ts \
        functions/src/homes/index.ts
git commit -m "refactor(functions): extraer buildNewMemberDoc para createHome/joinHome"
```

---

## Verificación final

### Task 16: Smoke test end-to-end

- [ ] **Step 16.1: Tests completos del cliente**

```bash
flutter analyze
flutter test
```

Esperado: sin errores ni tests fallando.

- [ ] **Step 16.2: Tests completos del backend**

```bash
cd functions && npm run build && npm test
```

Esperado: `tsc` OK, todos los tests pasan.

- [ ] **Step 16.3: Smoke manual en emulador Android**

```bash
# Asegúrate de que los emuladores de Firebase están corriendo
firebase emulators:start --import=./emulator-data --export-on-exit &

# Lanza la app en el emulador de Android (identificado como emulator-5554)
flutter run -d emulator-5554
```

Pasos a verificar visualmente:
1. **Login** con `toka.qa.owner@gmail.com / TokaQA2024!` (ver CLAUDE.md para coords exactas).
2. En la pantalla **Hoy**: banner AdMob de test (texto "Test Ad" de Google) visible abajo si el hogar es free.
3. En **Tareas** (all_tasks): banner AdMob visible al pie.
4. En **Historial**: banner AdMob al pie. Si hay >14 eventos, tras scrollear aparece el `_PremiumBanner` promocional como último item, **encima** del AdBanner.
5. En **Miembros**: banner AdMob al pie.
6. Toggle a premium desde Ajustes → Debug premium toggle: banners AdMob desaparecen; upsell de History también.
7. Crear dos hogares y verificar que invitar a un miembro sigue funcionando.

Capturar screenshot al menos de Hoy-free, Hoy-premium y Historial-free.

```bash
adb exec-out screencap -p > /tmp/today-free.png
# ... etc
```

- [ ] **Step 16.4: Capa manual no automatizable**

No podemos automatizar estos en esta sesión; deja anotado en el PR:

```markdown
## Pruebas manuales requeridas

- [ ] `debugSetPremiumStatus` desde producción (no emulador) debe fallar con "permission-denied".
- [ ] Expulsar al `currentPayerUid` con premium activo muestra snackbar con `members_error_payer_locked`.
- [ ] Salir del hogar como `currentPayerUid` con premium activo muestra el mismo error.
- [ ] `manualReassign` con UID inválido devuelve error visible al usuario.
- [ ] Ads de test aparecen en free y desaparecen al activar premium (verificado en paso 16.3).
```

- [ ] **Step 16.5: Commit final (si hay cambios de smoke)**

Si durante el smoke encuentras algún archivo a ajustar (padding de los banners, orden de items, etc.), hacer un commit separado:

```bash
git add <archivos>
git commit -m "chore(admob): ajustes menores tras smoke test"
```

---

## Checklist de cierre

- [ ] Todos los tests pasan (`flutter test` y `cd functions && npm test`).
- [ ] `flutter analyze` sin errores.
- [ ] `tsc` sin errores en functions.
- [ ] Todos los commits tienen mensajes descriptivos y están firmados con `Co-Authored-By`.
- [ ] El bloque "Pruebas manuales requeridas" está al final del PR.

---

## Out of scope (para siguiente tanda)

Recordatorio — NO incluidos en este plan, requieren decisiones previas:

- Validación real de recibos IAP vs App Store Connect / Google Play Developer API.
- Cerrar `allow read: if isAuth()` sobre `/users/{uid}` y migrar a subdocumento público.
- Rate limiting en callables.
- Whitelist de campos (`hasOnly`) en Firestore rules.
- Deprecar una de las dos versiones de skins (v1 o v2).
- Eliminar `_buildReceiptData` del cliente (depende de la validación server-side).
- Unit IDs de producción AdMob (alta en AdMob + configuración por plataforma).
