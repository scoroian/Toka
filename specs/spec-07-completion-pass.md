# Spec-07: Completar tarea y pasar turno

**Dependencias previas:** Spec-00 → Spec-06  
**Oleada:** Oleada 1

---

## Objetivo

Implementar la acción de "marcar tarea como hecha" y "pasar turno", incluyendo el flujo de confirmación, actualización de estadísticas, recálculo de `nextDueAt`, rotación del responsable y actualización del dashboard.

---

## Reglas de negocio — Completar tarea

1. Solo el `currentAssigneeUid` puede marcar una tarea como hecha.
2. Requiere **confirmación** antes de registrar.
3. Al confirmar:
   - Se crea un evento `eventType: "completed"` en `taskEvents`.
   - Se recalcula `nextDueAt` usando `RecurrenceCalculator`.
   - Se selecciona el siguiente responsable en la rotación (circular básica o inteligente).
   - Se actualizan los contadores: `completedCount` del miembro, `completedCount90d` de la tarea.
   - Se recalcula `complianceRate` del miembro.
   - Se actualiza el dashboard.
4. No se muestra publicidad al confirmar (regla de AdMob).
5. La tarjeta pasa visualmente de "Por hacer" a "Hechas".

## Reglas de negocio — Pasar turno

1. Solo el `currentAssigneeUid` puede pasar turno.
2. Antes de confirmar, la app debe **informar del impacto estadístico** (caída estimada del compliance).
3. Al confirmar:
   - Se crea un evento `eventType: "passed"` en `taskEvents`.
   - Se busca el siguiente miembro elegible (no congelado, no ausente).
   - Se actualiza `currentAssigneeUid` de la tarea.
   - Se actualizan `passedCount` del miembro que pasa.
   - Se recalcula `complianceRate`.
   - Se notifica al nuevo responsable.
   - Se actualiza el dashboard.
4. Si no hay otro miembro elegible, el pase queda en el mismo miembro (con registro auditable).

---

## Archivos a crear / modificar

```
lib/features/tasks/
├── application/
│   ├── task_completion_provider.dart
│   └── task_pass_provider.dart
└── presentation/
    └── widgets/
        ├── complete_task_dialog.dart
        └── pass_turn_dialog.dart

functions/src/tasks/
├── apply_task_completion.ts     (Callable Function)
├── pass_task_turn.ts            (Callable Function)
└── update_dashboard.ts          (ya iniciada en spec-06, ampliar)
```

---

## Implementación

### Callable Function: applyTaskCompletion

```typescript
// functions/src/tasks/apply_task_completion.ts
export const applyTaskCompletion = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Not authenticated');
  
  const { homeId, taskId } = data;
  const uid = context.auth.uid;
  
  // Transacción atómica
  return admin.firestore().runTransaction(async (tx) => {
    // 1. Leer tarea y validar que uid === currentAssigneeUid
    const taskRef = db.collection('homes').doc(homeId).collection('tasks').doc(taskId);
    const taskSnap = await tx.get(taskRef);
    const task = taskSnap.data();
    
    if (!task) throw new HttpsError('not-found', 'Task not found');
    if (task.currentAssigneeUid !== uid) throw new HttpsError('permission-denied', 'Not your turn');
    if (task.status !== 'active') throw new HttpsError('failed-precondition', 'Task not active');
    
    // 2. Calcular siguiente responsable
    const nextAssigneeUid = getNextAssignee(task.assignmentOrder, uid);
    
    // 3. Calcular nuevo nextDueAt
    const nextDueAt = calculateNextDue(task.recurrenceRule);
    
    // 4. Crear evento completed
    const eventRef = db.collection('homes').doc(homeId).collection('taskEvents').doc();
    tx.set(eventRef, {
      eventType: 'completed',
      taskId,
      taskTitleSnapshot: task.title,
      taskVisualSnapshot: { kind: task.visualKind, value: task.visualValue },
      actorUid: uid,
      performerUid: uid,
      completedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      penaltyApplied: false,
    });
    
    // 5. Actualizar tarea
    tx.update(taskRef, {
      currentAssigneeUid: nextAssigneeUid,
      nextDueAt,
      completedCount90d: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    // 6. Actualizar contadores del miembro
    const memberRef = db.collection('homes').doc(homeId).collection('members').doc(uid);
    const memberSnap = await tx.get(memberRef);
    const member = memberSnap.data()!;
    const newCompleted = (member.completedCount || 0) + 1;
    const newPassed = member.passedCount || 0;
    const newCompliance = newCompleted / (newCompleted + newPassed);
    
    tx.update(memberRef, {
      completedCount: FieldValue.increment(1),
      completions60d: FieldValue.increment(1),
      complianceRate: newCompliance,
      lastCompletedAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
    });
    
    return { eventId: eventRef.id, nextAssigneeUid };
  });
  
  // Post-transacción: actualizar dashboard (sin bloquear respuesta)
  await updateHomeDashboard(homeId);
});
```

