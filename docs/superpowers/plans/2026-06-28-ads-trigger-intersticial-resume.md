# Plan — Hallazgo #10: intersticial por "app resume" (no navegación)

> Diseño: `docs/superpowers/specs/2026-06-28-ads-trigger-intersticial-resume-design.md`
> Estilo: TDD por tarea (test rojo → impl → verde → analyze). Sin tocar la política de
> frecuencia ni el gating Premium del controlador.

## Tarea 1 — Decisión pura `shouldShowInterstitialOnResume`

**Archivo:** `lib/shared/widgets/ad_interstitial_decision.dart` (+ test
`test/unit/shared/widgets/ad_interstitial_decision_test.dart`).

- Test primero: sin background previo (`null`) → false; `< umbral` → false;
  `>= umbral` → true; `== umbral` → true.
- Impl: función pura
  `bool shouldShowInterstitialOnResume({DateTime? backgroundedAt, required DateTime now, required int minBackgroundSeconds})`.

**Gate:** `flutter test test/unit/shared/widgets/ad_interstitial_decision_test.dart`.

## Tarea 2 — Parámetro RC `ad_interstitial_resume_min_background_seconds`

**Archivos:** `lib/shared/services/remote_config_service.dart`,
`lib/shared/widgets/ad_flags_provider.dart`.

- `_defaults`: añadir `'ad_interstitial_resume_min_background_seconds': 240` con comentario.
- Getter `int get adInterstitialResumeMinBackgroundSeconds` (fallback 240).
- `InterstitialRemoteConfig`: campo `resumeMinBackgroundSeconds` (en ctor, en `disabled`
  con 240) + leerlo en `interstitialRemoteConfigProvider`.
- Actualizar tests que construyen `InterstitialRemoteConfig` (controller test) con el nuevo
  parámetro (default 240).

**Gate:** `flutter analyze` de los 2 archivos + el controller test compila.

## Tarea 3 — Widget `AdInterstitialResumeTrigger`

**Archivo nuevo:** `lib/shared/widgets/ad_interstitial_resume_trigger.dart`
(+ test `test/ui/shared/widgets/ad_interstitial_resume_trigger_test.dart`).

- `ConsumerStatefulWidget` tamaño cero, `WidgetsBindingObserver`
  (`addObserver`/`removeObserver`).
- `didChangeAppLifecycleState`:
  - `paused`/`hidden`/`detached` → `_backgroundedAt = ref.read(nowProvider)()`.
  - `resumed` → si `shouldShowInterstitialOnResume(...)` con `cfg.resumeMinBackgroundSeconds`,
    `ref.read(adInterstitialControllerProvider.notifier).maybeShow()` (sin await) y limpiar
    `_backgroundedAt`.
- Test con `_SpyController` + reloj fake (override `nowProvider`) + override
  `interstitialRemoteConfigProvider`; conducir el ciclo de vida con
  `tester.binding.handleAppLifecycleStateChanged(...)`. Casos: resume ≥ umbral → 1;
  resume < umbral → 0; resume sin background → 0; dos ciclos ≥ umbral → 2; rebuild sin
  ciclo de vida → 0 (regresión "navegación no dispara").

**Gate:** `flutter test test/ui/shared/widgets/ad_interstitial_resume_trigger_test.dart`.

## Tarea 4 — Cablear en el shell + limpiar trigger viejo

**Archivos:** `lib/shared/widgets/skins/main_shell_v2.dart`,
`lib/shared/widgets/ad_interstitial_controller.dart`; **eliminar**
`lib/shared/widgets/ad_interstitial_trigger.dart` y
`test/ui/shared/widgets/ad_interstitial_trigger_test.dart`.

- Shell: importar el nuevo trigger; reemplazar `AdInterstitialTrigger(tabIndex: tabIndex)`
  por `const AdInterstitialResumeTrigger()`; ajustar comentario.
- Controller: renombrar `_firstTabChangeSeen` → `_firstShowAttemptSeen` (mismo
  comportamiento) y actualizar doc-comments que mencionan "cambio de pestaña".
- Borrar el trigger viejo y su test.

**Gate:** `flutter analyze lib/shared` limpio; `grep -r AdInterstitialTrigger` sin
resultados (solo el nuevo `AdInterstitialResumeTrigger`).

## Tarea 5 — Doc de flags + gates finales

**Archivo:** `docs/cierre-monetizacion/REMOTE_CONFIG_FLAGS.md` (fila nueva en §2 para el
parámetro; nota para #21).

**Gates finales:**
- `flutter analyze` (archivos del hallazgo) → sin errores.
- `flutter test test/unit/shared/widgets/ test/ui/shared/widgets/` → verde.
- Build APK debug `main.dart` (Windows) → compila.

## Verificación en dispositivo (tras gates)

Ver plan de pruebas del diseño. Bajar temporalmente el umbral RC (p. ej. 15 s) para
acortar el ciclo y restaurar a 240 al cerrar. Capturas a `C:\tmp\h10\`.
