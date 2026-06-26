# Diseño — Hallazgo #06: "Sin publicidad" honesto + copy banner-vs-intersticial

> Lote UX 2026-06-25 · Prompt `06-monetizacion-sin-publicidad-honesto.md`
> Fecha: 2026-06-26 · Estado: aprobado para implementación

## Problema

El modelo de anuncios de Toka tiene **dos ejes independientes** que el usuario no
entiende y que ningún copy explica:

- **Intersticial**: se quita si el **hogar** es Premium (beneficio colectivo, para
  todos los miembros).
- **Banner**: solo se quita **por usuario** (siendo el **pagador** de un hogar
  Premium, o teniendo **Toka Plus**).

Fuente de verdad del comportamiento (función pura, ya existente):
`lib/shared/widgets/ad_visibility_provider.dart`

```dart
final interstitial = !homeIsPremium && !hasPlus;
final banner = !hasPlus && !(homeIsPremium && isPayer);
```

Matriz resultante:

| Hogar | Pagador | Plus | Banner | Intersticial |
|-------|---------|------|--------|--------------|
| Free | – | no | sí | sí |
| Free | – | sí | no | no |
| Premium | sí | no | **no** | no |
| Premium | **no** | no | **sí** | no |
| Premium | no | sí | no | no |

Consecuencia vivida: en un hogar Premium, un **miembro que no paga sigue viendo
banner** y no entiende por qué. Y la tarjeta comparativa del paywall promete
`"Sin publicidad"`, **falso para los no-pagadores** (solo se les quita el
intersticial). El propio doc de diseño de monetización marcó esto como "riesgo de
percepción… exige copy muy claro" (`Arreglos/mejora_modelos_premium.md:94`) y ese
copy no existía.

## Hallazgo clave del análisis de código

La afirmación `"Sin publicidad"` **solo** vive en `PlanComparisonCard`
(`lib/features/subscription/presentation/widgets/plan_comparison_card.dart`),
que renderizan:

- el **paywall binario** (`paywall_screen_v2.dart` → `_BinaryPaywallBody`, flag
  `home_tiers_enabled` OFF), y
- la **pantalla de rescate** (`rescue_screen_v2.dart`).

El **paywall tiered** (flag ON, el de 3 planes) **no** usa esa tarjeta ni dice
"Sin publicidad" (solo `paywall_tiers_same_features`). Por tanto la corrección de
copy se concentra en `PlanComparisonCard`.

El paywall de **Toka Plus** (`plus_paywall_screen_v2.dart`) hoy **no menciona en
absoluto** la eliminación del banner (solo lista skins + métricas personales).

El **banner** se pinta en una única instancia (`AdBanner`) dentro del shell
(`lib/shared/widgets/skins/main_shell_v2.dart`); su visibilidad per-usuario la
decide `adBannerConfigProvider` → `adVisibilityProvider.banner`.

## Objetivo

Hacer honesto y comprensible el mensaje sobre anuncios:

1. El paywall de hogar deja de afirmar un genérico "Sin publicidad". Distingue
   **intersticial (hogar)** de **banner (individual)**.
2. El paywall de Toka Plus deja claro que quita el banner **a ti**.
3. Donde un no-pagador de hogar Premium ve banner, hay una **vía de
   entendimiento** (caption descartable + CTA a Toka Plus), sin nag agresivo.
4. Todo localizado (es/en/ro). Sin afirmaciones falsas.

## Diseño

### 1. Tarjeta comparativa honesta (criterio 1)

`PlanComparisonCard` + ARB.

- `paywall_feature_no_ads`: `"Sin publicidad"` → **`"Sin anuncios a pantalla
  completa"`**. Describe con precisión el **intersticial**, que el Premium del
  hogar sí quita para **todos** los miembros (verdadero en toda la matriz
  Premium). Se actualiza su `@description`.
- Nueva clave `paywall_ads_banner_note` (nota al pie dentro de la tarjeta):
  *"El banner inferior se quita para quien paga el plan; los demás miembros pueden
  quitarlo con Toka Plus."* Al vivir dentro de la tarjeta compartida, **paywall
  binario y rescate** quedan honestos por construcción (DRY).

