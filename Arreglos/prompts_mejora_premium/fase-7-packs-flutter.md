# FASE 7 — Packs de miembros (FLUTTER)

> Pega este prompt completo como primer mensaje en una **sesión nueva** de Claude Code en el repo Toka. Es autónomo: no necesitas (ni debes) leer ningún otro documento de análisis.
>
> **Prerrequisito:** Fase 6 (Packs — backend) desplegada a dev. Lee del **código** la forma de los packs activos, sus productIds y la función de tope efectivo. No inventes nombres.

---

## 0. Quién eres y qué es Toka

Eres un ingeniero senior Flutter + Firebase en **Toka**, app cooperativa de tareas del hogar. Premium por hogar con tiers + **packs de miembros** para crecer por encima de 10 (tope 25).

Stack: Flutter 3.x + Dart 3.x (Riverpod, go_router, freezed, get_it), Firestore, Cloud Functions Node 20, FCM, Remote Config, AdMob, in_app_purchase. Firebase **dev**: `toka-dd241`.

## 1. Regla de oro: el CÓDIGO es la única fuente de verdad

- **Analiza el código tú mismo, desde cero.** Nada de resúmenes/hallazgos/spec/análisis previos.
- **PROHIBIDO leer**: `Arreglos/*.md`, `Monetizacion/`, `toka_qa_session/**/*.md`, `architecture/*.md`, cualquier `*.md` de spec/análisis, y los `.md` de este directorio salvo este prompt. **SÍ**: `CLAUDE.md`, `DEPLOY.md`.
- El QUÉ (precios, topes) está embebido. Ante duda real, **pregunta**.

## 2. Workflow obligatorio (en orden)

1. **Brainstorming** (`superpowers:brainstorming`).
2. **TDD** (`superpowers:test-driven-development`): tests antes. **mocktail**.
3. Implementa.
4. `flutter analyze` sin errores.
5. Si tocas freezed/riverpod/json: `dart run build_runner build --delete-conflicting-outputs` (cuidado `package_config.json` WSL/Windows; tests ANTES del build o `flutter pub get`).
6. Tests verdes: `flutter test test/unit/` y `flutter test test/ui/`.
7. Compila, instala y **verifica** en dispositivo (sección 4).

## 3. Restricciones de código

- **freezed**, `@riverpod` + sufijo `Provider`, `AsyncValue`, `ref.onDispose`.
- Strings visibles en ARB (es/en/ro) vía `l10n.clave`. **Nunca** hardcodear UI.
- Tope/packs se leen del entitlement del hogar (Firestore), nunca se hardcodean.
- Reutiliza el flujo/diálogo de downgrade existente (que ya avisa de penalización/congelación **antes** de confirmar) para la cancelación de packs.

## 4. Protocolo de verificación en 2 dispositivos (OBLIGATORIO)

- **MI_9** (USB, 1080×2340) + **emulador** (`emulator-5554`, 1080×2400), ambos a `toka-dd241`.
- Cuentas QA (`TokaQA2024!`): owner / member / admin. **Una distinta por dispositivo**.
- **Login por adb SIN Google** (ver `CLAUDE.md`). NUNCA `KEYCODE_TAB`/autocomplete. Campos sensibles char-a-char.
- **Forzar entitlement por Admin SDK**: tier Grupo + packs. Crea miembros de prueba por Admin SDK para ver el tope. NO compra real.
- **Capturas**: `adb exec-out screencap -p`; >1900px redimensiona con magick.
- Verifica: el **tope dinámico** mostrado, el **aviso de congelación** al cancelar pack, y la **sincronización** a la otra cuenta.

## 5. Remote Config flag

Respeta el flag de Remote Config de packs (Fase 6): con flag off, la UI no ofrece packs y el tope máximo mostrado es el del tier.

## 6. Cobertura de tests EXHAUSTIVA (obligatoria)

No te conformes con un caso feliz y uno de error: cubre **todos los flujos y casuísticas**. Esta fase NO está DONE si queda un estado de UI o una combinación sin test. Al terminar, **enumera las casuísticas cubiertas y por qué la lista es completa**.

**View models / lógica (unit):**
- Gating **requiere Grupo**: hogar Grupo (packs visibles) vs Pareja/Familia (bloqueado + CTA a Grupo).
- Cada combinación de packs activos (ninguno / +5 / +10 / ambos) × ciclo → **tope dinámico** mostrado correcto.
- Mensaje de **Toka Business** al alcanzar/superar 25.
- Aviso de **congelación** antes de confirmar cancelación (estado del diálogo de downgrade reutilizado).
- `AsyncValue` en sus tres estados.

