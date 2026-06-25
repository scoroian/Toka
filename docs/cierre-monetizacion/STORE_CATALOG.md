# Catálogo de SKUs — Google Play & App Store (cierre monetización Toka)

> Fuente de verdad: el **código**. Esta tabla refleja los `productId` mapeados en
> `functions/src/shared/tier_catalog.ts`, `functions/src/entitlement/pack_catalog.ts`,
> `functions/src/entitlement/plus_catalog.ts` (backend) y sus espejos en
> `lib/features/subscription/domain/{tier_catalog,member_pack_catalog,subscription_products}.dart`
> (cliente). Auditado el 2026-06-24.

## 1. Los 12 SKUs del modelo nuevo

Todos son **suscripciones auto-renovables** (no consumibles). 6 productos × 2 ciclos.

| # | productId | Producto | Ciclo | Precio (€) | Efecto al consumir | Eje |
|---|-----------|----------|-------|-----------|--------------------|-----|
| 1 | `toka_pareja_monthly`  | Toka Pareja  | Mensual | 2,99  | Hogar Premium, tope **2** | hogar/tier |
| 2 | `toka_pareja_annual`   | Toka Pareja  | Anual   | 19,99 | Hogar Premium, tope **2** (+ trial 14d*) | hogar/tier |
| 3 | `toka_familia_monthly` | Toka Familia | Mensual | 3,99  | Hogar Premium, tope **5** | hogar/tier |
| 4 | `toka_familia_annual`  | Toka Familia | Anual   | 29,99 | Hogar Premium, tope **5** (+ trial 14d*) | hogar/tier |
| 5 | `toka_grupo_monthly`   | Toka Grupo   | Mensual | 5,99  | Hogar Premium, tope **10** | hogar/tier |
| 6 | `toka_grupo_annual`    | Toka Grupo   | Anual   | 49,99 | Hogar Premium, tope **10** (+ trial 14d*) | hogar/tier |
| 7 | `toka_pack5_monthly`   | Pack +5 miembros  | Mensual | 1,49  | **+5 plazas** sobre Grupo → 15 (requiere Grupo) | pack (aditivo, reversible) |
| 8 | `toka_pack5_annual`    | Pack +5 miembros  | Anual   | 9,99  | **+5 plazas** sobre Grupo → 15 (requiere Grupo) | pack |
| 9 | `toka_pack10_monthly`  | Pack +10 miembros | Mensual | 2,49  | **+10 plazas** sobre Grupo → 20; con +5 → 25 (requiere Grupo) | pack |
| 10| `toka_pack10_annual`   | Pack +10 miembros | Anual   | 19,99 | **+10 plazas** sobre Grupo → 20; con +5 → 25 (requiere Grupo) | pack |
| 11| `toka_plus_monthly`    | Toka Plus (individual) | Mensual | 1,99  | Por usuario: quita banner + cosméticos/skins + métricas personales | usuario (Plus) |
| 12| `toka_plus_annual`     | Toka Plus (individual) | Anual   | 14,99 | Por usuario: idem (+ posible trial) | usuario (Plus) |

