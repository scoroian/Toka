# Spec-07: Completar Tarea y Pasar Turno — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar "marcar tarea hecha" y "pasar turno" con diálogos de confirmación, creación de eventos en Firestore, rotación del responsable, actualización de estadísticas y refresco del dashboard.

**Architecture:** `AssignmentCalculator` puro en `core/utils` maneja la rotación. Dos Cloud Functions (`applyTaskCompletion`, `passTaskTurn`) ejecutan transacciones atómicas. Dos providers Riverpod (`TaskCompletionProvider`, `TaskPassProvider`) llaman esas functions. Dos diálogos (`CompleteTaskDialog`, `PassTurnDialog`) gestionan la UX de confirmación. `TodayTaskSection` y `TodayScreen` se actualizan para conectar las acciones a los diálogos.

**Tech Stack:** Flutter/Riverpod, `cloud_functions` package, Cloud Functions TypeScript, `fake_cloud_firestore` + `mocktail` para tests.

---

## File Structure

### Archivos nuevos
- `lib/core/utils/assignment_calculator.dart` — rotación circular pura
- `lib/features/tasks/application/task_completion_provider.dart` + `.g.dart`
- `lib/features/tasks/application/task_pass_provider.dart` + `.g.dart`
- `lib/features/tasks/presentation/widgets/complete_task_dialog.dart`
- `lib/features/tasks/presentation/widgets/pass_turn_dialog.dart`
- `functions/src/tasks/apply_task_completion.ts`
- `functions/src/tasks/pass_task_turn.ts`
- `test/unit/features/tasks/assignment_calculator_test.dart`
- `test/unit/features/tasks/task_completion_provider_test.dart`
- `test/unit/features/tasks/pass_turn_dialog_test.dart`
- `test/integration/features/tasks/task_completion_test.dart`
- `test/integration/features/tasks/pass_turn_test.dart`
- `test/ui/features/tasks/complete_task_dialog_test.dart`
- `test/ui/features/tasks/pass_turn_dialog_test.dart`

### Archivos modificados
- `functions/src/tasks/update_dashboard.ts` — leer `taskEvents` en vez de `task_completions`
- `functions/src/tasks/index.ts` — exportar nuevas funciones
- `lib/features/tasks/presentation/widgets/today_task_section.dart` — añadir callbacks `onDone`/`onPass`
- `lib/features/tasks/presentation/today_screen.dart` — conectar diálogos
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` — nuevas claves
- `lib/l10n/app_localizations.dart` + `_es.dart` + `_en.dart` + `_ro.dart` — regenerados

---

## Task 1: AssignmentCalculator

**Files:**
- Create: `lib/core/utils/assignment_calculator.dart`
- Test: `test/unit/features/tasks/assignment_calculator_test.dart`

- [ ] **Step 1: Escribir test fallido**

Crear `test/unit/features/tasks/assignment_calculator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/utils/assignment_calculator.dart';

void main() {
  group('AssignmentCalculator.getNextAssignee', () {
    test('lista de 3: después del 3º vuelve al 1º', () {
      final order = ['A', 'B', 'C'];
      expect(AssignmentCalculator.getNextAssignee(order, 'C', []), 'A');
    });

    test('lista de 3: después del 1º va al 2º', () {
      final order = ['A', 'B', 'C'];
      expect(AssignmentCalculator.getNextAssignee(order, 'A', []), 'B');
    });

    test('salta miembro congelado', () {
      final order = ['A', 'B', 'C'];
      expect(AssignmentCalculator.getNextAssignee(order, 'A', ['B']), 'C');
    });

    test('todos congelados excepto el actual: se asigna a sí mismo', () {
      final order = ['A', 'B', 'C'];
      expect(AssignmentCalculator.getNextAssignee(order, 'A', ['B', 'C']), 'A');
    });

    test('lista vacía: retorna null', () {
      expect(AssignmentCalculator.getNextAssignee([], 'A', []), isNull);
    });

    test('miembro no en la lista: retorna el primero elegible', () {
      final order = ['A', 'B', 'C'];
      // indexOf returns -1; (-1 + 1) % 3 = 0 → 'A'
      expect(AssignmentCalculator.getNextAssignee(order, 'Z', []), 'A');
    });
  });
}
```

- [ ] **Step 2: Correr test para confirmar que falla**

```bash
flutter test test/unit/features/tasks/assignment_calculator_test.dart
```

Expected: ERROR — `assignment_calculator.dart` no existe.

- [ ] **Step 3: Implementar AssignmentCalculator**

Crear `lib/core/utils/assignment_calculator.dart`:

```dart
abstract class AssignmentCalculator {
  static String? getNextAssignee(
    List<String> order,
    String currentUid,
    List<String> frozenUids,
  ) {
    if (order.isEmpty) return null;
    final eligible = order.where((uid) => !frozenUids.contains(uid)).toList();
    if (eligible.isEmpty) return currentUid;
    final currentIndex = eligible.indexOf(currentUid);
    final nextIndex = (currentIndex + 1) % eligible.length;
    return eligible[nextIndex];
  }
}
```

- [ ] **Step 4: Correr test para confirmar que pasa**

```bash
flutter test test/unit/features/tasks/assignment_calculator_test.dart
```

Expected: All 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/assignment_calculator.dart test/unit/features/tasks/assignment_calculator_test.dart
git commit -m "feat(tasks): add AssignmentCalculator for circular rotation"
```

---

## Task 2: Claves l10n

**Files:**
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ro.arb`
- Regenerate: `lib/l10n/app_localizations*.dart`

- [ ] **Step 1: Añadir claves al final de app_es.arb** (antes del `}` de cierre)

```json
  "complete_task_dialog_body": "¿Confirmas que has completado esta tarea?",
  "@complete_task_dialog_body": { "description": "Complete task confirmation body" },
  "complete_task_confirm_btn": "Sí, hecha ✓",
  "@complete_task_confirm_btn": { "description": "Complete task confirm button" },
  "pass_turn_dialog_title": "¿Pasar turno?",
  "@pass_turn_dialog_title": { "description": "Pass turn dialog title" },
  "pass_turn_compliance_warning": "Tu cumplimiento bajará de {before}% a ~{after}%",
  "@pass_turn_compliance_warning": {
    "description": "Compliance drop warning",
    "placeholders": {
      "before": { "type": "String" },
      "after": { "type": "String" }
    }
  },
  "pass_turn_next_assignee": "El siguiente responsable será: {name}",
  "@pass_turn_next_assignee": {
    "description": "Next assignee label",
    "placeholders": { "name": { "type": "String" } }
  },
  "pass_turn_no_candidate": "No hay otro miembro disponible, seguirás siendo el responsable",
  "@pass_turn_no_candidate": { "description": "No other eligible member message" },
  "pass_turn_reason_hint": "Motivo (opcional)",
  "@pass_turn_reason_hint": { "description": "Pass reason text field hint" },
  "pass_turn_confirm_btn": "Pasar turno",
  "@pass_turn_confirm_btn": { "description": "Pass turn confirm button" }