**UI (golden + widget):**
- Un golden por cada pantalla y **estado visual**: sección de packs en el paywall (Grupo / no-Grupo), gestión con packs activos y tope efectivo, aviso de congelación, mensaje Toka Business; en **es/en/ro** y cada skin; sin overflow.
- Interacción: comprar pack, cancelar pack (pasa por el aviso de congelación), CTA a Grupo, CTA Toka Business → destinos correctos; textos desde ARB en los 3 idiomas.
- Flag de Remote Config **on y off** (off → no se ofrecen packs).

**Regresión:** ningún test/golden existente puede quedar en rojo sin justificación; amplía, no borres.

## 7. Al terminar

- Suite afectada en verde (pega salida).
- Archivos **nuevos** y **modificados**.
- **Contrato** y notas para la Fase 8 (QA integral).
- **NO** commit/push salvo petición; si la hay, separa ruido CRLF y cierra con `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## ESTA FASE: Packs de miembros — FLUTTER

### Objetivo

Llevar a la UI los packs de miembros (Fase 6): venta en el paywall con mensual/anual, tope dinámico visible, gating "requiere Grupo", aviso de congelación al cancelar y mensaje de Toka Business al superar 25.

### Reglas de producto (embebidas)

| Pack | Mensual | Anual | Efecto |
|---|---|---|---|
| **Pack +5 miembros** | 1,49 € | 9,99 € | **+5 plazas** (Grupo 10 → 15) |
| **Pack +10 miembros** | 2,49 € | 19,99 € | **+10 plazas** (Grupo 10 → 20; junto al +5 → 25) |

Los packs son **aditivos** sobre Grupo (10) y el tope queda **capado a 25**: solo +5 → 15, solo +10 → 20, ambos → 25.

- Los packs **requieren tier Grupo**. Si el hogar no es Grupo, la sección de packs aparece bloqueada con CTA a subir a Grupo.
- **Suscripción reversible**: cancelar un pack **congela** los miembros excedentes. La UI debe **avisar de la congelación antes de confirmar** (reutiliza el diálogo de downgrade existente).
- **Tope absoluto 25.** Al intentar crecer por encima de 25, muestra un mensaje informativo de **Toka Business** (CTA informativo; el producto B2B está fuera de alcance, solo el mensaje).

### Alcance técnico (analízalo en el código y decide el diseño)

1. **Sección de packs en el paywall**: muestra Pack +5 y Pack +10 con **mensual/anual** y sus precios, **solo si el hogar es Grupo** (si no, CTA a Grupo). Indica el **tope resultante** de comprar cada pack.
2. **Gestión de suscripción**: muestra los **packs activos** y el **tope efectivo** actual (tier + packs). Permite cancelar un pack, mostrando el **aviso de congelación de excedentes** antes de confirmar.
3. **Tope dinámico en la UI de miembros**: el contador/indicador de tope debe reflejar el tope efectivo del entitlement (no hardcode), y actualizarse en vivo.
4. **Mensaje Toka Business**: al intentar superar 25, mensaje informativo (no flujo de compra).
5. **i18n**: textos en es/en/ro.
6. **Remote Config flag** (sección 5).

### Verificación en dispositivos (mínimo)

- Hogar **Grupo** forzado: el paywall muestra Pack +5 y +10 con mensual/anual y el tope resultante (captura). En un hogar **Familia**, la sección de packs está bloqueada con CTA a Grupo (captura).
- Fuerza **Pack +10** por Admin SDK: el tope mostrado sube a **20** (Grupo 10 + 10) y se **sincroniza** a la otra cuenta; añade también **Pack +5** → tope **25**.
- Cancela el pack desde la UI: aparece el **aviso de congelación** antes de confirmar; al confirmar, los excedentes se ven congelados en ambas cuentas.
- Con miembros = 25, intenta crecer más → mensaje de **Toka Business**.
- Con el flag de Remote Config off, no se ofrecen packs.

### Criterios de aceptación

- Venta de packs (mensual/anual) gated por Grupo; tope dinámico correcto; aviso de congelación reutilizando el diálogo de downgrade; mensaje de Toka Business al superar 25.
- Textos es/en/ro; Material 3 sin overflow.
- Tests unit + UI/golden verdes; verificado en 2 dispositivos con capturas.
