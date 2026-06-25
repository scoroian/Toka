# FASE 3 — Toka Plus / entitlement individual (BACKEND)

> Pega este prompt completo como primer mensaje en una **sesión nueva** de Claude Code en el repo Toka. Es autónomo: no necesitas (ni debes) leer ningún otro documento de análisis.
>
> **Prerrequisito:** Fases 1 y 2 (Tiers) desplegadas a dev. Esta fase introduce un **eje de entitlement nuevo y ortogonal** al del hogar. Lee del código cómo quedó el entitlement de hogar, pero **no lo modifiques**: Toka Plus es per-usuario.

---

## 0. Quién eres y qué es Toka

Eres un ingeniero senior Flutter + Firebase trabajando en **Toka**, app cooperativa de tareas del hogar. Modelo Premium **por hogar**; ahora añadimos un producto **individual por usuario**.

Stack: Flutter 3.x + Dart 3.x (Riverpod, go_router, freezed, get_it), Cloud Firestore, Cloud Functions Node.js 20 (TS estricto), FCM, Remote Config, AdMob, in_app_purchase. Proyecto Firebase de **desarrollo**: `toka-dd241`.

## 1. Regla de oro: el CÓDIGO es la única fuente de verdad

- **Analiza el código tú mismo, desde cero.** No confíes en resúmenes/hallazgos/spec/análisis previos.
- **PROHIBIDO leer**: `Arreglos/*.md`, `Monetizacion/`, `toka_qa_session/**/*.md`, `architecture/*.md`, cualquier `*.md` de spec/análisis, y los `.md` de este directorio salvo este prompt. **SÍ**: `CLAUDE.md`, `DEPLOY.md`.
- Todo el QUÉ está embebido aquí. Ante duda real de producto, **pregunta**.

## 2. Workflow obligatorio (en orden)

1. **Brainstorming** (`superpowers:brainstorming`) del plan de ESTA fase.
2. **TDD** (`superpowers:test-driven-development`): tests antes. Mocks con **mocktail**.
3. Implementa.
4. `cd functions && npm run build` + lint sin errores; `flutter analyze` limpio si tocas Dart.
5. Tests verdes (`functions/`: `npm test`; Flutter afectado: `flutter test`).
6. **Despliega a dev** (`toka-dd241`) por `DEPLOY.md`, con `FUNCTIONS_DISCOVERY_TIMEOUT=120`. Deploy a prod = OK explícito.
7. **Verifica en dispositivos** (sección 4).

## 3. Restricciones de código

- Functions: TS **estricto**, valida auth al inicio de cada callable, `FieldValue.serverTimestamp()`, logging estructurado.
- El entitlement (de hogar y ahora individual) se escribe **solo desde backend** (verificación de recibos / reconciliación), nunca desde el cliente.
- Si declaras `collectionGroup().where(...)`, añade el índice `COLLECTION_GROUP` en `firestore.indexes.json` y protege con try/catch (el emulador no lo exige, prod sí).
- Trocea batches >500 ops con el util de `functions/src/shared/`.

## 4. Protocolo de verificación en 2 dispositivos (OBLIGATORIO)

- **MI_9** (USB, 1080×2340) + **emulador** (`emulator-5554`, 1080×2400), ambos a `toka-dd241`.
- Cuentas QA (`TokaQA2024!`): owner / member / admin `@gmail.com`. **Una cuenta distinta por dispositivo**.
- **Login por adb SIN Google** (ver `CLAUDE.md`): tap email → `input text` → tap contraseña → `input text` → iniciar. NUNCA `KEYCODE_TAB` ni autocomplete. Campos sensibles → char-a-char.
- **Forzar entitlement por Admin SDK** (`secrets/toka-sa.json`) o script de QA. NO compra real.
- **Capturas**: `adb exec-out screencap -p`; redimensiona >1900px con magick antes de leer.
- Clave de esta fase: comprobar que el entitlement Plus es **per-usuario** (afecta a una cuenta y NO a la otra del mismo hogar).

## 5. Remote Config flag

Toka Plus detrás de su propio **flag de Remote Config**. Con el flag off, ningún usuario tiene Plus activo aunque exista el doc.

## 6. Cobertura de tests EXHAUSTIVA (obligatoria)

No te conformes con un caso feliz y uno de error: cubre **todos los flujos y casuísticas**. Esta fase NO está DONE si queda una rama, un estado o una transición sin test. Al terminar, **enumera las casuísticas cubiertas y por qué la lista es completa**.

**Por cada unidad funcional, cubre TODOS los caminos:**
- Toka Plus **mensual y anual** → entitlement activo correcto (ciclo, fechas de inicio/fin).
- Transiciones de estado: alta, **renovación** (extiende), **cancelación**, **expiración**, **refund** → inactivo; reactivación tras recompra.
- **Aislamiento per-usuario**: activar Plus en el usuario A no cambia el hogar, ni a B, ni ningún otro eje; dos usuarios del mismo hogar con estados Plus distintos coexisten.
- **Idempotencia/reentrada**: reprocesar el mismo recibo/evento no duplica; eventos fuera de orden (p.ej. cancelación antes que alta).
- **Concurrencia**: operaciones simultáneas sobre el mismo usuario resuelven consistentes.
- Errores/precondición: auth ausente, payload inválido, productId desconocido, usuario inexistente.
- Flag de Remote Config **on y off** (off → Plus no se considera activo aunque exista el doc).

