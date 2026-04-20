# QA Full App Session — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to execute this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ejecutar una sesión QA end-to-end de Toka en dos dispositivos reales contra Firebase producción, documentando cada caso con evidencia y entregando un reporte con bugs priorizados.

**Enfoque:** No es un build de feature. Cada "task" es un bloque de pruebas con pasos concretos; la única escritura de código real es el script admin temporal (`scripts/qa/qa-admin.mjs`) que se borra al final. Cada paso produce evidencia (screenshot + entrada en el reporte).

**Tech Stack:** Flutter (`main.dart`, producción), Firebase Admin SDK (Node 20) para manipular Firestore y marcar Premium, `adb` para capturas, Firebase CLI 15.8 contra `toka-dd241`.

**Documentos derivados:**
- Reporte maestro: `toka_qa_session/QA_REPORT_2026-04-20.md`
- Capturas: `toka_qa_session/screenshots/`
- Script admin: `scripts/qa/qa-admin.mjs` (se borra al final)

---

## Task 0: Setup inicial

**Files:**
- Create: `toka_qa_session/QA_REPORT_2026-04-20.md`
- Create: `scripts/qa/qa-admin.mjs`
- Create: `scripts/qa/package.json`
- Create: `scripts/qa/.gitignore`

### Paso 0.1 — Verificar dispositivos y git SHA

- [ ] Ejecutar `adb devices` → confirmar que ambos dispositivos están `device` (no `offline`).
- [ ] Capturar git SHA actual: `git rev-parse --short HEAD`. Guardar para el header del reporte.

### Paso 0.2 — Preparar script admin temporal

- [ ] Crear carpeta `scripts/qa/`.
- [ ] Crear `scripts/qa/.gitignore` con:

```
service-account.json
node_modules/
```

- [ ] Crear `scripts/qa/package.json`:

```json
{
  "name": "toka-qa-admin",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "dependencies": {
    "firebase-admin": "^12.0.0"
  }
}
```

- [ ] Crear `scripts/qa/qa-admin.mjs` con utilidades:

```javascript
import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const projectId = 'toka-dd241';
initializeApp({
  credential: applicationDefault(),
  projectId,
});

const db = getFirestore();
const auth = getAuth();

const cmd = process.argv[2];
const args = process.argv.slice(3);

async function setPremium(homeId, daysAhead = 30) {
  const endsAt = new Date();
  endsAt.setDate(endsAt.getDate() + Number(daysAhead));
  await db.doc(`homes/${homeId}`).update({
    isPremium: true,
    premiumEndsAt: Timestamp.fromDate(endsAt),
    updatedAt: FieldValue.serverTimestamp(),
  });
  console.log(`Home ${homeId} premium until ${endsAt.toISOString()}`);
}

async function revokePremium(homeId) {
  await db.doc(`homes/${homeId}`).update({
    isPremium: false,
    premiumEndsAt: null,
    updatedAt: FieldValue.serverTimestamp(),
  });
  console.log(`Home ${homeId} premium revoked`);
}

async function createPastTask(homeId, { title, dueAtIso, assigneeUid }) {
  const ref = db.collection(`homes/${homeId}/tasks`).doc();
  await ref.set({
    id: ref.id,
    title,
    dueAt: Timestamp.fromDate(new Date(dueAtIso)),
    assigneeUid,
    status: 'todo',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  console.log(`Created task ${ref.id} dueAt ${dueAtIso}`);
}

async function listHomeMembers(homeId) {
  const snap = await db.collection(`homes/${homeId}/members`).get();
  snap.forEach(d => console.log(d.id, JSON.stringify(d.data())));
}

async function findHomeOfUser(uid) {
  const snap = await db.collection('homes').where('memberIds', 'array-contains', uid).get();
  snap.forEach(d => console.log(d.id, d.data().name));
}

switch (cmd) {
  case 'set-premium':       await setPremium(args[0], args[1]); break;
  case 'revoke-premium':    await revokePremium(args[0]); break;
  case 'past-task':         await createPastTask(args[0], JSON.parse(args[1])); break;
  case 'members':           await listHomeMembers(args[0]); break;
  case 'find-home':         await findHomeOfUser(args[0]); break;
  default:
    console.error('Usage: node qa-admin.mjs <set-premium|revoke-premium|past-task|members|find-home> ...');
    process.exit(1);
}
```

- [ ] Instalar dependencias: `cd scripts/qa && npm install`.

