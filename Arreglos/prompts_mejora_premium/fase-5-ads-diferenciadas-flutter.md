# FASE 5 — Publicidad diferenciada (banner vs intersticial) per-usuario

> Pega este prompt completo como primer mensaje en una **sesión nueva** de Claude Code en el repo Toka. Es autónomo: no necesitas (ni debes) leer ningún otro documento de análisis.
>
> **Prerrequisito:** Fases 1-4 desplegadas a dev. Esta fase **necesita** el entitlement de hogar (tier/premium, Fase 1) y el entitlement individual **Toka Plus** (Fase 3-4). Lee del **código** ambos contratos.

---

## 0. Quién eres y qué es Toka

Eres un ingeniero senior Flutter + Firebase en **Toka**, app cooperativa de tareas del hogar. Hoy solo hay **banner** (AdMob, con IDs de TEST porque la app está en desarrollo). Esta fase añade **intersticial** y hace la visibilidad de ads **diferenciada por contexto y por usuario**.

Stack: Flutter 3.x + Dart 3.x (Riverpod, go_router, freezed, get_it), Firestore, Cloud Functions Node 20, FCM, Remote Config, AdMob, in_app_purchase. Firebase **dev**: `toka-dd241`.

## 1. Regla de oro: el CÓDIGO es la única fuente de verdad

- **Analiza el código tú mismo, desde cero.** Nada de resúmenes/hallazgos/spec/análisis previos.
- **PROHIBIDO leer**: `Arreglos/*.md`, `Monetizacion/`, `toka_qa_session/**/*.md`, `architecture/*.md`, cualquier `*.md` de spec/análisis, y los `.md` de este directorio salvo este prompt. **SÍ**: `CLAUDE.md`, `DEPLOY.md`.
- El QUÉ (la matriz de ads) está embebido. Ante duda real, **pregunta**.

## 2. Workflow obligatorio (en orden)

1. **Brainstorming** (`superpowers:brainstorming`).
2. **TDD** (`superpowers:test-driven-development`): tests antes. **mocktail**.
3. Implementa.
4. `flutter analyze` sin errores.
5. Si tocas freezed/riverpod/json: `dart run build_runner build --delete-conflicting-outputs` (cuidado con `package_config.json` WSL/Windows; tests ANTES del build o `flutter pub get`).
6. Tests verdes: `flutter test test/unit/` y `flutter test test/ui/`.
7. Compila, instala y **verifica** en dispositivo (sección 4).

## 3. Restricciones de código

- **freezed**, `@riverpod` + sufijo `Provider`, `AsyncValue`, `ref.onDispose`.
- Strings visibles en ARB (es/en/ro). **Nunca** hardcodear UI.
- Mantén los **IDs de TEST** de AdMob en dev (no metas IDs reales; eso es de la fase de salida). El intersticial usa el unit ID de TEST oficial de AdMob para dev.
- El estado que decide los ads se lee de Firestore (dashboard del hogar + entitlement Plus), nunca se hardcodea.

## 4. Protocolo de verificación en 2 dispositivos (OBLIGATORIO)

- **MI_9** (USB, 1080×2340) + **emulador** (`emulator-5554`, 1080×2400), ambos a `toka-dd241`.
- Cuentas QA (`TokaQA2024!`): owner / member / admin. **Una distinta por dispositivo** — esta fase **exige** dos perfiles distintos en el mismo hogar para recorrer la matriz (pagador vs miembro).
- **Login por adb SIN Google** (ver `CLAUDE.md`). NUNCA `KEYCODE_TAB`/autocomplete.
- **Forzar estados por Admin SDK**: premium/tier del hogar, `currentPayerUid`, y Plus per-usuario. NO compra real.
- **Capturas**: `adb exec-out screencap -p`; >1900px redimensiona con magick. Para banners/intersticiales transitorios, captura en el momento (ver técnicas de captura de SnackBars/overlays en `CLAUDE.md` si aplica).
- Recorre **las 5 filas** de la matriz (abajo) y captura cada caso en el dispositivo correspondiente.

## 5. Remote Config flag

La publicidad diferenciada y el **intersticial** van detrás de flags de Remote Config (al menos: activar intersticial on/off y su frecuencia). Con el flag off, el comportamiento de banner vuelve al actual.

## 6. Cobertura de tests EXHAUSTIVA (obligatoria)

No te conformes con cubrir lo justo: prueba **todas las filas de la matriz y todas las casuísticas**. Esta fase NO está DONE si queda una combinación de (premium/tier × pagador × Plus) sin test. Al terminar, **enumera las casuísticas cubiertas y por qué la lista es completa**.

**Función pura de visibilidad (unit):**
- Un test por **cada una de las 5 filas** de la matriz → `{banner, interstitial}` esperado.
- Combinaciones cruzadas no listadas explícitamente que el modelo permita (p.ej. cada tier de Premium como pagador y como miembro) → deben seguir las dos reglas; testéalas.
- Edge: datos ausentes / cargando / error → **fail-safe** definido y testeado (decide y documenta si por defecto se muestran o no los ads cuando el estado aún no se conoce).
- **Recálculo en caliente**: al cambiar un input (el hogar pasa a Premium; el usuario activa/cancela Plus; cambia el pagador), la visibilidad se recalcula al valor correcto.