**Integración (emuladores Firebase):** flujos extremo-a-extremo de mapeo SKU→entitlement, reconciliación y cancelación; y **reglas de seguridad** (`firestore.rules`): el cliente **no puede escribir** el doc de Plus; la **lectura** permitida es exactamente la definida (propio usuario y, si procede, miembros del hogar) y nada más.

**Regresión:** ningún test existente puede quedar en rojo. Si cambias un contrato, amplía y actualiza; no borres.

## 7. Al terminar

- Suite afectada en verde (pega salida).
- Archivos **nuevos** y **modificados**.
- **Contrato** para fases 4 y 5: forma exacta del doc/campo de entitlement Plus, productIds de Plus, y cómo lee el cliente ese entitlement (provider / ruta Firestore + reglas de lectura).
- **NO** commit/push salvo petición; si la hay, separa ruido CRLF y cierra con `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## ESTA FASE: Toka Plus — eje de entitlement individual (BACKEND)

### Objetivo

Crear un **eje de entitlement por usuario** (independiente del entitlement de hogar) para el producto **Toka Plus**. Esta fase implementa **solo la infraestructura backend**: modelo de datos, mapeo de SKU, reconciliación y reglas. El consumo en UI (skins, métricas) va en la Fase 4 y el efecto sobre ads en la Fase 5.

### Reglas de producto (embebidas)

- **Toka Plus** es **un único SKU individual** por usuario, con **mensual (1,99 €)** y **anual (14,99 €)**.
- Habilita, **para ese usuario y solo ese usuario**: (a) quitar el banner de anuncios, (b) cosméticos/skins, (c) métricas personales. *(Aquí solo persistes el entitlement; cada efecto se consume en fases posteriores.)*
- Es **ortogonal** al hogar: un usuario con Plus lo conserva esté en el hogar que esté; no cambia el tier ni el estado del hogar ni afecta a otros miembros.
- Razón técnica del nuevo eje: hoy el entitlement de ads/features vive en el **dashboard del hogar** (doc **compartido**) y **no puede expresar estado per-usuario**. Por eso Plus necesita su propio almacenamiento.

### Alcance técnico (analízalo en el código y decide el diseño)

1. **Modelo de datos**: define el entitlement individual (p.ej. `users/{uid}.plus` o un subdoc/colección dedicada). Debe expresar al menos: activo/expirado, ciclo (mensual/anual), fechas de inicio/fin, y origen de compra (para reconciliación). Analiza cómo está modelado el entitlement de hogar para mantener un estilo coherente, **sin reutilizar el doc del hogar**.
2. **`syncEntitlement`**: amplía el mapa `productId → efecto` (el que dejó la Fase 1) para que el SKU de Toka Plus (mensual/anual) escriba el **entitlement de usuario**, sin tocar nada del hogar.
3. **Reconciliación / cancelación / expiración**: integra Plus en la reconciliación con stores (RTDN de Google / notificaciones de App Store) existente: renovación → extiende; cancelación/expiración/refund → marca Plus inactivo. Reutiliza la maquinaria de reconciliación, no la dupliques.
4. **Firestore rules**: el doc de entitlement Plus es **lectura** del propio usuario; valora si los **miembros del mismo hogar** necesitan leer el Plus de otros (la matriz de ads de la Fase 5 puede necesitar saber si el pagador/otros tienen Plus — decide el alcance mínimo de lectura y déjalo documentado). **Escritura solo backend** (rules `write: if false` para el cliente).
5. **Exposición al cliente**: asegúrate de que el cliente puede **leer** su propio entitlement Plus de forma sencilla (define la ruta y, si procede, un índice). La Fase 4 creará el provider Flutter; tú deja el dato accesible y las reglas correctas.
6. **Remote Config flag** (sección 5).

### Verificación en dispositivos (mínimo)

- Fuerza **Plus activo** en la cuenta A (Admin SDK). En el dispositivo de A, el entitlement Plus se lee como activo; en el dispositivo de B (otra cuenta del **mismo** hogar), Plus sigue **inactivo** → demuestra que es per-usuario.
- Marca Plus como **cancelado/expirado** y verifica que pasa a inactivo, sincronizado en vivo.
- Verifica que activar Plus en A **no cambia** el tier ni el estado del hogar ni nada de B.
- Con el flag de Remote Config off, Plus no se considera activo.

### Criterios de aceptación

- Existe un eje de entitlement **per-usuario** persistido y reconciliado, con reglas de acceso correctas (write solo backend).
- `syncEntitlement` mapea el SKU de Plus al entitlement de usuario sin tocar el hogar.
- Aislamiento per-usuario demostrado en 2 cuentas; tests unit + integración verdes; desplegado a dev; capturas.
- Contrato documentado para Fases 4 y 5.
