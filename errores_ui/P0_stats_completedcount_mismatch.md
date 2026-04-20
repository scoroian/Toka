# P0 — Mismatch de campo stats: completedCount vs tasksCompleted

## Bug que corrige
- **Bug #26** — Las estadísticas del miembro siempre muestran 0 en el perfil. La Cloud Function `apply_task_completion.ts` escribe el campo `completedCount` en `members/{uid}`, pero el modelo Flutter `member_model.dart` lee `tasksCompleted`. Los nombres no coinciden, por lo que el valor nunca llega a la UI.

## Causa raíz confirmada

`functions/src/tasks/apply_task_completion.ts` línea ~114:
```typescript
memberRef.update({ completedCount: FieldValue.increment(1) });
```

`lib/features/members/domain/member.dart` (o `member_model.dart`) línea ~32:
```dart
tasksCompleted: json['tasksCompleted'] as int? ?? 0,
```

Los campos `currentStreak` y `averageScore` tampoco son actualizados por ninguna Cloud Function actualmente.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `functions/src/tasks/apply_task_completion.ts` | Renombrar `completedCount` → `tasksCompleted` |
| `lib/features/members/domain/member.dart` | Confirmar que lee `tasksCompleted` (ya correcto) |
| `functions/src/tasks/apply_task_completion.ts` | Añadir actualización de `currentStreak` |
| `functions/src/tasks/apply_task_completion.ts` | Añadir actualización de `averageScore` (si se pasan valoraciones) |

## Cambios requeridos

### 1. Renombrar campo en Cloud Function

En `functions/src/tasks/apply_task_completion.ts`, buscar y reemplazar:

```typescript
// ANTES
transaction.update(memberRef, {
  completedCount: FieldValue.increment(1),
});

// DESPUÉS
transaction.update(memberRef, {
  tasksCompleted: FieldValue.increment(1),
});
```

### 2. Implementar actualización de currentStreak

El streak debe incrementarse si el usuario ha completado al menos una tarea ayer (o en el último período). Añadir lógica:

```typescript
// Leer doc del miembro dentro de la transacción
const memberSnap = await transaction.get(memberRef);
const memberData = memberSnap.data() ?? {};

const lastCompletedAt: Timestamp | undefined = memberData.lastCompletedAt;
const today = new Date();
const isConsecutive = lastCompletedAt
  ? isYesterday(lastCompletedAt.toDate(), today)
  : false;

transaction.update(memberRef, {
  tasksCompleted: FieldValue.increment(1),
  currentStreak: isConsecutive
    ? FieldValue.increment(1)
    : 1, // reinicia si no es consecutivo
  lastCompletedAt: FieldValue.serverTimestamp(),
});
```

Añadir función helper `isYesterday(date1, date2)` en el módulo de utils.

### 3. Implementar actualización de averageScore

El `averageScore` debe actualizarse cuando se registra una valoración. Crear o modificar la CF que gestiona las valoraciones para actualizar el promedio en `members/{uid}`:

```typescript
// En la CF de valoración
const currentAvg = memberData.averageScore ?? 0;
const currentCount = memberData.ratingsCount ?? 0;
const newAvg = (currentAvg * currentCount + newScore) / (currentCount + 1);

transaction.update(memberRef, {
  averageScore: newAvg,
  ratingsCount: FieldValue.increment(1),
});
```

### 4. Migración de datos existentes

Los docs `members/{uid}` en producción tienen el campo `completedCount` con valores acumulados. Crear script de migración (una Cloud Function de admin o script de Node) para:

```typescript
// Script de migración
const members = await db.collectionGroup('members').get();
for (const doc of members.docs) {
  const data = doc.data();
  if (data.completedCount !== undefined && data.tasksCompleted === undefined) {
    await doc.ref.update({
      tasksCompleted: data.completedCount,
      completedCount: FieldValue.delete(),
    });
  }
}
```

> **IMPORTANTE**: Ejecutar migración ANTES de desplegar la nueva CF para evitar inconsistencias.

## Criterios de aceptación

- [ ] Tras completar una tarea, el campo `tasksCompleted` en `members/{uid}` se incrementa en Firestore.
- [ ] El perfil del miembro (propio y de otros) muestra el número correcto de tareas completadas.
- [ ] El `currentStreak` se incrementa si se completó alguna tarea el día anterior.
- [ ] El `currentStreak` se reinicia a 1 si se rompe la racha.
- [ ] El `averageScore` refleja el promedio de las valoraciones recibidas.
- [ ] No quedan documentos con `completedCount` en producción.

## Tests requeridos

- Test unitario: `apply_task_completion` con miembro sin historial → `tasksCompleted=1`, `currentStreak=1`.
- Test unitario: `apply_task_completion` con `lastCompletedAt` de ayer → `currentStreak` se incrementa.
- Test unitario: `apply_task_completion` con `lastCompletedAt` de hace 2 días → `currentStreak` vuelve a 1.
- Test de integración: completar tarea → leer `members/{uid}` → verificar `tasksCompleted > 0`.
