# Spec: Sesión QA exhaustiva end-to-end de Toka

**Fecha:** 2026-04-20
**Tipo:** QA operativa (no es una implementación de feature)
**Entorno:** Firebase producción (`toka-dd241`), sin emuladores locales
**Dispositivos:** `4f26486b` (móvil personal, Android 16) + `emulator-5554` (emulador Android 14)

## Objetivo

Validar end-to-end el estado actual de Toka desplegado en ambos dispositivos, cubriendo funcionalidad, replicación entre miembros del hogar, integridad visual, navegación y detección de duplicados. Generar un reporte escrito con evidencia por cada caso probado y una lista priorizada de bugs encontrados.

## No objetivos

- No se modifica código de la app ni de Functions durante la sesión.
- No se borran datos de Firebase al terminar (usuarios, hogares, tareas quedan).
- No se cubre QA de rendimiento ni carga; solo funcional y UX.
- No se prueban integraciones reales de compra (AdMob, IAP); Premium se fuerza por Firestore.

## Setup

1. Arrancar `flutter logs` en background para ambos dispositivos (dos procesos separados) para capturar stack traces.
2. Compilar y desplegar `main.dart` (producción) en ambos dispositivos con `flutter run`.
3. Crear script temporal `scripts/qa/qa-admin.mjs` con Firebase Admin SDK para: marcar Premium, forzar `premiumEndsAt`, crear tareas con `dueAt` pasado, invocar callable functions. Se borra al final.
4. Crear el documento `toka_qa_session/QA_REPORT_2026-04-20.md` con estructura predefinida.

### Estructura del reporte

```
# QA Report — 2026-04-20

## Setup
- Versión compilada (git SHA), dispositivos, hora de inicio.

## Cuentas y hogares creados
Tabla: email · password · dispositivo · rol · hogar · notas.

## Bloque N — <nombre>
### Caso N.M — <título corto>
- Dispositivo:
- Usuario:
- Acción:
- Resultado esperado:
- Resultado obtenido:
- Evidencia: ![](screenshots/...)
- Estado: OK / BUG / BLOQUEADO
- Bug detallado (si aplica): resumen + pasos + severidad

## Bugs encontrados (resumen por severidad)
Crítico / Alto / Medio / Bajo.

## Auditoría de navegación y duplicados
Mapa de pantallas alcanzables desde varios sitios, y duplicados detectados.

## Pruebas manuales pendientes
Lo que no se pudo automatizar (IAP real, push con app cerrada, etc.).

## Limpieza
Qué se borró y qué quedó.
```

## Bloques de prueba

Los bloques se ejecutan en orden porque cada uno depende del estado creado en el anterior.

### Bloque 1 — Registro + onboarding

Crear desde cero:
- **Usuario A** (móvil, `4f26486b`): email nuevo, flujo completo de registro, selección de idioma (probar cambio es→en→ro→es), nombre y avatar.
- **Usuario B** (emulador): igual, desde cero.

Validar: validaciones de formulario, errores de red, estado tras cerrar y reabrir la app en medio del onboarding, idioma persistido en `users/{uid}.locale`.

### Bloque 2 — Hogar: crear y unirse

- A crea hogar nuevo.
- A ve el código de invitación (screenshot).
- B se une introduciendo el código.
- Verificar que A ve a B en miembros en < 5 segundos (replicación).
- Probar casos de error: código inválido, código ya usado, intento de crear segundo hogar.

### Bloque 3 — Tareas: CRUD, estados y rotación

- A crea varias tareas con distintas recurrencias (única, diaria, semanal, mensual) y asignación (A, B, rotación).
- B ve las tareas replicadas.
- B completa una tarea propia, salta otra, pasa turno de una tercera.
- Verificar: confirmación antes de pasar turno muestra penalización, tarea completada aparece en "Hechas", rotación avanza al siguiente miembro.
- Editar y eliminar tareas desde A y B.

### Bloque 4 — Tareas vencidas y orden de "Hoy"

