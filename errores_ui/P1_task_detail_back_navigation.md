# P1 — BACK desde TaskDetail cierra la app en lugar de volver a la lista

## Bug que corrige
- **Bug #32** — Pulsar el botón BACK del sistema Android desde `TaskDetailScreen` cierra la app completamente en lugar de volver a la lista de tareas. El stack de navegación de go_router no retiene la pantalla anterior correctamente al venir desde `/tasks/:id`.

## Causa raíz probable

go_router con `StatefulShellRoute` (para la NavigationBar) puede tener problemas con el back stack cuando se navega a una ruta de detalle:

1. **La ruta `/tasks/:id` es una ruta raíz, no una sub-ruta de `/tasks`**: Si la ruta está definida como hija del router raíz en lugar de hija de `/tasks`, el Navigator raíz no tiene la pantalla de lista como predecesor.

2. **`context.go()` en lugar de `context.push()`**: Si la navegación al detalle se hace con `context.go('/tasks/$id')`, reemplaza el stack completo en lugar de hacer push. Al hacer back, no hay pantalla anterior.

3. **StatefulShellRoute pierde el estado al navegar fuera**: El branch de Tasks del ShellRoute puede perder su historial de navegación al volver desde el detalle.

## Archivos a investigar

| Archivo | Qué buscar |
|---------|-----------|
| `lib/app.dart` | Definición de la ruta `/tasks/:id` y su relación con `/tasks` |
| `lib/features/tasks/presentation/skins/tasks_screen_v2.dart` | Cómo navega al detalle (`context.go` vs `context.push`) |
| `lib/features/tasks/router.dart` | Definición de rutas del feature |

## Cambios requeridos

### 1. Usar `context.push()` en lugar de `context.go()`

En la pantalla de lista de tareas, al navegar al detalle:

```dart
// MAL — reemplaza el stack
onTap: () => context.go('/tasks/${task.id}'),

// BIEN — hace push, permite volver atrás
onTap: () => context.push('/tasks/${task.id}'),
```

### 2. Definir la ruta de detalle como hija de la ruta de lista

En `app.dart` o `features/tasks/router.dart`:

```dart
// MAL — ruta raíz, sin predecesor
GoRoute(
  path: '/tasks/:id',
  builder: (_, state) => TaskDetailScreenV2(id: state.pathParameters['id']!),
),

// BIEN — ruta hija de /tasks
GoRoute(
  path: '/tasks',
  builder: (_, state) => TasksScreenV2(),
  routes: [
    GoRoute(
      path: ':id',         // resulta en /tasks/:id
      builder: (_, state) => TaskDetailScreenV2(id: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'edit',    // resulta en /tasks/:id/edit
          builder: (_, state) => CreateEditTaskScreenV2(editTaskId: state.pathParameters['id']),
        ),
      ],
    ),
  ],
),
```

### 3. Añadir botón Back explícito en la AppBar

Aunque el botón de sistema funcione, añadir un botón de vuelta explícito en `TaskDetailScreenV2` mejora la UX y es consistente con otras pantallas (ver también Bug #28):

```dart
AppBar(
  leading: BackButton(onPressed: () => context.pop()),
  title: Text(task.title),
  // ...actions
),
```

### 4. Verificar con StatefulShellRoute

Si se usa `StatefulShellRoute` para la NavigationBar, asegurarse de que cada branch tiene su propio `navigatorKey`:

```dart
StatefulShellRoute.indexedStack(
  branches: [
    StatefulShellBranch(
      navigatorKey: _tasksNavigatorKey, // ← key única por branch
      routes: [GoRoute(path: '/tasks', ...)],
    ),
    // ...otros branches
  ],
)
```

Con `navigatorKey` por branch, el historial de navegación de Tasks se mantiene aunque el usuario cambie de tab.

## Criterios de aceptación

- [ ] Desde la lista de tareas, pulsar una tarea navega al detalle.
- [ ] Pulsar BACK del sistema desde el detalle vuelve a la lista de tareas.
- [ ] Pulsar el botón Back de la AppBar (si existe) vuelve a la lista de tareas.
- [ ] No se sale de la app al hacer BACK desde el detalle.
- [ ] Cambiar de tab y volver a Tasks mantiene la posición de scroll de la lista.

## Tests requeridos

- Test de integración: navegar a `/tasks` → tap en tarea → `context.currentRoute` es `/tasks/:id` → back → `context.currentRoute` es `/tasks`.
- Test de widget: `TaskDetailScreenV2` tiene `BackButton` en la AppBar.
