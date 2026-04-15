# Task Expiry — Diseño

**Fecha:** 2026-04-15
**Feature:** Auto-marcar tareas vencidas como "missed" y avanzar su recurrencia

---

## Objetivo

Cuando un día termina sin que la tarea haya sido completada, el sistema debe:
1. Registrar el incumplimiento como evento `"missed"` en el historial.
2. Aplicar penalización estadística al responsable (igual que "pasar turno").
3. Avanzar `nextDueAt` al siguiente periodo de la recurrencia.
4. Reasignar la tarea según el flag `onMissAssign` de la propia tarea.

---

## Arquitectura general

Un Cloud Function con trigger de horario (`processExpiredTasks`) se ejecuta a las **00:05 UTC** cada día. Consulta todas las tareas activas cuyo `nextDueAt` ya ha pasado, y por cada una ejecuta una transacción Firestore que registra el evento, actualiza la tarea y penaliza al miembro. El cliente Flutter no necesita ningún cambio de lógica de negocio — solo consume el nuevo tipo de evento `"missed"` en el historial y expone el nuevo campo `onMissAssign` en el formulario de tarea.

---

## Sección 1 — Cambios en el modelo de datos

### 1.1 Campo `onMissAssign` en `Task` y `TaskInput`

Nuevo campo en la colección `homes/{homeId}/tasks`:

| Campo | Tipo | Valores | Default |
|---|---|---|---|
| `onMissAssign` | string | `"sameAssignee"` \| `"nextInRotation"` | `"sameAssignee"` |

- `"sameAssignee"`: la tarea se queda con el mismo responsable, solo avanza la fecha.
- `"nextInRotation"`: se rota al siguiente miembro elegible (misma lógica que `passTaskTurn`).

En Dart, añadido a `Task` y `TaskInput` (ambos `@freezed`) con `@Default('sameAssignee')`.

### 1.2 Nuevo tipo de evento `MissedEvent`

Nueva variante en la sealed class `TaskEvent`:

```dart
const factory TaskEvent.missed({
  required String id,
  required String taskId,
  required String taskTitleSnapshot,
  required TaskVisual taskVisualSnapshot,
  required String actorUid,         // quién tenía la tarea (el que no la hizo)
  required String toUid,            // a quién se asigna después
  required bool penaltyApplied,     // siempre true
  required double? complianceBefore,
  required double? complianceAfter,
  required DateTime missedAt,       // == nextDueAt original
  required DateTime createdAt,
}) = MissedEvent;
```

Almacenado en `homes/{homeId}/taskEvents` con `eventType: "missed"`.

Reglas del tipo:
- `penaltyApplied` siempre es `true`.
- `toUid == actorUid` cuando `onMissAssign == "sameAssignee"`.
- `toUid != actorUid` cuando `onMissAssign == "nextInRotation"` (puede coincidir si no hay otro miembro elegible).
- Los eventos `missed` **no se pueden valorar** (`canRate` siempre `false`).

### 1.3 Nuevo contador en `members`

| Campo | Tipo | Descripción |
|---|---|---|
| `missedCount` | number | Nº de tareas vencidas sin completar. Inicializado a 0 si no existe. |

La fórmula de `complianceRate` pasa a ser:

```
complianceRate = completedCount / (completedCount + passedCount + missedCount)
```

### 1.4 Índice compuesto en `firestore.indexes.json`

Nuevo índice para la query del job:

```json
{
  "collectionGroup": "tasks",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    { "fieldPath": "status",    "order": "ASCENDING" },
    { "fieldPath": "nextDueAt", "order": "ASCENDING" }
  ]
}
```

---

## Sección 2 — Cloud Function `processExpiredTasks`

**Archivo:** `functions/src/jobs/process_expired_tasks.ts`

**Schedule:** `"5 0 * * *"` (00:05 UTC)

### Algoritmo

```
// El job corre a las 00:05 UTC. Usamos medianoche UTC de HOY como corte:
// cualquier tarea con nextDueAt < medianoche de hoy venció ayer o antes.
cutoff = new Date() con hora 00:00:00.000 UTC  (inicio del día actual en UTC)

query = collectionGroup("tasks")
          .where("status", "==", "active")
          .where("nextDueAt", "<", cutoff)
          .limit(100)

for each taskDoc in paginatedResults:
  homeId = extraído de la ruta del documento (homes/{homeId}/tasks/{taskId})
  
  transaction:
    1. leer tarea
    2. leer members del hogar
    3. calcular toUid:
       - si onMissAssign == "nextInRotation": getNextEligibleMember(...)
       - si onMissAssign == "sameAssignee": currentAssigneeUid
    4. calcular nextDueAt = addRecurrenceInterval(task.nextDueAt, task.recurrenceType)
    5. calcular complianceBefore / complianceAfter del actorUid
    6. escribir evento "missed" en taskEvents
    7. actualizar tarea: currentAssigneeUid = toUid, nextDueAt = nextNextDueAt
    8. actualizar miembro: missedCount++, complianceRate recalculado

por cada homeId afectado: updateHomeDashboard(homeId)
```

**Paginación:** si hay más de 100 tareas vencidas en una ejecución, el job procesa la primera página y registra un warning en el log. Las tareas restantes se procesarán en la próxima ejecución (00:05 del día siguiente). Este caso es extremadamente improbable en una app de hogar.

**Idempotencia:** dentro de la transacción, el job relee la tarea y verifica que `task.nextDueAt < cutoff` y `task.status == "active"`. Si el usuario completó la tarea entre la query y la transacción, `nextDueAt` ya habrá avanzado más allá del corte y la transacción termina sin escribir nada.