\* **Trial 14 días (anual)**: el cliente NO promete trial salvo que la store lo
reporte (`IntroOffer` se lee de `queryProductDetails`, Hallazgo #14). El trial se
configura como **oferta introductoria del base plan anual** en cada store. En el
paywall tiered (flag `home_tiers_enabled` ON) el trial se lee **por tier**
(`tier_pricing_provider.dart`), así que para ofrecer trial en los 3 tiers hay que
configurarlo en los 3 base plans anuales (`toka_pareja_annual`, `toka_familia_annual`,
`toka_grupo_annual`).

### Tope absoluto
Grupo (10) + Pack +5 + Pack +10 = **25** (`ABSOLUTE_MAX_MEMBERS` en `tier_catalog.ts`,
`kAbsoluteMaxMembers` en `free_limits.dart`). Por encima de 25 → Toka Business (otro
producto, fuera de alcance; el paywall muestra un tile informativo, no un SKU).

### Free
3 miembros (`FREE_MAX_MEMBERS` / `kFreeMaxMembers`). No es un SKU.

## 2. SKUs legacy (compatibilidad de revert) — 2 adicionales

| productId | Mapea a | Cuándo se usa |
|-----------|---------|---------------|
| `toka_premium_monthly` | Grupo (10) | Paywall **binario** (flag `home_tiers_enabled` OFF) y pantalla de **rescate** |
| `toka_premium_annual`  | Grupo (10) | idem + intro offer del paywall binario |

`PRODUCT_TIER_CATALOG` (backend) mapea ambos a `grupo` para preservar el histórico
"Premium = 10". **Solo se compran cuando el flag de tiers está OFF** (modo binario),
salvo el bug de la pantalla de rescate (ver §4).

## 3. Resumen de alta en stores

- **Total a dar de alta para lanzar con tiers ON**: los **12** SKUs nuevos.
- **Si se lanza con `home_tiers_enabled` OFF** (revert/binario): bastan los **2**
  legacy `toka_premium_*`. Recomendación: dar de alta los 12 nuevos igualmente para
  poder activar el flag sin re-publicar.
- **Total recomendado en stores**: **14** (12 nuevos + 2 legacy de revert).

### Verificación de consistencia backend ↔ cliente (auditada)

| Conjunto | Backend | Cliente |
|----------|---------|---------|
| Tiers (6) | `PRODUCT_TIER_CATALOG` | `allTierProductIds` (`productIdFor`) |
| Packs (4) | `PRODUCT_PACK_CATALOG` | `allMemberPackProductIds` (`packProductIdFor`) |
| Plus (2) | `PLUS_PRODUCT_PREFIX` (`toka_plus*`) | `kPlusProductIds` |
| Legacy (2)| `toka_premium_*` → grupo | `kMonthlyProductId`/`kAnnualProductId` |

✅ Sin discrepancias en los nombres de los 12+2 productIds. El cliente consulta
precios a la store con `queryProductDetails` sobre exactamente estos conjuntos.

## 4. Hallazgo de auditoría (bug)

**Rescate compra el SKU legacy ignorando el tier** —
`lib/features/subscription/presentation/skins/rescue_screen_v2.dart` (pantalla viva,
montada por `AppRoutes.rescueScreen`) hardcodea `toka_premium_annual/monthly` sin
mirar `home_tiers_enabled` ni el tier actual del hogar. Con tiers ON, un hogar
**Pareja/Familia** en ventana de rescate que pulse "Renovar" compraría el SKU legacy
→ backend lo mapea a **Grupo (10)**: upgrade de tier no deseado y precio equivocado.

Fix planificado (TDD): cuando `home_tiers_enabled` ON, renovar el **tier actual** del
hogar (`dashboard.premiumFlags.tier` → `productIdFor(tier, cycle)`); fallback a
`toka_premium_*` cuando OFF. Ver tablero de tareas (BUG #7).

## 5. Checklist para PRODUCCIÓN (lo que falta)

- [ ] Alta de los **12 SKUs nuevos** en Google Play Console (suscripciones + base plans mensual/anual).
- [ ] Alta de los **12 SKUs nuevos** en App Store Connect (auto-renewable subscriptions; grupos de suscripción).
- [ ] Mantener los **2 legacy** `toka_premium_*` activos (revert sin re-publicar).
- [ ] **Precios localizados** por país (la tabla son precios de referencia €). Confirmar paridad de precios entre stores.
- [ ] **Oferta introductoria 14 días** en los base plans anuales (`*_annual`), al menos los 3 tiers; opcional Plus anual.
- [ ] **Secretos de verificación de recibos** server-to-store en prod (no en dev): `GOOGLE_PLAY_SA_JSON`, `APP_STORE_PRIVATE_KEY` (defineSecret en `sync_entitlement.ts`). Sin ellos la callable corre en modo inferencia (storeVerified=false) y NO concede créditos de plaza permanentes.
- [ ] Config no sensible en `functions/.env.<projectId>` de prod: packageName, bundleId, issuerId, keyId, env, STRICT_RECEIPT_VALIDATION.
- [ ] RTDN (Pub/Sub) + App Store Server Notifications (webhook HTTPS) apuntando a las funciones de prod.
- [ ] Verificar en sandbox/test de cada store los 12 flujos de compra antes de promover.
