# P0 — Sin botón de edición de tarea en la UI

## Bug que corrige
- **Bug #31** — `TaskDetailScreenV2` no tiene botón "Editar" en la AppBar ni en el cuerpo de la pantalla. La ruta `/task/:id/edit` existe en `app.dart:209` y `CreateEditTaskScreenV2(editTaskId)` está implementada, pero **ningún punto de la UI navega a ella**. Las tareas no se pueden editar desde la interfaz.

## Causa raíz

La ruta de edición fue implementada a nivel de router pero no se conectó ningún punto de entrada en la UI:
- `app.dart:209`: `GoRoute(path: '/task/:id/edit', builder: (_, state) => CreateEditTaskScreenV2(editTaskId: state.pathParameters['id']))`
- `TaskDetailScreenV2`: AppBar sin IconButton de edición.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` | Añadir botón "Editar" en AppBar (condicional por rol) |

## Cambio requerido

En `TaskDetailScreenV2`, añadir un `IconButton` en la `AppBar` que navegue a la ruta de edición. El botón debe mostrarse solo para usuarios con rol `owner` o `admin`:

```dart
AppBar(
  title: Text(task.title),
  leading: const BackButton(),
  actions: [
    // Solo owner y admin pueden editar
    if (canEdit)
      IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: l10n.editTask, // clave ARB: editTask
        onPressed: () => context.push('/task/${task.id}/edit'),
      ),
    // Menú de más opciones (Freeze, Delete) — solo si existen
    if (canManage)
      PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(value),
        itemBuilder: (_) => [
          if (canFreeze)
            PopupMenuItem(value: 'freeze', child: Text(l10n.freezeTask)),
          if (canDelete)
            PopupMenuItem(value: 'delete', child: Text(l10n.deleteTask)),
        ],
      ),
  ],
),
```

### Lógica de permisos

```dart
// Dentro del widget, obtener el rol del usuario actual
final currentRole = ref.watch(currentMemberRoleProvider);
final bool canEdit = currentRole == MemberRole.owner || currentRole == MemberRole.admin;
final bool canManage = canEdit; // mismo criterio o ajustar según reglas de negocio
```

### Claves ARB requeridas

Añadir en `l10n/app_es.arb`, `app_en.arb` y `app_ro.arb`:

```json
"editTask": "Editar tarea",
"@editTask": { "description": "Tooltip/label for the edit task button" }
```

## Criterios de aceptación

- [ ] Owner ve el botón "Editar" (icono lápiz) en la AppBar del detalle de tarea.
- [ ] Admin ve el botón "Editar" en la AppBar del detalle de tarea.
- [ ] Member NO ve el botón "Editar".
- [ ] Al pulsar "Editar", navega a `CreateEditTaskScreenV2` con los datos de la tarea pre-rellenos.
- [ ] Guardar los cambios actualiza la tarea y vuelve al detalle.
- [ ] Las 3 traducciones (es, en, ro) están presentes para la clave `editTask`.

## Tests requeridos

- Test de widget: `TaskDetailScreenV2` con rol Owner → botón Editar presente.
- Test de widget: `TaskDetailScreenV2` con rol Member → botón Editar ausente.
- Test de integración: pulsar Editar → modificar título → Guardar → verificar que el detalle muestra el nuevo título.
