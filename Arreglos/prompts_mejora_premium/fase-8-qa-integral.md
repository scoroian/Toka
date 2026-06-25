# FASE 8 — Cierre: SKUs, flags, QA end-to-end y paridad dev→prod

> Pega este prompt completo como primer mensaje en una **sesión nueva** de Claude Code en el repo Toka. Es autónomo: no necesitas (ni debes) leer ningún otro documento de análisis.
>
> **Prerrequisito:** Fases 1-7 desplegadas a dev. Esta fase **no añade producto nuevo**: consolida, audita y verifica de extremo a extremo el modelo completo, y deja listo (documentado) el salto a producción. Lee del **código** todo el contrato acumulado.

---

## 0. Quién eres y qué es Toka

Eres un ingeniero senior Flutter + Firebase y QA en **Toka**, app cooperativa de tareas del hogar. Acaba de implementarse, en 7 fases, un rediseño del modelo Premium: **tiers por tamaño** (Pareja 2 / Familia 5 / Grupo 10), **Toka Plus** individual, **publicidad diferenciada** banner/intersticial per-usuario, y **packs de miembros** (tope 25). Tu trabajo es cerrarlo.

Stack: Flutter 3.x + Dart 3.x (Riverpod, go_router, freezed, get_it), Firestore, Cloud Functions Node 20 (TS estricto), FCM, Remote Config, AdMob, in_app_purchase. Firebase **dev**: `toka-dd241`.

## 1. Regla de oro: el CÓDIGO es la única fuente de verdad

- **Analiza el código tú mismo, desde cero.** Nada de resúmenes/hallazgos/spec/análisis previos.
- **PROHIBIDO leer**: `Arreglos/*.md`, `Monetizacion/`, `toka_qa_session/**/*.md`, `architecture/*.md`, cualquier `*.md` de spec/análisis, y los `.md` de este directorio salvo este prompt. **SÍ**: `CLAUDE.md`, `DEPLOY.md`.
- El catálogo completo está embebido abajo. Ante duda real, **pregunta**.

## 2. Workflow obligatorio (en orden)

1. **Brainstorming** (`superpowers:brainstorming`) del plan de cierre.
2. Si encuentras bugs, **TDD** para arreglarlos (test que reproduce → fix). **mocktail**.
3. `flutter analyze` limpio; `cd functions && npm run build` + lint sin errores.
4. Toda la suite verde: `flutter test` (unit/ui) + `functions/` (`npm test`).
5. **No despliegues a prod** sin OK explícito del usuario. Sí puedes (re)desplegar a dev por `DEPLOY.md` (`FUNCTIONS_DISCOVERY_TIMEOUT=120`).
6. **Verifica end-to-end en dispositivos** (sección 4).

## 3. Restricciones de código

- Cualquier fix respeta las convenciones del repo (freezed, `@riverpod`, ARB es/en/ro, callables/transacciones para operaciones críticas, batching >500, índices `COLLECTION_GROUP`).
- No introduzcas IDs reales de AdMob ni secretos de producción en dev; documenta lo que falta para prod, no lo actives.

## 4. Protocolo de verificación end-to-end en 2 dispositivos (OBLIGATORIO)

- **MI_9** (USB, 1080×2340) + **emulador** (`emulator-5554`, 1080×2400), ambos a `toka-dd241`.
- Cuentas QA (`TokaQA2024!`): owner / member / admin. **Una distinta por dispositivo** (esta fase exige 2 perfiles del mismo hogar para validar sincronización y la matriz de ads).
- **Login por adb SIN Google** (ver `CLAUDE.md`). NUNCA `KEYCODE_TAB`/autocomplete. Campos sensibles char-a-char.
- **Forzar estados por Admin SDK** (`secrets/toka-sa.json`)/script QA. NO compra real. Crea miembros de prueba por Admin SDK cuando necesites llenar topes.
- **Capturas** de cada caso: `adb exec-out screencap -p`; >1900px redimensiona con magick.

## 5. Catálogo completo (embebido — la fuente de verdad del producto)

| Producto | Mensual | Anual | Habilita | productId esperado |
|---|---|---|---|---|
| Toka Pareja | 2,99 € | 19,99 € | hogar Premium, tope **2** | (léelo del código) |
| Toka Familia | 3,99 € | 29,99 € | hogar Premium, tope **5** | (léelo del código) |
| Toka Grupo | 5,99 € | 49,99 € | hogar Premium, tope **10** | (léelo del código) |
| Pack +5 miembros | 1,49 € | 9,99 € | **+5 plazas** sobre Grupo → 15 (requiere Grupo) | (léelo del código) |
| Pack +10 miembros | 2,49 € | 19,99 € | **+10 plazas** sobre Grupo → 20; con +5 → 25 (requiere Grupo) | (léelo del código) |
| Toka Plus (individual) | 1,99 € | 14,99 € | por usuario: quita banner + cosméticos + métricas | (léelo del código) |

**12 SKUs** = 6 productos × (mensual + anual). Free = 3 miembros. Tope absoluto = **25**. Matriz de ads: ver sección de tareas.

