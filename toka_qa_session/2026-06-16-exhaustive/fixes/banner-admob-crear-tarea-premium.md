# §7 — 🟡 Banner de AdMob visible en "Crear tarea" pese a premium

Estado: **RESUELTO** · Causa raíz corregida en cliente + backend + tooling QA · Verificado end-to-end en los **2 dispositivos** (MI_9 físico + emulador) + backend E2E contra producción (toka-dd241) + cobertura de tests (regresión cliente que falla antes / pasa después) · Fecha: 2026-06-17

## Bug

Con el hogar en premium (`dashboard.premiumFlags.showAds=false`), la pantalla
**Crear tarea** seguía mostrando el banner de AdMob de prueba, mientras que Hoy
lo ocultaba. Reportado como "la pantalla de creación no respeta el flag premium
para ads".

## Diagnóstico / causa raíz

El dashboard (`homes/{homeId}/views/dashboard`) tiene **dos** grupos de flags
distintos:

- `premiumFlags.showAds` — señal **autoritativa** del estado premium del hogar.
- `adFlags.showBanner` + `adFlags.bannerUnit` — flag **derivado** que consume la UI.

Toda la UI de banner cuelga de **una única fuente**, el provider
`adBannerConfigProvider` (`lib/shared/widgets/ad_banner_config_provider.dart`),
que alimenta el **único** `AdBanner` del shell (`MainShellV2`) y los cálculos de
padding (`main_shell_v2`, `ad_aware_bottom_padding`, `bottom_sheet_padding`).
Antes del fix ese provider leía **solo** `adFlags.showBanner`:

```dart
show: dashboard?.adFlags.showBanner ?? false,
```

El problema: `adFlags` puede quedar **desincronizado** respecto a `premiumFlags`.
Las vías de producción que tocan premium (`syncEntitlement`, `updateDashboard`,
`applyDowngradePlan`, `restorePremiumState`) escriben **ambos** flags de forma
coherente, **pero el toggle de QA/debug no**:

- `functions/src/homes/index.ts` → `debugSetPremiumStatus` actualizaba
  `premiumFlags` (incluido `showAds`) pero **no** `adFlags`.
- `secrets/qa_premium.js` (réplica del callable para QA) hacía lo mismo.

Resultado tras `qa_premium.js … active` partiendo de un hogar gratis:
`premiumFlags.showAds=false` pero `adFlags.showBanner=true` (stale). Como el
provider solo miraba `adFlags`, el shell pintaba banner en **todas** las
pantallas hasta que el siguiente recompute (`refreshDashboard` →
`updateDashboard`) corregía `adFlags`. La diferencia observada Hoy/Crear-tarea es
una **carrera con ese recompute**: `dashboardProvider` lanza `refreshDashboard`
en el bootstrap (fire-and-forget), que reescribe `adFlags.showBanner=!isPremium`
y "auto-cura" el estado; según en qué pantalla pille el snapshot stale vs. el ya
corregido, el banner aparece en una y no en otra. Es decir: banner que parpadea
para usuarios premium durante la ventana stale.

Confirmado leyendo Firestore de producción (Admin SDK) tras forzar el estado
exacto del bug:

```
premiumFlags: {"isPremium":true,"showAds":false,...}
adFlags:      {"showBanner":true,"bannerUnit":"ca-app-pub-3940256099942544/6300978111"}  ← STALE/incoherente
```

No es falso positivo: es una incoherencia real de datos + una fuente de verdad
equivocada en el cliente.

## Fix (defensa en profundidad — cubre TODAS las pantallas)

Como hay **un solo** banner (el del shell) y **una sola** fuente
(`adBannerConfigProvider`), corregir esa fuente cubre Hoy, Tareas, Miembros,
Historial y Crear/Editar tarea de una vez.

1. **Cliente (autoritativo)** — `lib/shared/widgets/ad_banner_config_provider.dart`:
   gatea `show` también por `premiumFlags.showAds`. Un hogar premium **nunca**
   muestra banner aunque `adFlags` llegue stale.
   ```dart
   final adsAllowed = dashboard?.premiumFlags.showAds ?? true;
   return AdBannerConfig(
     show: adsAllowed && (dashboard?.adFlags.showBanner ?? false),
     unitId: dashboard?.adFlags.bannerUnit ?? '',
   );
   ```

2. **Backend (causa raíz)** — `functions/src/homes/index.ts` → `debugSetPremiumStatus`:
   ahora escribe `adFlags` coherente con `premiumFlags`. La derivación se extrajo
   a una función pura testeable `buildDebugDashboardFlags(typed)` en el nuevo
   módulo `functions/src/homes/debug_premium_flags.ts` (mismo patrón que
   `debug_premium_allowlist.ts`, para no cargar `index.ts` —que inicializa
   firebase-admin— en los tests). Invariante: `adFlags.showBanner === premiumFlags.showAds`.

3. **Tooling QA** — `secrets/qa_premium.js`: ahora escribe también `adFlags`
   (`showBanner:!isPremium`, `bannerUnit:""` en premium) → los repros futuros de
   QA ya nacen coherentes.

