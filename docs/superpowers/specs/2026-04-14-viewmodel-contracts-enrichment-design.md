# ViewModel Contracts Enrichment — Toka

**Fecha:** 2026-04-14  
**Estado:** Aprobado  
**Objetivo:** Enriquecer los contratos de ViewModel de todas las pantallas principales para que cada skin tenga garantía en tiempo de compilación de exponer exactamente los datos que necesita, sin lógica de negocio en los screens.

---

## Contexto

La arquitectura MVVM con contratos (abstract class) ya está implementada según `2026-04-07-mvvm-skin-design.md`. Este documento **no cambia la arquitectura** — extiende los contratos existentes con los campos y acciones que faltaban para que cada pantalla sea completamente autosuficiente a partir de su ViewModel.

Enfoque elegido: **spec única + sub-planes por feature**. Un solo documento de referencia, implementación en trozos independientes por feature.

---

## Principios aplicados

- Los ViewModels **nunca** importan GoRouter ni BuildContext.
- El dominio no recibe campos de presentación. Los joins (nombre del actor, foto) se resuelven en el ViewModel y se exponen en clases de presentación (`*Item`, `*ViewData`).
- El estado de UI efímero (dropdown abierto, modo selección visible) se gestiona localmente en el screen, no en el ViewModel, **excepto** cuando ese estado afecta a datos que el ViewModel necesita computar (p. ej. `selectedIds` afecta a `bulkDelete`).
- `canRate` y `showApplyToday` son booleanos derivados computados en el ViewModel — el screen no evalúa condiciones de negocio.

---

## Sección 1 — Cambio de dominio

### `HomeMembership` — un campo nuevo

```dart
// lib/features/homes/domain/home_membership.dart
@freezed
class HomeMembership with _$HomeMembership {
  const factory HomeMembership({
    required String homeId,
    required String homeNameSnapshot,
    required MemberRole role,
    required BillingState billingState,
    required MemberStatus status,
    required DateTime joinedAt,
    DateTime? leftAt,
    @Default(false) bool hasPendingToday,  // ← nuevo: escrito por Cloud Function
  }) = _HomeMembership;
}
```

**Escrito por:** la Cloud Function `update_dashboard` al recalcular el dashboard de cada hogar. Para cada miembro del hogar, actualiza `users/{uid}/memberships/{homeId}.hasPendingToday = (tasksDueToday > tasksDoneToday)`.

Todos los demás cambios necesarios se resuelven en la capa Application mediante clases de presentación, sin tocar domain/.

---

## Sección 2 — Patrón de enriquecimiento

Cuando el ViewModel necesita datos que no están en el modelo de dominio (nombre del actor, si ya se valoró un evento), construye una **clase de presentación intermedia** que vive en `application/`, no en `domain/`.

```dart
// Ejemplo: TaskEventItem vive en history/application/history_view_model.dart
class TaskEventItem {
  final TaskEvent raw;          // evento original del dominio
  final String    actorName;    // resuelto desde homeMembersProvider
  final String?   actorPhotoUrl;
  final bool      isOwnEvent;   // raw.actorUid == currentUid
  final bool      isRated;      // leído de homes/{homeId}/taskRatings donde raterUid == currentUid
  final bool      canRate;      // raw is CompletedEvent && !isOwnEvent && !isRated
}
```

El screen consume `TaskEventItem`, nunca `TaskEvent` directamente.

---

## Sección 3 — Contratos por ViewModel

### 3.1 `TodayViewModel` — añadir selector de hogares

**Clase nueva:**

```dart
// lib/features/tasks/application/today_view_model.dart
class HomeDropdownItem {
  const HomeDropdownItem({
    required this.homeId,
    required this.name,
    required this.emoji,
    required this.role,
    required this.hasPendingToday,
    required this.isSelected,
  });
  final String     homeId;
  final String     name;
  final String     emoji;
  final MemberRole role;
  final bool       hasPendingToday;  // punto rojo sin número
  final bool       isSelected;
}
```

**Contrato actualizado:**

