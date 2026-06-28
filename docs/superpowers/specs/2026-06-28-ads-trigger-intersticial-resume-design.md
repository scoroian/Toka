# Diseño — Hallazgo #10: Sacar el intersticial de la navegación core

> Lote "UX Hallazgos 2026-06-25" · Prompt `10-ads-trigger-intersticial.md` · Fecha 2026-06-28

## Problema

El anuncio intersticial se dispara con el **cambio de pestaña principal**
(Hoy/Historial/Miembros/Tareas/Ajustes). En una app de tareas del hogar, cambiar de
pestaña es la acción más frecuente; interrumpirla con un anuncio a pantalla completa es
uno de los patrones más molestos posibles. Hay mitigaciones (gracia en el primer cambio,
cap 3/sesión, intervalo 210 s), pero el **trigger** sigue siendo navegación core.

## Estado actual (qué hay y cómo está acoplado)

El subsistema ya está **bien desacoplado**:

- `AdInterstitialController.maybeShow()` (`lib/shared/widgets/ad_interstitial_controller.dart`)
  contiene **toda** la política: flag maestro + `ad_interstitial_enabled`, gracia del
  primer disparo de la sesión, cap por sesión, intervalo mínimo, gating de visibilidad
  per-usuario (`adVisibilityProvider`, que ya pone el intersticial a cero en hogares
  Premium para **todos** sus miembros) y precarga. Es **agnóstico del trigger**.
- La decisión pura vive en `shouldShowInterstitial(...)`
  (`lib/shared/widgets/ad_interstitial_decision.dart`).
- Lo **único** atado a navegación es `AdInterstitialTrigger`
  (`lib/shared/widgets/ad_interstitial_trigger.dart`): observa `tabIndex` y, en cada
  cambio, llama a `maybeShow()`. Se monta en `main_shell_v2.dart:180`.

**Conclusión de diseño:** el cambio correcto es **reemplazar el trigger** (qué llama a
`maybeShow()`), sin tocar la política de frecuencia ni el gating Premium. Esto minimiza
el riesgo de regresión y reusa toda la maquinaria existente y sus tests.

## Trigger elegido: volver a foreground tras ≥ X tiempo en background ("app resume")

Cuando la app **vuelve a primer plano** después de haber estado en segundo plano al menos
`X` segundos, se evalúa mostrar un intersticial (sujeto a todos los caps existentes).

### Por qué este y no los otros candidatos

- **Resume tras X tiempo (elegido):** nunca interrumpe una acción en curso — el usuario
  se fue de la app y volvió, no hay ninguna acción en vuelo. Es un patrón reconocido y
  tolerado (App Open / App Resume). Se **autoespacia** (hay que salir y volver). El
  **cold-start NO dispara** (solo cuenta un background real previo de ≥ umbral), así que
  abrir la app para usarla nunca está gateado por un ad. Es el de menor fricción.
