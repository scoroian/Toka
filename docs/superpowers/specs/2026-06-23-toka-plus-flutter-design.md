# Toka Plus en Flutter (Fase 4) — Diseño

> Fecha: 2026-06-23 · Feature: consumo del entitlement Plus (Fase 3) en la UI.
> Producto **Toka Plus**: individual por usuario, 1,99 €/mes · 14,99 €/año.
> Esta fase NO toca ads (eso es Fase 5).

## Contexto verificado en código (fuente de verdad)

- Entitlement Plus (backend) ya existe end-to-end:
  - Doc privado `users/{uid}/entitlements/plus` con `status, active, cycle, startsAt, endsAt, autoRenewEnabled, productId, platform, chargeId, source` (`functions/src/entitlement/plus_entitlement.ts:97-114`).
  - Reglas: `allow read: if isUser(uid)` sobre `entitlements/{id}` (`firestore.rules:150-159`); escritura solo backend.
  - Proyección `homes/{homeId}/members/{uid}.plusActive` (legible por co-miembros).
  - SKUs `toka_plus_monthly`/`toka_plus_annual` (prefijo `toka_plus`); `plus_catalog.ts`.
  - Activación efectiva backend: `isPlusEffectivelyActive = doc.active && flag && (endsAt==null || endsAt>now)` (`plus_catalog.ts:75-95`).
- Flag Remote Config `toka_plus_enabled` (default OFF) ya está en el cliente: `RemoteConfigService.tokaPlusEnabled` (`lib/shared/services/remote_config_service.dart:98-104`). **Sin consumidor Dart aún.**
- `syncEntitlement` **no exige `homeId` para Plus**: enruta por SKU y usa `uid` de auth (`functions/src/entitlement/sync_entitlement.ts:101,129-159`).
- Compra: `Paywall.startPurchase({homeId, productId})` es genérica y hay **un único** listener de `InAppPurchase.purchaseStream` (`lib/features/subscription/application/paywall_provider.dart`). Reutilizable con `homeId:''`.
- Skins: `SkinSwitch` (24 call-sites) despacha builders por skin; hoy solo `AppSkin.v2`. Tema por skin en `app.dart:454-456`. Picker en `lib/features/settings/presentation/widgets/appearance_picker.dart`. Persistencia `SkinMode` (SharedPreferences, `core/theme/skin_provider.dart`).
- Datos reales para métricas: `Member` (`tasksCompleted, passedCount, complianceRate, currentStreak, averageScore`), `memberRadarProvider` (avgScore por tarea), `memberVisibleReviews`, `homeMembersProvider`, `authProvider`, `currentHomeProvider`. Widgets reutilizables: `radar_chart_widget.dart`, `stats_section.dart`.

## Decisiones de producto (aprobadas)

- Skins cosméticas: gating **data-driven** por catálogo, reutilizando pantallas `v2`. Se añade **1 skin cosmética Plus de ejemplo, "Océano" (paleta azul)**, suficiente para demostrar/verificar el gating; añadir más es trivial.
- Métricas personales: viven en la feature `profile`, con ruta propia y entradas desde Ajustes y perfil propio.
- Paywall de Plus: **pantalla dedicada** (no se mezcla con el paywall de hogar).

## Componentes

### 1. Entitlement Plus (cimiento + contrato Fase 5)

- `lib/features/subscription/domain/plus_entitlement.dart` — freezed `PlusEntitlement { status, active, cycle, startsAt?, endsAt?, autoRenewEnabled, productId? }` + `fromMap`.
- `lib/features/subscription/domain/plus_repository.dart` — abstracto `Stream<PlusEntitlement?> watch(String uid)`.
- `lib/features/subscription/data/plus_repository_impl.dart` — snapshots de `users/{uid}/entitlements/plus`.
- `lib/features/subscription/application/plus_provider.dart`:
  - `plusRepositoryProvider` (keepAlive).
  - `plusEntitlementProvider` → `AsyncValue<PlusEntitlement?>` (uid del `authProvider`; vacío si no autenticado).
  - `tokaPlusEnabledProvider` (bool, patrón de `homeTiersEnabledProvider`, reactivo a RC, fail-safe OFF).
  - **`plusActiveProvider` (bool)** = `flag && ent.active && (endsAt==null || endsAt>now)`; fail-safe `false` en loading/error. **Contrato para Fase 5 (ads).**

### 2. Paywall / compra de Plus

- `subscription_products.dart`: `kPlusMonthlyProductId='toka_plus_monthly'`, `kPlusAnnualProductId='toka_plus_annual'`.
- `application/plus_pricing_provider.dart`: precios localizados de store + trial; fallback ARB (1,99 / 14,99).
- `application/plus_paywall_view_model.dart`: ciclo seleccionado, `isLoading/purchasedSuccessfully/purchaseError` observando `paywallProvider`; `startPurchase` → `paywallProvider.notifier.startPurchase(homeId:'', productId:…)`.
- `presentation/skins/plus_paywall_screen.dart` (+ `_v2`): beneficios (skins + métricas), planes mensual/anual, CTA, restaurar, estado "ya tienes Plus".
- Ruta `AppRoutes.plusPaywall = '/subscription/plus'` (+ GoRoute + lista `all`).

