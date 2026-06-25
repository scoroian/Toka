# Informe de cierre — Modelo de monetización Toka

> Fecha: 2026-06-24 · Proyecto Firebase: `toka-dd241` (dev) · Fuente de verdad: el **código**.
> Acompaña a `STORE_CATALOG.md` (SKUs) y `REMOTE_CONFIG_FLAGS.md` (flags).

## Resumen ejecutivo

El modelo completo (tiers por tamaño + packs de miembro + Toka Plus individual + ads
diferenciadas) está **implementado y consistente backend↔cliente**, con la lógica de
negocio **exhaustivamente testeada**. Se encontró y corrigió (TDD) **1 bug real** (la
pantalla de rescate compraba el SKU legacy ignorando el tier). El backend está **100 %
verde** (916 tests) y la **suite Flutter completa también** (1261 unit+ui, 0 fallos). Se
corrigieron además **11 tests preexistentes del WIP de UI** que estaban en rojo (8 goldens
obsoletos regenerados + 3 tests de contenido actualizados a cambios de UI intencionales).

**¿Funciona end-to-end en dev?** **Sí.** Verificado en 3 capas (detalle en `QA_E2E.md`):
(1) suite + reglas + integración con emulador; (2) **enforcement server-side en la callable
desplegada** (`joinHomeByCode`): topes por tier (Pareja 2/Familia 5/Grupo 10) y con packs
(hasta 25, **26.º rechazado**); (3) **2 dispositivos / 2 cuentas del mismo hogar** (MI_9
owner-pagador + emulador member): matriz de ads (filas 1, 3, 4, 5), Plus per-usuario (quita
banner + desbloquea skin solo a esa cuenta), revert de Plus en vivo y **sincronización en
vivo** de los estados forzados por Admin SDK sin reinstalar.

**¿Qué bloquea producción?** Alta de los 12 SKUs en las stores, secretos de verificación
de recibos (IAP), AdMob unit IDs reales, y rellenar la config `.env` de prod (hoy en
"bloqueo seguro"). Detalle en §7.

---

## 1. SKUs (Fase 1) — ver `STORE_CATALOG.md`

- **12 SKUs** del modelo nuevo, todos suscripciones: 6 tiers (`toka_{pareja,familia,grupo}_{monthly,annual}`),
  4 packs (`toka_pack{5,10}_{monthly,annual}`), 2 Plus (`toka_plus_{monthly,annual}`).
- **Consistencia backend↔cliente verificada**: sin discrepancias en los productIds.
- **2 SKUs legacy** (`toka_premium_{monthly,annual}` → Grupo) usados como fallback con el
  flag de tiers OFF (paywall binario). Recomendado mantenerlos para revert sin re-publicar.
- **Hallazgo (corregido)**: la pantalla de rescate compraba el legacy ignorando el tier.

## 2. Remote Config (Fase 2) — ver `REMOTE_CONFIG_FLAGS.md`

5 flags del modelo, **todos default OFF** con fallback seguro y gating read-time:
`home_tiers_enabled`, `member_packs_enabled`, `toka_plus_enabled`,
`ad_differentiated_enabled` (maestro ads), `ad_interstitial_enabled`.

**Revert limpio verificado por tests** para los 5:
- tiers OFF → binario (10/3) [`tier_catalog.test.ts`]
- packs OFF → tope del tier [`tier_catalog.test.ts:218`]
- Plus OFF → sin Plus [`plus_catalog.test.ts`]
- ads maestro OFF → banner legacy / intersticial off [`ad_banner_config_provider_test.dart`, `ad_interstitial_controller_test.dart`]

**Caveat documentado**: apagar `member_packs_enabled` con hogares de >10 miembros deja
miembros over-cap (no destructivo; bloquea nuevas altas). Es un toggle de lanzamiento, no
de caliente. Defaults de lanzamiento recomendados: todos **ON** (ver doc).

## 3. Robustez hogar grande / tope 25 (Fase 3)

- **Batching (límite 500 ops)**: los 3 paths con escrituras **ilimitadas** (cron downgrade
  a Free, `restorePremiumState`, `reassignTasksFromDeletedUser`) **trocean** con
  `commitInChunks`/`chunked` (MAX_BATCH_OPS=450) y dejan el flip final en batch fijo;
  testeado con >500 entidades (`large_home_batching.test.ts`).
- Los paths de **packs** (`applyPackEntitlement`/`revokePack`) y **cambio de tier**
  (`reconcileVerifiedEntitlement`) congelan **solo miembros** en una transacción: como el
  tope absoluto es 25, son ≤~28 ops, estructuralmente <500. Sin riesgo.
- **Dashboard (1 MB)**: el tope de 25 miembros añade ~2,5 KB (`memberPreview`, 25 entradas).
  No introduce riesgo. El riesgo real (preexistente, **independiente del nº de miembros**)
  es `activeTasksPreview` = todas las tareas activas; un hogar con miles de tareas podría
  acercarse a 1 MB. Riesgo abierto (§7), no introducido por la monetización.

## 4. Cobertura (Fase 4)

