# FASE 2 — Tiers por tamaño de hogar (FLUTTER)

> Pega este prompt completo como primer mensaje en una **sesión nueva** de Claude Code en el repo Toka. Es autónomo: no necesitas (ni debes) leer ningún otro documento de análisis.
>
> **Prerrequisito:** la Fase 1 (Tiers — backend) debe estar mergeada/desplegada a dev. Esta fase lee del **código** el contrato que dejó la Fase 1 (campos del tier, productIds, derivación de `maxMembers`). No asumas nombres: léelos del código.

---

## 0. Quién eres y qué es Toka

Eres un ingeniero senior Flutter + Firebase trabajando en **Toka**, una app cooperativa de gestión de tareas del hogar para parejas, familias y pisos compartidos. Modelo Premium **por hogar**.

Stack: Flutter 3.x + Dart 3.x (Riverpod, go_router, freezed, get_it), Cloud Firestore, Cloud Functions Node.js 20 (TS estricto), FCM, Remote Config, AdMob, in_app_purchase. Proyecto Firebase de **desarrollo**: `toka-dd241`.

## 1. Regla de oro: el CÓDIGO es la única fuente de verdad

- **Analiza el código tú mismo, desde cero.** No confíes en ningún resumen, hallazgo, spec ni análisis previo.
- **PROHIBIDO leer**: `Arreglos/*.md` (incluidos `mejora_modelos_premium.md`, `premortem.md`, `Hallazgos.md`), `Monetizacion/`, `toka_qa_session/**/*.md`, `architecture/*.md`, cualquier `*.md` de spec/análisis, y los `.md` de este directorio salvo este prompt. **SÍ puedes** leer `CLAUDE.md` y `DEPLOY.md`.
- Todo el QUÉ (precios, topes) está embebido en este prompt. Ante duda real de producto, **pregunta**.

## 2. Workflow obligatorio (en orden)

1. **Brainstorming primero** (`superpowers:brainstorming`) para confirmar el plan de ESTA fase.
2. **TDD** (`superpowers:test-driven-development`): tests antes que implementación. Mocks con **mocktail**.
3. Implementa.
4. `flutter analyze` debe pasar **sin errores**.
5. Si tocas freezed/riverpod/json: `dart run build_runner build --delete-conflicting-outputs`. (Ojo: corre `flutter pub get` en el entorno donde lances los tests; si construyes el APK desde Windows, eso reescribe `package_config.json` y rompe `flutter test` en WSL — corre los tests ANTES del build, o restaura con `flutter pub get`.)
6. Tests verdes: `flutter test test/unit/` y `flutter test test/ui/`.
7. Compila e instala en dispositivo y **verifica** (sección 4). No marques DONE sin captura que lo confirme contra estas reglas.

## 3. Restricciones de código

- Modelos/estados con **freezed**; providers con `@riverpod` y sufijo `Provider`. Usa `AsyncValue` para carga/error/datos. Cierra listeners en `ref.onDispose`.
- Toda string visible al usuario va en ARB (`lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`) y se accede con `l10n.clave`. **Nunca** hardcodear texto UI. Añade las **3** traducciones (es/en/ro).
- Colores/tipografías/radios en `core/theme/`. Respeta Material 3 y el sistema de skins (`AppSkin`/`SkinSwitch`) ya existente.
- El estado Premium/entitlement/tope se lee SIEMPRE de Firestore (dashboard del hogar), nunca se hardcodea ni se calcula en el dispositivo de forma divergente al backend.
- No metas `BuildContext` fuera de widgets.

## 4. Protocolo de verificación en 2 dispositivos (OBLIGATORIO)

- **MI_9** (físico, USB, 1080×2340) + **emulador** (`emulator-5554`, 1080×2400). Ambos a `toka-dd241`.
- Cuentas QA (`TokaQA2024!`): `toka.qa.owner@gmail.com`, `toka.qa.member@gmail.com`, `toka.qa.admin@gmail.com`. **Una cuenta distinta por dispositivo** para ver sincronización entre miembros del mismo hogar.
- **Login por adb SIN Google** (ver `CLAUDE.md`): tap email → `input text` → tap contraseña → `input text` → tap iniciar. NUNCA `KEYCODE_TAB` ni autocomplete de Google. Campos de código → char-a-char.
- **Forzar entitlement por Admin SDK** (`secrets/toka-sa.json`) o script de QA: inyecta tier/`premiumStatus`/tope. NO compra real de store.
- **Capturas**: `adb exec-out screencap -p`; si una dimensión > 1900px, redimensiona con magick antes de leer.
- Verifica siempre: el cambio **se sincroniza en vivo** a la otra cuenta; los **límites** se reflejan correctamente en la UI de ambos.

## 5. Remote Config flag

Respeta el **mismo flag** de Remote Config que introdujo la Fase 1 (búscalo en el código): con el flag off, la UI debe mostrar el comportamiento binario anterior (un único Premium).

## 6. Cobertura de tests EXHAUSTIVA (obligatoria)

No te conformes con un caso feliz y uno de error: cubre **todos los flujos y casuísticas**. Esta fase NO está DONE si queda un estado de UI, una rama del view model o una combinación sin test. Al terminar, **enumera las casuísticas cubiertas y por qué la lista es completa**.

