# Spec: Rebuild de la pantalla Suscripción y fix de refresh en estados premium

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Alta (BUG-11, BUG-12, BUG-13)

---

## Contexto

La pantalla *Ajustes → Gestionar suscripción* ([lib/features/subscription/presentation/subscription_management_screen.dart](lib/features/subscription/presentation/subscription_management_screen.dart)) presenta tres problemas detectados en QA 2026-04-20:

- **BUG-11:** el bloque "Tu suscripción" está vacío en hogares Free: no dice nada del plan actual, precio, fecha de renovación o caducidad. El usuario no puede deducir en qué estado está.
- **BUG-12:** tras un force-stop o tras invocar `debugSetPremiumStatus` desde otro contexto, la pantalla muestra información obsoleta hasta un pull-to-refresh manual. El dashboard se actualiza en Firestore pero la pantalla no relee.
- **BUG-13:** los switches de "Notificaciones por tipo" en la pantalla de notificaciones aparecen deshabilitados en hogares Premium hasta reabrir la pantalla. Falla de carga del estado.

Esta spec no rediseña el paywall ni los flujos de compra (fuera de alcance). Sólo limpia la pantalla de gestión y el refresh de estado premium.

---

## Decisiones clave

- **La pantalla Suscripción se convierte en un `StreamProvider` que escucha el dashboard del hogar actual.** Cualquier cambio de `premiumStatus` se propaga automáticamente — resuelve BUG-12 sin necesidad de pull-to-refresh.
- **Contenido visible siempre,** tanto en Free como en cualquier estado Premium. Nunca debe quedar un bloque vacío.
- **Los toggles de notificaciones** dependen únicamente de `notificationPrefs` en el usuario, no del premium status. Si BUG-13 era por un `async` mal orquestado, se arregla reescribiendo el ViewModel con `StreamProvider`.

---

## Estructura nueva de la pantalla

Contenido por estado:

| Estado premium        | Sección principal                                                             | CTA primario              | CTA secundario           |
| --------------------- | ----------------------------------------------------------------------------- | ------------------------- | ------------------------ |
| `free`                | "Plan Free" + lista de 4 beneficios premium + contador de uso (3/3 miembros...) | "Hazte Premium" → paywall | —                        |
| `active`              | Plan contratado + precio + próxima renovación + pagador                       | "Gestionar facturación" → Play Store | "Cancelar renovación"   |
| `cancelledPendingEnd` | "Premium hasta el DD/MM/YYYY" + "No se renovará automáticamente"              | "Reactivar renovación"    | "Cambiar de plan"        |
| `rescue`              | Banner rojo "Tu Premium vence en X días — renueva para no perder capacidades" | "Renovar"                 | "Planificar downgrade"   |
| `expiredFree`         | "Tu Premium ha expirado el DD/MM/YYYY"                                        | "Reactivar Premium"       | —                        |
| `restorable`          | "Puedes restaurar tu Premium hasta el DD/MM/YYYY (quedan N días)"             | "Restaurar Premium"       | —                        |

Todas las fechas deben localizarse (ver spec 8).

---

## Fuente de verdad: `subscriptionDashboardProvider`

Nuevo provider en `lib/features/subscription/application/subscription_dashboard_provider.dart`:

```dart
@Riverpod(keepAlive: true)
Stream<SubscriptionDashboard> subscriptionDashboard(SubscriptionDashboardRef ref) {
  final homeId = ref.watch(currentHomeIdProvider);
  if (homeId == null) return const Stream.empty();
  return FirebaseFirestore.instance
    .doc('homes/$homeId/views/dashboard')
    .snapshots()
    .map(SubscriptionDashboard.fromFirestore);
}
```

donde `SubscriptionDashboard` es un nuevo freezed que captura **sólo** lo que la pantalla necesita (plan, endsAt, restoreUntil, autoRenew, currentPayer, planCounters).

La pantalla sustituye su provider actual por éste y cualquier modificación en Firestore (incluyendo el callable debug) se refleja al instante.

---