### Paso 0.3 — Configurar credenciales admin

- [ ] Verificar si `GOOGLE_APPLICATION_CREDENTIALS` ya está seteado: `echo $GOOGLE_APPLICATION_CREDENTIALS`.
- [ ] Si no, usar `firebase login:ci` o exportar un service account. Si falla, preguntar al usuario por la ruta del service account JSON antes de continuar.
- [ ] Smoke test: `cd scripts/qa && node qa-admin.mjs find-home nonexistent` debe devolver salida vacía sin errores de auth.

### Paso 0.4 — Crear esqueleto del reporte

- [ ] Crear `toka_qa_session/QA_REPORT_2026-04-20.md` con el header:

```markdown
# QA Report — 2026-04-20

**Git SHA:** <sha>
**Dispositivos:**
- Móvil: 4f26486b (Android 16, API 36)
- Emulador: emulator-5554 (Android 14, API 34)
**Hora inicio:** <timestamp>
**Ejecutor:** Claude Code

## Cuentas creadas

| Alias | Email | Password | Dispositivo | Rol | Hogar | Notas |
|-------|-------|----------|-------------|-----|-------|-------|

## Hogares creados

| Nombre | ID | Owner | Miembros | Código invitación |
|--------|----|----|----------|-------------------|

## Bloques

## Bugs encontrados

### Críticos
### Altos
### Medios
### Bajos

## Auditoría de navegación y duplicados

## Pruebas manuales pendientes

## Limpieza
```

### Paso 0.5 — Compilar y desplegar en ambos dispositivos

- [ ] En terminal 1: `cd <repo> && flutter run -d 4f26486b --release` (móvil). Esperar a "app running".
- [ ] En terminal 2 (en paralelo): `flutter run -d emulator-5554 --release` (emulador).
- [ ] Capturar pantalla inicial de cada uno para confirmar que arranca sin crash.
- [ ] Anotar en el reporte: versión compilada OK en ambos.

### Paso 0.6 — Arrancar captura de logs en background

- [ ] Arrancar `flutter logs -d 4f26486b > /tmp/toka-mobile.log 2>&1 &` y guardar PID.
- [ ] Arrancar `flutter logs -d emulator-5554 > /tmp/toka-emu.log 2>&1 &` y guardar PID.

---

## Task 1: Bloque 1 — Registro + onboarding

### Paso 1.1 — Usuario A en móvil (registro desde cero)

- [ ] Móvil: desinstalar versión previa si hay sesión persistida (`adb -s 4f26486b shell pm clear com.example.toka` — ajustar package real).
- [ ] Abrir la app. Screenshot de splash y pantalla de login.
- [ ] Registrar con email nuevo: `qa.a.2026.04.20@tokatest.dev` / password `TokaQA2026!`.
- [ ] Seguir onboarding: seleccionar idioma **es**, introducir nombre "QA A", subir avatar (cualquier imagen).
- [ ] Screenshot de cada paso del onboarding.
- [ ] Al llegar a Home, screenshot.
- [ ] Registrar en el reporte: caso 1.1 con resultado OK/BUG, adjuntar screenshots.

### Paso 1.2 — Persistencia de sesión

- [ ] Cerrar app completamente (`adb shell am force-stop <package>`).
- [ ] Reabrir. Debe ir directa al hogar/onboarding sin pedir login de nuevo. Screenshot. Registrar caso 1.2.

### Paso 1.3 — Usuario B en emulador

- [ ] Repetir 1.1 en emulador con: `qa.b.2026.04.20@tokatest.dev` / `TokaQA2026!`, idioma **en**, nombre "QA B".
- [ ] Screenshot y registro.

### Paso 1.4 — Cambio de idioma en pleno onboarding

- [ ] Crear usuario temporal `qa.lang.2026.04.20@tokatest.dev` en emulador.
- [ ] En la pantalla de selección de idioma, cambiar es → en → ro → es. Screenshot tras cada cambio verificando que textos traducen.
- [ ] Completar onboarding en ro. Verificar que `users/{uid}.locale = "ro"` vía `qa-admin.mjs members <homeId>`.
- [ ] Registrar caso 1.4.

### Paso 1.5 — Validaciones de formulario

- [ ] Email mal formado → ver error. Screenshot.
- [ ] Password corta → ver error. Screenshot.
- [ ] Email ya registrado → ver error. Screenshot.
- [ ] Registrar caso 1.5.