**Tareas sin `onMissAssign` (datos preexistentes):** el job usa `task.onMissAssign ?? "sameAssignee"` — las tareas creadas antes de esta feature se comportan como `"sameAssignee"` por defecto.

**Logging:** structured logging con `logger.info` por tarea procesada y `logger.warn` si se alcanza el límite de paginación.

---

## Sección 3 — Flutter: historial

### 3.1 `task_event.dart` + `.freezed.dart`

- Añadir variante `missed` a la sealed class.
- Actualizar `TaskEvent.fromMap()` para el caso `eventType == "missed"`.

### 3.2 `HistoryEventTile`

Nuevo caso `missed` en el `event.map(...)`:

```
icono: Icons.timer_off_outlined  (color: naranja/amber)
título: "{actorName} no completó"
subtítulo: "{emoji} {taskTitle}" + timestamp relativo
trailing: null (no valorable)
```

### 3.3 `HistoryFilterBar`

Nuevo chip `"Vencidas"` que filtra por `eventType: "missed"`.

### 3.4 `TaskEventItem`

- `computeCanRate`: devuelve `false` para `MissedEvent`.
- El switch exhaustivo en `HistoryViewModel` ya manejará el nuevo tipo.

### 3.5 Strings ARB (es / en / ro)

| Clave | Español | Inglés | Rumano |
|---|---|---|---|
| `history_event_missed` | `"{name} no completó"` | `"{name} didn't complete"` | `"{name} nu a finalizat"` |
| `history_filter_missed` | `"Vencidas"` | `"Missed"` | `"Expirate"` |
| `task_on_miss_label` | `"Si vence sin completar"` | `"If it expires incomplete"` | `"Dacă expiră neefectuată"` |
| `task_on_miss_same_assignee` | `"Mantener asignado"` | `"Keep assignee"` | `"Păstrează responsabilul"` |
| `task_on_miss_next_rotation` | `"Rotar al siguiente"` | `"Rotate to next"` | `"Rotație la următor"` |

---

## Sección 4 — Flutter: formulario de tarea

### 4.1 `CreateEditTaskScreen` (material + V2)

Nueva sección en el formulario, después del bloque de recurrencia:

```
┌─────────────────────────────────────────┐
│  Si vence sin completar                 │
│  [ Mantener asignado ] [ Rotar al sig ] │
└─────────────────────────────────────────┘
```

Implementado como `SegmentedButton<String>`:
- `selected`: `{vm.formState.onMissAssign}`
- `onSelectionChanged`: llama `vm.setOnMissAssign(value)`

Solo visible cuando hay más de un miembro en `assignmentOrder`. Si hay un único miembro, el campo no tiene sentido (siempre es el mismo) y se oculta.

### 4.2 `CreateEditTaskViewModel` (contrato abstracto)

Nuevos miembros en el contrato:
```dart
String get onMissAssign;
void setOnMissAssign(String value);
```

`TaskInput` incluirá `onMissAssign` al hacer submit.

---

## Sección 5 — Tests

| Capa | Archivo | Qué testea |
|---|---|---|
| Unit (TS) | `process_expired_tasks.test.ts` | lógica de expiración: sameAssignee, nextInRotation, idempotencia, complianceRate |
| Unit (Dart) | `task_event_test.dart` | `fromMap` deserializa `missed` correctamente |
| Unit (Dart) | `task_event_item_test.dart` | `canRate` false para MissedEvent |
| UI (Flutter) | `history_screen_v2_test.dart` | tile missed renderiza correctamente |
| UI (Flutter) | `create_edit_task_screen_test.dart` | toggle onMissAssign visible/oculto |

---

## Archivos a crear / modificar

| Acción | Ruta |
|---|---|
| Modify | `lib/features/tasks/domain/task.dart` |
| Modify | `lib/features/history/domain/task_event.dart` |
| Modify | `lib/l10n/app_es.arb` + `app_en.arb` + `app_ro.arb` |
| Modify | `lib/features/history/presentation/widgets/history_event_tile.dart` |
| Modify | `lib/features/history/presentation/widgets/history_filter_bar.dart` |
| Modify | `lib/features/history/application/history_view_model.dart` |
| Modify | `lib/features/tasks/presentation/create_edit_task_screen.dart` |
| Modify | `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` |
| Modify | `lib/features/tasks/application/create_edit_task_view_model.dart` |
| Create | `functions/src/jobs/process_expired_tasks.ts` |
| Modify | `functions/src/jobs/index.ts` |
| Modify | `functions/src/index.ts` |
| Modify | `firestore.indexes.json` |
| Create | `functions/src/jobs/process_expired_tasks.test.ts` |
| Create | `test/unit/features/history/task_event_test.dart` (ampliación) |

---

## Reglas de negocio

1. Solo se procesan tareas con `status == "active"`. Las tareas congeladas (`status == "frozen"`) se ignoran.
2. Si todos los miembros del hogar están frozen/absent y `onMissAssign == "nextInRotation"`, el responsable se mantiene igual (mismo comportamiento que `getNextEligibleMember` cuando no hay candidato).
3. La `missedAt` del evento es el valor original de `task.nextDueAt` (no el timestamp del job).
4. El job no envía notificación push — el historial de la app es el canal de comunicación.
5. El cálculo del nuevo `nextDueAt` usa `addRecurrenceInterval(task.nextDueAt, task.recurrenceType)` — misma función que usa `applyTaskCompletion`, por coherencia.