Lógica de monetización (cliente, `flutter test --coverage`):

| Área | Cobertura |
|------|-----------|
| tiers (`tier_catalog`) | **100 %** |
| packs | **90,7 %** |
| Toka Plus | **88,7 %** |
| feature subscription (completo) | **80,9 %** |
| ads (visibility/banner/interstitial) | 62,9 %* |
| rescue + renewal | 72 %* |

\* Lo no cubierto es **glue de SDK/Firebase no testeable en unit**: `ad_interstitial_gateway`
(wrapper nativo de AdMob, 0 %), `ad_flags_provider`/`current_tier_provider` (lecturas de
Remote Config/Firestore que fail-safean en tests), y paths de render de widgets. La
**lógica del modelo** está cubierta al 100 %/alto. Global lib 54,8 % (arrastrado por UI/
freezed/generados).

**Matriz de ads (5 filas) testeada explícitamente** [`ad_visibility_test.dart`] + cruzadas.
**Combinaciones de packs** (none/+5/+10/ambos → 10/15/20/25) [`tier_catalog.test.ts:196`].

**Reglas de Firestore (seguridad) — 171 tests verdes** [`test/rules`], incl. negativos: el
cliente NO puede escribir `premiumTier`/`limits`/`memberPacks` del hogar
(`firestore.rules:175-178`), ni `users/{uid}/entitlements/plus` (write:false), ni el
`views/dashboard` (write:false). Topes enforced server-side.

**Backend**: 916 tests verdes = 412 unit + 171 rules + 333 integración (emulador).

**Gap encontrado y cerrado (TDD)**: pantalla de rescate (ver §5). Tests nuevos:
`renewal_product_test.dart` (6), `rescue_view_model_test.dart` (+4), `rescue_screen_test.dart` (+2).

## 5. Bug corregido (TDD) — rescate ignoraba el tier

`RescueScreenV2` (pantalla viva) compraba `toka_premium_{annual,monthly}` hardcodeado.
Con `home_tiers_enabled` ON, un hogar **Pareja/Familia** en ventana de rescate sufría
**upgrade no deseado a Grupo** (el backend mapea el legacy a Grupo) y precio equivocado.

**Fix**: función pura `renewalProductId({tiersEnabled, tier, cycle})` + provider derivado
`currentHomeTierProvider` (lee el tier de `dashboard.premiumFlags.tier`). El VM expone
`annualProductId`/`monthlyProductId` resueltos; la pantalla los usa. Con tiers OFF o tier
desconocido → fallback legacy. **12 tests** (rojo→verde).

## 6. Estado de la suite y gates (Fase 5)

| Gate | Estado |
|------|--------|
| `tsc` backend (build) | ✅ 0 errores |
| backend unit (`jest src/`) | ✅ 412/412 |
| backend rules | ✅ 171/171 |
| backend integración (emulador) | ✅ 333/333 |
| `flutter analyze` | ✅ 0 errores (47 lints `info`/`warning` solo en archivos de test; **ninguno en `lib/` ni en mis archivos**) |
| `check:release-safety` | ✅ (sin debug-premium, sin test-ad-units en release) |
| Flutter unit+ui (completa) | ✅ **1261/1261 verde** (WSL) |

**11 tests preexistentes del WIP de UI corregidos** (estaban en rojo antes del cierre, no
causados por estos cambios). Root-cause de cada uno:
- **8 goldens obsoletos** por el WIP de theme/skins/members (`members_screen`,
  `complete_task_dialog`, `pass_turn_dialog` ×2, `today_card_todo` ×3, `today_card_done`):
  regenerados en **WSL** — ver nota de entorno abajo.
- **3 tests de contenido obsoletos** ante cambios de UI **intencionales** (no regresiones):
  (a) `complete_task_dialog` ya no concatena `'🧹 Barrer'` en un único `Text` — renderiza el
  visual (emoji/icono Material) aparte del título (arregla mostrar el codepoint crudo de
  iconos custom); (b/c) `RecurrenceOrder.all` ahora tiene **6** entradas con `'oneTime'`
  primero (sin esa entrada las tareas Puntuales no se renderizaban en Hoy). Se actualizaron
  las aserciones para reflejar el comportamiento correcto.

> **Nota de entorno de goldens (importante para CI):** en este working tree los goldens
> están generados en **WSL** (p. ej. `settings_screen`/`paywall_screen` del WIP pasan en
> WSL y fallan en Windows por antialiasing de fuentes). DEPLOY.md recomienda Windows para
> `analyze`/`test`, pero los goldens del árbol son WSL. Se regeneraron los míos en WSL para
> mantener el árbol **consistente y 100 % verde en WSL**. El equipo debería **estandarizar
> el entorno de goldens** (todo WSL o todo Windows) antes de activar la validación de
> goldens en CI; mezclarlos hará fallar uno u otro entorno.