Vía `qa-admin.mjs`:
- Crear tareas con `dueAt` en pasado (1h, 1 día, 1 semana atrás).
- Crear tareas con `dueAt` por hora, día, semana, mes, año.

Verificar en la pantalla "Hoy":
- Orden estricto: Hora → Día → Semana → Mes → Año.
- Subgrupos Por hacer / Hechas correctos.
- Badge de vencida visible.
- Lectura única del documento `homes/{homeId}/views/dashboard` (confirmar en logs o no hay N+1).

### Bloque 5 — Notificaciones

- Desde ajustes, cambiar preferencias de notificación de A y B.
- Provocar: nueva tarea asignada, paso de turno recibido, tarea vencida.
- Verificar llegada FCM en ambos dispositivos (estado activo y en background).
- Documentar si algún canal falla.

### Bloque 6 — Premium (happy + bordes)

Vía `qa-admin.mjs`:
- Marcar hogar como Premium con `premiumEndsAt = hoy + 30 días`.
- Invitar tercer miembro C (crear cuenta nueva C).
- Verificar que C se une al hogar Premium (plaza extra activa).
- Forzar `premiumEndsAt = hoy + 2 días` → verificar UI de ventana de rescate.
- Revocar Premium → verificar downgrade automático: C pierde acceso pero los créditos permanentes se conservan.
- Intentar expulsar al pagador A mientras hay Premium vigente → debe fallar.

### Bloque 7 — Valoraciones e historial

- A valora una tarea completada por B con nota privada.
- B ve la nota en su vista.
- C (tercer miembro) NO debe ver la nota privada.
- Verificar que el historial refleja la valoración con timestamp correcto.

### Bloque 8 — Auditoría de navegación y duplicados

Recorrer la app sistemáticamente documentando:
- Pantallas alcanzables desde más de una ruta (ej. "Ajustes del hogar" desde Miembros y desde Ajustes).
- Botones o acciones duplicadas que hacen lo mismo.
- Botón atrás: verificar que cada pantalla vuelve al origen correcto.
- Internacionalización: cambiar idioma y buscar strings hardcodeadas que no traducen.
- Estados vacíos de todas las listas (tareas, miembros, historial, notificaciones).

## Evidencia

Por cada caso:
- Screenshot con `adb -s <deviceId> exec-out screencap -p > toka_qa_session/screenshots/YYYYMMDD_HHMMSS_b<bloque>_<caso>.png`.
- Si > 1900px, redimensionar antes de analizar (`magick convert ... -resize 1900x`).
- Referenciar en el reporte con ruta relativa.

## Checkpoints

Al terminar cada bloque, dar un resumen corto al usuario: "Bloque N completo, X casos OK, Y bugs (severidad Z)", para que pueda cortar o redirigir antes de seguir.

## Limpieza al terminar

- **Borrar** `scripts/qa/qa-admin.mjs` y cualquier archivo temporal auxiliar.
- **Borrar** todas las capturas de `toka_qa_session/screenshots/` creadas en la sesión.
- **NO borrar** usuarios, hogares, tareas ni valoraciones de Firebase (instrucción explícita del usuario).
- **Dejar** el reporte `QA_REPORT_2026-04-20.md` con marca `IMAGES_CLEANED_UP: true` al final.

## Criterios de "hecho"

- Los 8 bloques ejecutados o explícitamente bloqueados con motivo documentado.
- Reporte escrito con al menos un caso por bloque, evidencia y estado.
- Lista de bugs priorizada por severidad.
- Limpieza completa del script temporal y screenshots.
- Resumen final al usuario con lo más relevante.

## Riesgos y consideraciones

- **Producción real**: los usuarios que cree serán reales en `toka-dd241`. Los dejaré limpios pero documentados en el reporte.
- **Notificaciones FCM**: llegada depende de Google Play Services en el emulador; si falla, lo documento y no es bug de la app.
- **Tiempo de ejecución**: estimación varias horas. Los checkpoints al final de cada bloque permiten cortar.
- **Multi-dispositivo**: tomar screenshots en secuencia (primero A, luego B) para no perder el estado de replicación.