```

- [ ] **Step 2: Añadir claves al final de app_en.arb**

```json
  "complete_task_dialog_body": "Confirm you have completed this task?",
  "@complete_task_dialog_body": { "description": "Complete task confirmation body" },
  "complete_task_confirm_btn": "Yes, done ✓",
  "@complete_task_confirm_btn": { "description": "Complete task confirm button" },
  "pass_turn_dialog_title": "Pass turn?",
  "@pass_turn_dialog_title": { "description": "Pass turn dialog title" },
  "pass_turn_compliance_warning": "Your compliance will drop from {before}% to ~{after}%",
  "@pass_turn_compliance_warning": {
    "description": "Compliance drop warning",
    "placeholders": {
      "before": { "type": "String" },
      "after": { "type": "String" }
    }
  },
  "pass_turn_next_assignee": "Next responsible: {name}",
  "@pass_turn_next_assignee": {
    "description": "Next assignee label",
    "placeholders": { "name": { "type": "String" } }
  },
  "pass_turn_no_candidate": "No other member available, you will remain responsible",
  "@pass_turn_no_candidate": { "description": "No other eligible member message" },
  "pass_turn_reason_hint": "Reason (optional)",
  "@pass_turn_reason_hint": { "description": "Pass reason text field hint" },
  "pass_turn_confirm_btn": "Pass turn",
  "@pass_turn_confirm_btn": { "description": "Pass turn confirm button" }
```

- [ ] **Step 3: Añadir claves al final de app_ro.arb**

```json
  "complete_task_dialog_body": "Confirmi că ai finalizat această sarcină?",
  "@complete_task_dialog_body": { "description": "Complete task confirmation body" },
  "complete_task_confirm_btn": "Da, gata ✓",
  "@complete_task_confirm_btn": { "description": "Complete task confirm button" },
  "pass_turn_dialog_title": "Pasezi rândul?",
  "@pass_turn_dialog_title": { "description": "Pass turn dialog title" },
  "pass_turn_compliance_warning": "Respectarea ta va scădea de la {before}% la ~{after}%",
  "@pass_turn_compliance_warning": {
    "description": "Compliance drop warning",
    "placeholders": {
      "before": { "type": "String" },
      "after": { "type": "String" }
    }
  },
  "pass_turn_next_assignee": "Următorul responsabil: {name}",
  "@pass_turn_next_assignee": {
    "description": "Next assignee label",
    "placeholders": { "name": { "type": "String" } }
  },
  "pass_turn_no_candidate": "Nu există alt membru disponibil, vei rămâne responsabil",
  "@pass_turn_no_candidate": { "description": "No other eligible member message" },
  "pass_turn_reason_hint": "Motiv (opțional)",
  "@pass_turn_reason_hint": { "description": "Pass reason text field hint" },
  "pass_turn_confirm_btn": "Pasează rândul",
  "@pass_turn_confirm_btn": { "description": "Pass turn confirm button" }
```

- [ ] **Step 4: Regenerar l10n**

```bash
flutter gen-l10n
```

Expected: Regenera `lib/l10n/app_localizations.dart` y los tres archivos de locale.

- [ ] **Step 5: Verificar compilación**

```bash
flutter analyze lib/l10n/
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/
git commit -m "feat(i18n): add l10n keys for complete-task and pass-turn dialogs"
```

---

## Task 3: Cloud Functions — applyTaskCompletion + update_dashboard

**Files:**
- Create: `functions/src/tasks/apply_task_completion.ts`
- Modify: `functions/src/tasks/update_dashboard.ts`
- Modify: `functions/src/tasks/index.ts`

- [ ] **Step 1: Crear apply_task_completion.ts**

```typescript
// functions/src/tasks/apply_task_completion.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

function getNextAssigneeTs(
  order: string[],
  currentUid: string,
  frozenUids: string[] = []
): string | null {
  if (!order.length) return null;
  const eligible = order.filter((uid) => !frozenUids.includes(uid));
  if (!eligible.length) return currentUid;
  const idx = eligible.indexOf(currentUid);
  const nextIdx = (idx + 1) % eligible.length;
  return eligible[nextIdx];
}

function addRecurrenceInterval(base: Date, recurrenceType: string): Date {
  const d = new Date(base);
  switch (recurrenceType) {
    case "hourly":  d.setHours(d.getHours() + 1); break;
    case "daily":   d.setDate(d.getDate() + 1); break;
    case "weekly":  d.setDate(d.getDate() + 7); break;
    case "monthly": d.setMonth(d.getMonth() + 1); break;
    case "yearly":  d.setFullYear(d.getFullYear() + 1); break;
  }
  return d;
}

