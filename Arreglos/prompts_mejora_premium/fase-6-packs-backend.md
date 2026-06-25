# FASE 6 — Packs de miembros (BACKEND)

> Pega este prompt completo como primer mensaje en una **sesión nueva** de Claude Code en el repo Toka. Es autónomo: no necesitas (ni debes) leer ningún otro documento de análisis.
>
> **Prerrequisito:** Fases 1-2 (Tiers) desplegadas a dev. Esta fase amplía el tope de miembros **por encima del tier Grupo** mediante packs. Lee del **código** cómo quedó el cálculo de `maxMembers` por tier y la maquinaria de downgrade/congelación; los packs se apoyan en ellos.

---

## 0. Quién eres y qué es Toka

Eres un ingeniero senior Flutter + Firebase en **Toka**, app cooperativa de tareas del hogar. Premium por hogar con tiers (Pareja 2 / Familia 5 / Grupo 10). Ahora añadimos **packs de miembros** para crecer por encima de 10.

Stack: Flutter 3.x + Dart 3.x (Riverpod, go_router, freezed, get_it), Firestore, Cloud Functions Node 20 (TS estricto), FCM, Remote Config, AdMob, in_app_purchase. Firebase **dev**: `toka-dd241`.

## 1. Regla de oro: el CÓDIGO es la única fuente de verdad

- **Analiza el código tú mismo, desde cero.** Nada de resúmenes/hallazgos/spec/análisis previos.
- **PROHIBIDO leer**: `Arreglos/*.md`, `Monetizacion/`, `toka_qa_session/**/*.md`, `architecture/*.md`, cualquier `*.md` de spec/análisis, y los `.md` de este directorio salvo este prompt. **SÍ**: `CLAUDE.md`, `DEPLOY.md`.
- El QUÉ está embebido. Ante duda real, **pregunta**.

## 2. Workflow obligatorio (en orden)

1. **Brainstorming** (`superpowers:brainstorming`).
2. **TDD** (`superpowers:test-driven-development`): tests antes. **mocktail**.
3. Implementa.
4. `cd functions && npm run build` + lint sin errores; `flutter analyze` limpio si tocas Dart.
5. Tests verdes (`functions/`: `npm test`; Flutter afectado).
6. **Despliega a dev** (`toka-dd241`) por `DEPLOY.md`, con `FUNCTIONS_DISCOVERY_TIMEOUT=120`. Prod = OK explícito.
7. **Verifica en dispositivos** (sección 4).

## 3. Restricciones de código

- Functions: TS **estricto**, valida auth, `FieldValue.serverTimestamp()`, logging estructurado.
- Entitlement (hogar y packs) se escribe **solo backend**.
- **Trocea batches >500 ops** con el util de `functions/src/shared/`: con tope **25** (vs 10), el fan-out de congelación/reasignación crece ~2,5×. El emulador no aplica el límite de 500; prod sí. Vigila también el tamaño del dashboard (doc único, límite 1 MB) si denormalizas listas.
- `collectionGroup().where(...)` → índice `COLLECTION_GROUP` + try/catch.

## 4. Protocolo de verificación en 2 dispositivos (OBLIGATORIO)

- **MI_9** (USB, 1080×2340) + **emulador** (`emulator-5554`, 1080×2400), ambos a `toka-dd241`.
- Cuentas QA (`TokaQA2024!`): owner / member / admin. **Una distinta por dispositivo**.
- **Login por adb SIN Google** (ver `CLAUDE.md`). NUNCA `KEYCODE_TAB`/autocomplete. Campos sensibles char-a-char.
- **Forzar entitlement por Admin SDK** (`secrets/toka-sa.json`)/script QA: tier + packs activos. NO compra real. (Para llenar muchos miembros, usa el Admin SDK para crear/aceptar miembros de prueba en lugar de hacerlo a mano.)
- **Capturas**: `adb exec-out screencap -p`; >1900px redimensiona con magick.
- Verifica: cambios de tope, **congelación de excedentes** al cancelar pack, y **sincronización** en vivo a la otra cuenta.

## 5. Remote Config flag

Packs de miembros detrás de su **flag de Remote Config**. Con flag off, el tope máximo vuelve a ser el del tier (Grupo 10) sin packs.

## 6. Cobertura de tests EXHAUSTIVA (obligatoria)

No te conformes con un caso feliz y uno de error: cubre **todos los flujos y casuísticas**. Esta fase NO está DONE si queda una combinación de packs, una transición o una frontera sin test. Al terminar, **enumera las casuísticas cubiertas y por qué la lista es completa**.

**Por cada unidad funcional, cubre TODOS los caminos:**
- Cada pack (**+5, +10**) × **mensual/anual**.
- **Todas las combinaciones** de packs activos sobre Grupo (10) → tope efectivo exacto: ninguno → **10**, solo +5 → **15**, solo +10 → **20**, ambos → **25** (capado a 25).
- **Requiere Grupo**: comprar/forzar un pack sobre Pareja o Familia → rechazo server-side.
- Cancelación/expiración de **cada** pack → congela el **número exacto** de excedentes; renovación mantiene plazas; refund.
- Tope absoluto: invitar/aceptar en 25 (ok), en 26 (rechazo).
- **Separación de ejes**: ninguna operación de packs altera `lifetimeUnlockedHomeSlots` (slots de hogar permanentes) ni viceversa.
- **Idempotencia/reentrada**: reprocesar el mismo recibo no duplica plazas; eventos fuera de orden.
- **Concurrencia/transacciones**: operaciones simultáneas sobre el mismo hogar consistentes.
- **Batching**: congelación masiva con ~25 miembros respeta el límite de **500 ops/batch** (testea el troceado con unit, no solo integración: el emulador no aplica el límite, prod sí).
- Errores/precondición: auth ausente, payload inválido, productId desconocido.
- Flag de Remote Config **on y off** (off → tope máximo vuelve al del tier).