### Callable Function: passTaskTurn

```typescript
export const passTaskTurn = functions.https.onCall(async (data, context) => {
  const { homeId, taskId, reason } = data;
  const uid = context.auth?.uid;
  
  return admin.firestore().runTransaction(async (tx) => {
    // 1. Validar que uid === currentAssigneeUid
    // 2. Buscar siguiente miembro elegible (no frozen, no ausente)
    // 3. Si no hay nadie elegible → asignarse a sí mismo con nota
    // 4. Calcular compliance antes y después
    // 5. Crear evento passed
    // 6. Actualizar tarea.currentAssigneeUid
    // 7. Actualizar passedCount y complianceRate del miembro
    // 8. Retornar { toUid, complianceBefore, complianceAfter }
  });
  
  // Enviar notificación al nuevo responsable
  // Actualizar dashboard
});
```

### Diálogo de confirmación — Completar tarea

```dart
// complete_task_dialog.dart
class CompleteTaskDialog extends StatelessWidget {
  final Task task;
  final VoidCallback onConfirm;
  
  // Muestra:
  // - Icono/emoji de la tarea
  // - Nombre de la tarea
  // - "¿Confirmas que has completado esta tarea?"
  // - Botones: "Cancelar" | "Sí, hecha ✓"
}
```

### Diálogo de confirmación — Pasar turno

```dart
// pass_turn_dialog.dart
class PassTurnDialog extends StatelessWidget {
  final Task task;
  final double currentComplianceRate;      // ej: 0.87
  final double estimatedComplianceAfter;   // ej: 0.81
  final String? nextAssigneeName;
  final VoidCallback onConfirm;
  
  // Muestra:
  // - Advertencia: "Si pasas turno, tu cumplimiento bajará de 87% a ~81%"
  // - "El siguiente responsable será: [nombre]" (si se puede calcular)
  // - Campo opcional de motivo (texto libre)
  // - Botones: "Cancelar" | "Pasar turno"
}
```

### TaskCompletionProvider

```dart
@riverpod
class TaskCompletion extends _$TaskCompletion {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);
  
  Future<void> completeTask(String homeId, String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _functions.httpsCallable('applyTaskCompletion').call({
        'homeId': homeId,
        'taskId': taskId,
      });
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
```

### Rotación circular básica

```dart
// core/utils/assignment_calculator.dart
class AssignmentCalculator {
  static String? getNextAssignee(List<String> order, String currentUid, List<String> frozenUids) {
    if (order.isEmpty) return null;
    final eligible = order.where((uid) => !frozenUids.contains(uid)).toList();
    if (eligible.isEmpty) return currentUid; // Nadie más disponible
    final currentIndex = eligible.indexOf(currentUid);
    final nextIndex = (currentIndex + 1) % eligible.length;
    return eligible[nextIndex];
  }
}
```

---

## Tests requeridos

### Unitarios

