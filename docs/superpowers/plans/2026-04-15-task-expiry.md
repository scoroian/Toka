# Task Expiry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Marcar automáticamente las tareas no completadas como "missed" al final del día, avanzar su recurrencia y aplicar penalización estadística al responsable.

**Architecture:** Un Cloud Function scheduled (`processExpiredTasks`, 00:05 UTC) procesa con una query de collection group todas las tareas activas vencidas. Por cada tarea ejecuta una transacción que registra un evento `"missed"`, actualiza `nextDueAt` y penaliza al miembro. El cliente Flutter añade `onMissAssign` al modelo de tarea, consume el nuevo tipo de evento en el historial y expone el toggle en el formulario.

**Tech Stack:** Flutter 3.x + Dart 3.x, Riverpod, freezed, Cloud Functions v2 (Node 20 TypeScript), Firestore

**Spec:** `docs/superpowers/specs/2026-04-15-task-expiry-design.md`

**Rama de trabajo:** `feature/task-expiry` (crear desde `main` antes de empezar)

---

## Mapa de ficheros

| Acción | Ruta |
|--------|------|
| Modify | `firestore.indexes.json` |
| Modify | `lib/l10n/app_es.arb` |
| Modify | `lib/l10n/app_en.arb` |
| Modify | `lib/l10n/app_ro.arb` |
| Modify | `lib/features/tasks/domain/task.dart` |
| Modify | `lib/features/tasks/data/task_model.dart` |
| Modify | `lib/features/tasks/application/task_form_provider.dart` |
| Modify | `lib/features/tasks/application/create_edit_task_view_model.dart` |
| Modify | `lib/features/history/domain/task_event.dart` |
| Modify | `lib/features/history/application/history_view_model.dart` |
| Modify | `lib/features/history/presentation/widgets/history_event_tile.dart` |
| Modify | `lib/features/history/presentation/widgets/history_filter_bar.dart` |
| Modify | `lib/features/tasks/presentation/create_edit_task_screen.dart` |
| Modify | `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` |
| Create | `functions/src/jobs/process_expired_tasks.ts` |
| Modify | `functions/src/jobs/index.ts` |
| Modify | `functions/src/jobs/jobs.test.ts` |

---

## Task 1: Índice Firestore + strings ARB

**Files:**
- Modify: `firestore.indexes.json`
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ro.arb`

- [ ] **Step 1: Añadir índice COLLECTION_GROUP en firestore.indexes.json**

En `firestore.indexes.json`, añadir este objeto al array `"indexes"` (después del último índice de `tasks`):

```json
    {
      "collectionGroup": "tasks",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "status",    "order": "ASCENDING" },
        { "fieldPath": "nextDueAt", "order": "ASCENDING" }
      ]
    },
```

- [ ] **Step 2: Añadir strings en app_es.arb**

Añadir antes de la última llave `}` del archivo:

```json
  "history_event_missed": "{name} no completó",
  "@history_event_missed": {
    "placeholders": { "name": { "type": "String" } }
  },
  "history_filter_missed": "Vencidas",
  "@history_filter_missed": {},
  "task_on_miss_label": "Si vence sin completar",
  "@task_on_miss_label": {},
  "task_on_miss_same_assignee": "Mantener asignado",
  "@task_on_miss_same_assignee": {},
  "task_on_miss_next_rotation": "Rotar al siguiente",
  "@task_on_miss_next_rotation": {}
```

- [ ] **Step 3: Añadir strings en app_en.arb**

```json
  "history_event_missed": "{name} didn't complete",
  "@history_event_missed": {
    "placeholders": { "name": { "type": "String" } }
  },
  "history_filter_missed": "Missed",
  "@history_filter_missed": {},
  "task_on_miss_label": "If it expires incomplete",
  "@task_on_miss_label": {},
  "task_on_miss_same_assignee": "Keep assignee",
  "@task_on_miss_same_assignee": {},
  "task_on_miss_next_rotation": "Rotate to next",
  "@task_on_miss_next_rotation": {}
```

- [ ] **Step 4: Añadir strings en app_ro.arb**

```json
  "history_event_missed": "{name} nu a finalizat",
  "@history_event_missed": {
    "placeholders": { "name": { "type": "String" } }
  },
  "history_filter_missed": "Expirate",
  "@history_filter_missed": {},
  "task_on_miss_label": "Dacă expiră neefectuată",
  "@task_on_miss_label": {},
  "task_on_miss_same_assignee": "Păstrează responsabilul",
  "@task_on_miss_same_assignee": {},
  "task_on_miss_next_rotation": "Rotație la următor",
  "@task_on_miss_next_rotation": {}