La nota se renderiza bajo la tabla de features, con estilo `bodySmall` /
secundario, separada por un pequeño espacio. Clave de test
`Key('plan_comparison_ads_note')`.

### 2. Paywall de Toka Plus dice que quita el banner *a ti* (criterio 2)

`plus_paywall_screen_v2.dart` (`_PlansBody`) + ARB.

- Nueva fila `_Benefit` (icono `Icons.block`), **primera** de la lista (es el
  beneficio más universal):
  - `plusBenefitNoAdsTitle`: *"Sin banner de anuncios"*
  - `plusBenefitNoAdsDesc`: *"Quita el banner inferior solo para ti, en todos tus
    hogares."*
- `plusPaywallSubtitle` y `plusAlreadyActiveBody` se reescriben para incluir el
  banner (sin alargar de más):
  - subtitle: *"Quita el banner, desbloquea aspectos exclusivos y consulta tus
    métricas personales."*
  - alreadyActive body: *"Sin banner, con aspectos exclusivos y tus métricas
    personales."*

### 3. Caption descartable sobre el banner (criterio 3)

Nuevo widget + providers + integración en el shell.

**Elegibilidad (función pura + provider).** Nuevo archivo
`lib/shared/widgets/ad_banner_notice_provider.dart`:

```dart
/// Elegible para la caption ⇔ el usuario VE banner *por ser* miembro no-pagador
/// de un hogar Premium sin Plus (la única fila confusa: "Premium pero con
/// anuncios"). Espeja la rama premium de computeAdVisibility.
bool computeBannerNoticeEligible({
  required bool homeIsPremium,
  required bool isPayer,
  required bool hasPlus,
}) => homeIsPremium && !isPayer && !hasPlus;
```

- `adBannerNoticeEligibleProvider` (keepAlive): cablea los mismos inputs que
  `adVisibilityProvider` (dashboard `premiumFlags.isPremium`, pagador vía
  `currentHomeProvider`/`authProvider`, `plusActiveProvider`). Fail-safe `false`
  si dashboard/home desconocidos.
- `AdBannerNoticeDismissal` (`Notifier<Set<String>>`, keepAlive, **scope sesión /
  in-memory**) con `dismiss(String homeId)`.
- `adBannerNoticeVisibleProvider` (bool): `eligible && homeId != null &&
  !dismissed.contains(homeId)`. **Route/teclado-agnóstico**: cada consumidor lo
  combina con su propio `bannerVisible`.

**Widget** `BannerPremiumNoticeCaption`
(`lib/shared/widgets/banner_premium_notice_caption.dart`):

- Línea fina (`kNoticeHeight = 34`), surface translúcida tipo banner, separada del
  anuncio por un gap (política AdMob: sin solape ni adyacencia que induzca clics
  accidentales).