```dart
abstract class TodayViewModel {
  AsyncValue<TodayViewData?> get viewData;
  List<HomeDropdownItem>     get homes;          // ← nuevo
  void selectHome(String homeId);                // ← nuevo
  Future<void> completeTask(String taskId);
  Future<({double complianceBefore, double estimatedAfter})> fetchPassStats(String currentUid);
  Future<void> passTurn(String taskId, {String? reason});
  void retry();
}
```

**Fuente de datos:** `homes` se construye combinando `userMembershipsProvider(uid)` (para obtener todos los hogares del usuario con `hasPendingToday`) con `homesProvider` (para obtener nombre y emoji). El estado del dropdown (abierto/cerrado) es local al screen.

**Navegación desde el dropdown:** los botones "Crear hogar" y "Unirse con código" son navegación pura — el screen hace `context.go(AppRoutes.createHome)` / `context.go(AppRoutes.joinHome)` directamente, sin pasar por el ViewModel.

---

### 3.2 `HistoryViewModel` — enriquecer eventos con `TaskEventItem`

**Clase nueva:**

```dart
// lib/features/history/application/history_view_model.dart
class TaskEventItem {
  const TaskEventItem({
    required this.raw,
    required this.actorName,
    this.actorPhotoUrl,
    required this.isOwnEvent,
    required this.isRated,
    required this.canRate,
  });
  final TaskEvent raw;
  final String    actorName;
  final String?   actorPhotoUrl;
  final bool      isOwnEvent;
  final bool      isRated;
  final bool      canRate;  // raw is CompletedEvent && !isOwnEvent && !isRated
}
```

**Contrato actualizado:**

```dart
abstract class HistoryViewModel {
  AsyncValue<List<TaskEventItem>> get items;    // ← era List<TaskEvent>
  HistoryFilter get filter;
  bool get hasMore;
  bool get isPremium;
  void loadMore();
  void applyFilter(HistoryFilter newFilter);
  Future<void> rateEvent(String eventId, double rating, {String? note});  // ← nuevo
}
```

**Regla de negocio `canRate`:** solo `true` cuando el evento es `CompletedEvent`, el actor no es el usuario logueado, y el usuario aún no ha valorado ese evento.

**Fuente de `isRated`:** colección `homes/{homeId}/taskRatings` filtrada por `raterUid == currentUid && eventId == event.id`. La implementación puede cachear las valoraciones propias del usuario en el notifier para evitar lecturas repetidas.

---

### 3.3 `MembersViewModel` — sin cambios de contrato

`Member` ya expone todos los campos necesarios: `complianceRate`, `role`, `photoUrl`, `status`. La pantalla lee directamente de `viewData.activeMembers` y `viewData.frozenMembers`.

---

### 3.4 `MemberProfileViewModel` — exponer estadísticas y overflow del radar

**Clase nueva:**

```dart
// lib/features/members/application/member_profile_view_model.dart
class OverflowEntry {
  const OverflowEntry({
    required this.taskId,
    required this.title,
    required this.visualKind,
    required this.visualValue,
    required this.averageScore,
  });
  final String taskId;
  final String title;
  final String visualKind;
  final String visualValue;
  final double averageScore;  // 0.0–10.0
}
```

**`MemberProfileViewData` actualizado:**

```dart
class MemberProfileViewData {
  const MemberProfileViewData({
    required this.member,
    required this.isSelf,
    required this.visiblePhone,
    required this.compliancePct,
    required this.radarEntries,
    required this.canManageRoles,
    required this.completedCount,    // ← member.tasksCompleted
    required this.streakCount,       // ← member.currentStreak
    required this.averageScore,      // ← member.averageScore
    required this.showRadar,         // ← radarEntries.length >= 3
    required this.overflowEntries,   // ← tareas fuera del radar
  });
  final Member member;
  final bool   isSelf;
  final String? visiblePhone;
  final String  compliancePct;
  final List<RadarEntry>    radarEntries;
  final bool                canManageRoles;
  final int                 completedCount;
  final int                 streakCount;
  final double              averageScore;
  final bool                showRadar;
  final List<OverflowEntry> overflowEntries;
}
```

**Lógica del radar (en el ViewModel):**