### Paridad dev→prod (gate §3 DEPLOY.md)
- **Secretos que el código exige**: `GOOGLE_PLAY_SA_JSON`, `APP_STORE_PRIVATE_KEY`
  (defineSecret en `sync_entitlement.ts`). Estado: **WIP, no provisionados** → `syncEntitlement`
  queda en "bloqueo seguro" en prod (rechaza hasta proveerlos). Correcto para dev.
- **Config `.env.toka-dd241`**: **todas las claves que el código usa existen** (paridad de
  claves OK) pero con **valores vacíos** (bloqueo seguro): `ADMOB_BANNER_UNIT_*`,
  `APP_STORE_*`, `GOOGLE_PLAY_PACKAGE_NAME`, `STRICT_RECEIPT_VALIDATION`,
  `TOKA_REQUIRE_REAL_AD_UNITS`. Para producción hay que rellenarlas con valores reales.

## 7. Checklist para PRODUCCIÓN (lo que falta)

- [ ] **Alta de los 12 SKUs** en Google Play Console y App Store Connect (suscripciones; base plans mensual/anual). Mantener los 2 legacy `toka_premium_*`.
- [ ] **Precios localizados** por país (la tabla de `STORE_CATALOG.md` son referencias €).
- [ ] **Free trial 14 días** en los base plans anuales (al menos los 3 tiers; opcional Plus).
- [ ] **Secretos IAP** en Secret Manager de prod: `GOOGLE_PLAY_SA_JSON`, `APP_STORE_PRIVATE_KEY`.
- [ ] **Rellenar `.env.toka-dd241`** con valores reales: `APP_STORE_*`, `GOOGLE_PLAY_PACKAGE_NAME`, `STRICT_RECEIPT_VALIDATION=true`, `ADMOB_BANNER_UNIT_*`, `ADMOB`/intersticial units, `TOKA_REQUIRE_REAL_AD_UNITS=true`.
- [ ] **AdMob unit IDs reales** (banner + intersticial, Android/iOS) por Remote Config (`ad_*_unit_*`) y/o env. Hoy en test IDs (dev).
- [ ] **RTDN (Pub/Sub) + App Store Server Notifications (webhook)** apuntando a las funciones de prod.
- [ ] **Defaults de Remote Config** de lanzamiento (ON) publicados en **ambos** namespaces (cliente + server template REST) para los 3 flags que el backend lee.
- [ ] **Índices `COLLECTION_GROUP`** declarados en `firestore.indexes.json` para cualquier `collectionGroup().where(...)` (el emulador no los exige; prod sí). Revisar antes de deploy.
- [ ] Verificar los 12 flujos de compra en **sandbox/test** de cada store antes de promover.
- [x] (No-monetización) Goldens del WIP regenerados + tests de contenido actualizados → suite verde. **Pendiente del equipo:** estandarizar entorno de goldens (WSL vs Windows) para CI.

## 8. Riesgos abiertos

| Riesgo | Severidad | Nota |
|--------|-----------|------|
| Dashboard >1 MB con miles de tareas activas | Media | Preexistente, task-driven, **no** por el tope 25. Mitigar capando `activeTasksPreview` si aparece en hogares reales. |
| `member_packs_enabled` OFF en caliente deja over-cap | Baja | No destructivo; documentado. Toggle de lanzamiento. |
| Restore tras pack expirado descongela todo > cap | Baja | Edge case; over-cap no destructivo. |
| Entorno de goldens mixto (WSL vs Windows) | Media | Los 11 fallos WIP se corrigieron (suite verde en WSL). Pero el árbol genera goldens en WSL y DEPLOY.md dice Windows → estandarizar antes de validar goldens en CI. |
| Secretos IAP + config prod vacíos | Alta (para prod) | Bloqueo seguro intencional en dev; rellenar para prod. |
| App Check bloquea callables en APK debug | Media (QA device) | Registrar debug token para verificar `syncEntitlement` en dispositivo. |

## 9. Archivos del cierre

**Nuevos (lib)**: `lib/features/subscription/domain/renewal_product.dart`,
`lib/features/subscription/application/current_tier_provider.dart`.
**Modificados (lib)**: `lib/features/subscription/application/rescue_view_model.dart`,
`lib/features/subscription/presentation/skins/rescue_screen_v2.dart`.
**Tests nuevos**: `test/unit/features/subscription/renewal_product_test.dart`.
**Tests modificados**: `test/unit/features/subscription/rescue_view_model_test.dart`,
`test/ui/features/subscription/rescue_screen_test.dart`.
**Tests WIP corregidos (preexistentes)**: `test/ui/features/tasks/complete_task_dialog_test.dart`,
`test/unit/features/tasks/recurrence_order_test.dart`.
**Goldens regenerados (WSL)**: `members_screen.png`, `complete_task_dialog.png`,
`pass_turn_dialog.png`, `pass_turn_dialog_minimal.png`, `today_card_todo_{no_buttons,overdue,with_buttons}.png`,
`today_card_done.png`.
**Docs nuevos**: `docs/cierre-monetizacion/{STORE_CATALOG,REMOTE_CONFIG_FLAGS,INFORME_CIERRE}.md`
(+ resultados de QA en §6 de este informe / `QA_E2E.md`).