export const applyTaskCompletion = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId } = request.data as { homeId: string; taskId: string };
  const uid = request.auth.uid;

  if (!homeId || !taskId) {
    throw new HttpsError("invalid-argument", "homeId and taskId are required");
  }

  const result = await db.runTransaction(async (tx) => {
    // 1. Leer tarea
    const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
    const taskSnap = await tx.get(taskRef);
    if (!taskSnap.exists) throw new HttpsError("not-found", "Task not found");

    const task = taskSnap.data()!;
    if (task["currentAssigneeUid"] !== uid) {
      throw new HttpsError("permission-denied", "Not your turn");
    }
    if (task["status"] !== "active") {
      throw new HttpsError("failed-precondition", "Task not active");
    }

    // 2. Calcular siguiente responsable
    const assignmentOrder: string[] = task["assignmentOrder"] ?? [uid];
    const frozenUids: string[] = task["frozenUids"] ?? [];
    const nextAssigneeUid = getNextAssigneeTs(assignmentOrder, uid, frozenUids) ?? uid;

    // 3. Calcular nuevo nextDueAt
    const currentDue = (task["nextDueAt"] as admin.firestore.Timestamp | undefined)?.toDate() ?? new Date();
    const recurrenceType: string = task["recurrenceType"] ?? "daily";
    const nextDueAt = addRecurrenceInterval(currentDue, recurrenceType);

    // 4. Crear evento completed
    const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
    tx.set(eventRef, {
      eventType: "completed",
      taskId,
      taskTitleSnapshot: task["title"] ?? "",
      taskVisualSnapshot: {
        kind: task["visualKind"] ?? "emoji",
        value: task["visualValue"] ?? "",
      },
      actorUid: uid,
      performerUid: uid,
      completedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      penaltyApplied: false,
    });

    // 5. Actualizar tarea
    tx.update(taskRef, {
      currentAssigneeUid: nextAssigneeUid,
      nextDueAt: admin.firestore.Timestamp.fromDate(nextDueAt),
      completedCount90d: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 6. Actualizar contadores del miembro
    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
    const memberSnap = await tx.get(memberRef);
    const member = memberSnap.data() ?? {};
    const newCompleted = (member["completedCount"] as number ?? 0) + 1;
    const newPassed = member["passedCount"] as number ?? 0;
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

  // Post-transacción: actualizar dashboard
  try {
    await updateHomeDashboard(homeId);
  } catch (err) {
    logger.error("Failed to update dashboard after completion", err);
  }

  return result;
});
```

- [ ] **Step 2: Actualizar update_dashboard.ts — leer de taskEvents**

Reemplazar el bloque "Leer completados de hoy" (líneas ~59-79) por:

```typescript
  // --- 3. Leer completados de hoy desde taskEvents ---
  const eventsSnap = await homeRef.collection("taskEvents")
    .where("eventType", "==", "completed")
    .where("completedAt", ">=", admin.firestore.Timestamp.fromDate(todayStart))
    .where("completedAt", "<", admin.firestore.Timestamp.fromDate(todayEnd))
    .get();

  const doneTasksPreview: Record<string, unknown>[] = [];
  for (const doc of eventsSnap.docs) {
    const ev = doc.data();
    // Intentar obtener nombre del miembro desde memberPreview (ya construido) o snapshot
    const actorUid = ev["actorUid"] as string ?? "";
    const memberDoc = await homeRef.collection("members").doc(actorUid).get();
    const m = memberDoc.data() ?? {};
    doneTasksPreview.push({
      taskId: ev["taskId"] ?? doc.id,
      title: ev["taskTitleSnapshot"] ?? "",
      visualKind: (ev["taskVisualSnapshot"] as Record<string, string>)?.kind ?? "emoji",
      visualValue: (ev["taskVisualSnapshot"] as Record<string, string>)?.value ?? "",
      recurrenceType: "daily",
      completedByUid: actorUid,
      completedByName: m["name"] ?? "",
      completedByPhoto: m["photoUrl"] ?? null,
      completedAt: ev["completedAt"],
    });
  }
```

- [ ] **Step 3: Actualizar functions/src/tasks/index.ts**

```typescript
export * from "./update_dashboard";
export * from "./apply_task_completion";
export * from "./pass_task_turn";
```

- [ ] **Step 4: Compilar funciones**

```bash
cd functions && npm run build
```

Expected: Sin errores TypeScript. (Si `pass_task_turn.ts` aún no existe, crearlo vacío primero: `export {};`)

- [ ] **Step 5: Commit**

```bash
cd ..
git add functions/src/tasks/apply_task_completion.ts functions/src/tasks/update_dashboard.ts functions/src/tasks/index.ts
git commit -m "feat(functions): add applyTaskCompletion callable and update dashboard to read taskEvents"
```

---

## Task 4: Cloud Function — passTaskTurn

**Files:**
- Create: `functions/src/tasks/pass_task_turn.ts`

- [ ] **Step 1: Crear pass_task_turn.ts**

```typescript
// functions/src/tasks/pass_task_turn.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

function getNextEligibleMember(
  order: string[],
  currentUid: string,
  frozenUids: string[]
): string {
  if (!order.length) return currentUid;
  const eligible = order.filter((uid) => uid !== currentUid && !frozenUids.includes(uid));
  if (!eligible.length) return currentUid;
  const currentIdx = order.indexOf(currentUid);
  // Find the first eligible member after currentUid in circular order
  for (let i = 1; i < order.length; i++) {
    const candidate = order[(currentIdx + i) % order.length];
    if (eligible.includes(candidate)) return candidate;
  }
  return eligible[0];
}

export const passTaskTurn = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId, reason } = request.data as {
    homeId: string;
    taskId: string;
    reason?: string;
  };
  const uid = request.auth.uid;

  if (!homeId || !taskId) {
    throw new HttpsError("invalid-argument", "homeId and taskId are required");
  }

  const result = await db.runTransaction(async (tx) => {
    // 1. Leer tarea y validar
    const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
    const taskSnap = await tx.get(taskRef);
    if (!taskSnap.exists) throw new HttpsError("not-found", "Task not found");

    const task = taskSnap.data()!;
    if (task["currentAssigneeUid"] !== uid) {
      throw new HttpsError("permission-denied", "Not your turn");
    }
    if (task["status"] !== "active") {
      throw new HttpsError("failed-precondition", "Task not active");
    }

    // 2. Leer miembros para conocer congelados/ausentes
    const membersSnap = await tx.get(
      db.collection("homes").doc(homeId).collection("members")
    );
    const frozenUids: string[] = [];
    for (const mDoc of membersSnap.docs) {
      const mData = mDoc.data();
      if (mData["status"] === "frozen" || mData["status"] === "absent") {
        frozenUids.push(mDoc.id);
      }
    }

    // 3. Encontrar siguiente elegible
    const assignmentOrder: string[] = task["assignmentOrder"] ?? [uid];
    const toUid = getNextEligibleMember(assignmentOrder, uid, frozenUids);
    const noCandidate = toUid === uid;

    // 4. Calcular compliance antes y después
    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
    const memberSnap = await tx.get(memberRef);
    const member = memberSnap.data() ?? {};
    const completed = member["completedCount"] as number ?? 0;
    const passed = member["passedCount"] as number ?? 0;
    const complianceBefore = completed / Math.max(completed + passed, 1);
    const complianceAfter = completed / Math.max(completed + passed + 1, 1);

    // 5. Crear evento passed
    const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
    tx.set(eventRef, {
      eventType: "passed",
      taskId,
      taskTitleSnapshot: task["title"] ?? "",
      taskVisualSnapshot: {
        kind: task["visualKind"] ?? "emoji",
        value: task["visualValue"] ?? "",
      },
      actorUid: uid,
      toUid,
      reason: reason ?? null,
      noCandidate,
      createdAt: FieldValue.serverTimestamp(),
      penaltyApplied: true,
    });

    // 6. Actualizar tarea
    tx.update(taskRef, {
      currentAssigneeUid: toUid,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 7. Actualizar contadores del miembro que pasa
    tx.update(memberRef, {
      passedCount: FieldValue.increment(1),
      complianceRate: complianceAfter,
      lastActiveAt: FieldValue.serverTimestamp(),
    });

    return { toUid, noCandidate, complianceBefore, complianceAfter };
  });

  // Actualizar dashboard
  try {
    await updateHomeDashboard(homeId);
  } catch (err) {
    logger.error("Failed to update dashboard after pass", err);
  }

  return result;
});
```

- [ ] **Step 2: Compilar funciones**

```bash
cd functions && npm run build
```

Expected: Sin errores TypeScript.

- [ ] **Step 3: Commit**

```bash
cd ..
git add functions/src/tasks/pass_task_turn.ts functions/src/tasks/index.ts
git commit -m "feat(functions): add passTaskTurn callable function"
```

---

## Task 5: TaskCompletionProvider

**Files:**
- Test: `test/unit/features/tasks/task_completion_provider_test.dart`
- Create: `lib/features/tasks/application/task_completion_provider.dart`

- [ ] **Step 1: Escribir test fallido**

```dart
// test/unit/features/tasks/task_completion_provider_test.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/task_completion_provider.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult extends Mock implements HttpsCallableResult {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    when(() => mockFunctions.httpsCallable('applyTaskCompletion'))
        .thenReturn(mockCallable);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          firebaseFunctionsProvider.overrideWithValue(mockFunctions),
        ],
      );

  test('completeTask llama callable con homeId y taskId correctos', () async {
    when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    await container.read(taskCompletionProvider.notifier).completeTask('home1', 'task1');

    verify(() => mockCallable.call({'homeId': 'home1', 'taskId': 'task1'})).called(1);
  });

  test('estado loading → data en flujo exitoso', () async {
    when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    final notifier = container.read(taskCompletionProvider.notifier);

    expect(container.read(taskCompletionProvider), const AsyncValue<void>.data(null));
    final future = notifier.completeTask('home1', 'task1');
    expect(container.read(taskCompletionProvider), isA<AsyncLoading<void>>());
    await future;
    expect(container.read(taskCompletionProvider), const AsyncValue<void>.data(null));
  });

  test('fallo permission-denied → estado error', () async {
    when(() => mockCallable.call(any())).thenThrow(
      FirebaseFunctionsException(message: 'Not your turn', code: 'permission-denied'),
    );

    final container = makeContainer();
    await container.read(taskCompletionProvider.notifier).completeTask('home1', 'task1');

    final state = container.read(taskCompletionProvider);
    expect(state, isA<AsyncError<void>>());
  });

  test('fallo not-found → estado error', () async {
    when(() => mockCallable.call(any())).thenThrow(
      FirebaseFunctionsException(message: 'Task not found', code: 'not-found'),
    );

    final container = makeContainer();
    await container.read(taskCompletionProvider.notifier).completeTask('home1', 'task1');

    final state = container.read(taskCompletionProvider);
    expect(state, isA<AsyncError<void>>());
  });
}
```

- [ ] **Step 2: Correr test para confirmar que falla**

```bash
flutter test test/unit/features/tasks/task_completion_provider_test.dart
```

Expected: ERROR — `task_completion_provider.dart` no existe.

- [ ] **Step 3: Implementar TaskCompletionProvider**

Crear `lib/features/tasks/application/task_completion_provider.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_completion_provider.g.dart';

