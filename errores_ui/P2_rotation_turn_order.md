# P2 — Sin opción de elegir quién empieza el turno en tareas con rotación

## Bug + Mejora que aborda
- **Bug #21** — Al crear una tarea con rotación habilitada y dos miembros asignados, la asignación inicial del turno no es configurable: siempre empieza por el primer miembro de la lista. No hay opción para elegir quién va primero.
- **Mejora #9** — Permitir elegir quién empieza el turno al crear una tarea con rotación.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` | Añadir selector de miembro inicial |
| `lib/features/tasks/application/task_form_provider.dart` | Añadir campo `initialAssigneeUid` |
| `lib/features/tasks/domain/task.dart` | Añadir campo `currentAssigneeUid` (si no existe) |

## Cambios requeridos

### 1. Añadir campo en el estado del formulario

En `task_form_provider.dart`:

```dart
@freezed
class TaskFormState with _$TaskFormState {
  const factory TaskFormState({
    // ... campos existentes
    @Default([]) List<String> selectedMembers,
    @Default(false) bool rotationEnabled,
    String? initialAssigneeUid, // ← NUEVO
  }) = _TaskFormState;
}
```

### 2. Añadir selector de miembro inicial en el formulario

Cuando `rotationEnabled == true` y `selectedMembers.length >= 2`, mostrar un selector de quién empieza:

```dart
if (formState.rotationEnabled && formState.selectedMembers.length >= 2) ...[
  const SizedBox(height: 12),
  Text(l10n.whoStartsFirst, style: Theme.of(context).textTheme.labelLarge),
  const SizedBox(height: 8),
  // Selector de miembro inicial
  Wrap(
    spacing: 8,
    children: formState.selectedMembers.map((uid) {
      final member = members.firstWhere((m) => m.uid == uid);
      final isSelected = (formState.initialAssigneeUid ?? formState.selectedMembers.first) == uid;
      return ChoiceChip(
        label: Text(member.nickname),
        selected: isSelected,
        onSelected: (_) => ref.read(taskFormProvider.notifier).setInitialAssignee(uid),
      );
    }).toList(),
  ),
],
```

### 3. Propagar `initialAssigneeUid` al crear la tarea

En el repository/use case de creación de tarea:

```dart
// En TaskRepository.createTask()
await _firestore.collection('homes/$homeId/tasks').add({
  // ... otros campos
  'currentAssigneeUid': formState.initialAssigneeUid ?? formState.selectedMembers.first,
  'rotationOrder': formState.selectedMembers, // orden completo de rotación
});
```

### 4. Cloud Function: respetar el turno inicial

En la CF de creación de tarea o en `apply_task_completion.ts`, al pasar al siguiente turno:

```typescript
// Calcular el siguiente en la rotación
const rotationOrder: string[] = taskData.rotationOrder;
const currentIndex = rotationOrder.indexOf(taskData.currentAssigneeUid);
const nextIndex = (currentIndex + 1) % rotationOrder.length;
const nextAssigneeUid = rotationOrder[nextIndex];
```

### 5. Claves ARB requeridas

```json
"whoStartsFirst": "¿Quién empieza?",
"@whoStartsFirst": {
  "description": "Label for the initial assignee selector in rotation task form"
}
```

## Criterios de aceptación

- [ ] Al activar rotación con 2+ miembros, aparece la sección "¿Quién empieza?" con chips de selección.
- [ ] Por defecto está seleccionado el primer miembro de la lista.
- [ ] Al seleccionar otro miembro, el estado del formulario se actualiza.
- [ ] La tarea creada tiene `currentAssigneeUid` igual al miembro seleccionado.
- [ ] En `TaskDetailScreen`, "Próximas fechas" muestra el orden correcto empezando por el miembro seleccionado.

## Tests requeridos

- Test unitario: `TaskFormNotifier.setInitialAssignee(uid)` → `state.initialAssigneeUid == uid`.
- Test de widget: formulario con rotación activada y 2 miembros → selector "¿Quién empieza?" visible.
- Test de integración: crear tarea con `initialAssigneeUid = memberB` → primer slot en Firestore asignado a memberB.
