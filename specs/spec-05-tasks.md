# Spec-05: Modelo de tareas y CRUD básico

**Dependencias previas:** Spec-00 → Spec-04  
**Oleada:** Oleada 1

---

## Objetivo

Implementar el modelo de tareas completo con CRUD (crear, leer, actualizar, eliminar/congelar), motor de recurrencia básico (sin inteligencia, sin rotación avanzada), identidad visual (icono/emoji), y pantalla "Todas las tareas".

---

## Reglas de negocio

1. Una tarea tiene: título, descripción opcional, identidad visual (icono o emoji), tipo de recurrencia, regla de recurrencia, asignación, y peso de dificultad.
2. Las tareas **no pueden usar imágenes personalizadas** — solo iconos del sistema o emojis.
3. En **Free**: máximo 4 tareas activas, máximo 3 recurrentes automáticas.
4. En **Premium**: tareas activas ilimitadas.
5. Solo `owner` y `admin` pueden crear, editar o congelar tareas.
6. Congelar una tarea la saca de la rotación sin borrarla.
7. Borrar una tarea es una acción destructiva que requiere confirmación y deja rastro auditable.
8. `nextDueAt` se calcula automáticamente al crear o completar una tarea.
9. El `currentAssigneeUid` puede ser null si no hay miembros o la rotación está pendiente.

---

## Motor de recurrencia (básico — sin smartDistribution)

El motor calcula `nextDueAt` dado un `RecurrenceRule` y una fecha base:

```dart
// core/utils/recurrence_calculator.dart
class RecurrenceCalculator {
  static DateTime calculateNextDue(RecurrenceRule rule, DateTime from);
  static List<DateTime> getUpcomingOccurrences(RecurrenceRule rule, DateTime from, int count);
  static bool isDueToday(DateTime nextDueAt);
  static bool isOverdue(DateTime nextDueAt);
}
```

### Tipos de recurrencia

| Tipo | Ejemplo |
|------|---------|
| `hourly` | Cada 2h, entre 08:00 y 20:00 |
| `daily` | Cada día a las 09:00 |
| `weekly` | Lunes y jueves a las 19:00 |
| `monthly` | Día 15 de cada mes, o "2º jueves" |
| `yearly` | 21 de marzo, o "3er domingo de marzo" |

Todas las reglas incluyen `timezone` (ej: `"Europe/Madrid"`).

---

## Archivos a crear

```
lib/features/tasks/
├── data/
│   ├── tasks_repository_impl.dart
│   └── task_model.dart
├── domain/
│   ├── tasks_repository.dart
│   ├── task.dart                        (modelo freezed)
│   ├── recurrence_rule.dart             (modelo freezed + union types)
│   └── task_status.dart                 (enum)
├── application/
│   ├── tasks_provider.dart
│   ├── task_form_provider.dart          (estado del formulario de crear/editar)
│   └── recurrence_provider.dart
└── presentation/
    ├── all_tasks_screen.dart
    ├── task_detail_screen.dart
    ├── create_edit_task_screen.dart
    └── widgets/
        ├── task_card.dart
        ├── task_visual_picker.dart      (icono/emoji)
        ├── recurrence_form.dart
        └── assignment_form.dart

lib/core/utils/
└── recurrence_calculator.dart
```

---

## Implementación

### Modelo RecurrenceRule (union type)

```dart
@freezed
sealed class RecurrenceRule with _$RecurrenceRule {
  const factory RecurrenceRule.hourly({
    required int every,
    required String startTime,   // "HH:mm"
    String? endTime,
    required String timezone,
  }) = HourlyRule;
  
  const factory RecurrenceRule.daily({
    required int every,
    required String time,
    required String timezone,
  }) = DailyRule;
  
  const factory RecurrenceRule.weekly({
    required List<String> weekdays,  // ["MON","THU"]
    required String time,
    required String timezone,
  }) = WeeklyRule;
  
  const factory RecurrenceRule.monthlyFixed({
    required int day,
    required String time,
    required String timezone,
  }) = MonthlyFixedRule;
  
  const factory RecurrenceRule.monthlyNth({
    required int weekOfMonth,   // 1-4
    required String weekday,    // "MON"-"SUN"
    required String time,
    required String timezone,
  }) = MonthlyNthRule;
  
  const factory RecurrenceRule.yearlyFixed({
    required int month,
    required int day,
    required String time,
    required String timezone,
  }) = YearlyFixedRule;
  
  const factory RecurrenceRule.yearlyNth({
    required int month,
    required int weekOfMonth,
    required String weekday,
    required String time,
    required String timezone,
  }) = YearlyNthRule;
}
```

### Modelo Task

```dart
@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String homeId,
    required String title,
    String? description,
    required String visualKind,    // "icon" | "emoji"
    required String visualValue,
    required TaskStatus status,
    required String recurrenceType,
    required RecurrenceRule recurrenceRule,
    required String assignmentMode,  // "basicRotation" | "smartDistribution"
    required List<String> assignmentOrder,  // UIDs en orden
    String? currentAssigneeUid,
    required DateTime nextDueAt,
    required double difficultyWeight,
    required int completedCount90d,
    required String createdByUid,
    required DateTime updatedAt,
    required DateTime createdAt,
  }) = _Task;
}

enum TaskStatus { active, frozen, deleted }
```

### TasksRepository

```dart
abstract interface class TasksRepository {
  Stream<List<Task>> watchHomeTasks(String homeId);
  Future<Task> fetchTask(String homeId, String taskId);
  Future<String> createTask(String homeId, TaskInput input);
  Future<void> updateTask(String homeId, String taskId, TaskInput input);
  Future<void> freezeTask(String homeId, String taskId);
  Future<void> deleteTask(String homeId, String taskId);
  Future<void> reorderAssignees(String homeId, String taskId, List<String> order);
}
```