@Riverpod(keepAlive: false)
FirebaseFunctions firebaseFunctions(FirebaseFunctionsRef ref) {
  return FirebaseFunctions.instance;
}

@riverpod
class TaskCompletion extends _$TaskCompletion {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> completeTask(String homeId, String taskId) async {
    state = const AsyncValue.loading();
    try {
      final functions = ref.read(firebaseFunctionsProvider);
      await functions.httpsCallable('applyTaskCompletion').call({
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

- [ ] **Step 4: Generar código Riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: Genera `task_completion_provider.g.dart`.

- [ ] **Step 5: Correr test**

```bash
flutter test test/unit/features/tasks/task_completion_provider_test.dart
```

Expected: All 4 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/tasks/application/task_completion_provider.dart lib/features/tasks/application/task_completion_provider.g.dart test/unit/features/tasks/task_completion_provider_test.dart
git commit -m "feat(tasks): add TaskCompletionProvider with cloud function callable"
```

---

## Task 6: TaskPassProvider

**Files:**
- Test: `test/unit/features/tasks/task_pass_provider_test.dart`
- Create: `lib/features/tasks/application/task_pass_provider.dart`

- [ ] **Step 1: Escribir test fallido**

```dart
// test/unit/features/tasks/task_pass_provider_test.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toka/features/tasks/application/task_completion_provider.dart';
import 'package:toka/features/tasks/application/task_pass_provider.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult extends Mock implements HttpsCallableResult {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    when(() => mockFunctions.httpsCallable('passTaskTurn')).thenReturn(mockCallable);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          firebaseFunctionsProvider.overrideWithValue(mockFunctions),
        ],
      );

  test('passTurn llama callable con homeId, taskId y reason', () async {
    when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    await container.read(taskPassProvider.notifier).passTurn('home1', 'task1', reason: 'Viaje');

    verify(() => mockCallable.call({
      'homeId': 'home1',
      'taskId': 'task1',
      'reason': 'Viaje',
    })).called(1);
  });

  test('passTurn sin reason omite la clave reason', () async {
    when(() => mockCallable.call(any())).thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    await container.read(taskPassProvider.notifier).passTurn('home1', 'task1');

    verify(() => mockCallable.call({'homeId': 'home1', 'taskId': 'task1'})).called(1);
  });

  test('fallo permission-denied → estado error', () async {
    when(() => mockCallable.call(any())).thenThrow(
      FirebaseFunctionsException(message: 'Not your turn', code: 'permission-denied'),
    );

    final container = makeContainer();
    await container.read(taskPassProvider.notifier).passTurn('home1', 'task1');

    expect(container.read(taskPassProvider), isA<AsyncError<void>>());
  });
}
```

- [ ] **Step 2: Correr test para confirmar que falla**

```bash
flutter test test/unit/features/tasks/task_pass_provider_test.dart
```

Expected: ERROR — `task_pass_provider.dart` no existe.

- [ ] **Step 3: Implementar TaskPassProvider**

Crear `lib/features/tasks/application/task_pass_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'task_completion_provider.dart';

part 'task_pass_provider.g.dart';

@riverpod
class TaskPass extends _$TaskPass {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> passTurn(
    String homeId,
    String taskId, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final functions = ref.read(firebaseFunctionsProvider);
      final data = <String, dynamic>{
        'homeId': homeId,
        'taskId': taskId,
      };
      if (reason != null) data['reason'] = reason;
      await functions.httpsCallable('passTaskTurn').call(data);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
```

- [ ] **Step 4: Generar código Riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Correr test**

```bash
flutter test test/unit/features/tasks/task_pass_provider_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/tasks/application/task_pass_provider.dart lib/features/tasks/application/task_pass_provider.g.dart test/unit/features/tasks/task_pass_provider_test.dart
git commit -m "feat(tasks): add TaskPassProvider with passTaskTurn callable"
```

---

## Task 7: CompleteTaskDialog

**Files:**
- Create: `lib/features/tasks/presentation/widgets/complete_task_dialog.dart`
- Create: `test/ui/features/tasks/complete_task_dialog_test.dart`

- [ ] **Step 1: Escribir test UI**

```dart
// test/ui/features/tasks/complete_task_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/complete_task_dialog.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

TaskPreview _task() => TaskPreview(
      taskId: 't1',
      title: 'Barrer',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: 'uid1',
      currentAssigneeName: 'Ana',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 6, 18, 0),
      isOverdue: false,
      status: 'active',
    );

void main() {
  testWidgets('muestra nombre e icono de la tarea', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => CompleteTaskDialog(task: _task(), onConfirm: () {}),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('🧹 Barrer'), findsOneWidget);
    expect(find.text('¿Confirmas que has completado esta tarea?'), findsOneWidget);
  });