## Tests

- **Dart** `test/unit/shared/widgets/ad_banner_config_provider_test.dart` (nuevo, 5 casos):
  - gratis + banner activo → muestra.
  - **premium con `adFlags` STALE** (`showAds=false`, `showBanner=true`) → **NO** muestra (regresión del bug; falla antes del fix, pasa después).
  - premium coherente → oculto.
  - gratis sin banner → oculto.
  - sin dashboard → oculto.
- **Backend** `functions/src/homes/homes_callables.test.ts` (+6 casos sobre `buildDebugDashboardFlags`):
  - invariante `showBanner === showAds` en **todos** los estados.
  - estados premium → ads off + banner off + `bannerUnit:""`.
  - estados gratis → ads on + banner on + unit no vacío.
  - rescue/active → rescueFlags correctos.
- `flutter analyze` limpio en los archivos tocados. `tsc --noEmit` (strict) sin errores. `jest` homes: **74/74**.

## Evidencia de verificación

**Backend/tooling, E2E contra producción (toka-dd241), hogar `SMQRtCjrA09gPIr1wazD`** `[ADMIN SDK]`:

| Acción | premiumFlags.showAds | adFlags.showBanner | adFlags.bannerUnit | ¿banner? |
|---|---|---|---|---|
| estado stale forzado (bug) | false | **true** | test unit | sí (BUG) |
| `qa_premium.js … active` (FIXED) | false | **false** | `""` | no ✓ |
| `qa_premium.js … free` (FIXED) | true | **true** | test unit | sí ✓ |

→ Tras el fix, `adFlags` queda siempre coherente con `premiumFlags`; nunca se
crea el estado stale. Hogar restaurado a `active` al terminar.

**Cliente, end-to-end en los 2 dispositivos** (MI_9 `43340fd2` + emulador
`emulator-5554`), forzando el estado del dashboard en vivo vía Admin SDK con la
app abierta (el listener del dashboard recoge el cambio sin re-bootstrap, así que
el estado stale no se auto-cura) `[ADMIN SDK]`:

| Estado del dashboard | Crear tarea | Resultado |
|---|---|---|
| premium coherente (showAds=false, showBanner=false) | sin banner | ✓ síntoma resuelto |
| premium + `adFlags` **STALE** (showAds=false, **showBanner=true**) | **sin banner** | ✓ el fix (sin él, el banner aparecería) |
| free (showAds=true, showBanner=true) | banner AdMob de test visible | ✓ los ads siguen funcionando cuando corresponden |

El caso intermedio es el **discriminante**: reproduce exactamente el bug y
demuestra que el cliente ya no pinta banner pese a `adFlags.showBanner=true`.
Capturas tomadas, analizadas y **borradas** al terminar. Hogar restaurado a
`active` coherente.

## Otros hallazgos detectados durante el trabajo

### 🟠 `flutter build apk` limpio fallaba por exhaustividad de `switch` (CFE) — CORREGIDO

Al compilar un APK limpio (Flutter 3.44.2), el compilador de build (CFE) fallaba
con errores de **exhaustividad de `switch`** sobre tipos `sealed`, que el
**analyzer NO marca** (`flutter analyze` limpio), por lo que el flujo habitual de
`flutter run` incremental lo enmascaraba pero un build de release desde cero lo
rechazaba. Eran **2 sitios genuinos** (preexistentes en HEAD; archivos idénticos
a HEAD salvo line-endings) donde el CFE no infiere el tipo `sealed` del scrutinee
y lo trata como `dynamic`:

- `lib/features/history/application/history_view_model.dart:166/171` — `e` llega
  por `whenData(...).map((e) => switch(e){…})`. **Fix**: `.map((TaskEvent e) {…})`.
- `lib/features/tasks/application/create_edit_task_view_model.dart` — `rule` llega
  de `ref.read(taskFormNotifierProvider).recurrenceRule` (el CFE no resuelve el
  tipo de estado del provider generado). **Fix**: `final RecurrenceRule? rule = …`.

Ambos fixes son **behavior-preserving** (el analyzer ya aceptaba el código; la
anotación solo fija el tipo que ya infería). Con ellos, **`flutter build apk
--debug` compila limpio** (verificado: `√ Built app-debug.apk`) y se pudo
instalar/verificar en los 2 dispositivos.

**Aviso de tooling (no es un bug del repo):** ejecutar `flutter pub get` en **WSL**
deja rutas Linux en `.dart_tool/package_config.json`; un `flutter build` posterior
en **Windows** mis-resuelve los tipos de los providers generados de Riverpod y
hace fallar **muchos** más `switch` sobre provider-reads (p. ej. `switch (skin)`).
No es real: desaparece haciendo **`flutter pub get` en Windows antes de `build`**.
Por eso el build debe lanzarse siempre como `flutter.bat pub get && flutter.bat
build apk` desde Windows (ver memoria `clean-apk-build-broken-cfe-exhaustiveness`).