- Contenido: icono `Icons.info_outline` + texto `ad_banner_notice_text` (*"Quita
  también el banner con Toka Plus"*, tappable → `AppRoutes.plusPaywall`) + chevron
  `Icons.chevron_right` + `IconButton` ✕ (`Icons.close`, a11y
  `ad_banner_notice_dismiss`) que llama `dismiss(homeId)`.
- Keys: `Key('banner_premium_notice')`, CTA `Key('banner_premium_notice_cta')`,
  ✕ `Key('banner_premium_notice_dismiss')`.

**Integración en el shell** (`main_shell_v2.dart`): la caption se pinta como un
`Positioned` justo encima del banner cuando `bannerVisible &&
adBannerNoticeVisibleProvider`. Su altura se suma a la reserva inferior en los
**4 sitios** que reservan el slot del banner, vía un helper compartido para no
tapar contenido ni FABs:

1. `MainShellV2.build` (alto del `bottomNavigationBar` + `Positioned` de la
   caption).
2. `MainShellV2.bottomContentPadding` (ScrollViews de pantallas tab).
3. `MainShellV2.fabBottomPadding` (FABs).
4. `adAwareBottomPadding` (función libre, `ad_aware_bottom_padding.dart`).

Helper: `noticeSlotHeight({required bool visible}) => visible ? kNoticeHeight +
gap : 0`. Cada sitio: `noticeVisible = bannerVisible &&
ref.watch(adBannerNoticeVisibleProvider)`.

## Copys (es / en / ro)

| clave | es | en | ro |
|---|---|---|---|
| `paywall_feature_no_ads` | Sin anuncios a pantalla completa | No full-screen ads | Fără reclame pe tot ecranul |
| `paywall_ads_banner_note` | El banner inferior se quita para quien paga el plan; los demás miembros pueden quitarlo con Toka Plus. | The bottom banner is removed for whoever pays the plan; other members can remove it with Toka Plus. | Bannerul de jos dispare pentru cine plătește planul; ceilalți membri îl pot elimina cu Toka Plus. |
| `plusBenefitNoAdsTitle` | Sin banner de anuncios | No banner ads | Fără bannere publicitare |
| `plusBenefitNoAdsDesc` | Quita el banner inferior solo para ti, en todos tus hogares. | Removes the bottom banner just for you, in all your homes. | Elimină bannerul de jos doar pentru tine, în toate casele tale. |
| `plusPaywallSubtitle` | Quita el banner, desbloquea aspectos exclusivos y consulta tus métricas personales. | Remove the banner, unlock exclusive looks and check your personal metrics. | Elimină bannerul, deblochează aspecte exclusive și vezi-ți statisticile personale. |
| `plusAlreadyActiveBody` | Sin banner, con aspectos exclusivos y tus métricas personales. | No banner, with exclusive looks and your personal metrics. | Fără banner, cu aspecte exclusive și statisticile tale personale. |
| `ad_banner_notice_text` | Quita también el banner con Toka Plus | Remove the banner too with Toka Plus | Elimină și bannerul cu Toka Plus |
| `ad_banner_notice_dismiss` | Descartar | Dismiss | Închide |

> Convención de nombres ARB (codebase mixto): se sigue al vecino — claves de
> paywall/tarjeta en snake_case (`paywall_*`), claves de Plus en camelCase
> (`plus*`), claves del banner en snake_case (`ad_banner_notice_*`).

## Pruebas

### Unit / Widget
- `computeBannerNoticeEligible`: tabla de verdad completa (8 combinaciones).
- `computeAdVisibility`: ya cubre la matriz (incl. "Premium + no pagador",
  Fila 4); se conserva.
- Helper de altura del shell: la reserva crece con la caption visible y vuelve al
  valor base al descartar / no elegible.
- `PlanComparisonCard`: muestra "Sin anuncios a pantalla completa" + nota; NO
  muestra el genérico "Sin publicidad". Golden `plan_comparison_card_*` regen.
- `PaywallScreenV2` binario: golden regen (nota nueva).
- `PlusPaywallScreenV2`: muestra el beneficio "Sin banner de anuncios"; golden
  `plus_paywall_*` regen.
- `BannerPremiumNoticeCaption`: render del texto; tap CTA navega a
  `/subscription/plus`; tap ✕ descarta (deja de mostrarse para ese hogar).

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Hogar Premium con dos miembros: **pagador** en MI_9 (sin banner ni
   intersticial) y **no-pagador** en emulador (sin intersticial, **con** banner +
   caption). Capturas: el copy explica la diferencia.
2. Activar Toka Plus en la cuenta no-pagadora → banner **y** caption desaparecen.
   Capturas antes/después.
3. Paywall de hogar y de Plus: ningún texto promete "sin publicidad" de forma
   engañosa. Capturas.

## Gates
`flutter analyze` limpio · `flutter test test/unit/` + tests nuevos verde ·
goldens regenerados · verificación en ambos dispositivos.

## Dependencias
- Coordina ARB con **05** (✅, mismo `app_*.arb` de paywall) y **16**.
- Relacionado con **10** (trigger del intersticial).

## Decisiones tomadas
- Caption **descartable** (✕); descarte **por hogar, scope sesión** (in-memory:
  reaparece tras reinicio, suave, sin estado persistido).
- Nota del banner dentro de `PlanComparisonCard` (DRY: cubre binario + rescate).
- `paywall_feature_no_ads` reescrito (no se crea clave nueva) para no dejar
  huérfana una clave referenciada por la tarjeta.