### Paso 1.6 — Commit checkpoint

- [ ] Checkpoint en el reporte: "Bloque 1 completo. N casos OK, M bugs." Resumen corto al usuario.

---

## Task 2: Bloque 2 — Hogar: crear y unirse

### Paso 2.1 — A crea hogar "QA Hogar 1"

- [ ] Móvil (A): pulsar "Crear hogar", nombre "QA Hogar 1", confirmar.
- [ ] Screenshot del hogar recién creado y del código de invitación visible.
- [ ] Anotar código en el reporte.

### Paso 2.2 — B se une por código

- [ ] Emulador (B): pulsar "Unirse a hogar", introducir el código.
- [ ] Screenshot antes y después de confirmar.
- [ ] Verificar que B ya ve el hogar.

### Paso 2.3 — Replicación en tiempo real

- [ ] Móvil (A): pantalla de miembros. Esperar a que B aparezca. Medir tiempo aproximado (< 5s esperado).
- [ ] Screenshot de A mostrando a B en miembros.
- [ ] Registrar caso 2.3 con tiempo medido.

### Paso 2.4 — Casos de error de código

- [ ] Emulador (B, segunda cuenta temporal si hace falta): introducir código inválido `XXXXXX`. Ver error. Screenshot.
- [ ] Emulador: intentar usar el mismo código de `QA Hogar 1` una segunda vez con B ya dentro → verificar mensaje esperado (ya eres miembro). Screenshot.
- [ ] Registrar caso 2.4.

### Paso 2.5 — Intento de crear segundo hogar

- [ ] Móvil (A): intentar crear un segundo hogar. Según reglas de negocio (A ya es owner de uno, máx 2 base + 3 extra = 5) debería permitirse un segundo hogar base. Verificar UI.
- [ ] Screenshot y registro.

### Paso 2.6 — Checkpoint

- [ ] Resumen al usuario. Anotar bugs.

---

## Task 3: Bloque 3 — Tareas CRUD + rotación

### Paso 3.1 — A crea tareas variadas

- [ ] Móvil (A), en QA Hogar 1, crear:
    - Tarea **T1**: "Sacar basura", asignada a A, recurrencia diaria.
    - Tarea **T2**: "Hacer compra", asignada a B, recurrencia semanal.
    - Tarea **T3**: "Limpiar cocina", rotación A→B→A, recurrencia cada 3 días.
    - Tarea **T4**: "Pagar alquiler", asignada a A, única, due mañana.
- [ ] Screenshot de la lista final en móvil. Registrar caso 3.1.

### Paso 3.2 — Replicación de tareas a B

- [ ] Emulador (B): abrir pestaña Tareas. Verificar que T1-T4 aparecen. Screenshot.
- [ ] Registrar caso 3.2.

### Paso 3.3 — B completa T2

- [ ] Emulador (B): marcar T2 como hecha. Screenshot antes y después.
- [ ] Móvil (A): verificar que T2 aparece como hecha en < 5s. Screenshot.
- [ ] Registrar caso 3.3.

### Paso 3.4 — B salta T1 (que está asignada a A)

- [ ] Aplicable solo si la UI permite saltar tareas ajenas. Probar y documentar comportamiento.
- [ ] Registrar caso 3.4 (puede ser "N/A" si no aplica).

### Paso 3.5 — A pasa turno de T1

- [ ] Móvil (A): pulsar "Pasar turno" en T1. Debe aparecer diálogo con penalización estadística visible (ver spec: "penalización visible antes de confirmar").
- [ ] Screenshot del diálogo con la penalización.
- [ ] Confirmar. Verificar que T1 pasa a B.
- [ ] Emulador (B): verificar replicación. Screenshot.
- [ ] Registrar caso 3.5 con atención al diálogo de penalización.

### Paso 3.6 — Editar y eliminar tareas

- [ ] Móvil (A): editar T3 cambiando título a "Limpiar cocina a fondo". Screenshot.
- [ ] Emulador (B): verificar cambio en < 5s.
- [ ] Móvil (A): eliminar T4. Screenshot del diálogo de confirmación.
- [ ] Emulador (B): verificar que T4 desaparece.
- [ ] Registrar caso 3.6.

### Paso 3.7 — Avance de rotación en T3

- [ ] Emulador (B, asignada ahora): completar T3.
- [ ] Verificar que la próxima instancia (al día 3) quedará asignada a A. Ver UI de vista previa o siguiente asignado. Screenshot.
- [ ] Registrar caso 3.7.

