# QA end-to-end — modelo de monetización (Fase 6)

> Proyecto: `toka-dd241` (dev). 2 dispositivos / 2 cuentas del **mismo hogar**
> `V4w8IDaA6FsALLdSip0S`: **MI_9** (físico, owner `Owner` = pagador) + **emulador-5554**
> (member `Sebas`). Estados forzados por **Admin SDK** (sin compra real). Flags ON.
> Capturas en `C:\tmp\qa_*.png` (no se commitean al repo — política DEPLOY.md).

## A. Enforcement server-side (callable desplegada `joinHomeByCode`)

Verificadores deterministas contra el backend **desplegado** en toka-dd241:

**`qa_verify_tier_enforcement.js`** — ✅ TODOS OK:
- Pareja(2) lleno → 3.º **RECHAZADO** (400 free_limit_members)
- Familia(5) lleno → 6.º **RECHAZADO**; en tope-1 → ACEPTADO
- Grupo(10) con 5 → ACEPTADO

**`qa_verify_pack_enforcement.js`** — ✅ TODOS OK:
- Grupo + ambos packs (tope **25**), 25 activos → **26.º RECHAZADO** (400)
- Grupo + ambos packs, 24 → 25.º ACEPTADO
- Grupo + solo +5 (tope 15), 15 → **16.º RECHAZADO**; 14 → 15.º ACEPTADO

➡️ **Los topes (tier y packs hasta 25) son server-side** y el 26.º se rechaza en el backend
real. Requisito clave de la fase, verificado objetivamente.

## B. Matriz de ads + Plus per-usuario (2 dispositivos, mismo hogar)

| # | Captura | Estado forzado | Dispositivo / cuenta | Resultado | Fila matriz |
|---|---------|----------------|----------------------|-----------|-------------|
| 1 | `qa_01_members_free_banner` | hogar **free** | emulador / member | **banner SÍ** (test ad) | Fila 1: Free sin Plus → banner sí |
| 2 | `qa_02_grupo_premium` | hogar **Grupo premium** (payer=owner) | emulador / member (no pagador, sin Plus) | **banner SÍ** | **Fila 4**: Premium miembro sin Plus → banner sí (diferenciadas) |
| – | `qa_mi9` | mismo hogar **Grupo premium** | MI_9 / owner = **pagador**, sin Plus | **banner NO** | **Fila 3**: Premium pagador → banner no |
| 3 | `qa_03_member_plus` | hogar premium + **Plus ON** en el member | emulador / member con Plus | **banner NO** + **skin Oceano** (avatares azules) desbloqueada | **Fila 5**: Premium miembro con Plus → no/no |
| 4 | `qa_04_plus_revert` | **Plus OFF** en el member | emulador / member | **banner REAPARECE** + skin revierte a default | Revert de Plus en vivo |

**Lecturas clave:**
- Con el hogar premium, el dashboard escribe `showAds=false`/`showBanner=false`. Aun así el
  **emulador (miembro no pagador) muestra banner** → prueba que la app usa la ruta
  **diferenciada** (`adVisibilityProvider`): la lógica legacy lo ocultaría para todos. El
  **MI_9 (pagador)** del MISMO hogar NO muestra banner. Es exactamente el propósito del
  eje de ads diferenciadas.
- **Plus es per-usuario**: el member con Plus pierde banner y gana skin; el owner (sin Plus)
  del mismo hogar conserva su skin por defecto. Activar/desactivar Plus surte efecto **en
  vivo** (banner + skin) sin reinstalar.
- **Fila 2** (Free **con** Plus → no/no) no se capturó por separado: es la misma lógica
  per-usuario de Plus que la Fila 5 (Plus ⇒ sin banner con independencia del premium del
  hogar) y está cubierta por unit tests (`computeAdVisibility`, `ad_banner_config_provider`).

## C. Sincronización en vivo

Cada estado se forzó por Admin SDK y **ambos dispositivos lo reflejaron sin reinstalar**:
forzar Grupo premium → MI_9 (pagador) ocultó banner y el emulador (miembro) lo mantuvo;
forzar/quitar Plus en el member → el emulador cambió skin + banner al instante. El hogar,
tope y flags premium se propagan por el listener del dashboard (`views/dashboard`).

## D. Tiers + packs (dashboard denormalizado)

Tras forzar Grupo premium, `homes/V4w8.../views/dashboard.premiumFlags` =
`{isPremium:true, showAds:false, tier:"grupo", maxMembers:10, memberPacks:{plus5,plus10}}`
y `adFlags.showBanner=false`. El cliente lo LEE (no recomputa). El tope efectivo real con
packs (25) lo gobierna el backend (verificado en §A).

## E. Cobertura por unit/widget tests (complementa lo visual)

La matriz completa de ads (5 filas + cruzadas), el gating de Plus, la selección de tier del
paywall, los packs (none/+5/+10/ambos → 10/15/20/25) y el revert de los 5 flags están
**testeados** (ver `INFORME_CIERRE.md` §4). Lo visual de §B confirma el comportamiento
end-to-end en dispositivos reales contra datos en vivo.

## Notas de estado dejado en dev
- Hogar `V4w8...` restaurado a **free** (baseline). Plus del member **OFF**.
- Remote Config de toka-dd241: flags del modelo **ON** (server + cliente) — dejados así por
  ser el estado de lanzamiento recomendado; ajustar desde consola si se quiere dev en OFF.
- App en dispositivos: build **debug** (ribbon DEBUG). App Check bloquea callables de compra
  en debug; por eso el QA fuerza estados por Admin SDK en vez de compra real (las lecturas
  de dashboard/entitlement NO se bloquean).
