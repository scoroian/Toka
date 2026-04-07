# Tasks CRUD — Diseño (Spec-05 revisado)

**Fecha:** 2026-04-07  
**Estado:** Aprobado por el usuario  
**Objetivo:** Implementar CRUD completo de tareas del hogar con motor de recurrencias, rotación de asignados, pantalla "Todas las tareas" como tab principal, y formulario de creación/edición pantalla completa.

---

## 1. Arquitectura y capa de datos

### Dominio (`lib/features/tasks/domain/`)

| Archivo | Contenido |
|---|---|
| `task_status.dart` | Enum `TaskStatus { active, frozen, deleted }` con `fromString` |
| `recurrence_rule.dart` | Sealed union freezed con 7 variantes: `HourlyRule`, `DailyRule`, `WeeklyRule`, `MonthlyFixedRule`, `MonthlyNthRule`, `YearlyFixedRule`, `YearlyNthRule` |
| `task.dart` | `Task` freezed (id, homeId, título, visual, status, recurrencia, asignación, peso, contadores, timestamps) + `TaskInput` DTO para crear/editar |
| `tasks_repository.dart` | Interfaz abstracta: `watchHomeTasks`, `fetchTask`, `createTask`, `updateTask`, `freezeTask`, `unfreezeTask`, `deleteTask` (soft), `reorderAssignees` |
| `task_validator.dart` | `ValidationResult` sealed + `TaskValidator` — valida título no vacío, recurrencia coherente, al menos 1 asignado |

### Utilidades

- `lib/core/utils/recurrence_calculator.dart` — Calculadora pura DST-aware via paquete `timezone`. Calcula `nextDueAt` para cada variante de `RecurrenceRule`. Sin efectos secundarios, 100% testeable.

### Capa de datos (`lib/features/tasks/data/`)

- `task_model.dart` — Convierte `Map<String, dynamic>` (Firestore) ↔ `Task` freezed
- `tasks_repository_impl.dart` — Escribe directamente en `homes/{homeId}/tasks/{taskId}`. Usa `FieldValue.serverTimestamp()` para timestamps. Soft-delete: `deleteTask` establece `status = 'deleted'`.

### Application layer (`lib/features/tasks/application/`)

- `tasks_provider.dart` — `Stream<List<Task>>` con tareas active+frozen del hogar actual; provider del repositorio
- `task_form_provider.dart` — Estado del formulario: modo (create vs edit), campos, errores de validación, `isLoading`
- `recurrence_provider.dart` — Devuelve las próximas N ocurrencias dada una `RecurrenceRule` parcial (para preview en tiempo real)

### Dependencia nueva

```yaml
timezone: ^0.9.4  # DST-aware date calculations
```

---

## 2. Pantallas y navegación

### Nuevo tab en MainShell

`MainShell` pasa de 4 a 5 tabs:

| Índice | Label | Ruta | Icono |
|---|---|---|---|
| 0 | Hoy | `/home` | `Icons.home` |
| 1 | Tareas | `/tasks` | `Icons.task_alt` |
| 2 | Historial | `/history` | `Icons.history` |
| 3 | Miembros | `/members` | `Icons.people` |
| 4 | Ajustes | `/settings` | `Icons.settings` |

### Pantallas nuevas

**`AllTasksScreen`** (`/tasks`)
- Lista tareas activas y congeladas del hogar actual agrupadas en dos secciones
- Cada tarjeta (`TaskCard`) muestra: visual, título, próxima fecha, asignado actual
- FAB `+` en esquina inferior derecha → navega a `/tasks/create`
- Estado vacío con CTA "Crear primera tarea"
- Skeleton loader mientras carga

**`TaskDetailScreen`** (`/tasks/:id`)
- Visual grande + título + descripción
- Sección recurrencia: tipo + próximas 3 ocurrencias
- Sección asignación: modo + lista de miembros en orden
- Botones de acción: **Editar** → `/tasks/:id/edit`, **Congelar/Descongelar**, **Eliminar** (con diálogo de confirmación)
- Fuera del shell (sin NavigationBar), accesible con `context.push()`

**`CreateEditTaskScreen`** (`/tasks/create` y `/tasks/:id/edit`)
- AppBar: "Crear tarea" / "Editar tarea" + botón **Guardar** (deshabilitado durante `isLoading`)
- Fuera del shell (sin NavigationBar)