## 6. ESTA FASE: tareas de cierre

### 6.1 Auditoría del catálogo de SKUs
- Extrae del **código** los productIds que `syncEntitlement` (y el cliente) mapean hoy, y verifica que cubren **los 12 SKUs**. Lista discrepancias.
- Genera (en un archivo nuevo bajo este directorio o donde el repo ya documente config de stores) la **tabla de los 12 productIds** que hay que dar de alta en Google Play y App Store, con tipo (suscripción), ciclo y efecto. En dev quedan como **test**; documenta qué falta para producción (alta en stores, precios localizados, free trial si aplica).

### 6.2 Consolidación de Remote Config
- Inventaria, leyéndolos del código, **todos los flags de Remote Config** introducidos por las fases 1-7 (tiers, Toka Plus, ads diferenciadas/intersticial, packs).
- Verifica que **apagar cada flag revierte** limpiamente al comportamiento anterior (sin crashear, sin estados inconsistentes). Documenta los nombres y sus valores por defecto recomendados para el lanzamiento.

### 6.3 QA end-to-end combinado (2 dispositivos, 2 cuentas)
Forzando estados por Admin SDK, recorre el ciclo de vida completo y captura cada hito:

1. **Tiers + packs**: hogar Free → fuerza **Grupo (10)** → invita/crea hasta 10 → añade **Pack +5 y Pack +10** (tope 25) → llena a 25 → el 26.º se rechaza server-side → **cancela el pack** (excedentes congelados) → **baja a Familia (5)** (más congelados) → **a Free (3)**. En cada paso, comprueba que el cambio de tope y las **congelaciones se sincronizan en vivo** a la otra cuenta y que los límites son **server-side**.
2. **Toka Plus**: activa Plus en la cuenta A → en A se desbloquean **skins** y **métricas personales** y **desaparece el banner**; la cuenta B (sin Plus) mantiene su banner. Cancela Plus en A → se revierte. Confirma que Plus es **per-usuario** (no afecta a B ni al hogar).
3. **Matriz de ads** (las 5 filas, con 2 cuentas del mismo hogar):
   - Free sin Plus → banner **sí**, intersticial **sí**.
   - Free con Plus → **no/no**.
   - Premium, pagador → **no/no**.
   - Premium, miembro sin Plus → banner **sí**, intersticial **no**.
   - Premium, miembro con Plus → **no/no**.
4. **Sincronización**: en cada cambio relevante, verifica que la **otra cuenta** lo refleja sin reinstalar.

Si algún paso falla, abre un mini-ciclo TDD: test que reproduce → fix → re-deploy a dev → re-verifica. No marques la fase DONE con fallos abiertos.

### 6.4 Robustez con hogares grandes (tope 25)
- Verifica que las operaciones masivas de congelación/reasignación con ~25 miembros **no superan el límite de 500 ops** por batch en prod (revisa el troceado) y que el **dashboard** (doc único, límite 1 MB) no se desborda con hogares grandes. Si detectas riesgo, arréglalo.

### 6.5 Auditoría de cobertura de tests (exhaustividad)
- El objetivo de cobertura del proyecto es **exhaustivo**, no mínimo: **todos los flujos y casuísticas** del modelo deben estar probados.
- Mide la cobertura real con la herramienta del proyecto (p.ej. `flutter test --coverage` + lcov; para Functions, la cobertura de su runner). Identifica **huecos**: ramas, estados o transiciones del modelo (tiers, Plus, ads, packs) sin test.
- Por cada hueco, abre un mini-ciclo TDD y añade el test que falta (no solo el caso feliz: errores, fronteras, idempotencia, concurrencia, reglas de seguridad, y las combinaciones de la matriz de ads y de packs).
- Verifica que las **reglas de Firestore** están testeadas: ningún cliente puede escribir entitlements (hogar/usuario/packs) ni saltarse topes.
- Deja constancia en el informe (6.6) del % de cobertura por área y de que no quedan casuísticas sin cubrir.

### 6.6 Paridad dev→prod
- Ejecuta los **gates de `DEPLOY.md`**: tests + `flutter analyze` + paridad de secretos/config entre dev y prod (no despliegues a prod).
- Produce un **informe final** (archivo nuevo en este directorio) con: estado de los 12 SKUs, flags de Remote Config y sus defaults, resultados del QA end-to-end con rutas a las capturas, riesgos abiertos, y la **checklist de lo que falta para producción** (AdMob unit IDs reales, alta de SKUs y precios en stores, free trial, secretos de verificación de recibos, cualquier índice `COLLECTION_GROUP` pendiente).

## 7. Al terminar

- Toda la suite en verde (pega salida) y el informe final escrito.
- Lista de archivos **nuevos** y **modificados** (incluido el informe).
- Resumen ejecutivo: ¿el modelo completo funciona end-to-end en dev? ¿Qué bloquea producción?
- **NO** commit/push ni deploy a prod salvo que el usuario lo pida explícitamente. Si commiteas con su OK: separa ruido CRLF y cierra con `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