```

- [ ] **Step 5: Verificar que los ARB generan código**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Esperado: genera `lib/l10n/app_localizations_es.dart` etc. sin errores.

- [ ] **Step 6: Commit**

```bash
git add firestore.indexes.json lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ro.arb
git commit -m "feat(expiry): índice Firestore collection group + strings ARB"
```

---

## Task 2: Campo onMissAssign en modelo de tarea

**Files:**
- Modify: `lib/features/tasks/domain/task.dart`
- Modify: `lib/features/tasks/data/task_model.dart`
- Modify: `lib/features/tasks/application/task_form_provider.dart`

- [ ] **Step 1: Añadir onMissAssign a Task y TaskInput en task.dart**

En `lib/features/tasks/domain/task.dart`, el modelo `Task` y `TaskInput` son clases `@freezed`. Añadir el campo `onMissAssign` con default `'sameAssignee'` en ambas:

```dart
// En Task (dentro del const factory Task):
    @Default('sameAssignee') String onMissAssign,

// En TaskInput (dentro del const factory TaskInput):
    @Default('sameAssignee') String onMissAssign,
```

El archivo completo resultante de `task.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'recurrence_rule.dart';
import 'task_status.dart';

part 'task.freezed.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String homeId,
    required String title,
    String? description,
    required String visualKind,
    required String visualValue,
    required TaskStatus status,
    required RecurrenceRule recurrenceRule,
    required String assignmentMode,
    required List<String> assignmentOrder,
    String? currentAssigneeUid,
    required DateTime nextDueAt,
    required double difficultyWeight,
    required int completedCount90d,
    required String createdByUid,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default('sameAssignee') String onMissAssign,
  }) = _Task;
}

@freezed
class TaskInput with _$TaskInput {
  const factory TaskInput({
    required String title,
    String? description,
    required String visualKind,
    required String visualValue,
    required RecurrenceRule recurrenceRule,
    required String assignmentMode,
    required List<String> assignmentOrder,
    @Default(1.0) double difficultyWeight,
    @Default('sameAssignee') String onMissAssign,
  }) = _TaskInput;
}
```

- [ ] **Step 2: Regenerar freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Esperado: regenera `task.freezed.dart` sin errores.

- [ ] **Step 3: Actualizar TaskModel en task_model.dart**

En `lib/features/tasks/data/task_model.dart`:

**3a. En `fromFirestore`**, añadir lectura del campo (al final del constructor de `Task`, después de `updatedAt:`):
```dart
      onMissAssign: d['onMissAssign'] as String? ?? 'sameAssignee',
```

**3b. En `toFirestore`**, añadir escritura del campo (al final del mapa, después de `'updatedAt': ...`):
```dart
      'onMissAssign': input.onMissAssign,
```

**3c. En `toUpdateMap`**, añadir también (al final del mapa, después de `'difficultyWeight': ...`):
```dart
      'onMissAssign': input.onMissAssign,
```

- [ ] **Step 4: Añadir onMissAssign a TaskFormState en task_form_provider.dart**

En `lib/features/tasks/application/task_form_provider.dart`:

**4a. En `TaskFormState`**, añadir campo con default:
```dart
    @Default('sameAssignee') String onMissAssign,
```

**4b. En `initEdit`**, añadir la línea en `TaskFormState(...)`:
```dart
      onMissAssign: task.onMissAssign,
```

**4c. En `save`**, actualizar la construcción de `TaskInput` para incluir el campo:
```dart
    final input = TaskInput(
      title: state.title,
      description: state.description.isEmpty ? null : state.description,
      visualKind: state.visualKind,
      visualValue: state.visualValue,
      recurrenceRule: state.recurrenceRule!,
      assignmentMode: state.assignmentMode,
      assignmentOrder: state.assignmentOrder,
      difficultyWeight: state.difficultyWeight,
      onMissAssign: state.onMissAssign,
    );
```

**4d. Añadir método `setOnMissAssign`** al final de `TaskFormNotifier`:
```dart
  void setOnMissAssign(String value) =>
      state = state.copyWith(onMissAssign: value);