```
tareas = tareas asignadas al miembro, ordenadas:
  1. Activas primero (status == active)
  2. Por frecuencia de ocurrencias completadas (descendente)

if tareas.length < 3:
  showRadar = false, radarEntries = [], overflowEntries = tareas como OverflowEntry
elif tareas.length <= 10:
  showRadar = true, radarEntries = todas, overflowEntries = []
else:
  showRadar = true, radarEntries = tareas.take(10), overflowEntries = tareas.skip(10)
```

**Contrato sin cambios de métodos** (solo se extiende `MemberProfileViewData`).

---

### 3.5 `AllTasksViewModel` — añadir selección múltiple y renombrar `canCreate`

**`AllTasksViewData` actualizado:**

```dart
class AllTasksViewData {
  const AllTasksViewData({
    required this.tasks,
    required this.filter,
    required this.canManage,  // ← renombrado de canCreate
    required this.uid,
    required this.homeId,
  });
  final List<Task>    tasks;
  final AllTasksFilter filter;
  final bool          canManage;
  final String        uid;
  final String        homeId;
}
```

**Contrato actualizado:**

```dart
abstract class AllTasksViewModel {
  AsyncValue<AllTasksViewData?> get viewData;
  Set<String> get selectedIds;                    // ← nuevo
  bool        get isSelectionMode;                // ← selectedIds.isNotEmpty
  void setStatusFilter(TaskStatus s);
  void setAssigneeFilter(String? uid);
  void toggleSelection(String taskId);            // ← nuevo
  void clearSelection();                          // ← nuevo
  Future<void> toggleFreeze(Task task);
  Future<void> deleteTask(Task task);
  Future<void> bulkDelete();                      // ← nuevo
  Future<void> bulkFreeze();                      // ← nuevo
}
```

**Regla de negocio:** `bulkDelete` y `bulkFreeze` solo ejecutan si `canManage == true`. El screen oculta los botones si `!canManage`, pero el ViewModel también guarda la verificación internamente.

**Fecha mostrada por tarea:** si la tarea está atrasada (`task.nextDueAt < hoy`) se muestra la fecha original + indicador "atrasada". Si no está atrasada, se muestra `task.nextDueAt`. El screen no computa esto — el ViewModel expone `task.nextDueAt` e `isOverdue` (ya en `Task`).

---

### 3.6 `CreateEditTaskViewModel` — nuevo

**Clases auxiliares:**

```dart
// lib/features/tasks/application/create_edit_task_view_model.dart

enum VisualTab { emoji, icon }

class MemberOrderItem {
  const MemberOrderItem({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.isAssigned,
    required this.position,
  });
  final String  uid;
  final String  name;
  final String? photoUrl;
  final bool    isAssigned;
  final int     position;    // posición en la rotación (0-based), ignorado si !isAssigned
}

class UpcomingDateItem {
  const UpcomingDateItem({required this.date, this.assigneeName});
  final DateTime date;
  final String?  assigneeName;
}
```

**Contrato completo:**

```dart
abstract class CreateEditTaskViewModel {
  // ── Estado ──
  String         get selectedVisualKind;   // 'emoji' | 'icon'
  String         get selectedVisualValue;
  VisualTab      get activeTab;
  String         get name;
  String         get description;
  RecurrenceRule get recurrenceRule;
  bool           get hasFixedTime;
  TimeOfDay?     get fixedTime;
  /// true cuando hasFixedTime && fixedTime aún no ha pasado hoy.
  /// Aplica tanto en creación como en edición.
  bool           get showApplyToday;
  bool           get applyToday;
  List<UpcomingDateItem> get upcomingDates;   // próximas 3 fechas con asignado
  List<MemberOrderItem>  get orderedMembers;  // todos los miembros del hogar
  TaskDifficulty get difficulty;
  /// true cuando name.isNotEmpty && al menos 1 miembro tiene isAssigned == true
  bool           get canSave;
  bool           get isEditing;              // false = crear, true = editar

  // ── Acciones ──
  void selectVisual(String kind, String value);
  void setActiveTab(VisualTab tab);
  void setName(String value);
  void setDescription(String value);
  void setRecurrenceRule(RecurrenceRule rule);
  void setHasFixedTime(bool value);
  void setFixedTime(TimeOfDay? time);
  void setApplyToday(bool value);
  void toggleMember(String uid);
  void reorderMember(int fromIndex, int toIndex);
  void setDifficulty(TaskDifficulty d);
  Future<void> save();
}
```

