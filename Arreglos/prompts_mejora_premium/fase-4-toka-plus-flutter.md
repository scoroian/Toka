# FASE 4 — Toka Plus / skins + métricas personales (FLUTTER)

> Pega este prompt completo como primer mensaje en una **sesión nueva** de Claude Code en el repo Toka. Es autónomo: no necesitas (ni debes) leer ningún otro documento de análisis.
>
> **Prerrequisito:** Fase 3 (Toka Plus — backend) desplegada a dev. Lee del **código** cómo se persiste y se lee el entitlement Plus per-usuario (ruta/campo/reglas). No inventes nombres.
>
> **Límite de alcance importante:** en esta fase Plus habilita **skins** y **métricas personales** y añade el **punto de compra**. El efecto "Plus **quita el banner**/intersticial" se implementa en la **Fase 5** (que centraliza toda la matriz de ads). Aquí NO toques el sistema de ads.

---

## 0. Quién eres y qué es Toka

Eres un ingeniero senior Flutter + Firebase en **Toka**, app cooperativa de tareas del hogar. Premium por hogar + producto individual **Toka Plus** por usuario.

Stack: Flutter 3.x + Dart 3.x (Riverpod, go_router, freezed, get_it), Firestore, Cloud Functions Node 20, FCM, Remote Config, AdMob, in_app_purchase. Firebase **dev**: `toka-dd241`.

## 1. Regla de oro: el CÓDIGO es la única fuente de verdad

- **Analiza el código tú mismo, desde cero.** Nada de resúmenes/hallazgos/spec/análisis previos.
- **PROHIBIDO leer**: `Arreglos/*.md`, `Monetizacion/`, `toka_qa_session/**/*.md`, `architecture/*.md`, cualquier `*.md` de spec/análisis, y los `.md` de este directorio salvo este prompt. **SÍ**: `CLAUDE.md`, `DEPLOY.md`.
- El QUÉ está embebido. Ante duda real, **pregunta**.

## 2. Workflow obligatorio (en orden)

1. **Brainstorming** (`superpowers:brainstorming`).
2. **TDD** (`superpowers:test-driven-development`): tests antes. **mocktail**.
3. Implementa.
4. `flutter analyze` sin errores.
5. Si tocas freezed/riverpod/json: `dart run build_runner build --delete-conflicting-outputs` (corre `flutter pub get` en el entorno de tests; build de Windows reescribe `package_config.json` y rompe tests en WSL — tests ANTES del build o restaura con `pub get`).
6. Tests verdes: `flutter test test/unit/` y `flutter test test/ui/`.
7. Compila, instala y **verifica** en dispositivo (sección 4).

## 3. Restricciones de código

- **freezed** para modelos/estados; `@riverpod` + sufijo `Provider`; `AsyncValue`; `ref.onDispose`.
- Strings visibles en ARB (es/en/ro) vía `l10n.clave`. **Nunca** hardcodear UI.
- Tema/skins en `core/theme/`. El sistema de skins (`AppSkin`/`SkinSwitch`/`skin_provider`/`skin_switcher`) **ya existe**: intégrate con él, no lo reescribas.
- El entitlement Plus se lee de Firestore (Fase 3), nunca se infiere localmente.

## 4. Protocolo de verificación en 2 dispositivos (OBLIGATORIO)

- **MI_9** (USB, 1080×2340) + **emulador** (`emulator-5554`, 1080×2400), ambos a `toka-dd241`.
- Cuentas QA (`TokaQA2024!`): owner / member / admin. **Una distinta por dispositivo**.
- **Login por adb SIN Google** (ver `CLAUDE.md`): tap email → text → tap contraseña → text → iniciar. NUNCA `KEYCODE_TAB`/autocomplete. Campos sensibles char-a-char.
- **Forzar Plus por Admin SDK** (`secrets/toka-sa.json`)/script QA. NO compra real.
- **Capturas**: `adb exec-out screencap -p`; >1900px redimensiona con magick antes de leer.
- Verifica: Plus desbloquea cosas **solo en la cuenta con Plus**; la otra cuenta las ve **bloqueadas** con CTA al paywall; los cambios se **sincronizan** al activar/desactivar Plus.

## 5. Remote Config flag

Respeta el flag de Remote Config de Toka Plus (Fase 3): con flag off, ningún usuario ve features Plus desbloqueadas.

## 6. Cobertura de tests EXHAUSTIVA (obligatoria)

No te conformes con un caso feliz y uno de error: cubre **todos los flujos y casuísticas**. Esta fase NO está DONE si queda un estado de UI, una rama de gating o una combinación sin test. Al terminar, **enumera las casuísticas cubiertas y por qué la lista es completa**.