### Paso 3.8 — Checkpoint

- [ ] Resumen al usuario.

---

## Task 4: Bloque 4 — Tareas vencidas y orden de "Hoy"

### Paso 4.1 — Obtener IDs necesarios

- [ ] Ejecutar `cd scripts/qa && node qa-admin.mjs find-home <uid_A>` para obtener `homeId`. UID de A se ve en Firebase Auth o se busca por email.
- [ ] Anotar `homeId` en el reporte.

### Paso 4.2 — Inyectar tareas con `dueAt` pasado

- [ ] Crear T-pasada-1h: `node qa-admin.mjs past-task <homeId> '{"title":"Vencida 1h","dueAtIso":"<hoy-1h ISO>","assigneeUid":"<uid_A>"}'`.
- [ ] Repetir para: 1 día atrás, 1 semana atrás.
- [ ] Registrar los tres IDs en el reporte.

### Paso 4.3 — Inyectar tareas futuras por franja

- [ ] Crear una tarea para cada franja: Hora (+2h), Día (+1d), Semana (+5d), Mes (+15d), Año (+200d).
- [ ] Registrar IDs.

### Paso 4.4 — Verificar orden en "Hoy"

- [ ] Móvil (A): abrir pantalla Hoy. Screenshot completa (scroll si hace falta, varias screenshots).
- [ ] Verificar orden: Hora → Día → Semana → Mes → Año.
- [ ] Verificar subgrupos "Por hacer" / "Hechas".
- [ ] Verificar badge "vencida" en las tres pasadas.
- [ ] Registrar caso 4.4 con evidencia.

### Paso 4.5 — Verificar lectura única del dashboard

- [ ] Filtrar `flutter logs` buscando lecturas a `homes/{homeId}/tasks` directas desde la pantalla Hoy. Si hay, es bug (debe leer solo `views/dashboard`).
- [ ] Alternativa: ver `homes/{homeId}/views/dashboard` en Firestore y verificar que existe y contiene las tareas esperadas.
- [ ] Registrar caso 4.5.

### Paso 4.6 — Checkpoint

- [ ] Resumen.

---

## Task 5: Bloque 5 — Notificaciones

### Paso 5.1 — Verificar permisos FCM

- [ ] Móvil (A): ir a Ajustes → Notificaciones. Verificar estado. Si pide permiso, aceptar.
- [ ] Emulador (B): idem.
- [ ] Screenshot de cada.

### Paso 5.2 — Ajustar preferencias

- [ ] Cambiar preferencias en A (ej. desactivar "tareas asignadas"), screenshot.
- [ ] Verificar que el cambio persiste tras cerrar y reabrir la app.

### Paso 5.3 — Provocar eventos

- [ ] Evento 1 (**nueva tarea asignada a B**): móvil (A) crea tarea "Notif test 1" asignada a B. Emulador (B) debe recibir notificación push (app en background).
- [ ] Evento 2 (**paso de turno recibido**): móvil (A) pasa turno de una tarea a B.
- [ ] Evento 3 (**tarea vencida**): usar `qa-admin.mjs` para crear tarea de A con `dueAt` de hace 5 minutos (si hay trigger de vencimiento; si no, documentar como "no testeable sin esperar").
- [ ] Por cada evento: screenshot de la notificación (bandeja sistema) + estado tras abrirla.

### Paso 5.4 — Notificación con app cerrada

- [ ] Cerrar emulador (B) completamente. A provoca evento.
- [ ] Verificar si llega notificación (esto depende de Play Services del emulador; si falla aquí, marcar como "pendiente verificación en móvil").
- [ ] Registrar caso 5.4.

### Paso 5.5 — Checkpoint

- [ ] Resumen.

---

## Task 6: Bloque 6 — Premium (happy + bordes)

### Paso 6.1 — Marcar hogar como Premium

- [ ] `node qa-admin.mjs set-premium <homeId> 30` → `premiumEndsAt = hoy + 30 días`.
- [ ] Móvil (A): verificar badge/indicador Premium. Screenshot.
- [ ] Emulador (B): idem.
- [ ] Registrar caso 6.1.

### Paso 6.2 — Invitar tercer miembro C (plaza extra)