### Flujos principales

```
AllTasksScreen → [FAB +] → CreateEditTaskScreen (crear)
AllTasksScreen → [tarjeta] → TaskDetailScreen → [Editar] → CreateEditTaskScreen (editar)
TaskDetailScreen → [Eliminar] → diálogo confirmación → pop a AllTasksScreen
TodayScreen → [tap título tarea] → TaskDetailScreen
```

### Rutas en `routes.dart`

```dart
static const String allTasks    = '/tasks';
static const String createTask  = '/tasks/create';
static const String editTask    = '/tasks/:id/edit';
// taskDetail existente ('/task/:id') nunca fue registrado en app.dart ni usado
// Se reemplaza por '/tasks/:id' para coherencia con el nuevo tab
static const String taskDetail  = '/tasks/:id';
```

---

## 3. Formulario y UI de recurrencia

### Campos de `CreateEditTaskScreen`

1. **Visual** (`TaskVisualPicker`) — dos tabs: grid de emojis comunes | iconos Material de categorías del hogar. Obligatorio.
2. **Título** — `TextFormField`, obligatorio, max 60 chars
3. **Descripción** — `TextFormField`, opcional, multilínea, max 300 chars
4. **Recurrencia** — `DropdownButton` con los 7 tipos + sub-formulario contextual (`RecurrenceForm`):
   - *Hourly*: cada N horas, hora inicio (HH:mm), hora fin opcional
   - *Daily*: cada N días, hora
   - *Weekly*: checkboxes días de la semana, hora
   - *Monthly Fixed*: día del mes (1–31), hora
   - *Monthly Nth*: Nth semana (1–4) + día de semana, hora
   - *Yearly Fixed*: mes + día, hora
   - *Yearly Nth*: mes + Nth semana + día de semana, hora
   - Todos incluyen selector de timezone (default: timezone del dispositivo)
5. **Preview de próximas ocurrencias** — 3 fechas calculadas en tiempo real via `recurrenceProvider`, se actualiza al cambiar cualquier campo de recurrencia
6. **Asignación** (`AssignmentForm`):
   - Modo: Rotación básica | Distribución inteligente
   - Lista reordenable de miembros del hogar con checkboxes
7. **Peso de dificultad** — `Slider` 0.5–3.0, visible solo en modo Distribución inteligente

### Validación

- Inline: errores bajo cada campo al intentar guardar
- `TaskValidator` valida antes de llamar al repositorio
- Botón Guardar deshabilitado durante `isLoading: true`

---

## 4. Gestión de errores y tests

### Estados y errores

| Pantalla | Loading | Error | Vacío |
|---|---|---|---|
| `AllTasksScreen` | Skeleton loader | Mensaje + retry | CTA "Crear primera tarea" |
| `CreateEditTaskScreen` | Botón Guardar deshabilitado | Snackbar + errores inline | — |
| `TaskDetailScreen` | Indicador inline | Mensaje + retry | — |

- Congelar/Descongelar: feedback visual inmediato (optimistic update)
- Eliminar: diálogo de confirmación obligatorio antes de ejecutar

### Tests

| Tipo | Archivo | Casos cubiertos |
|---|---|---|
| Unitario | `recurrence_calculator_test.dart` | Todas las reglas, DST, timezone |
| Unitario | `task_validator_test.dart` | Casos felices y errores por campo |
| Integración | `tasks_crud_test.dart` | CRUD completo contra `fake_cloud_firestore`, soft-delete, reorder |
| UI | `all_tasks_screen_test.dart` | Lista con datos, estado vacío, skeleton |
| UI | `create_task_screen_test.dart` | Validación, submit exitoso, submit con error |

---

## 5. Decisiones clave

- **Opción A confirmada**: Firestore directo para CRUD; Cloud Functions solo para operaciones complejas (completar, pasar turno, reasignar)
- **Soft delete**: `deleteTask` establece `status = 'deleted'`, nunca borra el documento
- **Timezone**: paquete `timezone` con `initializeTimeZones()` en `main.dart`
- **HomeLimits.isPremium**: se añade para que el formulario pueda mostrar/ocultar features premium
- `taskDetail` ruta existente (`/task/:id`) se migra a `/tasks/:id` para coherencia con el nuevo tab