```

- [ ] **Step 5: Regenerar freezed y riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Verificar que compila**

```bash
flutter analyze lib/features/tasks/
```

Esperado: 0 errores.

- [ ] **Step 7: Commit**

```bash
git add lib/features/tasks/domain/task.dart lib/features/tasks/data/task_model.dart lib/features/tasks/application/task_form_provider.dart
git commit -m "feat(expiry): campo onMissAssign en Task, TaskInput y TaskFormState"
```

---

## Task 3: Campo onMissAssign en CreateEditTaskViewModel + UI

**Files:**
- Modify: `lib/features/tasks/application/create_edit_task_view_model.dart`
- Modify: `lib/features/tasks/presentation/create_edit_task_screen.dart`
- Modify: `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart`

- [ ] **Step 1: Añadir getter y setter al contrato abstracto CreateEditTaskViewModel**

En `lib/features/tasks/application/create_edit_task_view_model.dart`, añadir en la sección `// Existing actions` del `abstract class CreateEditTaskViewModel`:

```dart
  // Expiry behaviour
  String get onMissAssign;
  void   setOnMissAssign(String value);
```

- [ ] **Step 2: Implementar getter y setter en CreateEditTaskViewModelNotifier**

Añadir los métodos de implementación en la clase `CreateEditTaskViewModelNotifier` (después de `setApplyToday`):

```dart
  @override
  String get onMissAssign =>
      ref.read(taskFormNotifierProvider).onMissAssign;

  @override
  void setOnMissAssign(String value) =>
      ref.read(taskFormNotifierProvider.notifier).setOnMissAssign(value);
```

- [ ] **Step 3: Regenerar código Riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Añadir widget _OnMissAssignSelector a create_edit_task_screen.dart (material)**

Primero leer `lib/features/tasks/presentation/create_edit_task_screen.dart` para identificar dónde acaban los campos de formulario (cerca de donde está la sección de asignación o dificultad). Añadir la llamada al widget después de la sección de dificultad y antes del botón Guardar.

El widget a añadir **al final del archivo** (después de las otras clases privadas):

```dart
class _OnMissAssignSelector extends StatelessWidget {
  const _OnMissAssignSelector({required this.vm});
  final CreateEditTaskViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Solo visible con más de 1 miembro en la rotación
    if (vm.orderedMembers.where((m) => m.isAssigned).length <= 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.task_on_miss_label,
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            key: const Key('on_miss_assign_selector'),
            segments: [
              ButtonSegment(
                value: 'sameAssignee',
                label: Text(l10n.task_on_miss_same_assignee),
                icon: const Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: 'nextInRotation',
                label: Text(l10n.task_on_miss_next_rotation),
                icon: const Icon(Icons.swap_horiz),
              ),
            ],
            selected: {vm.onMissAssign},
            onSelectionChanged: (set) => vm.setOnMissAssign(set.first),
          ),
        ],
      ),
    );
  }
}
```

En el cuerpo del formulario de `create_edit_task_screen.dart`, añadir la llamada al widget en el lugar apropiado dentro del `ListView` o `Column` del formulario, justo antes del botón de guardar:

```dart
_OnMissAssignSelector(vm: vm),
```

- [ ] **Step 5: Añadir _OnMissAssignSelector a create_edit_task_screen_v2.dart**

En `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart`, añadir el mismo widget al final del archivo e invocarlo en el formulario, igual que en el step anterior. El widget es idéntico — cópialo completo, no referenciar la versión material.

```dart
class _OnMissAssignSelectorV2 extends StatelessWidget {
  const _OnMissAssignSelectorV2({required this.vm});
  final CreateEditTaskViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (vm.orderedMembers.where((m) => m.isAssigned).length <= 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.task_on_miss_label,
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            key: const Key('on_miss_assign_selector'),
            segments: [
              ButtonSegment(
                value: 'sameAssignee',
                label: Text(l10n.task_on_miss_same_assignee),
                icon: const Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: 'nextInRotation',
                label: Text(l10n.task_on_miss_next_rotation),
                icon: const Icon(Icons.swap_horiz),
              ),
            ],
            selected: {vm.onMissAssign},
            onSelectionChanged: (set) => vm.setOnMissAssign(set.first),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Verificar**

```bash
flutter analyze lib/features/tasks/
```

Esperado: 0 errores.

- [ ] **Step 7: Commit**

```bash
git add lib/features/tasks/application/create_edit_task_view_model.dart lib/features/tasks/presentation/create_edit_task_screen.dart lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart
git commit -m "feat(expiry): selector onMissAssign en formulario de tarea"
```

---

## Task 4: MissedEvent en task_event.dart

**Files:**
- Modify: `lib/features/history/domain/task_event.dart`
- Modify: `lib/features/history/application/history_view_model.dart`

- [ ] **Step 1: Escribir el test que falla**

Crear `test/unit/features/history/task_event_missed_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/history/domain/task_event.dart';

