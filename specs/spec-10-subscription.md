# Spec-10: Suscripción Premium, rescate, downgrade y restauración

**Dependencias previas:** Spec-00 → Spec-09  
**Oleada:** Oleada 3

---

## Objetivo

Implementar el sistema completo de monetización freemium: compra de Premium (mensual/anual), sincronización de entitlement desde las stores, flujo de rescate (3 días antes de expirar), downgrade controlado (manual o automático), congelación de extras y restauración en ventana de 30 días.

---

## Precios

| Plan            | Precio        | ID producto            |
| --------------- | ------------- | ---------------------- |
| Premium mensual | 3,99 EUR/mes  | `toka_premium_monthly` |
| Premium anual   | 29,99 EUR/año | `toka_premium_annual`  |

---

## Estados del hogar respecto a Premium

| Estado                  | Descripción                                         |
| ----------------------- | --------------------------------------------------- |
| `free`                  | Plan gratuito, sin Premium activo                   |
| `active`                | Premium vigente y renovación activa                 |
| `cancelled_pending_end` | Cancelado pero sigue activo hasta `premiumEndsAt`   |
| `rescue`                | Faltan ≤3 días para `premiumEndsAt`, sin renovación |
| `expired_free`          | Premium terminó, operando como Free                 |
| `restorable`            | Extras congelados, dentro de ventana de 30 días     |
| `purged`                | Pasaron 30 días, extras ya no restaurables          |

---

## Archivos a crear

```
lib/features/subscription/
├── data/
│   └── subscription_repository_impl.dart
├── domain/
│   ├── subscription_repository.dart
│   ├── subscription_state.dart        (modelo freezed)
│   └── purchase_result.dart
├── application/
│   ├── subscription_provider.dart
│   └── paywall_provider.dart
└── presentation/
    ├── paywall_screen.dart
    ├── subscription_management_screen.dart
    ├── rescue_screen.dart
    ├── downgrade_planner_screen.dart
    └── widgets/
        ├── premium_feature_gate.dart   (wrapper para features Premium)
        ├── rescue_banner.dart
        └── plan_comparison_card.dart

functions/src/entitlement/
├── sync_entitlement.ts              (Callable + webhook de store)
├── open_rescue_window.ts            (Job programado)
└── apply_downgrade_plan.ts          (Job programado)

functions/src/jobs/
├── purge_expired_frozen.ts          (Job: 30 días post-downgrade)
└── restore_premium_state.ts         (Callable)
```

---

## Implementación

### syncEntitlementFromStore (Callable Function)

```typescript
export const syncEntitlement = functions.https.onCall(async (data, context) => {
  const { homeId, receiptData, platform } = data;
  const uid = context.auth?.uid;

  // 1. Validar recibo con Apple/Google
  // 2. Determinar estado: active, cancelled, expired
  // 3. Actualizar homes/{homeId}:
  //    premiumStatus, premiumPlan, premiumEndsAt, autoRenewEnabled
  //    currentPayerUid = uid
  // 4. Guardar en homes/{homeId}/subscriptions/history/{chargeId}
  // 5. Si es un cobro válido nuevo → incrementar lifetimeUnlockedHomeSlots en users/{uid}
  //    (máx 3 créditos extra)
  // 6. Actualizar dashboard.premiumFlags
});
```

### Desbloqueo de plazas permanentes

```typescript
async function unlockSlotIfEligible(
  uid: string,
  chargeId: string,
): Promise<void> {
  // Verificar que este chargeId no se ha procesado antes (idempotencia)
  // Verificar que el cobro es válido (validForUnlock = true)
  // Verificar que lifetimeUnlockedHomeSlots < 3
  // Si todo ok: incrementar lifetimeUnlockedHomeSlots, homeSlotCap
  // Guardar en users/{uid}/slotLedger/{unlockId}
}
```

### openRescueWindow (Job cron — 3 días antes de premiumEndsAt)

```typescript
// Ejecutar diariamente a las 09:00
export const openRescueWindowJob = functions.pubsub
  .schedule("0 9 * * *")
  .onRun(async () => {
    const threeDaysFromNow = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);

    // Buscar hogares donde premiumEndsAt <= threeDaysFromNow
    // AND premiumStatus = 'cancelled_pending_end'
    // AND rescueFlags.isInRescue = false

    // Para cada hogar:
    // 1. Actualizar premiumStatus = 'rescue'
    // 2. Actualizar dashboard.rescueFlags
    // 3. Enviar notificaciones push a owner, pagador y miembros
  });
```

### applyDowngradePlan (Job cron — ejecutar en premiumEndsAt)

```typescript
export const applyDowngradeJob = functions.pubsub
  .schedule("*/30 * * * *")
  .onRun(async () => {
    // Buscar hogares donde premiumEndsAt <= now
    // AND premiumStatus IN ['rescue', 'cancelled_pending_end']
    // Para cada hogar:
    // 1. Leer homes/{homeId}/downgrade/current
    // 2. Si existe plan manual → aplicarlo
    // 3. Si no → aplicar selección automática
    // 4. Congelar miembros excedentes
    // 5. Congelar tareas excedentes
    // 6. Actualizar premiumStatus = 'expired_free' o 'restorable'
    // 7. Establecer restoreUntil = now + 30 days
    // 8. Actualizar limits del hogar a límites Free
    // 9. Actualizar dashboard
  });
```

### Selección automática al downgrade