  testWidgets('botón Cancelar cierra el diálogo', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => CompleteTaskDialog(task: _task(), onConfirm: () {}),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_cancel_complete')));
    await tester.pumpAndSettle();

    expect(find.byType(CompleteTaskDialog), findsNothing);
  });

  testWidgets('botón Sí hecha dispara onConfirm', (tester) async {
    bool confirmed = false;
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => CompleteTaskDialog(
            task: _task(),
            onConfirm: () => confirmed = true,
          ),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_confirm_complete')));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('golden: diálogo completar tarea', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => CompleteTaskDialog(task: _task(), onConfirm: () {}),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/complete_task_dialog.png'),
    );
  });
}
```

- [ ] **Step 2: Correr test para confirmar que falla**

```bash
flutter test test/ui/features/tasks/complete_task_dialog_test.dart
```

Expected: ERROR — `complete_task_dialog.dart` no existe.

- [ ] **Step 3: Implementar CompleteTaskDialog**

```dart
// lib/features/tasks/presentation/widgets/complete_task_dialog.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class CompleteTaskDialog extends StatelessWidget {
  final TaskPreview task;
  final VoidCallback onConfirm;

  const CompleteTaskDialog({
    super.key,
    required this.task,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${task.visualValue} ${task.title}'),
      content: Text(l10n.complete_task_dialog_body),
      actions: [
        TextButton(
          key: const Key('btn_cancel_complete'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          key: const Key('btn_confirm_complete'),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(l10n.complete_task_confirm_btn),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Generar golden y correr tests**

```bash
flutter test test/ui/features/tasks/complete_task_dialog_test.dart --update-goldens
```

Expected: Golden generado, 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/widgets/complete_task_dialog.dart test/ui/features/tasks/complete_task_dialog_test.dart test/ui/features/tasks/goldens/complete_task_dialog.png
git commit -m "feat(tasks): add CompleteTaskDialog widget with UI tests and golden"
```

---

## Task 8: PassTurnDialog

**Files:**
- Test (lógica): `test/unit/features/tasks/pass_turn_dialog_test.dart`
- Create: `lib/features/tasks/presentation/widgets/pass_turn_dialog.dart`
- Test (UI): `test/ui/features/tasks/pass_turn_dialog_test.dart`

- [ ] **Step 1: Escribir test unitario de lógica**

```dart
// test/unit/features/tasks/pass_turn_dialog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/presentation/widgets/pass_turn_dialog.dart';

void main() {
  group('PassTurnDialog.estimatedComplianceAfter', () {
    test('caso normal: (3 completadas, 1 pasadas) → 3/5', () {
      final result = PassTurnDialog.estimatedComplianceAfter(
        completedCount: 3,
        passedCount: 1,
      );
      expect(result, closeTo(0.6, 0.001));
    });

    test('caso 0 completadas → 0.0', () {
      final result = PassTurnDialog.estimatedComplianceAfter(
        completedCount: 0,
        passedCount: 0,
      );
      expect(result, 0.0);
    });

    test('resultado no puede ser negativo', () {
      final result = PassTurnDialog.estimatedComplianceAfter(
        completedCount: 0,
        passedCount: 5,
      );
      expect(result, greaterThanOrEqualTo(0.0));
    });
  });
}
```

- [ ] **Step 2: Correr test para confirmar que falla**

```bash
flutter test test/unit/features/tasks/pass_turn_dialog_test.dart
```

Expected: ERROR — `pass_turn_dialog.dart` no existe.

- [ ] **Step 3: Escribir test UI**

```dart
// test/ui/features/tasks/pass_turn_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/pass_turn_dialog.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

TaskPreview _task() => TaskPreview(
      taskId: 't1',
      title: 'Barrer',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: 'uid1',
      currentAssigneeName: 'Ana',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 6, 18, 0),
      isOverdue: false,
      status: 'active',
    );

void _openDialog(
  WidgetTester tester, {
  double compliance = 0.87,
  double estimated = 0.81,
  String? nextName,
  void Function(String?)? onConfirm,
}) async {
  await tester.pumpWidget(_wrap(Builder(
    builder: (context) => ElevatedButton(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => PassTurnDialog(
          task: _task(),
          currentComplianceRate: compliance,
          estimatedComplianceAfter: estimated,
          nextAssigneeName: nextName,
          onConfirm: onConfirm ?? (_) {},
        ),
      ),
      child: const Text('open'),
    ),
  )));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra los dos valores de compliance', (tester) async {
    await _openDialog(tester, compliance: 0.87, estimated: 0.81);

    expect(find.textContaining('87'), findsOneWidget);
    expect(find.textContaining('81'), findsOneWidget);
  });

  testWidgets('muestra nombre del siguiente responsable', (tester) async {
    await _openDialog(tester, nextName: 'Carlos');

    expect(find.textContaining('Carlos'), findsOneWidget);
  });

  testWidgets('muestra mensaje sin candidato cuando nextName es null', (tester) async {
    await _openDialog(tester, nextName: null);

    expect(
      find.text('No hay otro miembro disponible, seguirás siendo el responsable'),
      findsOneWidget,
    );
  });

  testWidgets('campo de motivo es opcional y visible', (tester) async {
    await _openDialog(tester);

    expect(find.byKey(const Key('field_pass_reason')), findsOneWidget);
  });

  testWidgets('botón Pasar turno dispara confirmación con reason', (tester) async {
    String? capturedReason;
    await _openDialog(tester, onConfirm: (r) => capturedReason = r);

    await tester.enterText(
      find.byKey(const Key('field_pass_reason')),
      'Me voy de viaje',
    );
    await tester.tap(find.byKey(const Key('btn_confirm_pass')));
    await tester.pumpAndSettle();

    expect(capturedReason, 'Me voy de viaje');
  });

  testWidgets('golden: diálogo pasar turno con next assignee', (tester) async {
    await _openDialog(tester, compliance: 0.87, estimated: 0.81, nextName: 'Carlos');

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pass_turn_dialog.png'),
    );
  });
}
```

- [ ] **Step 4: Implementar PassTurnDialog**

```dart
// lib/features/tasks/presentation/widgets/pass_turn_dialog.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class PassTurnDialog extends StatefulWidget {
  final TaskPreview task;
  final double currentComplianceRate;
  final double estimatedComplianceAfter;
  final String? nextAssigneeName;
  final void Function(String? reason) onConfirm;

  const PassTurnDialog({
    super.key,
    required this.task,
    required this.currentComplianceRate,
    required this.estimatedComplianceAfter,
    required this.nextAssigneeName,
    required this.onConfirm,
  });

  /// Cálculo puro para tests: (completed) / (completed + passed + 1)
  static double estimatedComplianceAfter({
    required int completedCount,
    required int passedCount,
  }) {
    final total = completedCount + passedCount + 1;
    if (total <= 0) return 0;
    return (completedCount / total).clamp(0.0, 1.0);
  }

  @override
  State<PassTurnDialog> createState() => _PassTurnDialogState();
}