**View models / lógica (unit):**
- Provider de Plus en **todos** los estados: con Plus activo, sin Plus, expirado, cargando, error; `AsyncValue` en sus tres estados.
- Gating de skins y de métricas: con derecho (desbloqueado) y sin derecho (bloqueado + **CTA correcto** al paywall de Plus).
- Métricas personales: con datos, **sin datos (vacío)**, datos parciales/incompletos; que las cifras se calculen bien a partir de los datos reales.
- Per-usuario: el estado de Plus del usuario actual no se mezcla con el de otros.

**UI (golden + widget):**
- Un golden por cada pantalla y **estado visual**: entrada/paywall de Plus (mensual/anual), métricas personales (datos / vacío), selector de skins gated (desbloqueado / bloqueado); en **es/en/ro** y en cada skin/tema; sin overflow.
- Interacción: comprar Plus, abrir métricas, seleccionar una skin premium → destinos correctos; textos desde ARB en los 3 idiomas.
- Flag de Remote Config **on y off** (off → nadie ve features Plus).

**Regresión:** ningún test/golden existente puede quedar en rojo sin justificación; amplía, no borres.

## 7. Al terminar

- Suite afectada en verde (pega salida).
- Archivos **nuevos** y **modificados**.
- **Contrato** para la Fase 5: el provider/forma con que la UI conoce si el usuario actual tiene Plus (lo reutilizará el cálculo de ads).
- **NO** commit/push salvo petición; si la hay, separa ruido CRLF y cierra con `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## ESTA FASE: Toka Plus — skins + métricas personales + compra (FLUTTER)

### Objetivo

Consumir el entitlement Plus (Fase 3) en la UI: **punto de entrada/compra** de Toka Plus, **cosméticos/skins** desbloqueados con Plus, y una pantalla de **métricas personales** nueva gated por Plus.

### Reglas de producto (embebidas)

- **Toka Plus**: 1,99 €/mes · 14,99 €/año (un único SKU individual). Es **por usuario**.
- Lo que esta fase desbloquea con Plus:
  1. **Cosméticos / skins**: el usuario con Plus puede elegir skins cosméticas; sin Plus, quedan bloqueadas (preview + CTA al paywall de Plus).
  2. **Métricas personales**: pantalla con estadísticas del **propio** usuario (p.ej. tareas completadas, racha, puntualidad, reparto). Compón las métricas con datos que ya existan (analiza history/dashboard/eventos); no inventes datos que no haya. Gated por Plus.
- El efecto "quita banner" **NO** se hace aquí (es de la Fase 5). No toques ads.

### Alcance técnico (analízalo en el código y decide el diseño)

1. **Provider de entitlement Plus**: crea el provider Riverpod que lee del Firestore (ruta/campo que dejó la Fase 3) si el **usuario actual** tiene Plus activo. Será la base del gating.
2. **Entrada/paywall de Plus**: punto de compra de Toka Plus con **mensual/anual** (1,99/14,99 €). Reutiliza la infraestructura de compra/paywall existente (feature `subscription`), pero como producto **individual** (no de hogar). Respeta precios localizados de la store cuando existan; los de arriba son fallback/copy.
3. **Skins gated**: integra con `AppSkin`/`SkinSwitch`/`skin_provider`/`skin_switcher`. Decide qué skins son cosméticas-Plus y gatéalas por el provider de Plus, con preview y CTA si no hay Plus.
4. **Métricas personales**: pantalla nueva (con su ruta en el `router.dart` de la feature correspondiente y constante de ruta en `core/constants/routes.dart`). Gated por Plus. Diseño Material 3, sin overflow.
5. **i18n**: todos los textos en es/en/ro.
6. **Remote Config flag** (sección 5).

### Verificación en dispositivos (mínimo)

- Fuerza **Plus** en la cuenta A: en su dispositivo, las **skins cosméticas** se pueden seleccionar y la pantalla de **métricas personales** está accesible (capturas).
- En la cuenta B (sin Plus), esas mismas opciones aparecen **bloqueadas** con CTA al paywall (captura).
- Activa/desactiva Plus en A y comprueba que el desbloqueo/bloqueo se **sincroniza** en vivo.
- Con el flag de Remote Config off, nadie ve features Plus.

### Criterios de aceptación

- Provider de Plus per-usuario funcionando; skins y métricas gated correctamente; entrada de compra mensual/anual.
- Pantalla de métricas personales nueva, Material 3, es/en/ro, sin overflow.
- Tests unit + UI/golden verdes; verificado en 2 cuentas (una con Plus, otra sin) con capturas; **sin tocar ads**.