### 3. Skins gated

- `core/theme/skin_catalog.dart`: `enum SkinTier { free, plus }` + `SkinTier skinTier(AppSkin)`; `bool isPlusSkin(AppSkin)`.
- `AppSkin.oceano` nuevo valor (paleta azul). Tema `core/theme/app_theme_oceano.dart` (mismo armazón que `AppThemeV2`, paleta distinta). Ramas nuevas en los 3 `switch(skin)`: `SkinSwitch` (→ builder `v2`), `app.dart` (tema Océano), `AppearancePicker` (label + `_MiniPreview`).
- `core/theme/effective_skin_provider.dart` → `effectiveSkinProvider`: si `isPlusSkin(selected) && !plusActive` ⇒ `AppSkin.v2`. `app.dart` y `SkinSwitch` consumen **este** provider (re-tematización en vivo al activar/desactivar Plus; preferencia preservada).
- `AppearancePicker`: con `!tokaPlusEnabled` oculta skins Plus; con flag on y sin Plus → card bloqueada (candado + "Requiere Toka Plus", tap → paywall Plus); con Plus → seleccionable.

### 4. Métricas personales (feature `profile`, gated)

- `application/personal_metrics_view_model.dart` + modelo freezed `PersonalMetrics` (tareas completadas, racha, puntualidad %, puntuación media, turnos pasados, reparto = mis completadas ÷ Σ completadas de activos, desglose por tarea del radar). Casos vacío/parcial.
- `presentation/skins/personal_metrics_screen.dart` (+ `_v2`), Material 3, reutiliza `radar_chart_widget`/`stats_section`. Gated: sin Plus → teaser + CTA; con Plus → métricas.
- Ruta `AppRoutes.personalMetrics = '/profile/metrics'`.
- Entradas (visibles solo con `tokaPlusEnabled`): fila en Ajustes ("Toka Plus" + "Mis métricas") y botón en perfil propio.

### 5. i18n

- Claves nuevas en `app_es.arb`, `app_en.arb`, `app_ro.arb`: Plus, planes, beneficios, candado "Requiere Toka Plus", labels skin Océano, títulos/labels de métricas, estados vacíos. Regenerar `app_localizations*`.

### 6. Remote Config

- `tokaPlusEnabledProvider` gobierna **visibilidad** (skins Plus y entradas ocultas con flag OFF) y, vía `plusActiveProvider`, el **desbloqueo**. Flag OFF ⇒ nadie ve features Plus. No se toca ads.

## Flujos de datos clave

- Gating: `authProvider.uid` → `plusEntitlementProvider` (stream Firestore) + `tokaPlusEnabledProvider` (RC) → `plusActiveProvider` (bool) → consumido por `effectiveSkinProvider`, AppearancePicker y pantalla de métricas.
- Compra: pantalla Plus → `plusPaywallViewModel.startPurchase` → `Paywall.startPurchase(homeId:'', SKU)` → `purchaseStream` → `syncEntitlement` (ruta Plus, sin homeId) → backend escribe `entitlements/plus` → stream actualiza `plusEntitlementProvider` → UI se desbloquea en vivo.

## Manejo de errores

- Providers fail-safe a "sin Plus" en loading/error y si RC falla.
- Compra: estados pending/error/cancelled del stream → SnackBars; éxito → pop + confirmación.
- Lectura del doc Plus: si no existe → `null` (sin Plus); si reglas niegan (no debería para el propio uid) → error AsyncValue → fail-safe false.

## Tests (exhaustivos)

- Unit: `plusEntitlementProvider`/`plusActiveProvider` en activo/sin-Plus/expirado/cargando/error y flag on/off; `effectiveSkinProvider` (degrada skin Plus sin Plus, preserva con Plus); gating de skins y métricas (desbloqueado vs bloqueado+CTA); `PersonalMetrics` con datos/vacío/parcial y cálculos correctos; per-usuario sin mezcla; `plus_pricing_provider` con/ sin store.
- Golden/widget: paywall Plus (mensual/anual), métricas (datos/vacío/bloqueado), AppearancePicker (desbloqueado/bloqueado/flag-off) en es/en/ro, sin overflow; navegación a destinos correctos.

## Verificación en 2 dispositivos

- A con Plus (forzado por Admin SDK): skins Océano + métricas accesibles.
- B sin Plus: bloqueadas + CTA al paywall.
- Activar/desactivar Plus en A → sincroniza en vivo.
- Flag `toka_plus_enabled` OFF → nadie ve features Plus.

## Fuera de alcance

- Ads / quitar banner (Fase 5).
- B2B / packs de miembros / tiers de hogar.
- Sets de pantallas alternativos por skin (solo paleta de tema reutilizando `v2`).
