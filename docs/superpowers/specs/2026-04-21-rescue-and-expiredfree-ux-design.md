# Spec: UX del estado rescue y mensajes para expiredFree

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Media (BUG-14, BUG-16, BUG-17)

---

## Contexto

El documento maestro define seis estados de premium: `free`, `active`, `cancelledPendingEnd`, `rescue`, `expiredFree`, `restorable`. Entre ellos:

- **`rescue`** es la ventana de **3 días antes** de `premiumEndsAt` cuando el pago automático ha fallado (tarjeta caducada, fondos insuficientes, etc.). Es el último aviso antes de caer a Free.
- **`expiredFree`** es el estado inmediato tras superar `premiumEndsAt` sin renovar. La ventana de restauración dura 30 días (`restorable`).

QA 2026-04-20 detectó que la app no comunica apenas nada al usuario en estos estados:

- **BUG-14 (medio):** en `rescue` no hay banner ni aviso visible en Hoy ni en Ajustes. El usuario se entera cuando deja de ver features premium (demasiado tarde).
- **BUG-16 (medio):** el campo `daysLeft` en `rescueFlags` se calcula con `premiumEndsAt.difference(now).inDays`, que **trunca**. Si faltan 2.9 días muestra "2 días". Debería usar ceil (`(diff.inHours / 24).ceil()` o similar) para no mostrar "0 días" cuando aún queda unas horas.
- **BUG-17 (bajo):** en `expiredFree` los textos son iguales que en `free`. No hay diferenciación ("Hazte Premium" en ambos casos) aunque el caso `expiredFree` merece un mensaje específico ("Tu Premium ha expirado — renuévalo").

---

## Decisiones clave

- **Banner no cerrable en Hoy y Ajustes del hogar** cuando el hogar está en `rescue`. Color semántico rojo/ámbar, con CTA directa a la pantalla de suscripción.
- **`daysLeft` se calcula con `ceil`**, no con `.inDays`. Cuando faltan <1h, se muestra "menos de 1 día".
- **`expiredFree` vs `free`:** en `expiredFree`, la copy del tile de Ajustes y del paywall cambia — "Reactivar Premium" en lugar de "Hazte Premium", y se indica la fecha de expiración.
- **`restorable`:** banner informativo (no crítico) en Hoy que recuerda "Puedes restaurar tu Premium hasta el DD/MM. Quedan N días."

---

## Cambio de cálculo de `daysLeft`

Actualmente el writer del dashboard (en el backend) produce:

```ts
const daysLeft = Math.floor((premiumEndsAt.toMillis() - now) / 86400000);
```

Cambiar por (en [functions/src/jobs/premium_daily.ts](functions/src/jobs/premium_daily.ts) o archivo equivalente):

```ts
const diffMs = premiumEndsAt.toMillis() - Date.now();
const daysLeft = Math.max(0, Math.ceil(diffMs / 86400000));
```

Y pre-compute **en el cliente** también cuando se necesite real-time (los 3 días son una ventana pequeña; si el cron corre cada 24h, la UI podría mostrar un valor desfasado por varias horas). El cliente recalcula en tiempo real partiendo del `premiumEndsAt` absoluto:

```dart
int daysLeftFrom(DateTime endsAt) {
  final diff = endsAt.difference(DateTime.now());
  if (diff.isNegative) return 0;
  return (diff.inMinutes / (60 * 24)).ceil();
}
```

El cliente prefiere este valor al que venga del dashboard. El `rescueFlags.daysLeft` del backend queda sólo como backup/analítica.

---

## Banners

Nuevo widget `PremiumStateBanner` en `lib/features/subscription/presentation/widgets/premium_state_banner.dart`. Se renderiza como el primer child de la pantalla Hoy (encima del header), y en la parte superior de Ajustes del hogar. Sólo aparece cuando el estado lo requiere.

| Estado                  | Visual                                                 | Texto (i18n)                                                              | Acción primaria               |
| ----------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------- | ----------------------------- |
| `rescue` (≥1 día)       | Fondo rojo 80%, icono `warning`                        | `rescueBannerTitle` — "Tu Premium vence en {days} — renueva para no perder features" | "Renovar" → paywall          |
| `rescue` (<1 día)       | Fondo rojo 100%, pulse sutil                           | `rescueBannerLastDay` — "Tu Premium vence hoy. Renueva antes de medianoche." | "Renovar"                     |
| `cancelledPendingEnd`   | Fondo ámbar                                            | `cancelledEndsBannerTitle` — "No se renovará tras el {date}. Puedes reactivar cuando quieras." | "Reactivar renovación"       |
| `expiredFree`           | Fondo neutro con icono `info`                          | `expiredFreeBannerTitle` — "Tu Premium expiró el {date}. Reactívalo cuando quieras." | "Reactivar Premium"          |
| `restorable`            | Fondo verde claro                                      | `restorableBannerTitle` — "Puedes restaurar tu Premium hasta el {date}"   | "Restaurar"                   |
| `active`, `free`        | (ningún banner)                                        | —                                                                         | —                             |

Los banners respetan el `adAwareBottomPadding` cuando se muestran apilados con otros banners.

---

## Copy diferenciada `expiredFree` vs `free`

### En Ajustes → Gestionar suscripción (ya cubierto por spec 5)

Los dos estados ya se diferencian según la tabla de spec 5. Esta spec sólo añade la clave de texto.

### En paywall

[lib/features/subscription/presentation/paywall_screen.dart](lib/features/subscription/presentation/paywall_screen.dart) recibe un parámetro `PaywallEntryContext`:

```dart
enum PaywallEntryContext { fromFree, fromExpired, fromRescue, fromRestorable }
```

El título del paywall cambia:

- `fromFree` → "Hazte Premium"
- `fromExpired` → "Reactivar Premium" + subtítulo con fecha de expiración.
- `fromRescue` → "Renueva antes de perder tus capacidades" + días restantes.
- `fromRestorable` → "Restaurar tu Premium" + días restantes de la ventana de 30.

Sólo cambia la copy de la cabecera y el texto del CTA principal. Los planes y el flujo de compra no cambian.

---

## Pantalla rescue (`rescue_screen.dart`)

Existe una pantalla dedicada ([lib/features/subscription/presentation/rescue_screen.dart](lib/features/subscription/presentation/rescue_screen.dart)) que se abre desde el banner. Ajustes:

- Cambiar la cuenta atrás a usar el nuevo helper `daysLeftFrom` con precisión de horas cuando falta menos de un día: "Quedan 7 horas".
- Añadir info del último intento de cobro fallido si `homes/{homeId}.lastBillingError` está presente (nuevo campo opcional; si no existe, ocultar la sección).

---

## Tests

- `premium_state_banner_test.dart`: golden para cada estado.
- `days_left_test.dart`: `(60min * 23h * 59)` devuelve 1; `(60min * 24 + 1)` devuelve 2; `0` devuelve 0; negativo devuelve 0.
- `paywall_screen_test.dart`: cambia cabecera/CTA según `PaywallEntryContext`.
- Integración manual (checklist): simular cada estado con el toggle debug y verificar banners.

---

## Accesibilidad

Cada banner debe tener `Semantics(container: true, label: ...)` con el texto completo. El color nunca es la única señal: siempre hay un icono y texto.

---

## Fuera de alcance

- Notificaciones push proactivas en el umbral (D-3, D-1, D0) del estado rescue — spec aparte si producto lo prioriza. Requiere cron y trigger FCM.
- Cambios en la política de 30 días de `restorable` (viene del documento maestro).
- Integración del error real de Play Billing para poblar `lastBillingError` — depende del rework del flujo de compra.