void main() {
  group('TaskEvent.fromMap — missed', () {
    test('deserializa un evento missed correctamente', () {
      const taskId = 'task-1';
      final now = DateTime(2026, 4, 15, 10, 0, 0);
      final data = <String, dynamic>{
        'eventType': 'missed',
        'taskId': taskId,
        'taskTitleSnapshot': 'Barrer',
        'taskVisualSnapshot': {'kind': 'emoji', 'value': '🧹'},
        'actorUid': 'uid-a',
        'toUid': 'uid-b',
        'penaltyApplied': true,
        'complianceBefore': 0.8,
        'complianceAfter': 0.75,
        'missedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      final event = TaskEvent.fromMap('event-1', data);

      expect(event, isA<MissedEvent>());
      final missed = event as MissedEvent;
      expect(missed.id, 'event-1');
      expect(missed.taskId, taskId);
      expect(missed.actorUid, 'uid-a');
      expect(missed.toUid, 'uid-b');
      expect(missed.penaltyApplied, isTrue);
      expect(missed.complianceBefore, 0.8);
      expect(missed.complianceAfter, 0.75);
    });

    test('campos onMissAssign ausentes usan defaults seguros', () {
      final now = DateTime(2026, 4, 15, 10, 0, 0);
      final data = <String, dynamic>{
        'eventType': 'missed',
        'taskId': 'task-2',
        'taskTitleSnapshot': 'Fregar',
        'taskVisualSnapshot': {'kind': 'emoji', 'value': '🍽'},
        'actorUid': 'uid-a',
        'toUid': 'uid-a',
        'penaltyApplied': true,
        'complianceBefore': null,
        'complianceAfter': null,
        'missedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      final event = TaskEvent.fromMap('event-2', data);
      expect(event, isA<MissedEvent>());
      final missed = event as MissedEvent;
      expect(missed.complianceBefore, isNull);
      expect(missed.complianceAfter, isNull);
    });
  });
}
```

- [ ] **Step 2: Ejecutar test — debe fallar**

```bash
flutter test test/unit/features/history/task_event_missed_test.dart -v
```

Esperado: FAIL con "type 'Null' is not a subtype" o error de compilación por `MissedEvent` inexistente.

- [ ] **Step 3: Añadir MissedEvent a task_event.dart**

En `lib/features/history/domain/task_event.dart`, la sealed class `TaskEvent` tiene actualmente `completed` y `passed`. Añadir la variante `missed`:

```dart
  const factory TaskEvent.missed({
    required String id,
    required String taskId,
    required String taskTitleSnapshot,
    required TaskVisual taskVisualSnapshot,
    required String actorUid,
    required String toUid,
    required bool penaltyApplied,
    double? complianceBefore,
    double? complianceAfter,
    required DateTime missedAt,
    required DateTime createdAt,
  }) = MissedEvent;
```

También actualizar `TaskEvent.fromMap` añadiendo el caso `'missed'` antes del default `completed`:

```dart
    if (eventType == 'missed') {
      return TaskEvent.missed(
        id: id,
        taskId: data['taskId'] as String? ?? '',
        taskTitleSnapshot: data['taskTitleSnapshot'] as String? ?? '',
        taskVisualSnapshot: visual,
        actorUid: data['actorUid'] as String? ?? '',
        toUid: data['toUid'] as String? ?? '',
        penaltyApplied: data['penaltyApplied'] as bool? ?? true,
        complianceBefore: (data['complianceBefore'] as num?)?.toDouble(),
        complianceAfter: (data['complianceAfter'] as num?)?.toDouble(),
        missedAt: (data['missedAt'] as Timestamp?)?.toDate() ?? createdAt,
        createdAt: createdAt,
      );
    }
```

- [ ] **Step 4: Regenerar freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Ejecutar test — debe pasar**

```bash
flutter test test/unit/features/history/task_event_missed_test.dart -v
```

Esperado: `+2: All tests passed!`

- [ ] **Step 6: Actualizar history_view_model.dart para el nuevo tipo**

En `lib/features/history/application/history_view_model.dart`, hay un switch que extrae `actorUid`:

```dart
        final actorUid = switch (e) {
          CompletedEvent c => c.actorUid,
          PassedEvent p    => p.actorUid,
        };
```

Añadir el caso `MissedEvent`:

```dart
        final actorUid = switch (e) {
          CompletedEvent c => c.actorUid,
          PassedEvent p    => p.actorUid,
          MissedEvent m    => m.actorUid,
        };
```

También actualizar `TaskEventItem.computeCanRate` para que `MissedEvent` devuelva siempre `false`:

```dart
  static bool computeCanRate({
    required TaskEvent raw,
    required bool isOwnEvent,
    required bool isRated,
  }) =>
      raw is CompletedEvent && !isOwnEvent && !isRated;
```

Este método ya devuelve `false` para cualquier cosa que no sea `CompletedEvent`, así que **no necesita cambio** — verificar que sigue siendo correcto.

- [ ] **Step 7: Verificar**

```bash
flutter analyze lib/features/history/
```

Esperado: 0 errores.

- [ ] **Step 8: Commit**

```bash
git add lib/features/history/domain/task_event.dart lib/features/history/application/history_view_model.dart test/unit/features/history/task_event_missed_test.dart
git commit -m "feat(expiry): MissedEvent en TaskEvent + historia view model"
```

---

## Task 5: UI historial — tile y filtro

**Files:**
- Modify: `lib/features/history/presentation/widgets/history_event_tile.dart`
- Modify: `lib/features/history/presentation/widgets/history_filter_bar.dart`

- [ ] **Step 1: Añadir _MissedTile a history_event_tile.dart**

En `lib/features/history/presentation/widgets/history_event_tile.dart`, el método `build` del `HistoryEventTile` tiene actualmente:

```dart
    return event.map(
      completed: (e) => _CompletedTile(...),
      passed: (e) => _PassedTile(...),
    );
```

Añadir el caso `missed`:

```dart
    return event.map(
      completed: (e) => _CompletedTile(...),
      passed: (e) => _PassedTile(...),
      missed: (e) => _MissedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        timestamp: _formatRelativeTime(l10n, e.createdAt),
        l10n: l10n,
      ),
    );
```

Añadir la clase `_MissedTile` al final del archivo (después de `_PassedTile`):

```dart
class _MissedTile extends StatelessWidget {
  const _MissedTile({
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.timestamp,
    required this.l10n,
  });
  final MissedEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String timestamp;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '${visual.value} ${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    return ListTile(
      key: Key('history_tile_${event.id}'),
      leading: _Avatar(photoUrl: actorPhotoUrl, name: actorName),
      title: Text(l10n.history_event_missed(actorName)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(taskLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: const Icon(Icons.timer_off_outlined, color: Colors.orange),
      isThreeLine: true,
    );
  }
}
```

- [ ] **Step 2: Añadir chip "Vencidas" a history_filter_bar.dart**

En `lib/features/history/presentation/widgets/history_filter_bar.dart`, añadir un cuarto `FilterChip` después del chip `filter_chip_passed`:

```dart
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filter_chip_missed'),
            label: Text(l10n.history_filter_missed),
            selected: current.eventType == 'missed',
            onSelected: (_) => onChanged(
              HistoryFilter(
                memberUid: current.memberUid,
                taskId: current.taskId,
                eventType: 'missed',
              ),
            ),
          ),
