# FASE 1 — Tiers por tamaño de hogar (BACKEND)

> Pega este prompt completo como primer mensaje en una **sesión nueva** de Claude Code en el repo Toka. Es autónomo: no necesitas (ni debes) leer ningún otro documento de análisis.

---

## 0. Quién eres y qué es Toka

Eres un ingeniero senior Flutter + Firebase trabajando en **Toka**, una app cooperativa de gestión de tareas del hogar para parejas, familias y pisos compartidos. Reparte tareas con rotación, recurrencias, estadísticas, valoraciones y un modelo Premium **por hogar**.

Stack: Flutter 3.x + Dart 3.x (Riverpod, go_router, freezed, get_it), Cloud Firestore, Cloud Functions Node.js 20 (TypeScript estricto), FCM, Remote Config, AdMob, in_app_purchase. Proyecto Firebase de **desarrollo**: `toka-dd241`.

## 1. Regla de oro: el CÓDIGO es la única fuente de verdad

- **Analiza el código tú mismo, desde cero.** No confíes en ningún resumen, hallazgo, spec ni análisis previo.
- **PROHIBIDO leer** (contienen análisis/opiniones potencialmente desactualizados): `Arreglos/*.md` (incluidos `mejora_modelos_premium.md`, `premortem.md`, `Hallazgos.md`), `Monetizacion/`, `toka_qa_session/**/*.md`, `architecture/*.md`, cualquier `*.md` de spec o análisis, y los `.md` de este propio directorio salvo este prompt. **SÍ puedes** leer `CLAUDE.md` y `DEPLOY.md` (son operativos).
- Todo el QUÉ (precios, topes, reglas de negocio) está embebido en este prompt. Si algo de producto no está aquí y hay duda real, **pregunta** antes de inventar.

## 2. Workflow obligatorio (en orden)

1. **Brainstorming primero**: usa la skill `superpowers:brainstorming` para confirmar el plan de ESTA fase antes de tocar código.
2. **TDD**: escribe los tests antes que la implementación (skill `superpowers:test-driven-development`). Mocks con **mocktail** (nunca mockito).
3. Implementa.
4. `cd functions && npm run build` y lint deben pasar **sin errores**; `flutter analyze` limpio si tocas Dart.
5. Tests verdes: los de `functions/` (`npm test`) y los Flutter afectados (`flutter test`).
6. **Despliega a dev** (`toka-dd241`) siguiendo `DEPLOY.md` (gates de tests+analyze y paridad de secretos/config). Usa `FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy --only functions:...`. El usuario autoriza deploys a dev mientras la app NO esté publicada; deploy a prod requiere OK explícito.
7. **Verifica en dispositivos** (sección 4). No marques nada DONE sin verde + evidencia.

## 3. Restricciones de código

- Functions: TypeScript **estricto**, validar auth al inicio de cada callable, `FieldValue.serverTimestamp()` para timestamps, logging estructurado con el `logger` de Firebase Functions.
- Operaciones críticas (entitlement, downgrade, límites) por **Callable Functions o transacciones**, nunca por escritura directa del cliente.
- El estado Premium/entitlement se lee SIEMPRE de Firestore, nunca del dispositivo.
- Firestore: nunca leer listas completas sin paginación. Respeta el patrón de denormalización al dashboard (`homes/{homeId}/views/dashboard`).
- Si un `WriteBatch`/transacción puede superar 500 ops, trocéalo (busca el util de batching existente en `functions/src/shared/`). El emulador NO aplica el límite de 500; prod sí.
- Si declaras un `collectionGroup().where(...)`, añade el índice `COLLECTION_GROUP` en `firestore.indexes.json` (el emulador no lo exige, prod sí) y protege con try/catch.

## 4. Protocolo de verificación en 2 dispositivos (OBLIGATORIO)

Hay **dos dispositivos** conectados, cada uno con **una cuenta distinta**, para ver sincronización en vivo:

- **MI_9** (físico, USB, 1080×2340) y **emulador** Android Studio (`emulator-5554`, 1080×2400). Ambos apuntan a `toka-dd241` (no a emuladores Firebase).
- Cuentas QA (contraseña `TokaQA2024!`): `toka.qa.owner@gmail.com`, `toka.qa.member@gmail.com`, `toka.qa.admin@gmail.com`. Usa **cuentas diferentes en cada dispositivo** (p.ej. owner en MI_9, member en emulador) para validar sincronización entre miembros del mismo hogar.
- **Login por adb SIN Google** (ver `CLAUDE.md` → "Login en el emulador"): tap campo email → `input text` → tap campo contraseña → `input text` → tap iniciar. NUNCA `KEYCODE_TAB` ni dejar abierto el autocomplete de cuentas Google. Para campos de código/entrada sensible usa input char-a-char (no `input text` de golpe, que corrompe el campo en MIUI).
- **Forzar entitlement por Admin SDK**: como todavía NO hay compra real con SKUs sandbox, inyecta el estado (tier, `premiumStatus`, maxMembers, congelaciones) escribiendo Firestore directamente con el **Admin SDK** (`secrets/toka-sa.json`) o un script Node de QA. Si no existe un helper, créalo. NO uses compra real de la store.
- **Capturas**: `adb exec-out screencap -p`. Si una dimensión supera 1900px, redimensiónala con magick antes de leerla (regla de `CLAUDE.md`).
- **Qué verificar siempre**: el cambio **se sincroniza en vivo** a la otra cuenta; los **límites se aplican en servidor** (no solo en UI); los **estados transitorios** (congelación, downgrade) se ven correctos en ambos dispositivos.

## 5. Remote Config flag

Mete el nuevo modelo de tiers detrás de un **flag de Remote Config** (reutiliza el patrón de flags que ya exista en el código). Con el flag desactivado debe mantenerse el comportamiento binario actual (Free 3 / Premium 10). Documenta el nombre del flag en el cierre.

## 6. Cobertura de tests EXHAUSTIVA (obligatoria)

No te conformes con un caso feliz y uno de error: cubre **todos los flujos y todas las casuísticas**. Esta fase NO está DONE si queda una rama, un estado o una transición sin test. Al terminar, **enumera las casuísticas cubiertas y razona por qué la lista es completa** (qué ramas/estados existen y qué test cubre cada uno).

**Por cada unidad funcional, cubre TODOS los caminos:**
- Cada productId por separado: los **6 SKUs de tier** (Pareja/Familia/Grupo × mensual/anual) → su tope correcto.
- Derivación de `maxMembers` para **todos** los estados: Free=3, Pareja=2, Familia=5, Grupo=10 (y producto desconocido → fail-safe).
- **Downgrade entre cada par de tiers** y a Free (Grupo→Familia, Grupo→Pareja, Familia→Pareja, cada uno→Free), verificando el **número exacto** de miembros congelados; y **subida** de tier (no congela).
- Reconciliación con stores: renovación, cambio de plan, cancelación, expiración y refund, cada uno mapeado al tier correcto.
- Enforcement del tope: invitar/aceptar **justo en el tope**, en **tope+1** (rechazo) y en tope−1 (ok).
- Errores/precondición: auth ausente, payload inválido, hogar inexistente, no-pagador intentando operar.
- Fronteras y datos: colecciones vacías, campos null/ausentes, valores legacy de `premiumStatus`, consistencia `member.status` vs `membership.status`.
- **Idempotencia/reentrada**: reprocesar el mismo recibo/evento no duplica ni corrompe; eventos fuera de orden.
- **Concurrencia/transacciones**: dos operaciones simultáneas sobre el mismo hogar resuelven de forma consistente.
- **Aislamiento**: la operación no afecta a otros hogares/usuarios.
- Flag de Remote Config **on y off** (el off restaura el binario 3/10).

**Integración (emuladores Firebase):** un test por cada flujo extremo-a-extremo que toque Firestore/Functions, incluyendo los efectos **denormalizados al dashboard** y las **reglas de seguridad** (`firestore.rules`): un cliente NO puede escribir lo que solo escribe el backend; el tope se enforce server-side aunque el cliente intente saltarlo.

**Regresión:** ningún test existente puede quedar en rojo. Si cambias un contrato, amplía y actualiza los tests; no los borres.

## 7. Al terminar