class _PassTurnDialogState extends State<PassTurnDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final before = (widget.currentComplianceRate * 100).round();
    final after = (widget.estimatedComplianceAfter * 100).round();

    return AlertDialog(
      title: Text(l10n.pass_turn_dialog_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.pass_turn_compliance_warning(
                  before.toString(),
                  after.toString(),
                ),
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.nextAssigneeName != null)
              Text(l10n.pass_turn_next_assignee(widget.nextAssigneeName!))
            else
              Text(
                l10n.pass_turn_no_candidate,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('field_pass_reason'),
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: l10n.pass_turn_reason_hint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_pass'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          key: const Key('btn_confirm_pass'),
          onPressed: () {
            final reason = _reasonController.text.trim();
            Navigator.of(context).pop();
            widget.onConfirm(reason.isEmpty ? null : reason);
          },
          child: Text(l10n.pass_turn_confirm_btn),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Correr tests unitarios**

```bash
flutter test test/unit/features/tasks/pass_turn_dialog_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Generar golden y correr tests UI**

```bash
flutter test test/ui/features/tasks/pass_turn_dialog_test.dart --update-goldens
```

Expected: Golden generado, todos los tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/tasks/presentation/widgets/pass_turn_dialog.dart test/unit/features/tasks/pass_turn_dialog_test.dart test/ui/features/tasks/pass_turn_dialog_test.dart test/ui/features/tasks/goldens/pass_turn_dialog.png
git commit -m "feat(tasks): add PassTurnDialog widget with compliance preview"
```

---

## Task 9: Wire TodayTaskSection + TodayScreen

**Files:**
- Modify: `lib/features/tasks/presentation/widgets/today_task_section.dart`
- Modify: `lib/features/tasks/presentation/today_screen.dart`

- [ ] **Step 1: Actualizar TodayTaskSection — añadir callbacks**

En `today_task_section.dart`, añadir parámetros `onDone` y `onPass` y pasarlos a `TodayTaskCardTodo`:

```dart
// lib/features/tasks/presentation/widgets/today_task_section.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';
import '../../domain/recurrence_order.dart';
import 'today_task_card_done.dart';
import 'today_task_card_todo.dart';

class TodayTaskSection extends StatelessWidget {
  final String recurrenceType;
  final List<TaskPreview> todos;
  final List<DoneTaskPreview> dones;
  final String? currentUid;
  final void Function(TaskPreview)? onDone;
  final void Function(TaskPreview)? onPass;

  const TodayTaskSection({
    super.key,
    required this.recurrenceType,
    required this.todos,
    required this.dones,
    required this.currentUid,
    this.onDone,
    this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sectionTitle = RecurrenceOrder.localizedTitle(context, recurrenceType);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              sectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              key: Key('section_title_$recurrenceType'),
            ),
          ),
        ),
        if (todos.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                l10n.today_section_todo,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final task = todos[index];
              return TodayTaskCardTodo(
                task: task,
                currentUid: currentUid,
                onDone: onDone != null ? () => onDone!(task) : null,
                onPass: onPass != null ? () => onPass!(task) : null,
              );
            },
          ),
        ],
        if (dones.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: Text(
                l10n.today_section_done,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: dones.length,
            itemBuilder: (context, index) =>
                TodayTaskCardDone(task: dones[index]),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Actualizar TodayScreen — conectar diálogos**

```dart
// lib/features/tasks/presentation/today_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../application/task_completion_provider.dart';
import '../application/task_pass_provider.dart';
import '../domain/home_dashboard.dart';
import '../domain/recurrence_order.dart';
import 'widgets/complete_task_dialog.dart';
import 'widgets/pass_turn_dialog.dart';
import 'widgets/today_empty_state.dart';
import 'widgets/today_header_counters.dart';
import 'widgets/today_skeleton_loader.dart';
import 'widgets/today_task_section.dart';

typedef RecurrenceGroup = ({
  List<TaskPreview> todos,
  List<DoneTaskPreview> dones,
});

@visibleForTesting
Map<String, RecurrenceGroup> groupByRecurrence(
  List<TaskPreview> activeTasks,
  List<DoneTaskPreview> doneTasks,
) {
  final result = <String, RecurrenceGroup>{};

  for (final task in activeTasks) {
    final key = task.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: [...(existing?.todos ?? []), task],
      dones: existing?.dones ?? [],
    );
  }

  for (final done in doneTasks) {
    final key = done.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: existing?.todos ?? [],
      dones: [...(existing?.dones ?? []), done],
    );
  }

  for (final key in result.keys) {
    final group = result[key]!;
    final sorted = <TaskPreview>[...group.todos];
    sorted.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      final dateCmp = a.nextDueAt.compareTo(b.nextDueAt);
      if (dateCmp != 0) return dateCmp;
      return a.title.compareTo(b.title);
    });
    result[key] = (todos: sorted, dones: group.dones);
  }

  return result;
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _onDone(
    BuildContext context,
    WidgetRef ref,
    TaskPreview task,
    String homeId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CompleteTaskDialog(
        task: task,
        onConfirm: () {},
      ),
    );
    // Dialog calls onConfirm which returns null pop; we use pop(true) pattern
    // Re-check: CompleteTaskDialog pops after calling onConfirm.
    // We show the dialog and wait; use a completer pattern instead.
    if (!context.mounted) return;
    // Show the real dialog with result
    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => _CompleteTaskDialogWithResult(task: task),
    );
    if (didConfirm == true) {
      await ref
          .read(taskCompletionProvider.notifier)
          .completeTask(homeId, task.taskId);
    }
  }

  Future<void> _onPass(
    BuildContext context,
    WidgetRef ref,
    TaskPreview task,
    String homeId,
    String? currentUid,
    HomeDashboard dashboard,
  ) async {
    if (currentUid == null) return;

    // Leer stats del miembro para mostrar impacto en compliance
    double complianceBefore = 1.0;
    double estimatedAfter = 1.0;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(currentUid)
          .get();
      final data = snap.data() ?? {};
      final completed = (data['completedCount'] as int?) ?? 0;
      final passed = (data['passedCount'] as int?) ?? 0;
      complianceBefore = (data['complianceRate'] as double?) ??
          (completed / (completed + passed).clamp(1, double.maxFinite));
      estimatedAfter = PassTurnDialog.estimatedComplianceAfter(
        completedCount: completed,
        passedCount: passed,
      );
    } catch (_) {
      // Si falla la lectura, usar defaults
    }

    if (!context.mounted) return;

    final result = await showDialog<String?>(
      context: context,
      builder: (_) => PassTurnDialog(
        task: task,
        currentComplianceRate: complianceBefore,
        estimatedComplianceAfter: estimatedAfter,
        nextAssigneeName: null, // assignmentOrder no está en el dashboard
        onConfirm: (reason) => Navigator.of(context).pop(reason ?? ''),
      ),
    );

    if (result != null && context.mounted) {
      await ref.read(taskPassProvider.notifier).passTurn(
            homeId,
            task.taskId,
            reason: result.isEmpty ? null : result,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dashboardAsync = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider);
    final currentUid = auth.whenOrNull(authenticated: (u) => u.uid);
    final homeAsync = ref.watch(currentHomeProvider);
    final homeId = homeAsync.valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.today_screen_title),
      ),
      body: dashboardAsync.when(
        loading: () => const TodaySkeletonLoader(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.error_generic),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null) return const TodayEmptyState();

          final grouped = groupByRecurrence(
            data.activeTasksPreview,
            data.doneTasksPreview,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TodayHeaderCounters(counters: data.counters),
              ),
              for (final recurrenceType in RecurrenceOrder.all)
                if (grouped[recurrenceType] != null) ...[
                  TodayTaskSection(
                    recurrenceType: recurrenceType,
                    todos: grouped[recurrenceType]!.todos,
                    dones: grouped[recurrenceType]!.dones,
                    currentUid: currentUid,
                    onDone: homeId != null
                        ? (task) => _onDoneSimple(context, ref, task, homeId)
                        : null,
                    onPass: homeId != null
                        ? (task) => _onPass(
                              context,
                              ref,
                              task,
                              homeId,
                              currentUid,
                              data,
                            )
                        : null,
                  ),
                ],
              if (data.adFlags.showBanner)
                const SliverToBoxAdapter(
                  child: _AdBannerPlaceholder(
                    key: Key('ad_banner'),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onDoneSimple(
    BuildContext context,
    WidgetRef ref,
    TaskPreview task,
    String homeId,
  ) async {
    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => _CompleteTaskDialogWithResult(task: task),
    );
    if (didConfirm == true && context.mounted) {
      await ref
          .read(taskCompletionProvider.notifier)
          .completeTask(homeId, task.taskId);
    }
  }
}

