# 05 · 🟠 Alto — Migrar los copys binarios del paywall al modelo tiered

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
El backend ya es *tiered* (Pareja 2 / Familia 5 / Grupo 10 + packs + Plus), pero la UI arrastra copys del modelo binario antiguo que **mienten sobre lo que el usuario compra**. Aparecen en el paywall binario **y en la pantalla de rescate**: un hogar **Pareja** (2 miembros, 2,99 €) ve prometidos "Hasta 10 miembros" y "3,99 €". Genera sensación de estafa.

## Evidencia
- `lib/features/subscription/presentation/widgets/plan_comparison_card.dart:12-19` — features `hasFree/hasPremium` como si "Premium" fuera único nivel; usado en `paywall_screen_v2.dart:103` y `rescue_screen_v2.dart:50`.
- `lib/features/subscription/presentation/widgets/plan_summary_card.dart:137-142` — `_buildFree` lista los mismos copys hardcodeados.
- ARB: `app_es.arb:660` `paywall_feature_members: "Hasta 10 miembros por hogar"`; `:630` `subscription_price_monthly: "3,99 €/mes"`; `:634` `subscription_annual_saving: "Ahorra 17,89 €"`.
- Precios reales por tier: `docs/cierre-monetizacion/STORE_CATALOG.md:13-20` (2,99 / 3,99 / 5,99 €).
- Lectura de precio real de store con fallback ARB: `paywall_screen_v2.dart:244-246` (`tier_pricing_provider`).

## Objetivo
Parametrizar los copys de comparación/resumen por **tier** (miembros, precio, ahorro), leyendo el precio localizado de la store cuando exista y un fallback correcto por tier cuando no. Eliminar las cifras hardcodeadas genéricas en todas las superficies (paywall binario, paywall tiered y rescate).

## Criterios de aceptación
- [ ] El número de miembros mostrado coincide con el **tier concreto** (2/5/10, +packs si aplica), nunca "10" fijo.
- [ ] El precio mostrado es el de la store (localizado) y, si no hay, el fallback del **tier correcto**, no "3,99 €" plano.
- [ ] La **pantalla de rescate** muestra lo que el usuario realmente renueva (su tier), coherente con `renewal_product.dart`.
- [ ] Sin strings hardcodeadas; todo parametrizado en ARB (es/en/ro).
- [ ] No se rompe el modo binario legacy cuando `home_tiers_enabled` está OFF (mostrar el tier por defecto correcto).

## Pruebas obligatorias
### Unit / Widget / Golden
- Widget test de `PlanComparisonCard`/`PlanSummaryCard` parametrizado por tier: Pareja muestra 2 miembros + su precio; Familia 5; Grupo 10. Golden por tier.
- Test de fallback: sin precio de store → fallback del tier correcto (no el legacy).
- Test de la pantalla de rescate: el tier del hogar se refleja en la comparación.

### Verificación en dispositivo (Firebase real)
> App Check / IAP: ver `_CONVENCIONES.md §6`. Si la verificación de recibos está en juego, coordina el debug token con el usuario.
1. Con `home_tiers_enabled` ON, abre el paywall desde un hogar Pareja y otro Familia (usa dos hogares con la cuenta QA). Captura: las cifras deben diferir y ser correctas.
2. Lleva un hogar a estado de rescate y abre `/subscription/rescue`: la comparación debe mostrar su tier, no "10 miembros / 3,99 €". Captura.
3. Con `home_tiers_enabled` OFF (legacy), verifica que no aparecen cifras absurdas.

## Dependencias
- Relacionado con **06** (copy de "Sin publicidad") y **16** (a quién beneficia). Pueden hacerse en serie tocando ARB de forma coordinada.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
