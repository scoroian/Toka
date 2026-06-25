# Diseño — Publicidad diferenciada (banner vs intersticial, per-usuario)

Fecha: 2026-06-24. Fase: monetización de ads. Firebase dev: `toka-dd241`.

## Objetivo

Centralizar el cálculo de visibilidad de anuncios combinando **estado del hogar**
(premium/tier) × **entitlement individual Toka Plus** × **rol de pagador**, e integrar
el **intersticial** de AdMob (hoy solo hay banner). Todo detrás de flags de Remote
Config, reversible al comportamiento actual.

## Matriz (fuente de verdad)

| Contexto del miembro | Banner | Intersticial |
|---|:--:|:--:|
| Hogar Free, sin Toka Plus | sí | sí |
| Hogar Free, con Toka Plus | no | no |
| Hogar Premium, el pagador (`currentPayerUid`) | no | no |
| Hogar Premium, miembro sin Plus | **sí (solo banner)** | no |
| Hogar Premium, miembro con Plus | no | no |

Reglas puras que la generan:
- **Intersticial** ⇔ hogar NO Premium ∧ usuario SIN Plus (Premium de hogar lo elimina para todos).
- **Banner** ⇔ usuario SIN Plus ∧ NO es el pagador de un hogar Premium (se quita solo individualmente).

## Componentes

### 1. Función pura + provider de visibilidad
`computeAdVisibility({homeIsPremium, isPayer, hasPlus}) -> AdVisibility{banner, interstitial}`
```
interstitial = !homeIsPremium && !hasPlus
banner       = !hasPlus && !(homeIsPremium && isPayer)
```
`adVisibilityProvider` (`@riverpod`), inputs leídos de Firestore:
- `homeIsPremium` ← `dashboardProvider.premiumFlags.isPremium` (server-authoritative).
- `isPayer` ← `currentHomeProvider.currentPayerUid == uid` (`authProvider`).
- `hasPlus` ← `plusActiveProvider`.
- **Fail-safe**: dashboard o currentHome en loading/error → `AdVisibility(false, false)` (ocultar ambos).
- Recálculo en caliente automático (providers reactivos).

### 2. Banner
`adBannerConfigProvider` ramifica por el flag maestro `ad_differentiated_enabled`:
- ON → `show = adVisibility.banner`.
- OFF → comportamiento actual: `premiumFlags.showAds && adFlags.showBanner`.

`ad_banner.dart`: ocultar solo si `!show` (no si `unitId` vacío). El widget resuelve
`_effectiveUnitId(unitId)` que ya devuelve **test IDs** en `kDebugMode`/vacío, de modo
que un miembro de hogar Premium (unit vacío en dashboard) ve banner de test en dev.
Test IDs siguen viviendo solo en `ad_banner.dart`. Nota prod: ops debe fijar
`ad_banner_unit_*` en RC para el unit real (fase de salida).

### 3. Intersticial (nuevo)
- Decisión pura `shouldShowInterstitial({enabled, visibility, now, lastShownAt, sessionCount, minIntervalSeconds, maxPerSession}) -> bool`:
  `enabled ∧ visibility.interstitial ∧ (now-lastShownAt ≥ minInterval) ∧ (sessionCount < maxPerSession)`.
- `adInterstitialControllerProvider` (Notifier): estado `lastShownAt` + `sessionCount`;
  `maybeShow()` consulta la decisión pura, carga/mu­estra `InterstitialAd` (test ID en dev),
  precarga el siguiente, actualiza estado.
- **Disparador**: cambio de pestaña principal. `AdInterstitialTrigger` (ConsumerStatefulWidget
  en el shell) detecta el cambio de tab y llama `maybeShow()`. El cap de intervalo (~3,5 min)
  evita que cambios rápidos disparen otro. Nunca desde completar tarea / flujos críticos.

### 4. Remote Config (maestro + intersticial)
| Clave | Tipo | Default |
|---|---|---|
| `ad_differentiated_enabled` | bool | false |
| `ad_interstitial_enabled` | bool | false |
| `ad_interstitial_min_interval_seconds` | int | 210 |
| `ad_interstitial_max_per_session` | int | 3 |
| `ad_interstitial_unit_android` / `_ios` | string | '' |

Getters en `RemoteConfigService` + tiempo real (`onConfigUpdated`).

## Tests
- Unit visibilidad: 5 filas + cada tier Premium como pagador/miembro + fail-safe + recálculo en caliente.
- Unit intersticial: decisión pura (enabled off, visibility off, intervalo, tope sesión, feliz).
- Widget intersticial: no se muestra con flag off / cap alcanzado.
- UI/golden banner: aparece/no según provider por fila; flags RC on/off.

## Contrato Fase 8
- `adVisibilityProvider` → `AdVisibility{banner, interstitial}`; `computeAdVisibility`.
- `adInterstitialControllerProvider`.
- Flags RC: los 5 de la tabla.

## Fail-safe (decisión documentada)
Mientras el estado (premium/Plus/pagador) no se conoce (loading/error) → **ocultar ambos**.
Evita parpadear un anuncio a un usuario de pago; coste de revenue despreciable.
