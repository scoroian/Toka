# Spec: Permisos de admin, nombre de asignado y próximas fechas con asignado

**Fecha:** 2026-04-13  
**Área:** `lib/features/tasks/`  
**Tipo:** Bug fix + mejora de UX

---

## Contexto

Tres problemas relacionados con la pantalla de detalle de tarea y los permisos de gestión:

1. Los miembros con rol `admin` no ven el FAB de crear tarea ni los botones de editar/congelar/eliminar en el detalle. Solo los `owner` los ven.
2. En el detalle de tarea, el nombre del asignado actual muestra "—" en lugar del nombre real tras la compleción.
3. La sección de próximas fechas en el detalle muestra solo fechas, sin indicar quién es el responsable en cada una.

---

## Causa raíz

### Bug de permisos de admin

`AllTasksViewModel` y `TaskDetailViewModel` calculan `canCreate`/`canManage` leyendo el rol desde `userMembershipsProvider(uid)`, que lee `users/{uid}/memberships/{homeId}.role`.

Cuando se promueve un miembro a admin, la Cloud Function `promoteToAdmin` actualiza `homes/{homeId}/members/{uid}.role` (fuente autoritativa), pero **no** actualiza `users/{uid}/memberships/{homeId}.role`. Por eso el campo denormalizado queda obsoleto y el rol siempre aparece como `member`.

### Nombre del asignado muestra "—"

El lookup del nombre usa `homeMembersProvider(home.id)` que es un stream `keepAlive`. Sin embargo, el view model usa `valueOrNull ?? []`, lo que devuelve `[]` si el stream aún no ha emitido en el momento en que la tarea actualiza su `currentAssigneeUid`. El miembro no se encuentra en la lista vacía y `currentAssigneeName` queda `null`.

Al corregir el bug de admin (ambos view models empezarán a esperar datos de `homeMembersProvider` antes de computar), este problema también se resuelve: los miembros ya están cargados antes de que se complete el cálculo.

---

## Diseño — Enfoque A (mínimo y quirúrgico)

### 1. Fix permisos de admin

**`lib/features/tasks/application/all_tasks_view_model.dart`**

- Añadir `ref.watch(homeMembersProvider(home.id))`
- Encontrar el miembro actual en esa lista: `homeMembers.where((m) => m.uid == uid).firstOrNull`
- `canCreate = myMember?.role == MemberRole.owner || myMember?.role == MemberRole.admin`
- Eliminar el bloque de `userMembershipsProvider` usado para el rol (puede seguir siendo necesario para otros usos; revisar si se usa solo para el rol)

**`lib/features/tasks/application/task_detail_view_model.dart`**

- El watch de `homeMembersProvider(home.id)` ya existe para resolver el nombre del asignado
- Reusar esa lista para obtener el rol del usuario actual
- `myMember = homeMembers.where((m) => m.uid == uid).firstOrNull`
- `canManage = myMember?.role == MemberRole.owner || myMember?.role == MemberRole.admin`
- Eliminar el bloque de `userMembershipsProvider` para el rol

### 2. Fix nombre del asignado actual

**`lib/features/tasks/application/task_detail_view_model.dart`**

- El lookup ya existe y es correcto. Con el fix de sección 1, `homeMembersProvider` ya tiene datos cuando se computa el view data.
- Asegurar que si `homeMembersProvider` está en `AsyncLoading`, el view model devuelve `null` (estado de carga) en lugar de computar con lista vacía.
- Comportamiento esperado:
  - Cargando: pantalla muestra loading
  - Cargado: muestra nombre del `currentAssigneeUid` o "—" si null/no encontrado
  - Tras compleción: stream de Firestore emite tarea actualizada con nuevo `currentAssigneeUid` → view model recalcula → muestra nombre de la siguiente persona

### 3. Próximas fechas con asignado

**Nuevo tipo en `task_detail_view_model.dart`:**

```dart
class UpcomingOccurrence {
  final DateTime date;
  final String? assigneeName;
}
```

Reemplaza `List<DateTime> upcomingOccurrences` por `List<UpcomingOccurrence> upcomingOccurrences` en `TaskDetailViewData`.

**Lógica de rotación (calculada en el frontend):**

```
order = task.assignmentOrder
currentIdx = order.indexOf(task.currentAssigneeUid)  // -1 si null
Para cada fecha futura i (0-based):
  nextIdx = (currentIdx + 1 + i) % order.length
  uid = order[nextIdx]
  name = homeMembers.where(m.uid == uid).firstOrNull?.nickname
```

Si `assignmentOrder` está vacío o `currentAssigneeUid` es null, `assigneeName` es null.

**Reactive:** Cuando alguien pasa turno, el backend actualiza `currentAssigneeUid` en Firestore. El stream de tareas emite, el view model recalcula las próximas fechas con los nuevos asignados. No requiere ningún cambio en el backend.

**`lib/features/tasks/presentation/task_detail_screen.dart`**

En la sección de próximas fechas, cada `ListTile` muestra fecha + nombre:

```
📅 13 abr · 09:00   →   Paco
📅 14 abr · 09:00   →   María
📅 15 abr · 09:00   →   Ana
```

Si `assigneeName` es null, mostrar solo la fecha (sin trailing).

---

## Archivos afectados

| Archivo | Cambio |
|---|---|
| `lib/features/tasks/application/task_detail_view_model.dart` | Leer rol de `homeMembers`; añadir `UpcomingOccurrence`; esperar datos de miembros |
| `lib/features/tasks/application/all_tasks_view_model.dart` | Añadir watch `homeMembersProvider`; leer rol de `homeMembers` |
| `lib/features/tasks/presentation/task_detail_screen.dart` | Mostrar `assigneeName` en próximas fechas |

---

## Tests requeridos

### Unitarios — `task_detail_view_model`
- Admin ve `canManage = true`
- Owner ve `canManage = true`
- Member ve `canManage = false`
- `currentAssigneeName` se resuelve desde `homeMembers`
- Próximas ocurrencias calculan correctamente el asignado en rotación round-robin
- Si `currentAssigneeUid` es null, `upcomingOccurrences[0].assigneeName` usa el primer miembro del orden
- Si pasa turno (currentAssigneeUid cambia), los asignados futuros se recalculan

### Unitarios — `all_tasks_view_model`
- Admin ve `canCreate = true`
- Member ve `canCreate = false`

### UI (golden o widget test) — `task_detail_screen`
- Pantalla con rol admin muestra botones de editar/congelar/eliminar
- Próximas fechas muestran nombre del asignado

---

## Reglas de negocio que NO cambian

- La lógica de rotación en el backend (`getNextAssigneeRoundRobin`) no se toca
- El cálculo de próximas fechas en el frontend es solo display; no afecta la lógica real de asignación
- `userMembershipsProvider` se mantiene para otros usos (navegación entre hogares en `currentHomeProvider`)
