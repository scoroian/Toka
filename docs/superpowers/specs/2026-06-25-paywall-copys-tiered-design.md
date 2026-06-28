# Migrar los copys binarios del paywall al modelo tiered

> Hallazgo #05 · 🟠 Alto. Diseño aprobado el 2026-06-25.

## Problema

El backend es *tiered* (Pareja 2 / Familia 5 / Grupo 10 + packs + Plus), pero varias
superficies de la UI arrastran copys del modelo binario antiguo que **mienten sobre
lo que el usuario compra**: un hogar **Pareja** (2 miembros, 2,99 €) ve prometidos
"Hasta 10 miembros" y "3,99 €". Genera sensación de estafa.

El **paywall tiered** (`_TieredPaywallBody` en `paywall_screen_v2.dart`) ya muestra
miembros y precios correctos por tier — **no se toca**. El copy mentiroso vive en
tres superficies que comparten widgets binarios:

1. **`PlanComparisonCard`** (tabla Free-vs-Premium): fila `paywall_feature_members`
   = "Hasta 10 miembros" fija. La usan el **paywall binario** (`paywall_screen_v2.dart:103`)
   y la **pantalla de rescate** (`rescue_screen_v2.dart:50`).
2. **`_PriceChip`** del paywall binario: `subscription_price_monthly/annual`
   (3,99 / 29,99 € — cifras de *Familia*, no del SKU que se vende) +
   `subscription_annual_saving` ("Ahorra 17,89 €").
3. **`PlanSummaryCard._buildFree`** (tarjeta "Con Premium desbloqueas",
   Ajustes→Suscripción): mismo "Hasta 10 miembros" hardcodeado.

### Contexto técnico relevante (ya existente)

- El SKU legacy `toka_premium_*` (paywall binario, flag `home_tiers_enabled` OFF)
  el backend lo mapea a **Grupo (10)**. Por eso el "tier por defecto correcto" del
  modo binario es **Grupo**.
- `currentHomeTierProvider` deriva el tier actual del hogar de
  `dashboard.premiumFlags.tier` (`null` con flag OFF o dashboard legacy).
- `tierPricingProvider` consulta a la store los 6 SKUs de tier y devuelve precio
  localizado + trial por `productId`; ausencia → fallback ARB.
- `tierFallbackPrice(l10n, tier, cycle)` da el precio de referencia ARB por tier
  (`tier_price_{tier}_{monthly|annual}`): Pareja 2,99/19,99 · Familia 3,99/29,99 ·
  Grupo 5,99/49,99.
- `paywall_tier_members(count)` = "Hasta {count} miembros" (ya existe, lo usa el
  paywall tiered).
- `renewalProductId(tiersEnabled, tier, cycle)` ya resuelve la **compra** de
  renovación al tier actual (fallback legacy=Grupo). Este diseño alinea el **copy**
  con esa compra.

## Decisiones de producto (confirmadas con el usuario)

- **Hogar Free** (PlanSummaryCard): mostrar **rango explícito** "De 2 a 10 miembros
  según el plan" — no promete cifra fija.
- **Precio binario**: mostrar el precio de **Grupo** leído de la store (reutilizando
  `tierPricingProvider`) con fallback ARB Grupo (5,99 / 49,99 €), y mostrar el
  **ahorro correcto de Grupo**: "Ahorra 21,89 €" (5,99×12 − 49,99).

## Enfoque

`PlanComparisonCard` deja de tener cifras fijas y recibe el **límite de miembros**
como parámetro `int premiumMemberLimit`. Cada superficie inyecta el valor correcto.
El widget sigue siendo `StatelessWidget` puro (sin Riverpod dentro) → trivial de
testear con goldens por tier.

*Alternativa descartada*: convertir `PlanComparisonCard` en `ConsumerWidget` que lea
`currentHomeTierProvider`. Descartada porque el paywall binario necesita Grupo (no el
tier del hogar) y acoplaría el widget a providers, complicando los goldens.

## Componentes

### 1. `PlanComparisonCard({required int premiumMemberLimit})`
`lib/features/subscription/presentation/widgets/plan_comparison_card.dart`

- Añadir campo `final int premiumMemberLimit;`.
- La fila de miembros de la tabla pasa de `l10n.paywall_feature_members` a
  `l10n.paywall_tier_members(premiumMemberLimit)`.
- El resto de la tabla (smart, vacaciones, valoraciones, historial, sin ads) no cambia.

### 2. Paywall binario — `_BinaryPaywallBody` (`paywall_screen_v2.dart`)
- `PlanComparisonCard(premiumMemberLimit: HomeTier.grupo.maxMembers)` → 10.
- Los dos `_PriceChip` toman el precio de Grupo:
  `pricing[productIdFor(HomeTier.grupo, cycle)]?.price ?? tierFallbackPrice(l10n, HomeTier.grupo, cycle)`,
  donde `pricing = ref.watch(tierPricingProvider).valueOrNull ?? {}` (mismo patrón que
  `_TieredPaywallBody`). Sustituye a `subscription_price_monthly/annual`.