```

- [ ] **Step 3: Verificar**

```bash
flutter analyze lib/features/history/presentation/
```

Esperado: 0 errores.

- [ ] **Step 4: Commit**

```bash
git add lib/features/history/presentation/widgets/history_event_tile.dart lib/features/history/presentation/widgets/history_filter_bar.dart
git commit -m "feat(expiry): tile MissedEvent y chip Vencidas en historial"
```

---

## Task 6: Cloud Function processExpiredTasks

**Files:**
- Create: `functions/src/jobs/process_expired_tasks.ts`
- Modify: `functions/src/jobs/index.ts`
- Modify: `functions/src/jobs/jobs.test.ts`

- [ ] **Step 1: Escribir los tests de lógica pura**

En `functions/src/jobs/jobs.test.ts`, añadir al final del archivo:

```typescript
// ── processExpiredTasks — lógica pura ────────────────────────────────────────

function computeNextAssignee(
  onMissAssign: string,
  currentUid: string,
  assignmentOrder: string[],
  frozenUids: string[]
): string {
  if (onMissAssign === "nextInRotation") {
    const eligible = assignmentOrder.filter((u) => !frozenUids.includes(u));
    if (!eligible.length) return currentUid;
    const idx = eligible.indexOf(currentUid);
    return eligible[(idx + 1) % eligible.length];
  }
  return currentUid; // sameAssignee
}