### TaskInput (DTO para crear/editar)

```dart
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
    required double difficultyWeight,
  }) = _TaskInput;
}
```

### Validaciones al crear tarea

```dart
class TaskValidator {
  static ValidationResult validate(TaskInput input, HomeLimits limits, int currentActiveCount) {
    if (input.title.trim().isEmpty) return ValidationResult.error('title_required');
    if (input.title.length > 60) return ValidationResult.error('title_too_long');
    if (!limits.isPremium && currentActiveCount >= 4) return ValidationResult.error('free_task_limit');
    if (input.assignmentOrder.isEmpty) return ValidationResult.error('no_assignees');
    return ValidationResult.ok();
  }
}
```

### Pantalla "Todas las tareas"

- Filtros: estado (activas/congeladas), recurrencia, responsable actual.
- Ordenación: por `nextDueAt` (default), por nombre.
- Al tocar una tarea → `TaskDetailScreen`.
- FAB "+" para crear tarea (solo owner/admin).
- Swipe left → congelar/reactivar.
- Swipe right → eliminar (con diálogo de confirmación).

### Pantalla "Detalle de tarea"

- Nombre, descripción, identidad visual, recurrencia.
- Responsable actual + orden de rotación.
- Próxima ocurrencia.
- Botón "Editar" (solo owner/admin).
- Historial de la tarea (últimos completados y pases — preparado, llenado en spec-09).

### Pantalla "Crear/Editar tarea"

Secciones del formulario:
1. Identidad: picker de icono/emoji + campo de nombre.
2. Descripción (opcional).
3. Recurrencia: selector de tipo + campos dinámicos según tipo.
4. Asignación: lista de miembros con checkboxes para incluir en rotación, drag para reordenar.
5. Dificultad: slider 1-5.

---

## Tests requeridos

### Unitarios

**`test/unit/features/tasks/recurrence_calculator_test.dart`**
- `calculateNextDue` para cada tipo de regla con múltiples casos:
  - hourly: calcula la siguiente franja correctamente.
  - daily: calcula el próximo día correcto.
  - weekly: calcula el próximo día de la semana correcto, incluyendo salto de semana.
  - monthlyFixed: día 31 en mes de 30 días → ajusta al último día.
  - monthlyNth: "2º jueves" de febrero.
  - yearlyFixed: 29 de febrero en año no bisiesto → fallback.
  - yearlyNth: "3er domingo de marzo".
- `isDueToday`: devuelve true/false correctamente.
- `isOverdue`: tarea vencida antes de ahora → true.
- Timezones: una tarea en `Europe/Madrid` se calcula correctamente con DST.

**`test/unit/features/tasks/task_validator_test.dart`**
- Título vacío → error.
- Título > 60 chars → error.
- Free plan con 4 tareas activas → error al crear la 5ª.
- Sin asignados → error.
- Todos válidos → ok.

**`test/unit/features/tasks/tasks_repository_test.dart`** (mocktail)
- `watchHomeTasks` emite lista de tareas activas.
- `createTask` llama a Firestore con los campos correctos.
- `freezeTask` actualiza status a `frozen`.
- `deleteTask` actualiza status a `deleted` y crea evento auditable.

### De integración

**`test/integration/features/tasks/tasks_crud_test.dart`** (emuladores)
- Crear tarea → documento en `homes/{id}/tasks/{id}` con todos los campos.
- `nextDueAt` calculado correctamente.
- Congelar tarea → status `frozen`, desaparece de listas activas.
- Borrar tarea → status `deleted`, no aparece en ningún listado.
- Free plan: crear 5ª tarea → rechazada.

### UI

**`test/ui/features/tasks/all_tasks_screen_test.dart`**
- Lista de tareas renderiza nombre e icono/emoji.
- Filtro por responsable filtra correctamente.
- FAB visible para admin, no visible para miembro.
- Estado vacío muestra mensaje.
- Golden test con lista de 5 tareas.

**`test/ui/features/tasks/create_task_screen_test.dart`**
- Formulario muestra campos dinámicos según tipo de recurrencia.
- "Guardar" sin título → error de validación.
- Picker de emoji abre y selecciona correctamente.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Crear tarea diaria:**
   - Ir a "Tareas" → "+" → Nombre: "Fregar", tipo: Diaria a las 20:00.
   - Asignar a todos los miembros en rotación.
   - Guardar → aparece en la lista.
   - Verificar en Firestore: documento en `homes/{id}/tasks/{id}` con `nextDueAt` correcto (mañana a las 20:00 si ya pasó hoy).

2. **Crear tarea semanal:**
   - Crear tarea "Aspirar" → tipo semanal → lunes y jueves a las 18:00.
   - Verificar que `nextDueAt` apunta al próximo lunes o jueves (el que toque antes).

3. **Crear tarea mensual (Nth):**
   - Crear "Limpiar nevera" → mensual → 2º jueves a las 10:00.
   - Verificar `nextDueAt`.

4. **Límite Free:**
   - En un hogar Free, crear 4 tareas activas.
   - Intentar crear la 5ª → mensaje de "límite alcanzado en plan Free".

5. **Congelar tarea:**
   - Deslizar una tarea → "Congelar".
   - Confirmar → la tarea desaparece de la lista activa.
   - Cambiar filtro a "Congeladas" → aparece allí.

6. **Eliminar tarea:**
   - Deslizar → "Eliminar" → diálogo de confirmación.
   - Confirmar → desaparece de todas las listas.

7. **Identidad visual:**
   - Al crear una tarea, probar el picker de emoji → seleccionar 🏠.
   - Probar el picker de icono → seleccionar un icono del sistema.
   - La tarjeta de tarea debe mostrar el emoji/icono correctamente.
