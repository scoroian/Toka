# P2 — Validación silenciosa en formulario de crear/editar tarea

## Bugs que corrige
- **Bug #11** — El botón "Guardar" se desactiva silenciosamente cuando no hay miembros asignados. El usuario no sabe qué le falta para poder guardar.
- **Bug #22** — Si se deseleccionan todos los miembros, "Guardar" se desactiva sin mensaje. Al reactivar "Rotar al siguiente" con solo 1 miembro, la UI no limpia el estado de rotación.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` | Añadir mensajes de validación |
| `lib/features/tasks/application/task_form_provider.dart` | Lógica de validación |

## Cambios requeridos

### 1. Mostrar mensaje de validación junto al selector de miembros

Cuando el botón "Guardar" está desactivado por falta de miembros, mostrar un hint visible:

```dart
// En el bloque del selector de miembros
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // ... selector de miembros (chips)
    if (selectedMembers.isEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n.assignAtLeastOneMember,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
  ],
),
```

### 2. Botón "Guardar" con tooltip cuando está desactivado

```dart
Tooltip(
  message: _getValidationMessage(formState),
  child: FilledButton(
    onPressed: formState.isValid ? _onSave : null,
    child: Text(l10n.save),
  ),
),

String _getValidationMessage(TaskFormState state) {
  if (state.selectedMembers.isEmpty) return l10n.assignAtLeastOneMember;
  if (state.title.isEmpty) return l10n.taskTitleRequired;
  return '';
}
```

### 3. Limpiar estado de rotación al reducir a 1 miembro

En `task_form_provider.dart`, cuando el usuario elimina miembros y queda solo 1:

```dart
// En el método que actualiza los miembros seleccionados
void toggleMember(String uid) {
  final current = state.selectedMembers.toList();
  if (current.contains(uid)) {
    current.remove(uid);
  } else {
    current.add(uid);
  }
  
  // Si queda 1 o menos miembros, desactivar rotación
  final shouldDisableRotation = current.length < 2;
  
  state = state.copyWith(
    selectedMembers: current,
    rotationEnabled: shouldDisableRotation ? false : state.rotationEnabled,
  );
}
```

En la UI, deshabilitar el switch de rotación cuando hay menos de 2 miembros:

```dart
SwitchListTile(
  title: Text(l10n.rotateAssignment),
  value: state.rotationEnabled,
  onChanged: state.selectedMembers.length >= 2
      ? (v) => ref.read(taskFormProvider.notifier).setRotation(v)
      : null, // deshabilitado si < 2 miembros
  subtitle: state.selectedMembers.length < 2
      ? Text(l10n.rotationRequiresTwoMembers,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
      : null,
),
```

### 4. Claves ARB requeridas

```json
"assignAtLeastOneMember": "Asigna al menos un miembro a la tarea.",
"taskTitleRequired": "El título de la tarea es obligatorio.",
"rotationRequiresTwoMembers": "La rotación requiere al menos 2 miembros."
```

## Criterios de aceptación

- [ ] Al deseleccionar todos los miembros, aparece el texto de error "Asigna al menos un miembro" debajo del selector.
- [ ] El botón "Guardar" tiene un tooltip explicativo cuando está desactivado.
- [ ] El switch "Rotar al siguiente" se desactiva automáticamente al reducir a 1 miembro.
- [ ] El switch "Rotar al siguiente" muestra el subtexto "Requiere 2 miembros" cuando hay solo 1.
- [ ] Volver a seleccionar 2 miembros habilita de nuevo el switch de rotación.

## Tests requeridos

- Test unitario: `TaskFormNotifier.toggleMember()` — al quedar 1 miembro → `rotationEnabled = false`.
- Test de widget: formulario con 0 miembros → texto de error visible, botón Guardar desactivado.
- Test de widget: formulario con 1 miembro → switch de rotación deshabilitado.
- Test de widget: formulario con 2 miembros y campos válidos → botón Guardar habilitado.