**Integración (emuladores Firebase):** flujos extremo-a-extremo de compra/cancelación de pack, recálculo de tope denormalizado al dashboard, y **reglas de seguridad** (el cliente no escribe packs; el tope se enforce server-side).

**Regresión:** ningún test existente puede quedar en rojo. Si cambias un contrato, amplía y actualiza; no borres.

## 7. Al terminar

- Suite afectada en verde (pega salida).
- Archivos **nuevos** y **modificados**.
- **Contrato** para la Fase 7: forma de los packs activos, productIds de packs, función de tope efectivo (tier + packs).
- **NO** commit/push salvo petición; si la hay, separa ruido CRLF y cierra con `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## ESTA FASE: Packs de miembros — BACKEND

### Objetivo

Permitir que un hogar **Grupo (10)** amplíe su tope de miembros con **packs**, vendidos como **suscripción reversible** (no permanente). El backend recalcula el tope efectivo y, al perder un pack, **congela** los miembros excedentes.

### Reglas de producto (embebidas)

- **Pack +5 miembros** → **+5 plazas**. **Requiere tier Grupo.** Ciclo mensual/anual.
- **Pack +10 miembros** → **+10 plazas**. **Requiere tier Grupo.** Ciclo mensual/anual.
- Los packs son **aditivos** sobre el tope del tier. **Tope efectivo = tope del tier (Grupo = 10) + suma de plazas de los packs activos**, capado a 25. Por tanto, partiendo de Grupo (10): sin packs → 10; solo +5 → **15**; solo +10 → **20**; **ambos (+5 y +10) → 25**.
- **Tope absoluto = 25** (= 10 + 5 + 10). Por encima de 25 NO se permite (eso sería Toka Business, otro producto fuera de alcance).
- Pareja y Familia **no** admiten packs (los packs requieren Grupo); valida ese requisito server-side.
- **Suscripción, NO permanente** (decisión consciente): mientras pagas el pack tienes las plazas; al **cancelar/expirar** el pack, los miembros que excedan el nuevo tope se **congelan** (status `frozen`), reutilizando exactamente la maquinaria de downgrade/congelación que ya existe (la misma que la bajada de tier de la Fase 1).
- **Separa conceptualmente** dos ejes que NO debes mezclar:
  - **Slots de hogar** (multi-hogar, `lifetimeUnlockedHomeSlots` u homólogo en el código) → **permanentes**, no cambian con esto.
  - **Plazas de miembro (packs)** → **suscripción, reversibles** vía congelación. No toques la permanencia de los slots de hogar.

### Alcance técnico (analízalo en el código y decide el diseño)

1. **Catálogo**: añade al mapa `productId → efecto` (el de fases anteriores) los productIds de Pack +5 y Pack +10 (× mensual/anual), cada uno con su incremento de tope.
2. **`syncEntitlement`**: al verificar un recibo de pack, persiste el pack activo en el entitlement del **hogar** y **recalcula el tope efectivo**. Valida que el hogar es **Grupo** (rechaza pack sobre Pareja/Familia).
3. **Tope efectivo**: implementa `topeEfectivo(tier, packs)` = topeTier + Σ packs, **capado a 25**. Úsalo en el enforcement server-side de invitar/aceptar miembros.
4. **Cancelación/expiración de pack**: amplía el downgrade para que la pérdida de un pack **congele excedentes** igual que la bajada de tier. Reusa la maquinaria, no la dupliques. Cuidado con `member.status` vs `membership.status` (ejes distintos): sé consistente con lo que ya hace el downgrade.
5. **Reconciliación con stores**: renovación / cancelación / refund de packs mapeados al efecto correcto (igual patrón que tiers).
6. **Enforcement del tope absoluto 25**: ninguna combinación puede superar 25; intentar invitar por encima se rechaza en servidor.
7. **Remote Config flag** (sección 5). **Batching** y tamaño de dashboard (sección 3) son críticos aquí por el tope 25.

### Verificación en dispositivos (mínimo)

- Hogar **Grupo (10)** forzado; añade **Pack +5 y Pack +10** → tope **25**; crea miembros (Admin SDK) hasta 25; el 26.º se **rechaza** server-side.
- **Cancela el Pack +10** → tope baja a **15** (Grupo 10 + Pack +5): los miembros que superen 15 se **congelan** y se ven congelados **en vivo** en la otra cuenta.
- Intenta comprar/forzar un pack sobre un hogar **Familia** → debe rechazarse (requiere Grupo).
- Con el flag de Remote Config off, el tope máximo vuelve a 10.

### Criterios de aceptación

- Tope efectivo = tier + packs, capado a 25; requiere Grupo; enforced en servidor.
- Cancelar pack congela excedentes reutilizando la maquinaria existente; slots de hogar permanentes intactos (eje separado).
- Batching correcto para no romper el límite de 500 ops en prod con hogares grandes.
- Tests unit + integración verdes; desplegado a dev; verificado en 2 dispositivos con capturas; contrato documentado para la Fase 7.