function computeComplianceAfterMiss(
  completedCount: number,
  passedCount: number,
  missedCount: number
): number {
  const total = completedCount + passedCount + missedCount + 1;
  return completedCount / total;
}

function isExpired(nextDueAtMs: number, cutoffMs: number): boolean {
  return nextDueAtMs < cutoffMs;
}

describe("processExpiredTasks — lógica pura", () => {
  describe("computeNextAssignee", () => {
    it("sameAssignee → devuelve el mismo uid", () => {
      expect(computeNextAssignee("sameAssignee", "u1", ["u1", "u2"], [])).toBe("u1");
    });

    it("nextInRotation → avanza al siguiente", () => {
      expect(computeNextAssignee("nextInRotation", "u1", ["u1", "u2", "u3"], [])).toBe("u2");
    });

    it("nextInRotation → omite frozen", () => {
      expect(computeNextAssignee("nextInRotation", "u1", ["u1", "u2", "u3"], ["u2"])).toBe("u3");
    });

    it("nextInRotation → rota al principio cuando es el último", () => {
      expect(computeNextAssignee("nextInRotation", "u3", ["u1", "u2", "u3"], [])).toBe("u1");
    });

    it("nextInRotation sin candidatos elegibles → mismo uid", () => {
      expect(computeNextAssignee("nextInRotation", "u1", ["u1", "u2"], ["u2"])).toBe("u1");
    });

    it("onMissAssign ausente (undefined) → sameAssignee por defecto", () => {
      expect(computeNextAssignee(undefined as unknown as string ?? "sameAssignee", "u1", ["u1", "u2"], [])).toBe("u1");
    });
  });

  describe("computeComplianceAfterMiss", () => {
    it("miembro con 5 completas, 1 passed, 0 missed → compliance correcta tras miss", () => {
      // Antes: 5 / (5+1+0) = 0.833
      // Después del miss: 5 / (5+1+0+1) = 5/7 ≈ 0.714
      expect(computeComplianceAfterMiss(5, 1, 0)).toBeCloseTo(5 / 7, 5);
    });

    it("miembro nuevo (0, 0, 0) → compliance 0 tras primera miss", () => {
      expect(computeComplianceAfterMiss(0, 0, 0)).toBe(0);
    });
  });

  describe("isExpired", () => {
    it("nextDueAt antes del corte → vencida", () => {
      const cutoff = new Date("2026-04-15T00:00:00.000Z").getTime();
      const yesterday = new Date("2026-04-14T10:00:00.000Z").getTime();
      expect(isExpired(yesterday, cutoff)).toBe(true);
    });

    it("nextDueAt igual al corte → NO vencida (< no <=)", () => {
      const cutoff = new Date("2026-04-15T00:00:00.000Z").getTime();
      expect(isExpired(cutoff, cutoff)).toBe(false);
    });

    it("nextDueAt posterior al corte → no vencida", () => {
      const cutoff = new Date("2026-04-15T00:00:00.000Z").getTime();
      const today = new Date("2026-04-15T10:00:00.000Z").getTime();
      expect(isExpired(today, cutoff)).toBe(false);
    });
  });
});
```

- [ ] **Step 2: Ejecutar tests — deben fallar**

```bash
cd functions && npm test -- --testPathPattern="jobs.test" 2>&1 | tail -30
```

Esperado: FAIL — las funciones `computeNextAssignee`, `computeComplianceAfterMiss`, `isExpired` no existen.

- [ ] **Step 3: Crear process_expired_tasks.ts**

Crear `functions/src/jobs/process_expired_tasks.ts`:

```typescript
// functions/src/jobs/process_expired_tasks.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { addRecurrenceInterval } from "../tasks/task_assignment_helpers";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ── Lógica pura (exportada para tests) ───────────────────────────────────────