**`test/unit/features/tasks/assignment_calculator_test.dart`**
- Lista de 3 miembros: después del 3º vuelve al 1º.
- Lista con miembro congelado: lo salta.
- Todos congelados excepto el actual: se asigna a sí mismo.
- Lista vacía: retorna null.
- Miembro no en la lista: retorna el primero.

**`test/unit/features/tasks/task_completion_provider_test.dart`** (mocktail)
- `completeTask` llama a la callable function con los parámetros correctos.
- Si la callable falla con "permission-denied" → estado de error correcto.
- Si la callable falla con "not-found" → estado de error correcto.

**`test/unit/features/tasks/pass_turn_dialog_test.dart`** (lógica)
- Cálculo de `estimatedComplianceAfter = (completed) / (completed + passed + 1)`.
- Si el compliance calculado es < 0 → se muestra como 0.

### De integración (emuladores)

**`test/integration/features/tasks/task_completion_test.dart`**
- Completar tarea → evento `completed` creado en `taskEvents`.
- `nextDueAt` de la tarea actualizado correctamente.
- `currentAssigneeUid` rotado al siguiente.
- `completedCount` del miembro incrementado.
- `complianceRate` recalculado.
- Dashboard actualizado.

**`test/integration/features/tasks/pass_turn_test.dart`**
- Pasar turno → evento `passed` creado.
- `currentAssigneeUid` cambia al siguiente elegible.
- `passedCount` del miembro incrementado.
- `complianceRate` reducido.
- Miembro congelado es saltado en la rotación.

### UI

**`test/ui/features/tasks/complete_task_dialog_test.dart`**
- Muestra nombre e icono de la tarea.
- Botón "Cancelar" cierra el diálogo.
- Botón "Sí, hecha" dispara `onConfirm`.
- Durante carga (state: loading) → botones deshabilitados + spinner.
- Golden test del diálogo.

**`test/ui/features/tasks/pass_turn_dialog_test.dart`**
- Muestra los dos valores de compliance (antes/después).
- Muestra el nombre del siguiente responsable.
- Campo de motivo es opcional.
- Botón "Pasar turno" dispara confirmación.
- Golden test del diálogo.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Completar tarea — flujo básico:**
   - En la pantalla Hoy, ser el responsable de una tarea.
   - Tocar "✓ Hecho" → aparece el diálogo de confirmación.
   - Confirmar → la tarjeta se mueve de "Por hacer" a "Hechas".
   - Verificar en Firestore: evento `completed` creado, `nextDueAt` actualizado, `currentAssigneeUid` cambiado.

2. **Rotación circular:**
   - Hogar con 3 miembros (A, B, C) en la rotación.
   - A completa → B es el nuevo responsable.
   - B completa → C es el nuevo responsable.
   - C completa → A es el nuevo responsable (ciclo completo).

3. **Pasar turno — flujo completo:**
   - Ser el responsable de una tarea.
   - Tocar "↷ Pasar" → aparece diálogo con el impacto en el compliance.
   - Verificar que el porcentaje mostrado es correcto (ej: baja de 90% a 83%).
   - Añadir motivo opcional "Me voy de viaje".
   - Confirmar → el nuevo responsable aparece en la tarjeta.
   - Verificar en Firestore: evento `passed` con `reason: "Me voy de viaje"`, `penaltyApplied: true`.

4. **Pasar turno sin candidatos elegibles:**
   - Hogar con un solo miembro activo.
   - Pasar turno → se asigna a sí mismo.
   - El diálogo debe indicar "No hay otro miembro disponible, seguirás siendo el responsable".

5. **Protección: no es tu turno:**
   - Acceder a la app como miembro B cuando la tarea está asignada a A.
   - Los botones de acción no deben aparecer en la tarjeta.
   - Si se intenta completar por API directa → debe ser rechazado por la Function.

6. **Actualización en tiempo real:**
   - Abrir la app en dos dispositivos (A y B) en el mismo hogar.
   - A completa una tarea → la pantalla de B debe actualizarse automáticamente.