- **Post-completar-tarea (descartado como principal):** completar es un **flujo crítico**
  (Hallazgo #02) con SnackBars de fallo/reintento y marca persistente; acoplar un ad ahí
  arriesga colisión con el reintento y, además, limpiar varias tareas seguidas es en sí
  un "flow" productivo que no conviene cortar.
- **Post-cierre de sheet de detalle (descartado):** más arbitrario; sigue interrumpiendo
  el "browsing" y un sheet no es un límite de sesión claro.

### Parámetro nuevo

`ad_interstitial_resume_min_background_seconds` (int, default **240** = 4 min). Es un
**parámetro de config**, no un feature flag (misma familia que
`ad_interstitial_min_interval_seconds` / `ad_interstitial_max_per_session`). Un
backgrounding corto (mirar una notificación, copiar un código, contestar un mensaje) **no**
debe disparar el ad; solo un "me fui y volví más tarde" real. Fail-safe al default 240 si
Remote Config no está disponible.

## Arquitectura de la solución

### Unidad pura nueva — decisión del momento

`bool shouldShowInterstitialOnResume({DateTime? backgroundedAt, required DateTime now, required int minBackgroundSeconds})`
en `ad_interstitial_decision.dart`. Devuelve `true` ⇔ hubo un background previo
(`backgroundedAt != null`) **y** transcurrieron ≥ `minBackgroundSeconds` desde entonces.
`backgroundedAt == null` (cold-start, sin background previo) ⇒ `false`. Testeable
exhaustivamente sin Flutter ni AdMob, igual que `shouldShowInterstitial`.

### Widget nuevo — `AdInterstitialResumeTrigger`

`lib/shared/widgets/ad_interstitial_resume_trigger.dart`. `ConsumerStatefulWidget` de
tamaño cero, `WidgetsBindingObserver`:

- En `AppLifecycleState.paused` / `hidden` / `detached`: registra `_backgroundedAt = now`
  (reloj inyectable `nowProvider`).
- En `AppLifecycleState.resumed`: si
  `shouldShowInterstitialOnResume(backgroundedAt: _backgroundedAt, now: now, minBackgroundSeconds: cfg.resumeMinBackgroundSeconds)`,
  llama (sin `await`, sin bloquear) a `ref.read(adInterstitialControllerProvider.notifier).maybeShow()`
  y limpia `_backgroundedAt`. La política (gracia/caps/visibilidad/Premium) la sigue
  resolviendo el controlador.

Separación de responsabilidades: **el trigger decide el _momento_** (resume tras X);
**el controlador decide la _frecuencia_ y la _elegibilidad_** (caps, gracia, Premium).

### Cambios en piezas existentes

- `main_shell_v2.dart`: sustituir `AdInterstitialTrigger(tabIndex: tabIndex)` por
  `const AdInterstitialResumeTrigger()` en el `Stack` del shell (sigue siendo tamaño cero,
  no afecta layout). `tabIndex` ya no se usa para ads.
- `ad_flags_provider.dart`: añadir `resumeMinBackgroundSeconds` a
  `InterstitialRemoteConfig` (+ `disabled` con default 240) y leerlo en el provider.
- `remote_config_service.dart`: añadir `ad_interstitial_resume_min_background_seconds: 240`
  a `_defaults` y el getter `adInterstitialResumeMinBackgroundSeconds`.
- `ad_interstitial_controller.dart`: actualizar el doc-comment ("Disparado por el cambio de
  pestaña" → "Disparado al volver a foreground tras X tiempo") y renombrar el campo de
  gracia `_firstTabChangeSeen` → `_firstShowAttemptSeen` (mismo comportamiento; nombre
  agnóstico del trigger). **Sin cambios de lógica.**
- Eliminar `ad_interstitial_trigger.dart` y su test (reemplazados).
- `docs/cierre-monetizacion/REMOTE_CONFIG_FLAGS.md`: documentar el nuevo parámetro (y nota
  para el Hallazgo #21, que publica los flags en ambos namespaces).

## Lo que NO cambia (garantías por construcción)

- **Caps**: gracia, cap por sesión (3), intervalo mínimo (210 s) → viven en `maybeShow()`,
  intacto.
- **Premium = cero**: `adVisibilityProvider` (intersticial visible ⇔ hogar no-Premium ∧ sin
  Plus) gatea dentro de `maybeShow()`; no se toca → cero regresión.
- **Flag**: `ad_interstitial_enabled` (+ maestro `ad_differentiated_enabled`) sigue siendo
  condición necesaria.
- **Banner**: no se toca (Hallazgo #06).

## Criterios de aceptación (del prompt) — VERIFICADOS 2026-06-28

- [x] El intersticial **ya no** se dispara por cambiar de pestaña. (emu Free: 10
      cambios → 0 intersticiales, con subsistema vivo confirmado por el banner.)
- [x] Se dispara al volver a foreground tras ≥ umbral, respetando caps (3/sesión,
      intervalo, gracia) y el flag `ad_interstitial_enabled`. (emu Free: resume #1 =
      gracia; resume #2 → intersticial AdMob a pantalla completa.)
- [x] Hogar Premium: cero intersticiales (sin regresión). (MI_9 CasaDos: tabs + 2
      ciclos resume → 0 `AdActivity` en logcat.)
- [x] Sin impacto en la fluidez de la navegación (el trigger ya no conoce las pestañas).

## Plan de pruebas

### Unit (decisión pura) — `ad_interstitial_decision_test.dart`
- `shouldShowInterstitialOnResume`: sin background previo (`null`) → false; background <
  umbral → false; background ≥ umbral → true; límite exacto (== umbral) → true.

### Widget — `ad_interstitial_resume_trigger_test.dart`
- resume tras background ≥ umbral → `maybeShow` llamado 1 vez.
- resume tras background < umbral → no llama.
- resume sin background previo (cold) → no llama.
- dos ciclos background→resume, ambos ≥ umbral → 2 llamadas.
- (regresión) reconstrucciones / cambios de ruta del widget **no** llaman a `maybeShow`
  (el trigger no observa pestañas; estructuralmente no puede dispararse por navegación).

### Controller (sin cambios de lógica) — `ad_interstitial_controller_test.dart`
- La batería existente sigue verde tras el rename del campo de gracia (gating, cap de
  frecuencia, gracia, robustez). El nuevo trigger usa el mismo `maybeShow()`.

### Verificación en dispositivo (Firebase real `toka-dd241`, APK debug `main.dart`)
1. MI_9 (hogar Free): navegar entre pestañas repetidamente → **no** aparece intersticial.
2. MI_9 (hogar Free): background ≥ umbral y volver → aparece (respetando gracia/cap).
   Background corto y volver → no aparece.
3. Emulador (hogar Premium): cualquier acción + resume → **cero** intersticiales.

> El intersticial usa AdMob (test IDs en debug), **no** callables → App Check no bloquea
> esta verificación. Para acortar el ciclo en device, el umbral RC se puede bajar
> temporalmente (p. ej. 15 s) y restaurar al cerrar.

## Riesgos / notas

- El default 240 s aplica aunque RC no esté publicado (fail-safe). El Hallazgo #21
  publicará el parámetro en ambos namespaces; aquí solo se añade el default cliente.
- La gracia (primer disparo libre) implica que el usuario debe hacer dos ciclos
  background→resume ≥ umbral antes de la **primera** impresión real. Es deliberadamente
  conservador y coherente con el espíritu del hallazgo (reducir intrusividad).