```typescript
function autoSelectForDowngrade(
  members: Member[],
  tasks: Task[],
  ownerId: string,
) {
  // Miembros: owner siempre + los más participativos (completions60d)
  // Tareas: las 4 con más completedCount90d

  const sortedMembers = members
    .filter((m) => m.uid !== ownerId && m.status === "active")
    .sort((a, b) => {
      if (b.completions60d !== a.completions60d)
        return b.completions60d - a.completions60d;
      if (b.lastCompletedAt && a.lastCompletedAt) {
        return b.lastCompletedAt.seconds - a.lastCompletedAt.seconds;
      }
      return a.joinedAt.seconds - b.joinedAt.seconds; // más antiguo gana
    });

  const selectedMemberIds = [
    ownerId,
    ...sortedMembers.slice(0, 2).map((m) => m.uid),
  ];

  const sortedTasks = tasks
    .filter((t) => t.status === "active")
    .sort((a, b) => {
      if (b.completedCount90d !== a.completedCount90d)
        return b.completedCount90d - a.completedCount90d;
      return a.nextDueAt.seconds - b.nextDueAt.seconds;
    });

  const selectedTaskIds = sortedTasks.slice(0, 4).map((t) => t.id);

  return { selectedMemberIds, selectedTaskIds, mode: "auto" };
}
```

### Pantalla Paywall

```dart
// paywall_screen.dart
// Diseño visual atractivo con:
// - Comparativa Free vs Premium (tabla)
// - Precio mensual y anual con ahorro destacado
// - Lista de features Premium
// - Botón principal "Empezar Premium" (anual por defecto)
// - Botón secundario "Plan mensual"
// - Link "Restaurar compras"
// - Link "Ver términos y política de privacidad"
// - Remote Config controla qué plan se ofrece primero
```

### RescueBanner

```dart
// Aparece en la cabecera del hogar si premiumStatus == 'rescue'
// "⚠️ Premium expira en X días · [Renovar]"
// Solo visible para owner y pagador actual
```

### DowngradePlannerScreen

```dart
// Accesible durante el estado 'rescue'
// Solo para el owner
// Secciones:
// - "¿Qué miembros continuarán?" (checkboxes, máx 3, owner siempre marcado)
// - "¿Qué tareas continuarán?" (checkboxes, máx 4)
// - "¿Qué admin se mantiene?" (radio button)
// - "¿Congelar al pagador actual?" (si es distinto del owner)
// - Botón "Guardar plan"
// - Información: "Si no decides, se aplicará selección automática"
```

### PremiumFeatureGate

```dart
// Widget wrapper que muestra un candado y prompt de upgrade
// si el hogar no tiene Premium y el feature requiere Premium
class PremiumFeatureGate extends ConsumerWidget {
  final Widget child;
  final bool requiresPremium;
  final String featureName;
  // Si requiresPremium y !isPremium → muestra overlay de upgrade
}
```

---

## Tests requeridos

### Unitarios

- `autoSelectForDowngrade` con 5 miembros → selecciona owner + 2 más participativos.
- `autoSelectForDowngrade` desempate por `lastCompletedAt` y antigüedad.
- `autoSelectForDowngrade` con 6 tareas → selecciona las 4 con más completados.
- `unlockSlotIfEligible` no desbloquea si `lifetimeUnlockedHomeSlots >= 3`.
- `unlockSlotIfEligible` no desbloquea si el chargeId ya fue procesado (idempotencia).

### De integración (emuladores)

- Compra válida → `premiumStatus = 'active'`, `premiumEndsAt` seteado.
- Compra reembolsada → `validForUnlock = false`, plaza no desbloqueada.
- `openRescueWindow` con hogar a 2 días → cambia a `rescue`.
- `applyDowngrade` con plan manual → congela los miembros y tareas seleccionados.
- `applyDowngrade` sin plan manual → aplica selección automática.
- Restaurar Premium dentro de 30 días → todos los extras descongelados.
- Restaurar después de 30 días → error, ya fue `purged`.

### UI

- Paywall muestra precios correctos desde Remote Config.
- RescueBanner visible para owner con días restantes.
- DowngradePlannerScreen: no permite deseleccionar al owner.
- DowngradePlannerScreen: no permite seleccionar más de 3 miembros.
- PremiumFeatureGate: en Free, muestra overlay de upgrade.
- Golden tests de Paywall y RescueBanner.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Compra mensual (sandbox):** En iOS/Android sandbox, comprar plan mensual → `premiumStatus` cambia a `active` en Firestore.
2. **Cancelar suscripción:** Cancelar desde la store → `autoRenewEnabled = false`, `premiumStatus = 'cancelled_pending_end'`.
3. **Simular rescate:** Modificar `premiumEndsAt` a 2 días desde ahora en Firestore emulador → ejecutar `openRescueWindow` manualmente → banner aparece.
4. **Downgrade manual:** En estado rescue, ir a "Planear downgrade" → seleccionar 2 miembros y 3 tareas → guardar → esperar a `premiumEndsAt` → verificar que los extras congelados son los correctos.
5. **Downgrade automático:** No definir plan → forzar `premiumEndsAt` → verificar que la selección automática elige a los más participativos.
6. **Restauración en 30 días:** Downgrade → reactivar Premium dentro de los 30 días → verificar que los congelados se descongelan instantáneamente.
7. **Restauración fuera de plazo:** Downgrade → esperar >30 días (simular en emulador) → intentar restaurar → error explicativo.
8. **Desbloqueo de plazas:** Hacer primera compra Premium → `lifetimeUnlockedHomeSlots` pasa de 0 a 1, `homeSlotCap` de 2 a 3.
9. **Feature gate:** En Free, intentar usar rotación inteligente → aparece overlay de upgrade.