/// Variante de CompleteTaskDialog que devuelve `true` al confirmar.
class _CompleteTaskDialogWithResult extends StatelessWidget {
  final TaskPreview task;
  const _CompleteTaskDialogWithResult({required this.task});

  @override
  Widget build(BuildContext context) {
    return CompleteTaskDialog(
      task: task,
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}

class _AdBannerPlaceholder extends StatelessWidget {
  const _AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Ad')),
    );
  }
}
```

**Nota:** El `CompleteTaskDialog` original tiene `onConfirm: VoidCallback`. En `_CompleteTaskDialogWithResult` se sobreescribe `onConfirm` para hacer `pop(true)`. El `PassTurnDialog.onConfirm` recibe la razón y hace `pop(reason)`.

- [ ] **Step 3: Correr análisis estático**

```bash
flutter analyze lib/features/tasks/
```

Expected: No errores.

- [ ] **Step 4: Correr todos los tests existentes del feature tasks**

```bash
flutter test test/unit/features/tasks/ test/ui/features/tasks/
```

Expected: Todos PASS (incluyendo los tests pre-existentes de today_screen).

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/widgets/today_task_section.dart lib/features/tasks/presentation/today_screen.dart
git commit -m "feat(tasks): wire CompleteTaskDialog and PassTurnDialog into TodayScreen"
```

---

## Task 10: Tests de integración

**Files:**
- Create: `test/integration/features/tasks/task_completion_test.dart`
- Create: `test/integration/features/tasks/pass_turn_test.dart`

- [ ] **Step 1: Crear task_completion_test.dart**

```dart
// test/integration/features/tasks/task_completion_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula lo que haría la Cloud Function applyTaskCompletion.
Future<void> simulateCompletion(
  FakeFirebaseFirestore db,
  String homeId,
  String taskId,
  String uid,
) async {
  final taskRef = db.collection('homes').doc(homeId).collection('tasks').doc(taskId);
  final taskSnap = await taskRef.get();
  final task = taskSnap.data()!;

  final assignmentOrder = List<String>.from(task['assignmentOrder'] as List? ?? [uid]);
  final eligible = assignmentOrder;
  final idx = eligible.indexOf(uid);
  final nextUid = eligible[(idx + 1) % eligible.length];

  final currentDue = (task['nextDueAt'] as Timestamp).toDate();
  final nextDue = currentDue.add(const Duration(days: 1));

  final eventRef = db.collection('homes').doc(homeId).collection('taskEvents').doc();
  await eventRef.set({
    'eventType': 'completed',
    'taskId': taskId,
    'taskTitleSnapshot': task['title'],
    'taskVisualSnapshot': {'kind': task['visualKind'], 'value': task['visualValue']},
    'actorUid': uid,
    'performerUid': uid,
    'completedAt': Timestamp.fromDate(DateTime.now()),
    'createdAt': Timestamp.fromDate(DateTime.now()),
    'penaltyApplied': false,
  });

  await taskRef.update({
    'currentAssigneeUid': nextUid,
    'nextDueAt': Timestamp.fromDate(nextDue),
    'completedCount90d': FieldValue.increment(1),
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  });

  final memberRef = db.collection('homes').doc(homeId).collection('members').doc(uid);
  final memberSnap = await memberRef.get();
  final member = memberSnap.data()!;
  final newCompleted = (member['completedCount'] as int? ?? 0) + 1;
  final newPassed = member['passedCount'] as int? ?? 0;
  final newCompliance = newCompleted / (newCompleted + newPassed);

  await memberRef.update({
    'completedCount': FieldValue.increment(1),
    'complianceRate': newCompliance,
  });
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';

  setUp(() async {
    db = FakeFirebaseFirestore();

    // Crear tarea inicial
    await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .set({
      'title': 'Barrer',
      'visualKind': 'emoji',
      'visualValue': '🧹',
      'recurrenceType': 'daily',
      'status': 'active',
      'currentAssigneeUid': 'uid-A',
      'assignmentOrder': ['uid-A', 'uid-B', 'uid-C'],
      'nextDueAt': Timestamp.fromDate(DateTime(2026, 4, 6, 10)),
      'completedCount90d': 0,
    });

    // Crear miembros
    for (final uid in ['uid-A', 'uid-B', 'uid-C']) {
      await db
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(uid)
          .set({
        'name': uid,
        'completedCount': 3,
        'passedCount': 1,
        'complianceRate': 0.75,
        'status': 'active',
      });
    }
  });

  test('completar tarea crea evento completed en taskEvents', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final events = await db
        .collection('homes')
        .doc(homeId)
        .collection('taskEvents')
        .where('eventType', isEqualTo: 'completed')
        .get();

    expect(events.docs.length, 1);
    expect(events.docs.first.data()['taskId'], 'task1');
    expect(events.docs.first.data()['actorUid'], 'uid-A');
  });

  test('nextDueAt de la tarea avanza 1 día', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    final nextDue = (task.data()!['nextDueAt'] as Timestamp).toDate();
    expect(nextDue, DateTime(2026, 4, 7, 10));
  });

  test('currentAssigneeUid rota al siguiente miembro', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-B');
  });

  test('completedCount del miembro se incrementa', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final member = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-A')
        .get();

    expect(member.data()!['completedCount'], 4);
  });

  test('complianceRate del miembro se recalcula', () async {
    await simulateCompletion(db, homeId, 'task1', 'uid-A');

    final member = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-A')
        .get();

    // completedCount=4, passedCount=1 → 4/5 = 0.8
    expect(member.data()!['complianceRate'], closeTo(0.8, 0.001));
  });

  test('rotación circular: C completa → A es el nuevo responsable', () async {
    // Avanzar: A → B → C
    await simulateCompletion(db, homeId, 'task1', 'uid-A');
    await db.collection('homes').doc(homeId).collection('tasks').doc('task1')
        .update({'currentAssigneeUid': 'uid-C'});

    await simulateCompletion(db, homeId, 'task1', 'uid-C');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-A');
  });
}
```

