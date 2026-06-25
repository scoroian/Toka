# 30 · 🟡 Medio — Claridad de qué se pierde en downgrade/expiración + ventana de restauración

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
La comunicación del fin de Premium es desigual:
- **Bien:** la cancelación de pack avisa antes de confirmar cuántos miembros se congelan, y el rescate explica el downgrade.
- **Flojo:** el banner de estado `expiredFree` y el resumen `_buildExpiredFree` **no enumeran qué features perdió el hogar** (smart, vacaciones, valoraciones, historial extendido); solo dicen "expiró el {fecha}". El usuario ya degradado no ve un balance claro de lo perdido.
- **Riesgo:** al pulsar "Restaurar Premium" en estado `restorable`, no se advierte **de antemano** cuántos días quedan de la ventana de 30 días junto a ese CTA (el dato está en el banner, no junto al botón). Y la urgencia del rescate usa pulso rojo + "antes de medianoche", que roza la ansiedad inducida.

## Evidencia
- `lib/features/subscription/presentation/widgets/plan_summary_card.dart:275-292` — `_buildExpiredFree` (sin enumerar lo perdido).
- `lib/features/subscription/presentation/widgets/premium_state_banner.dart:130-135` — pulso rojo último día.
- `lib/features/subscription/.../subscription_management_screen_v2.dart:76-80` — error de ventana de restauración expirada (manejado, pero sin aviso previo junto al CTA).
- ARB: `app_es.arb:700` (`expiredFree`), `:684` (`rescue_banner_last_day`), `:762` (`subscription_restore_expired_error`).

## Objetivo
1. En el estado expirado/Free, **enumerar de forma clara** qué capacidades perdió el hogar y cómo recuperarlas.
2. Junto al CTA "Restaurar", mostrar **cuántos días quedan** de la ventana de 30 días (no solo en el banner).
3. Suavizar la urgencia visual (pulso rojo / "antes de medianoche") a algo informativo sin ansiedad, manteniendo la transparencia de la fecha real.

## Criterios de aceptación
- [ ] El resumen/banner de expirado lista las features perdidas y la vía de recuperación.
- [ ] El CTA de restaurar muestra los días restantes de la ventana antes de pulsarlo.
- [ ] La urgencia del rescate deja de usar alarma agresiva (pulso rojo) sin ocultar la fecha real.
- [ ] Localizado (es/en/ro).

## Pruebas obligatorias
### Widget / Golden
- Golden de los estados: `expiredFree` (con lista de lo perdido), `restorable` (con días restantes junto al CTA), `rescue` (urgencia suavizada).
- Test de cálculo de días restantes de la ventana de 30 días.

### Verificación en dispositivo (Firebase real)
> Manipula los estados con Admin SDK (fechas de `premiumEndsAt`/ventana) sobre un hogar de prueba.
1. Lleva un hogar a `expiredFree`: el resumen debe enumerar lo perdido. Captura.
2. Estado `restorable` con pocos días: el CTA muestra los días restantes. Captura.
3. Estado de rescate último día: la urgencia es informativa, no ansiógena. Captura.

## Dependencias
- Coordinar ARB con **05**, **06**, **16**.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
