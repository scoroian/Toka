# P0 — Contadores del dashboard siempre en 0

## Bug que corrige
- **Bug #8** — La pantalla Hoy muestra "0 tareas para hoy" y "0 completadas hoy" aunque existan tareas activas y se hayan completado. El documento `homes/{homeId}/views/dashboard` de Firestore no se actualiza.

## Causa raíz (a confirmar)

La pantalla Hoy lee de `homes/{homeId}/views/dashboard` un único documento (según CLAUDE.md, regla de arquitectura Firestore). Ese documento debe ser actualizado por una Cloud Function cada vez que:
- Se completa una tarea (trigger en `taskEvents` o callable `applyTaskCompletion`).
- Se crea/modifica/elimina una tarea recurrente.
- Cambia el día (00:05 UTC job `processExpiredTasks`).

Posibles causas del fallo:
1. La CF `applyTaskCompletion` no escribe en `views/dashboard`.
2. El nombre del campo leído en Flutter no coincide con el escrito por la CF.
3. El documento `views/dashboard` no existe (nunca fue creado para el hogar).
4. Las reglas de Firestore bloquean la lectura/escritura de la sub-colección `views`.

## Archivos a investigar

| Archivo | Qué buscar |
|---------|-----------|
| `functions/src/tasks/apply_task_completion.ts` | ¿Escribe en `views/dashboard`? |
| `functions/src/jobs/` | ¿Hay un job diario que regenere `views/dashboard`? |
| `lib/features/tasks/application/today_view_model.dart` | ¿Qué campos lee del documento? |
| `lib/features/tasks/data/today_repository.dart` | ¿Qué path de Firestore usa? |
| `firestore.rules` | ¿Tiene permisos correctos para `views/{viewId}`? |

## Cambios requeridos

### 1. Cloud Function: actualizar `views/dashboard` al completar tarea

En `apply_task_completion.ts`, al final de la transacción, añadir escritura en el documento dashboard:

```typescript
const dashboardRef = db.doc(`homes/${homeId}/views/dashboard`);
transaction.set(dashboardRef, {
  tasksCompletedToday: FieldValue.increment(1),
  lastUpdated: FieldValue.serverTimestamp(),
}, { merge: true });
```

### 2. Cloud Function: job diario que recalcula `views/dashboard`

Crear o actualizar `functions/src/jobs/recalculate_dashboard.ts` para que a las 00:05 UTC:
- Cuente las tareas programadas para hoy en `homes/{homeId}/tasks`.
- Cuente los eventos completados hoy en `homes/{homeId}/taskEvents`.
- Escriba ambos valores en `homes/{homeId}/views/dashboard`.

### 3. Flutter: verificar los nombres de campo

En `today_view_model.dart` / `today_repository.dart`, asegurar que los campos leídos coinciden exactamente con los escritos por la CF:

```dart
// Ejemplo esperado en el modelo
final int tasksToday = dashboard['tasksToday'] ?? 0;
final int tasksCompletedToday = dashboard['tasksCompletedToday'] ?? 0;
```

### 4. Inicializar `views/dashboard` al crear el hogar

En `homes/index.ts`, al crear el hogar, inicializar el documento dashboard:

```typescript
await db.doc(`homes/${homeId}/views/dashboard`).set({
  tasksToday: 0,
  tasksCompletedToday: 0,
  lastUpdated: FieldValue.serverTimestamp(),
});
```

### 5. Reglas de Firestore

Asegurar que `views/{viewId}` es legible por miembros del hogar:

```
match /homes/{homeId}/views/{viewId} {
  allow read: if isMember(homeId);
  allow write: if false; // Solo Cloud Functions
}
```

## Criterios de aceptación

- [ ] Al cargar la pantalla Hoy con tareas existentes, el contador "X tareas para hoy" muestra el número correcto.
- [ ] Al completar una tarea, el contador "X completadas hoy" se incrementa en tiempo real (o tras un refresco).
- [ ] El documento `views/dashboard` existe en Firestore para el hogar QA.
- [ ] El documento se regenera correctamente a las 00:05 UTC.

## Tests requeridos

- Test unitario: `TodayViewModel` con mock de dashboard con datos → muestra contadores correctos.
- Test de integración: completar tarea via CF → leer `views/dashboard` → verificar que `tasksCompletedToday` se incrementó.
