# Flags de Remote Config — modelo de monetización Toka

> Fuente de verdad: el **código**. Cliente: `lib/shared/services/remote_config_service.dart`
> (`_defaults`). Backend: `functions/src/shared/feature_flags.ts` (server template,
> default OFF embebido). Auditado 2026-06-24.

## 1. Inventario de flags del modelo de monetización

| Flag | Tipo | Default | Lado | Efecto | Revert (OFF) |
|------|------|---------|------|--------|--------------|
| `home_tiers_enabled` | bool | **false** | cliente + backend | Activa el modelo de **tiers por tamaño** (paywall de 3 tiers, display de tier, tope por tier). | Vuelve al **binario** (Premium 10 / Free 3); paywall Premium único; compra legacy `toka_premium_*`. `resolveEntitlement(tiersEnabled:false)` → tier `null`. |
| `member_packs_enabled` | bool | **false** | cliente + backend | Activa **packs de miembro** (sección packs en paywall, tope dinámico hasta 25). | El tope vuelve al del tier (Grupo 10), packs ignorados en `effectiveMaxMembers`. UI de packs oculta. Ver §3 (caveat over-cap). |
| `toka_plus_enabled` | bool | **false** | cliente + backend | Activa el eje **Toka Plus** individual (quita banner + skins + métricas, per-usuario). | `isPlus(Effectively)Active` → false: nadie tiene Plus aunque exista el doc. Banner vuelve, skins/ métricas revierten. Gating al consumir → efecto instantáneo. |
| `ad_differentiated_enabled` | bool | **false** | cliente | Flag **MAESTRO** de ads diferenciadas: banner per-usuario (`adVisibilityProvider`) + habilita subsistema de intersticial. | Banner vuelve al **legacy de hogar** (`premiumFlags.showAds && adFlags.showBanner`); intersticial desactivado (el controlador exige el maestro ON). |
| `ad_interstitial_enabled` | bool | **false** | cliente | On/off del **intersticial** (requiere además el maestro ON). | Sin intersticiales. |

## 2. Parámetros de config asociados (no son feature flags)

| Clave | Tipo | Default | Notas |
|-------|------|---------|-------|
| `ad_banner_enabled` | bool | true | Master legacy del banner (pre-diferenciación). |
| `ad_banner_unit_android` / `ad_banner_unit_ios` | string | '' | Unit IDs reales del banner; '' → test IDs en dev. |
| `ad_interstitial_unit_android` / `ad_interstitial_unit_ios` | string | '' | Unit IDs reales del intersticial; '' → test IDs en dev. |
| `ad_interstitial_min_interval_seconds` | int | 210 | Cap de frecuencia (~3,5 min). |
| `ad_interstitial_max_per_session` | int | 3 | Tope por sesión. |
| `ad_interstitial_resume_min_background_seconds` | int | 240 | **Hallazgo #10**: tiempo mínimo en segundo plano para que el regreso a primer plano ("app resume") sea momento elegible de intersticial. El trigger ya **no** es el cambio de pestaña. Pendiente de publicar en ambos namespaces (ver Hallazgo #21). |
| `paywall_default_plan` | string | 'monthly' | Plan preseleccionado. |
| `paywall_show_annual_savings` | bool | true | Badge de ahorro anual. |
| `rescue_notification_days` | int | 3 | Ventana de rescate. |
| `max_review_note_chars` | int | 300 | Límite de notas de valoración. |

## 3. Verificación de revert limpio (sin crash, sin estado inconsistente)

Todos los flags tienen **fallback seguro a OFF** y el gateo se aplica **read-time / al
consumir**, así que un cambio del flag surte efecto sin recomputar nada persistido:

- **`home_tiers_enabled` OFF**: `resolveEntitlement` ignora `premiumTier` persistido y
  devuelve binario (10/3). Un hogar Pareja (tope 2) pasaría a tope 10 → solo **expande**
  el cap, nunca deja miembros fuera. Limpio.
- **`toka_plus_enabled` OFF**: `isPlusEffectivelyActive`/`isPlusActive` cortan en seco;
  el doc `users/{uid}/entitlements/plus` se conserva (la verdad de la store), pero no
  concede beneficios. Banner/skins/métricas revierten al instante. Limpio.
- **`ad_differentiated_enabled` OFF**: `ad_banner_config_provider` toma la rama legacy;
  `ad_interstitial_controller` se desactiva. Limpio.
- **`member_packs_enabled` OFF** — ⚠️ **caveat documentado**: el tope efectivo vuelve a
  10 (Grupo base), pero los miembros que excedan 10 **no se congelan** por el flag (la
  congelación solo la dispara la cancelación/expiración del pack vía store). Resultado:
  un hogar con 15-25 miembros queda **over-cap** (15/10) hasta una cancelación real.
  Es **no destructivo** (no se pierde a nadie) y **el enforcement bloquea nuevas altas**
  (cap 10). El cap solo se reescribe al dashboard en el próximo recompute (sync/
  enforcement/reconcile/restore); hasta entonces el dashboard mantiene 25 (más benigno).
  **Recomendación operativa:** `member_packs_enabled` es un toggle de lanzamiento; no
  apagarlo en caliente sobre hogares que ya compraron packs. La UI cliente debe tolerar
  `memberCount > maxMembers` sin crash (verificado en cobertura/QA).

## 4. Defaults recomendados para el LANZAMIENTO

| Flag | Default lanzamiento | Razonamiento |
|------|---------------------|--------------|
| `home_tiers_enabled` | **true** | Es el modelo nuevo que se quiere lanzar. |
| `member_packs_enabled` | **true** | Packs disponibles para hogares Grupo. |
| `toka_plus_enabled` | **true** | Eje individual Plus disponible. |
| `ad_differentiated_enabled` | **true** | Matriz de ads per-usuario. |
| `ad_interstitial_enabled` | **true** (con caps por defecto) | Intersticial activo y limitado (210s / 3 por sesión). |
| `ad_banner_unit_*` / `ad_interstitial_unit_*` | unit IDs **reales** | Obligatorio en prod (guardrail `check-ad-units.js`). |

**Rollout seguro:** se puede lanzar con todos OFF (binario + banner legacy, sin riesgo)
y activarlos progresivamente desde la consola sin re-publicar la app, gracias al fallback
a OFF y al Remote Config en tiempo real (`onConfigUpdated`).

> Importante: el **server template** de Remote Config vive en un namespace distinto del
> de cliente (`firebase-server`). Publicar el flag server-side va por REST
> (`getServerTemplate`/`publishTemplate` solo es cliente). Hay que publicar el valor en
> AMBOS lados (cliente + server) para los 3 flags que el backend también lee
> (`home_tiers_enabled`, `toka_plus_enabled`, `member_packs_enabled`).