- [ ] **Step 2: Crear pass_turn_test.dart**

```dart
// test/integration/features/tasks/pass_turn_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula lo que haría la Cloud Function passTaskTurn.
Future<void> simulatePass(
  FakeFirebaseFirestore db,
  String homeId,
  String taskId,
  String uid, {
  String? reason,
}) async {
  final taskRef = db.collection('homes').doc(homeId).collection('tasks').doc(taskId);
  final taskSnap = await taskRef.get();
  final task = taskSnap.data()!;

  final membersSnap = await db.collection('homes').doc(homeId).collection('members').get();
  final frozenUids = membersSnap.docs
      .where((d) => d.data()['status'] == 'frozen')
      .map((d) => d.id)
      .toSet();

  final assignmentOrder = List<String>.from(task['assignmentOrder'] as List? ?? [uid]);
  final eligibleOthers = assignmentOrder
      .where((u) => u != uid && !frozenUids.contains(u))
      .toList();
  final toUid = eligibleOthers.isNotEmpty
      ? eligibleOthers.first
      : uid;
  final noCandidate = toUid == uid;

  final eventRef = db.collection('homes').doc(homeId).collection('taskEvents').doc();
  await eventRef.set({
    'eventType': 'passed',
    'taskId': taskId,
    'actorUid': uid,
    'toUid': toUid,
    'reason': reason,
    'noCandidate': noCandidate,
    'createdAt': Timestamp.fromDate(DateTime.now()),
    'penaltyApplied': true,
  });

  await taskRef.update({'currentAssigneeUid': toUid});

  final memberRef = db.collection('homes').doc(homeId).collection('members').doc(uid);
  final memberSnap = await memberRef.get();
  final member = memberSnap.data()!;
  final completed = member['completedCount'] as int? ?? 0;
  final passed = (member['passedCount'] as int? ?? 0) + 1;
  final newCompliance = completed / (completed + passed);

  await memberRef.update({
    'passedCount': FieldValue.increment(1),
    'complianceRate': newCompliance,
  });
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';

  setUp(() async {
    db = FakeFirebaseFirestore();

    await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .set({
      'title': 'Barrer',
      'visualKind': 'emoji',
      'visualValue': '🧹',
      'recurrenceType': 'daily',
      'status': 'active',
      'currentAssigneeUid': 'uid-A',
      'assignmentOrder': ['uid-A', 'uid-B', 'uid-C'],
      'nextDueAt': Timestamp.fromDate(DateTime(2026, 4, 6, 10)),
    });

    for (final uid in ['uid-A', 'uid-B', 'uid-C']) {
      await db
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(uid)
          .set({
        'name': uid,
        'completedCount': 4,
        'passedCount': 0,
        'complianceRate': 1.0,
        'status': 'active',
      });
    }
  });

  test('pasar turno crea evento passed en taskEvents', () async {
    await simulatePass(db, homeId, 'task1', 'uid-A', reason: 'Viaje');

    final events = await db
        .collection('homes')
        .doc(homeId)
        .collection('taskEvents')
        .where('eventType', isEqualTo: 'passed')
        .get();

    expect(events.docs.length, 1);
    expect(events.docs.first.data()['actorUid'], 'uid-A');
    expect(events.docs.first.data()['reason'], 'Viaje');
  });

  test('currentAssigneeUid cambia al siguiente elegible', () async {
    await simulatePass(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-B');
  });

  test('passedCount del miembro se incrementa', () async {
    await simulatePass(db, homeId, 'task1', 'uid-A');

    final member = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-A')
        .get();

    expect(member.data()!['passedCount'], 1);
  });

  test('complianceRate se reduce tras pasar', () async {
    await simulatePass(db, homeId, 'task1', 'uid-A');

    final member = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-A')
        .get();

    // completedCount=4, passedCount=1 → 4/5 = 0.8
    expect(member.data()!['complianceRate'], closeTo(0.8, 0.001));
  });

  test('miembro congelado se salta en la rotación', () async {
    // Congelar uid-B
    await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc('uid-B')
        .update({'status': 'frozen'});

    await simulatePass(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    // uid-B está congelado → debe ir a uid-C
    expect(task.data()!['currentAssigneeUid'], 'uid-C');
  });

  test('sin candidatos eligibles: se asigna a sí mismo', () async {
    // Congelar uid-B y uid-C
    for (final uid in ['uid-B', 'uid-C']) {
      await db
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(uid)
          .update({'status': 'frozen'});
    }

    await simulatePass(db, homeId, 'task1', 'uid-A');

    final task = await db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .doc('task1')
        .get();

    expect(task.data()!['currentAssigneeUid'], 'uid-A');
  });
}
```

- [ ] **Step 3: Correr tests de integración**

```bash
flutter test test/integration/features/tasks/task_completion_test.dart test/integration/features/tasks/pass_turn_test.dart
```

Expected: All 11 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add test/integration/features/tasks/task_completion_test.dart test/integration/features/tasks/pass_turn_test.dart
git commit -m "test(tasks): add integration tests for task completion and pass turn"
```

---

## Verificación Final

- [ ] **Correr todos los tests de la spec**

```bash
flutter test test/unit/features/tasks/assignment_calculator_test.dart test/unit/features/tasks/task_completion_provider_test.dart test/unit/features/tasks/pass_turn_dialog_test.dart test/integration/features/tasks/task_completion_test.dart test/integration/features/tasks/pass_turn_test.dart test/ui/features/tasks/complete_task_dialog_test.dart test/ui/features/tasks/pass_turn_dialog_test.dart
```

Expected: All tests PASS.

- [ ] **Análisis estático completo**

```bash
flutter analyze
```

Expected: No errors.

---

## Pruebas Manuales Requeridas

Ver spec-07 sección "Pruebas manuales requeridas" — incluir resultado en el informe de cierre de spec.