- [ ] Crear usuario C en un flujo. Como no hay tercer dispositivo físico, pedir logout en emulador y registrar `qa.c.2026.04.20@tokatest.dev` / `TokaQA2026!`, idioma es, nombre "QA C".
- [ ] Unirse al hogar con el código de "QA Hogar 1".
- [ ] Screenshot del emulador con C dentro del hogar.
- [ ] Móvil (A): ver a C en miembros. Screenshot.
- [ ] Registrar caso 6.2.

### Paso 6.3 — Forzar ventana de rescate

- [ ] `node qa-admin.mjs set-premium <homeId> 2` → faltan 2 días para expirar.
- [ ] Móvil (A, owner y pagador): abrir ajustes o pantalla Premium. Debe aparecer UI de "ventana de rescate" (según reglas: 3 días antes de `premiumEndsAt`).
- [ ] Screenshot. Registrar caso 6.3.

### Paso 6.4 — Intentar expulsar al pagador A

- [ ] Emulador (logueado ahora como C, ver si tiene permisos de admin; si no, se hace con B como admin si lo es, o se documenta que solo el owner puede expulsar).
- [ ] Intentar expulsar a A → debe fallar porque es pagador con Premium vigente.
- [ ] Screenshot del error.
- [ ] Registrar caso 6.4.

### Paso 6.5 — Revocar Premium

- [ ] `node qa-admin.mjs revoke-premium <homeId>`.
- [ ] Móvil (A): verificar que desaparece el badge Premium y que C queda con acceso restringido (según reglas de downgrade).
- [ ] Emulador (C): verificar UI de "has sido removido por downgrade" o equivalente. Screenshot.
- [ ] Registrar caso 6.5.

### Paso 6.6 — Créditos permanentes

- [ ] Verificar en Firestore que `homes/{homeId}` conserva `permanentCredits` (o campo equivalente) tras la revocación. Documentar con dump de Firestore o screenshot de la consola.
- [ ] Registrar caso 6.6.

### Paso 6.7 — Checkpoint

- [ ] Resumen.

---

## Task 7: Bloque 7 — Valoraciones e historial

### Paso 7.1 — Preparación

- [ ] Asegurar que B (emulador) y A están dentro de "QA Hogar 1". Si C sigue dentro, se usa también para verificar la parte privada.
- [ ] Emulador: si está logueado como C, cerrar sesión y entrar como B.

### Paso 7.2 — B completa una tarea de su asignación

- [ ] Emulador (B): crear y completar una tarea "Tarea a valorar" (o usar una existente).
- [ ] Screenshot del completado.

### Paso 7.3 — A valora la tarea con nota privada

- [ ] Móvil (A): ir a la tarea completada por B. Valorar (ej. 4★) con nota privada "Nota privada QA A→B".
- [ ] Screenshot del formulario.
- [ ] Confirmar.

### Paso 7.4 — B ve la nota privada

- [ ] Emulador (B): abrir la tarea valorada. Verificar que ve la nota privada "Nota privada QA A→B". Screenshot.

### Paso 7.5 — C NO ve la nota privada

- [ ] Cambiar sesión del emulador a C (logout B, login C). Si es costoso, omitir y verificar las reglas de Firestore directamente con `firebase firestore:get`.
- [ ] Verificar que C no puede leer el campo de nota privada (ya sea por UI oculta o por reglas que bloquean).
- [ ] Screenshot.
- [ ] Registrar caso 7.5.

### Paso 7.6 — Historial

- [ ] Móvil (A): abrir pantalla Historial. Verificar que la valoración aparece con timestamp correcto.
- [ ] Screenshot.
- [ ] Registrar caso 7.6.

### Paso 7.7 — Checkpoint

- [ ] Resumen.

---

## Task 8: Bloque 8 — Auditoría de navegación y duplicados

### Paso 8.1 — Mapa de pantallas alcanzables

- [ ] Recorrer la app anotando cada pantalla y desde qué puntos se alcanza. Ejemplo esperado: "Ajustes del hogar" desde [Miembros → icono ajustes] y [Ajustes → hogar].
- [ ] Guardar tabla en el reporte:

| Pantalla | Rutas de acceso | Duplicación sospechosa |
|----------|-----------------|------------------------|

### Paso 8.2 — Botón atrás y stack de navegación

- [ ] En cada pantalla encontrada, pulsar atrás (tanto botón UI como gesto sistema). Verificar que vuelve al origen esperado, sin saltar pantallas ni reiniciar stacks.
- [ ] Documentar cualquier anomalía.