- El badge del chip anual mantiene la lógica `hasTrial ? paywall_trial_badge : subscription_annual_saving`;
  `subscription_annual_saving` se actualiza a "Ahorra 21,89 €".

### 3. Pantalla de rescate — `RescueScreenV2` + `RescueViewModel`
- `RescueViewModel` expone `int get premiumMemberLimit`, resuelto en el provider como
  `(ref.watch(currentHomeTierProvider) ?? HomeTier.grupo).maxMembers`.
- `RescueScreenV2`: `PlanComparisonCard(premiumMemberLimit: vm.premiumMemberLimit)`.
- No se añade precio a la pantalla de rescate (sus botones ya usan `paywall_cta_*` sin
  precio; fuera de alcance). El criterio "muestra su tier" se cumple con los miembros.

### 4. `PlanSummaryCard._buildFree` (`plan_summary_card.dart`)
- La línea `_benefit(l10n.paywall_feature_members)` pasa a
  `_benefit(l10n.premium_benefit_members_range)`.

### 5. ARB (`lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`)
- **Nueva** `premium_benefit_members_range`:
  - es: "De 2 a 10 miembros según el plan"
  - en: "From 2 to 10 members depending on your plan"
  - ro: "De la 2 la 10 membri în funcție de plan"
- **Actualizar** `subscription_annual_saving`:
  - es: "Ahorra 21,89 €" · en: "Save €21.89" · ro: "Economisești 21,89 €"
- **Eliminar** (quedan huérfanas tras el cambio): `paywall_feature_members`,
  `subscription_price_monthly`, `subscription_price_annual` (en los 3 ARB y sus
  entradas `@`).
- Regenerar `lib/l10n/app_localizations*.dart` con `flutter gen-l10n`.

## Criterios de aceptación

- [ ] El número de miembros mostrado coincide con el tier concreto (2/5/10), nunca
      "10" fijo.
- [ ] El precio del paywall binario es el de la store (localizado) y, si no hay, el
      fallback de Grupo (5,99/49,99 €), no "3,99 €" plano.
- [ ] La pantalla de rescate muestra los miembros del tier real del hogar (fallback
      Grupo si el tier es desconocido), coherente con `renewal_product.dart`.
- [ ] Sin strings hardcodeadas; todo parametrizado en ARB (es/en/ro).
- [ ] El modo binario legacy (`home_tiers_enabled` OFF) muestra el tier por defecto
      correcto (Grupo) sin cifras absurdas.

## Plan de pruebas (TDD — tests antes que implementación)

### Unit / Widget / Golden
- `PlanComparisonCard` parametrizado: `premiumMemberLimit` 2→"Hasta 2 miembros",
  5→"Hasta 5", 10→"Hasta 10". Golden por límite.
- Paywall binario: el chip anual/mensual muestra el precio de Grupo (fallback) y NO
  "3,99 €"; con `tierPricingProvider` override muestra el precio de store.
- Rescate: `currentHomeTierProvider = Pareja` → "Hasta 2 miembros"; `null` → "Hasta 10"
  (fallback Grupo). Reusa el harness de `rescue_screen_test.dart`.
- `PlanSummaryCard` free: el golden refleja "De 2 a 10 miembros según el plan".
- Regenerar goldens afectados (`paywall_screen`, `plan_summary_card_free`,
  los nuevos de `PlanComparisonCard`).

### Verificación en dispositivo (Firebase real)
1. `home_tiers_enabled` ON: abrir paywall desde un hogar Pareja y otro Familia — las
   cifras deben diferir y ser correctas. Captura.
2. Llevar un hogar a rescate y abrir `/subscription/rescue` — la comparación muestra
   su tier (no "10 miembros"). Captura.
3. `home_tiers_enabled` OFF (binario): no aparecen cifras absurdas (Grupo/10 +
   precios de Grupo). Captura.

## Fuera de alcance

- El paywall tiered (`_TieredPaywallBody`) y las tarjetas de tier/packs (ya correctos).
- Añadir precio a la pantalla de rescate.
- Resolver la inconsistencia moneda-localizada vs ahorro en € de referencia (problema
  preexistente del modelo de "ahorro" hardcodeado; el badge usa la cifra € de
  referencia, igual que hoy).

## Dependencias

Relacionado con el Hallazgo #06 (copy de "Sin publicidad") y #16 (a quién beneficia):
tocan el mismo ARB. Coordinar el orden de edición del ARB si se hacen en serie.