**`upcomingDates`** se recalcula reactivamente cada vez que cambia `recurrenceRule`, `fixedTime`, `orderedMembers` o `applyToday`. Muestra las próximas 3 fechas con el asignado según rotación round-robin.

**`showApplyToday`** es `true` si `hasFixedTime == true` y la `TimeOfDay` configurada es posterior a `TimeOfDay.now()` del día actual. Si no se ha configurado hora, no tiene sentido "aplicar hoy" como ocurrencia separada — la tarea sin hora fija ya cubre el día entero.

---

### 3.7 `TaskDetailViewModel` — exponer `difficulty`, ampliar ocurrencias a 5

**`TaskDetailViewData` actualizado:**

```dart
class TaskDetailViewData {
  const TaskDetailViewData({
    required this.task,
    required this.canManage,
    required this.currentAssigneeName,
    required this.upcomingOccurrences,  // ahora take(5) en lugar de take(3)
    required this.difficulty,           // ← nuevo: task.difficulty
  });
  final Task   task;
  final bool   canManage;
  final String? currentAssigneeName;
  final List<UpcomingOccurrence> upcomingOccurrences;
  final TaskDifficulty difficulty;

  bool get isFrozen => task.status == TaskStatus.frozen;
}
```

**Contrato sin cambios de métodos** (`toggleFreeze`, `deleteTask`).

---

## Sección 4 — Tests requeridos por ViewModel

| ViewModel              | Tests unitarios nuevos mínimos                                                                 |
|------------------------|-----------------------------------------------------------------------------------------------|
| `TodayViewModel`       | homes list construida correctamente; `hasPendingToday` refleja membresía; `selectHome` cambia currentHome |
| `HistoryViewModel`     | `canRate` solo true para CompletedEvent + !isOwnEvent + !isRated; `rateEvent` persiste y actualiza `isRated` |
| `MemberProfileViewModel` | showRadar false con <3 tareas; radar con 10 de 12 + 2 overflow; completedCount/streak/score del Member |
| `AllTasksViewModel`    | `isSelectionMode` reactivo a selectedIds; `bulkDelete` solo si canManage; `canManage` (antes canCreate) |
| `CreateEditTaskViewModel` | `showApplyToday` falso cuando hora ya pasó; `canSave` falso sin miembros; upcomingDates reactivas al cambiar recurrencia |
| `TaskDetailViewModel`  | upcomingOccurrences devuelve 5; difficulty expuesta correctamente                              |

---

## Sección 5 — Orden de implementación

Los sub-planes de implementación se ejecutan en este orden, ya que cada uno es independiente del siguiente:

1. **`HomeMembership.hasPendingToday`** — cambio de dominio + backend (Cloud Function `update_dashboard`) + test de integración
2. **`TodayViewModel`** — selector de hogares con punto rojo
3. **`HistoryViewModel`** — `TaskEventItem`, `rateEvent`
4. **`MemberProfileViewModel`** — estadísticas + overflow del radar
5. **`AllTasksViewModel`** — selección múltiple, bulk actions, renombrar `canCreate`
6. **`CreateEditTaskViewModel`** — nuevo ViewModel completo
7. **`TaskDetailViewModel`** — exponer `difficulty`, ampliar a 5 ocurrencias

Los pasos 2–5 son independientes entre sí y pueden ejecutarse en paralelo si hay capacidad.

---

## Qué NO cambia

- Domain layer (excepto `HomeMembership.hasPendingToday`)
- Data layer (repositorios existentes)
- Providers de infraestructura (`currentHomeProvider`, `dashboardProvider`, `homeMembersProvider`)
- Estructura de rutas (`AppRoutes`)
- ARB files e i18n
- Tests de integración existentes (tocan Firestore, no dependen de presentación)
- `MembersViewModel` (contrato completo sin cambios)