## `SubscriptionManagementViewModel` — cambios

### Antes

El ViewModel actual lee `premiumStatusProvider` (snapshot puntual). Los `CallableFunction` para cancelar/reactivar llaman al backend pero no disparan recarga.

### Después

- Consume `subscriptionDashboardProvider` vía `ref.watch`.
- Las acciones (`cancelAutoRenew`, `reactivate`, `plannedDowngrade`, `restore`) llaman al callable correspondiente y **no** necesitan forzar un refresh — el stream lo propaga.
- Añade `isLoading` discreto por acción (mapa `Map<String, bool> pending`) para deshabilitar botones mientras una llamada está en curso.

---

## Widgets

Nuevo archivo `lib/features/subscription/presentation/widgets/plan_summary_card.dart` con un `PlanSummaryCard` que recibe un `SubscriptionDashboard` y renderiza el bloque según la tabla de arriba. La pantalla queda:

```dart
Scaffold(
  body: ListView(
    padding: EdgeInsets.only(bottom: adAwareBottomPadding(context, ref, extra: 16)),
    children: [
      PlanSummaryCard(data: dashboard),
      if (dashboard.status == 'free') UpgradeBenefitsSection(),
      if (isPremium(dashboard.status)) ManageActionsSection(vm: vm),
      if (dashboard.status == 'rescue') RescueWarningBanner(data: dashboard),
    ],
  ),
);
```

---

## BUG-13: toggles de notificaciones

Causa raíz investigada en QA: el `notification_settings_view_model` hacía `FutureBuilder` sobre la carga inicial de `notificationPrefs`. Cuando el hogar cambia de estado premium (o el provider de homes reconstruye), el FutureBuilder reinicia su future y los toggles saltan a su valor por defecto (`disabled`) durante ~200ms — y a veces se queda pegado.

### Fix

Convertir el ViewModel a un `@riverpod Stream<NotificationSettingsView> notificationSettings(...)`:

```dart
@Riverpod(keepAlive: true)
Stream<NotificationSettingsView> notificationSettings(NotificationSettingsRef ref) {
  final uid = ref.watch(authUidProvider);
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instance
    .doc('users/$uid')
    .snapshots()
    .map(NotificationSettingsView.fromFirestore);
}
```

La pantalla de notificaciones pasa de `FutureBuilder` a `ref.watch` con `AsyncValue`. El toggle de "notificaciones push" sólo se habilita cuando:

1. `data.systemAuthorized == true` (ver spec 3).
2. `data.masterEnabled == true`.

Los toggles por tipo (nueva tarea / turno / valoración / etc.) se habilitan en función de `masterEnabled`, **independientemente** del plan premium. No hay tipo de notificación bloqueado por plan hoy — si en el futuro lo hubiera, se añade un campo `requiresPremium` en el catálogo.

---

## Tests

- `subscription_dashboard_provider_test.dart`: simula cambio de estado en Firestore mock y verifica que el stream emite dos veces.
- `plan_summary_card_test.dart` — golden test con los 6 estados.
- `subscription_management_view_model_test.dart`: para cada acción, el callable se invoca con los argumentos correctos y el `pending` flag se resetea al completar.
- `notification_settings_view_model_test.dart`: al cambiar `masterEnabled` en Firestore, los toggles reflejan el cambio sin interacción.

---

## Compatibilidad con spec 2 (debug premium gate)

El toggle debug invoca el callable y escribe en Firestore. Con el nuevo `subscriptionDashboardProvider` basado en `snapshots()`, el cambio se refleja en la pantalla sin que el usuario tenga que reabrirla. Esto resuelve BUG-12 también para la ruta de debug.

---

## Fuera de alcance

- Rediseño del paywall ([paywall_screen.dart](lib/features/subscription/presentation/paywall_screen.dart)).
- Integración con Google Play Billing Library v7 (proceso independiente).
- Estadísticas de uso por categoría — mantener el comportamiento actual.
- Rework del `downgrade_planner_screen` (se mantiene; sólo se asegura que usa el nuevo provider si ya lo consume).