export function computeNextAssignee(
  onMissAssign: string,
  currentUid: string,
  assignmentOrder: string[],
  frozenUids: string[]
): string {
  if ((onMissAssign ?? "sameAssignee") === "nextInRotation") {
    const eligible = assignmentOrder.filter((u) => !frozenUids.includes(u));
    if (!eligible.length) return currentUid;
    const idx = eligible.indexOf(currentUid);
    return eligible[(idx + 1) % eligible.length];
  }
  return currentUid;
}

export function computeComplianceAfterMiss(
  completedCount: number,
  passedCount: number,
  missedCount: number
): number {
  const total = completedCount + passedCount + missedCount + 1;
  if (total === 0) return 0;
  return completedCount / total;
}

export function isExpired(nextDueAtMs: number, cutoffMs: number): boolean {
  return nextDueAtMs < cutoffMs;
}

// ── Job programado ────────────────────────────────────────────────────────────

/**
 * Cron diario a las 00:05 UTC.
 * Marca como "missed" todas las tareas activas con nextDueAt < medianoche UTC de hoy.
 */
export const processExpiredTasks = onSchedule("5 0 * * *", async () => {
  // Corte: medianoche UTC del día actual
  const cutoff = new Date();
  cutoff.setUTCHours(0, 0, 0, 0);

  logger.info(`processExpiredTasks: cutoff = ${cutoff.toISOString()}`);

  const snapshot = await db
    .collectionGroup("tasks")
    .where("status", "==", "active")
    .where("nextDueAt", "<", admin.firestore.Timestamp.fromDate(cutoff))
    .limit(100)
    .get();

  if (snapshot.empty) {
    logger.info("processExpiredTasks: no expired tasks found");
    return;
  }

  if (snapshot.size >= 100) {
    logger.warn(
      "processExpiredTasks: reached 100-task limit; remaining tasks will be processed tomorrow"
    );
  }

  logger.info(`processExpiredTasks: processing ${snapshot.size} tasks`);

  const affectedHomeIds = new Set<string>();

  for (const taskDoc of snapshot.docs) {
    // homeId se obtiene del path: homes/{homeId}/tasks/{taskId}
    const pathParts = taskDoc.ref.path.split("/");
    const homeId = pathParts[1];
    const taskId = taskDoc.id;

    try {
      await db.runTransaction(async (tx) => {
        const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
        const taskSnap = await tx.get(taskRef);
        if (!taskSnap.exists) return;

        const task = taskSnap.data()!;

        // Verificación de idempotencia dentro de la transacción
        const taskNextDue: admin.firestore.Timestamp | undefined = task["nextDueAt"];
        if (!taskNextDue || taskNextDue.toMillis() >= cutoff.getTime()) return;
        if (task["status"] !== "active") return;

        const actorUid: string = task["currentAssigneeUid"] ?? "";
        const assignmentOrder: string[] = task["assignmentOrder"] ?? [actorUid];
        const onMissAssign: string = task["onMissAssign"] ?? "sameAssignee";

        // Leer miembros para frozen/absent
        const membersSnap = await tx.get(
          db.collection("homes").doc(homeId).collection("members")
        );
        const frozenUids: string[] = [];
        for (const mDoc of membersSnap.docs) {
          const s = mDoc.data()["status"] as string | undefined;
          if (s === "frozen" || s === "absent") frozenUids.push(mDoc.id);
        }

        const toUid = computeNextAssignee(onMissAssign, actorUid, assignmentOrder, frozenUids);
        const nextDueAt = addRecurrenceInterval(
          taskNextDue.toDate(),
          (task["recurrenceType"] as string | undefined) ?? "daily"
        );

        // Stats del miembro que incumplió
        const memberRef = db.collection("homes").doc(homeId).collection("members").doc(actorUid);
        const memberDocInSnap = membersSnap.docs.find((d) => d.id === actorUid);
        const member = memberDocInSnap?.data() ?? {};
        const completed: number = (member["completedCount"] as number) ?? 0;
        const passed: number    = (member["passedCount"]   as number) ?? 0;
        const missed: number    = (member["missedCount"]   as number) ?? 0;
        const complianceBefore  = completed / Math.max(completed + passed + missed, 1);
        const complianceAfter   = computeComplianceAfterMiss(completed, passed, missed);

        // Evento missed
        const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
        tx.set(eventRef, {
          eventType: "missed",
          taskId,
          taskTitleSnapshot: task["title"] ?? "",
          taskVisualSnapshot: {
            kind: task["visualKind"] ?? "emoji",
            value: task["visualValue"] ?? "",
          },
          actorUid,
          toUid,
          penaltyApplied: true,
          complianceBefore,
          complianceAfter,
          missedAt: taskNextDue,
          createdAt: FieldValue.serverTimestamp(),
        });

        // Actualizar tarea
        tx.update(taskRef, {
          currentAssigneeUid: toUid,
          nextDueAt: admin.firestore.Timestamp.fromDate(nextDueAt),
          updatedAt: FieldValue.serverTimestamp(),
        });

        // Actualizar miembro
        tx.update(memberRef, {
          missedCount: FieldValue.increment(1),
          complianceRate: complianceAfter,
          lastActiveAt: FieldValue.serverTimestamp(),
        });
      });

      affectedHomeIds.add(homeId);
      logger.info(`processExpiredTasks: processed task ${taskId} in home ${homeId}`);
    } catch (err) {
      logger.error(`processExpiredTasks: error processing task ${taskId}`, err);
    }
  }

  logger.info(`processExpiredTasks: done. Affected homes: ${affectedHomeIds.size}`);
});
```

- [ ] **Step 4: Actualizar los tests para importar las funciones exportadas**

En `functions/src/jobs/jobs.test.ts`, los tests de la sección `processExpiredTasks — lógica pura` usan funciones locales definidas en el propio test. Reemplazar las funciones locales del test con importaciones del módulo real:

Al inicio del archivo `jobs.test.ts`, añadir:
```typescript
import {
  computeNextAssignee,
  computeComplianceAfterMiss,
  isExpired,
} from "./process_expired_tasks";
```

Y eliminar las definiciones locales de `computeNextAssignee`, `computeComplianceAfterMiss` e `isExpired` que hay en el bloque de tests (las funciones que el step 1 definió inline en el test). Los tests en sí permanecen igual.

- [ ] **Step 5: Ejecutar tests — deben pasar**

```bash
cd functions && npm test -- --testPathPattern="jobs.test" 2>&1 | tail -30
```

Esperado: todos los tests pasan, incluyendo los nuevos de `processExpiredTasks`.

- [ ] **Step 6: Exportar desde jobs/index.ts**

En `functions/src/jobs/index.ts`, añadir:

```typescript
export { processExpiredTasks } from "./process_expired_tasks";
```

El archivo completo resultante:
```typescript
export { purgeExpiredFrozen } from "./purge_expired_frozen";
export { restorePremiumState } from "./restore_premium_state";
export { processExpiredTasks } from "./process_expired_tasks";
```

- [ ] **Step 7: Compilar TypeScript**

```bash
cd functions && npm run build 2>&1 | tail -20
```

Esperado: 0 errores de compilación.

- [ ] **Step 8: Commit**

```bash
cd functions && git add src/jobs/process_expired_tasks.ts src/jobs/index.ts src/jobs/jobs.test.ts && git commit -m "feat(expiry): Cloud Function processExpiredTasks (00:05 UTC)"
```

---

## Task 7: Verificación final

**Files:** ninguno nuevo

- [ ] **Step 1: Ejecutar todos los tests de Dart**

```bash
flutter test test/unit/ -v 2>&1 | tail -20
```

Esperado: todos pasan. En particular `task_event_missed_test.dart`.

- [ ] **Step 2: Ejecutar todos los tests de Functions**

```bash
cd functions && npm test 2>&1 | tail -20
```

Esperado: todos pasan, incluyendo los nuevos de `processExpiredTasks`.

- [ ] **Step 3: flutter analyze completo**

```bash
flutter analyze
```

Esperado: 0 errores.

- [ ] **Step 4: Compilar Functions**

```bash
cd functions && npm run build
```

Esperado: 0 errores TypeScript.

- [ ] **Step 5: Commit final si hay ficheros sin commit**

```bash
git status
```

Si hay ficheros pendientes de `lib/` (los de Tasks 2, 3, 4, 5 que pueden haberse commiteado por separado), verificar que están todos commiteados. Si no:

```bash
git add -p
git commit -m "feat(expiry): integración completa task expiry"
```