**View models / lógica (unit):**
- Cada **tier × ciclo** (mensual y anual): precio, copy y tope correctos; fallback cuando la store no da precio.
- Cada estado de entitlement del hogar: Free, Pareja, Familia, Grupo, expirado/legacy; y `AsyncValue` en sus **tres** estados (loading/data/error) para cada provider nuevo.
- Gating de límite: justo en el tope, tope±1, lista de miembros vacía; el mensaje de límite es el del tier correcto.
- Datos null/ausentes → fail-safe (no mostrar features que no tocan).

**UI (golden + widget):**
- Un golden por cada pantalla y por cada **estado visual relevante** (no solo el feliz): paywall con los 3 tiers y toggle mensual/anual, mensaje de límite por tier, gestión de suscripción con el tier actual; estados vacío / cargando / error / con-datos; **overflow** de textos largos en **es/en/ro**; cada skin/tema.
- Interacción: cada tap (seleccionar tier, alternar mensual/anual, CTA de límite) lleva al destino correcto; los textos vienen de ARB en los **3 idiomas**.
- Flag de Remote Config **on y off** (off → Premium único).
- Si los goldens cambian intencionadamente, regéneralos y explica por qué.

**Regresión:** ningún test/golden existente puede quedar en rojo sin justificación; amplía, no borres.

## 7. Al terminar

- Suite afectada en verde (pega salida).
- Lista archivos **nuevos** y **modificados**.
- Resume el **contrato** que dejas para fases siguientes (providers/keys de entitlement de hogar que consumirán las fases de ads/packs).
- **NO** commit/push salvo que el usuario lo pida (entonces: separa ruido CRLF; cierra con `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`).

---

## ESTA FASE: Tiers por tamaño de hogar — FLUTTER

### Objetivo

Llevar a la UI el modelo de tiers que la Fase 1 implementó en backend: límites del cliente derivados del tier, y un **paywall con selector de tier por tamaño de hogar** con ciclo **mensual/anual**.

### Reglas de producto (embebidas)

Selector de tier en el paywall, cada uno con **mensual** y **anual**:

| Tier | Mensual | Anual | Tope de miembros |
|---|---|---|---|
| **Toka Pareja** | 2,99 € | 19,99 € | 2 |
| **Toka Familia** | 3,99 € | 29,99 € | 5 |
| **Toka Grupo** | 5,99 € | 49,99 € | 10 |

- **Mensaje clave de copy** (en ARB, es/en/ro): *las mismas funciones premium están en los tres planes; lo único que cambia es cuántos miembros caben*. El usuario elige por tamaño de su hogar.
- **Free** sigue en 3 miembros. Al alcanzar el tope del tier actual, el mensaje de límite debe **sugerir subir de tier** (o pasar a Premium si es Free), no un genérico "hazte Premium".

### Alcance técnico (analízalo en el código y decide el diseño)

1. **Límites cliente**: localiza dónde el cliente conoce hoy el tope (busca `free_limits.dart`, `home_limits.dart`, modelos de dashboard). Haz que el tope se **lea del entitlement/dashboard** que dejó la Fase 1 (no hardcodear 3/10). Mismas features premium en los 3 tiers.
2. **Paywall**: localiza el paywall actual (feature `subscription`, p.ej. `paywall_screen*`/`paywall_view_model`/`subscription_products`). Conviértelo en un selector de **3 tiers** con toggle **mensual/anual** y los precios de arriba. Respeta cómo se cargan hoy los productos de la store (precios localizados de la store cuando existan; los de arriba son el fallback/copy de referencia).
3. **Pantalla de gestión de suscripción**: muestra el **tier actual** del hogar y su tope, y permite cambiar de tier (upsell/downgrade), reutilizando el flujo de downgrade existente (que ya avisa de penalización/congelación antes de confirmar).
4. **Mensajes de límite**: al intentar superar el tope (invitar miembro), muestra el mensaje contextual del tier. El rechazo real es server-side (Fase 1); la UI solo informa.
5. **i18n**: textos en es/en/ro.
6. **Remote Config flag** (sección 5).

### Verificación en dispositivos (mínimo)

- Abre el paywall en ambos dispositivos: se ven los **3 tiers** con **mensual/anual** y los precios correctos, sin overflow ni texto cortado (captura de cada uno).
- Fuerza por Admin SDK el hogar a **Pareja (2)**, luego **Familia (5)**, luego **Grupo (10)**: el tope mostrado y los mensajes de límite cambian en consecuencia y se **sincronizan** a la otra cuenta.
- Intenta invitar por encima del tope: la UI muestra el mensaje del tier y el servidor rechaza.
- Con el flag de Remote Config off, la UI vuelve al Premium único.

### Criterios de aceptación

- Paywall con 3 tiers × mensual/anual, copy claro de "mismas features, cambia el tope", textos en es/en/ro.
- Topes y mensajes derivados del entitlement del hogar (no hardcode).
- Tests unit + UI/golden verdes; verificado en los 2 dispositivos con capturas legibles (Material 3, sin overflow).