### Paso 8.3 — Estados vacíos

- [ ] Navegar a: Tareas (hogar sin tareas), Historial (hogar sin eventos), Notificaciones (sin push recibidos), Miembros (si fuera posible, hogar con solo owner).
- [ ] Screenshot de cada empty state. Verificar que tiene texto traducible y un CTA si corresponde.
- [ ] Registrar caso 8.3.

### Paso 8.4 — Internacionalización en toda la app

- [ ] En ajustes, cambiar idioma a **en**. Recorrer Hoy, Historial, Miembros, Tareas, Ajustes, Hogar. Screenshot de cada.
- [ ] Anotar cualquier string que permanezca en español (hardcodeada).
- [ ] Repetir con **ro** (muestreo rápido).
- [ ] Volver a **es**.
- [ ] Registrar caso 8.4.

### Paso 8.5 — Botones duplicados y acciones redundantes

- [ ] Anotar si hay dos botones que llevan al mismo destino desde la misma pantalla (ej. dos "Invitar" en Miembros: FAB y botón dentro de la lista).
- [ ] Registrar caso 8.5.

### Paso 8.6 — Checkpoint

- [ ] Resumen.

---

## Task 9: Consolidación y limpieza

### Paso 9.1 — Priorizar bugs

- [ ] Revisar todas las entradas marcadas BUG. Clasificar por severidad (Crítico, Alto, Medio, Bajo) según:
    - **Crítico**: data loss, crash, bloqueo del flujo principal.
    - **Alto**: replicación rota, funcionalidad esencial no disponible.
    - **Medio**: UX degradada, strings hardcodeadas visibles, duplicados molestos.
    - **Bajo**: cosmético, typo, padding.
- [ ] Rellenar sección "Bugs encontrados" del reporte con cada bug en su bucket.

### Paso 9.2 — Sección de pruebas manuales pendientes

- [ ] Listar lo que no se pudo automatizar: IAP real, FCM con app cerrada si falló en emulador, etc.

### Paso 9.3 — Parar logs en background

- [ ] `kill <PID_móvil> <PID_emu>`.
- [ ] Guardar las últimas 100 líneas relevantes de cada log en el reporte si ayudan a documentar bugs.

### Paso 9.4 — Borrar capturas

- [ ] `rm -rf toka_qa_session/screenshots/*.png` (solo las generadas en esta sesión; si hay previas, filtrar por fecha).
- [ ] Verificar que la carpeta queda sin PNG nuevos.

### Paso 9.5 — Borrar script admin temporal

- [ ] `rm -rf scripts/qa/`.
- [ ] Verificar con `ls scripts/` que no queda rastro.

### Paso 9.6 — NO borrar datos de Firebase

- [ ] Confirmar que no se ejecuta ningún `deleteUser`, ni borrado de hogares o tareas.
- [ ] Añadir al reporte: "Datos Firebase conservados por instrucción del usuario."

### Paso 9.7 — Cerrar reporte

- [ ] Añadir al final del reporte:
    - `IMAGES_CLEANED_UP: true`
    - `TEMP_SCRIPTS_REMOVED: true`
    - `FIREBASE_DATA_PRESERVED: true`
    - Hora fin.

### Paso 9.8 — Commit final del reporte

- [ ] `git add toka_qa_session/QA_REPORT_2026-04-20.md`
- [ ] `git commit` con mensaje:

```
docs(qa): reporte sesion QA end-to-end 2026-04-20

Ejecucion de 8 bloques (registro, hogares, tareas, notificaciones,
premium, valoraciones, auditoria). N bugs encontrados y priorizados.
Capturas y script admin borrados; datos Firebase conservados.
```

### Paso 9.9 — Resumen final al usuario

- [ ] Mensaje resumen (≤100 palabras) con: bloques completos, bugs por severidad, lo más importante, y dónde está el reporte.

---

## Self-review notes

- Cobertura spec: los 8 bloques del spec están representados en Tasks 1-8. Setup en Task 0. Limpieza en Task 9.
- Placeholders: ninguno sin resolver; los IDs y UIDs se capturan en Paso 4.1 antes de usarse.
- Consistencia: `homeId`, `uid_A/B/C`, aliases de tarea (T1-T4) se mantienen entre tasks.
- Instrucción de usuario sobre limpieza (no borrar Firebase, solo script + capturas) reflejada en 9.4, 9.5 y 9.6.