**Intersticial (unit + widget):**
- No se muestra nunca cuando `interstitial=false`.
- Respeta el **cap de frecuencia** (no más de N por sesión/tiempo, vía Remote Config); el disparador correcto lo lanza y los flujos críticos no.

**UI (golden + widget):**
- El banner aparece / no aparece según el provider, en cada pantalla con scaffold y para cada fila relevante de la matriz.
- Flags de Remote Config **on y off** (off → comportamiento de banner anterior; intersticial desactivado).

**Regresión:** ningún test existente puede quedar en rojo sin justificación; amplía, no borres.

## 7. Al terminar

- Suite afectada en verde (pega salida).
- Archivos **nuevos** y **modificados**.
- **Contrato** para la Fase 8: nombre del provider de visibilidad de ads y de los flags de Remote Config.
- **NO** commit/push salvo petición; si la hay, separa ruido CRLF y cierra con `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## ESTA FASE: Publicidad diferenciada banner vs intersticial (per-usuario)

### Objetivo

Centralizar el cálculo de visibilidad de anuncios combinando **estado del hogar** (premium/tier) × **entitlement individual Plus** × **rol de pagador**, e **integrar el intersticial** de AdMob (hoy solo hay banner).

### Matriz objetivo (embebida — es la fuente de verdad del comportamiento)

| Contexto del miembro | Banner | Intersticial |
|---|:--:|:--:|
| Hogar **Free**, sin Toka Plus | **sí** | **sí** |
| Hogar **Free**, con Toka Plus | no | no |
| Hogar **Premium**, el **pagador** del hogar (`currentPayerUid`) | no | no |
| Hogar **Premium**, miembro **sin** Toka Plus | **sí (solo banner)** | no |
| Hogar **Premium**, miembro **con** Toka Plus | no | no |

Reglas que generan la matriz (impleméntalas como funciones puras, testeables):

- **Intersticial visible** ⇔ el hogar **NO** es Premium **Y** el usuario **NO** tiene Toka Plus. → El Premium de hogar (cualquier tier) elimina el intersticial para **todos** los miembros del hogar (beneficio colectivo).
- **Banner visible** ⇔ el usuario **NO** tiene Toka Plus **Y** no es el **pagador** de un hogar Premium. → El banner solo se quita **individualmente**: siendo el pagador del hogar Premium, o teniendo Toka Plus.

### Alcance técnico (analízalo en el código y decide el diseño)

1. **Provider de visibilidad** (`adVisibilityProvider` o similar): función pura que recibe (estado premium/tier del hogar, ¿soy `currentPayerUid`?, ¿tengo Plus?) y devuelve `{banner: bool, interstitial: bool}` según las reglas. Reemplaza la dependencia del `adFlags` binario del dashboard donde haga falta (un flag de hogar no puede expresar el caso per-usuario).
2. **Banner**: localiza la integración actual del banner (busca el scaffold con banner / widget de banner) y haz que respete `banner` del provider.
3. **Intersticial**: integra el interstitial de AdMob (unit ID de **TEST** en dev). Define disparadores razonables (p.ej. en ciertas transiciones/acciones) con una **frecuencia controlada** (cap por sesión/tiempo, vía Remote Config) y muéstralo solo cuando `interstitial` sea true. No seas intrusivo (no en flujos críticos como completar tarea sin control de frecuencia).
4. **Lectura del entitlement de otros**: para decidir el banner del usuario actual solo necesitas SU Plus y si ÉL es el pagador; confírmalo en el código de la Fase 3 (reglas de lectura del doc Plus).
5. **i18n** si hay textos.
6. **Remote Config flags** (sección 5).

### Verificación en dispositivos (mínimo — recorrer la matriz)

Forzando estados por Admin SDK y usando **2 cuentas del mismo hogar** en los 2 dispositivos:

1. Hogar Free, cuenta sin Plus → **banner sí, intersticial sí**.
2. Misma cuenta con Plus forzado → **banner no, intersticial no**.
3. Hogar Premium (cualquier tier), cuenta = **pagador** → **banner no, intersticial no**.
4. Hogar Premium, cuenta = **miembro sin Plus** → **banner sí, intersticial no**.
5. Hogar Premium, miembro **con Plus** → **banner no, intersticial no**.

Captura cada caso. Comprueba que al cambiar el estado (p.ej. el hogar pasa a Premium, o el usuario activa Plus) la visibilidad se **actualiza** sin reinstalar.

### Criterios de aceptación

- Provider de visibilidad puro que cumple las 5 filas (1 test unit por fila, todos verdes).
- Intersticial integrado (test IDs) con frecuencia controlada por Remote Config, mostrándose solo cuando corresponde.
- Las 5 filas verificadas en dispositivo con capturas; flags de Remote Config revierten el comportamiento.