- Ejecuta toda la suite afectada y confirma verde (pega salida real).
- Lista archivos **nuevos** y **modificados**.
- Resume **el contrato que dejaste en el código** para la fase siguiente: nombres exactos de campos/colecciones/productIds/funciones que la próxima sesión leerá del código.
- **NO** hagas commit ni push salvo que el usuario lo pida. Si lo pide: separa el ruido CRLF con `git diff --ignore-cr-at-eol`, y cierra el mensaje de commit con `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## ESTA FASE: Tiers por tamaño de hogar — BACKEND

### Objetivo

Hoy el límite de miembros es **binario**: Free = 3, Premium = 10. Conviértelo en **tres tiers de hogar Premium** cuyo tope de miembros escala con el precio. El **backend** (Functions + Firestore rules + dashboard denormalizado) pasa a ser la fuente de verdad del tier de cada hogar y del `maxMembers` efectivo.

### Reglas de producto (embebidas — no las busques en otro sitio)

- **Tres tiers Premium**, todos con ciclo **mensual y anual**:
  - **Toka Pareja** → tope **2** miembros.
  - **Toka Familia** → tope **5** miembros.
  - **Toka Grupo** → tope **10** miembros.
- **Free** sigue en **3** miembros (sin cambios) y mantiene sus demás límites actuales (tareas, recurrentes, admins, historial 30 días).
- **Las mismas features premium** (smart distribution, vacaciones, reviews, 90 días de historial, etc.) están en los **tres tiers**: lo único que cambia entre tiers es el **tope de miembros**. No diferencies features por tier.
- El tier es **del hogar** (no del usuario) y lo paga el pagador del hogar (`currentPayerUid`). Rol operativo y facturación siguen **desacoplados** (no los acoples).

### Alcance técnico (analízalo en el código y decide el diseño concreto)

1. **Catálogo de productos extensible**: define un mapa `productId → efecto` extensible (no un `if monthly/annual`). Esta fase añade 6 productIds (3 tiers × mensual/anual), cada uno con su tope. Analiza cómo `sync_entitlement` infiere hoy `monthly/annual` y sustitúyelo por este mapa, dejándolo preparado para que fases futuras añadan packs y Toka Plus sin reescribirlo.
2. **Derivación de `maxMembers`**: hoy es una constante (busca `FREE_LIMITS`/`maxMembers`/límites premium en `functions/src/shared/` y donde se enforque el tope al invitar/aceptar miembros). Conviértelo en una función del tier: Free→3, Pareja→2, Familia→5, Grupo→10. Persiste el tier y el `maxMembers` efectivo en el entitlement del hogar y **denormalízalo al dashboard** (`premiumFlags` u homólogo) para que el cliente lo lea sin recomputar.
3. **`syncEntitlement`**: al verificar un recibo, mapea el productId al tier y persiste tier + tope. (La verificación real de recibos ya existe en el código; respétala. Si está incompleta para algún store, no la rehagas: deja el mapeo productId→tier desacoplado del verificador.)
4. **Downgrade entre tiers**: la maquinaria de downgrade (busca `applyDowngradeJob` / `apply_downgrade_plan` / planes de downgrade) hoy contempla Premium↔Free. Amplíala a **bajada de tier** (Grupo→Familia→Free, Grupo→Pareja, etc.): al bajar de tier, **congelar** los miembros que excedan el nuevo tope (status `frozen`), reutilizando exactamente la lógica de congelación que ya usa el downgrade a Free. Recuerda que `member.status` y `membership.status` son ejes distintos: comprueba cuál leen las reglas y cuál mueve el downgrade actual, y sé consistente.
5. **Reconciliación con stores**: la reconciliación (RTDN de Google / notificaciones de App Store) debe mapear renovación / cambio de plan / cancelación / refund al **tier** correcto, no a Premium binario.
6. **Enforcement server-side del tope**: invitar/aceptar un miembro por encima del tope del tier debe rechazarse en **servidor** (no solo ocultar el botón). Localiza el punto de validación actual del tope y hazlo derivar del tier.
7. **Firestore rules**: si las rules gatean por premium/maxMembers, actualízalas para reflejar el tier. Añade los índices necesarios.
8. **Remote Config flag** (sección 5).

### Verificación en dispositivos (mínimo)

- Fuerza por Admin SDK un hogar a tier **Grupo (10)**, mete miembros hasta 10 desde las dos cuentas, e intenta el 11.º → debe **rechazarse server-side** y verse el mensaje en ambos dispositivos.
- Baja el hogar a **Familia (5)** por Admin SDK / downgrade: los **5 excedentes deben congelarse** y reflejarse **en vivo** en la otra cuenta.
- Baja a **Free (3)** y repite la comprobación de congelación.
- Verifica que con el **flag de Remote Config desactivado** el comportamiento vuelve al binario actual.

### Criterios de aceptación

- `maxMembers` deriva del tier en servidor; el dashboard expone tier + tope.
- Downgrade entre tiers congela excedentes reutilizando la maquinaria existente (sin duplicarla).
- Tope enforced en servidor; tests unit + integración verdes; desplegado a dev; verificado en los 2 dispositivos con capturas.
- Contrato documentado (nombres de campo del tier, productIds, función de derivación) para que la Fase 2 (Flutter) lo consuma desde el código.
