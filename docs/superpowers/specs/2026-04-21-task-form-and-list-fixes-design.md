# Spec: Fixes del formulario de tareas, rotación y detalles de lista

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Alta (BUG-01, BUG-06, BUG-07, BUG-08, BUG-23)

---

## Contexto

Cinco bugs acumulados en los flujos de crear / editar / borrar tarea y en la lista, todos detectados en QA 2026-04-20:

| Bug    | Severidad | Resumen                                                                                     |
| ------ | --------- | ------------------------------------------------------------------------------------------- |
| BUG-01 | Baja      | El campo Email del login activa autocorrector en MIUI y sustituye letras al escribir rápido. |
| BUG-06 | Alta      | Con 2 miembros y `onMissAssign=sameAssignee`, la rotación no avanza al pasar turno en ciertos casos. |
| BUG-07 | Alta      | Al editar una tarea existente, el formulario no precarga la recurrencia actual (queda en "Selecciona una frecuencia"). |
| BUG-08 | Media     | Tras borrar una tarea desde el detalle, la app queda en la pantalla de detalle mostrando datos cacheados con ruedecita de carga infinita; debería volver a la lista. |
| BUG-23 | Baja      | Las tareas anuales muestran "25 abr" sin año en los previews, confundiendo con tareas mensuales. |

---

## BUG-01: autocorrector en el campo Email

### Localización

Pantalla de login: [lib/features/auth/presentation/](lib/features/auth/presentation/) — campo Email del `SignInForm` o similar.

### Fix

```dart
TextField(
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  autocorrect: false,
  enableSuggestions: false,
  textCapitalization: TextCapitalization.none,
  autofillHints: const [AutofillHints.email],
  // ...
)
```

Las cuatro propiedades combinadas neutralizan MIUI, Samsung Keyboard y Gboard. Revisar **todos** los `TextField` con tipo email en la app para aplicar el mismo patrón (Gestionar subs, restaurar cuenta, etc.).

### Tests

- Widget test que verifica las cuatro propiedades en el `TextField` de email.

---

## BUG-06: rotación con 2 miembros y `onMissAssign=sameAssignee`

### Análisis

En [functions/src/tasks/pass_turn_helpers.ts](functions/src/tasks/pass_turn_helpers.ts), `computeNextAssignee` recibe `(currentUid, assignmentOrder, onMissAssign, activeMembers)` y con 2 miembros + `sameAssignee` aplica:

```ts
if (onMissAssign === "sameAssignee") {
  return currentUid; // 👈 incorrecto al PASAR TURNO (sí al FALLAR sin acción)
}
```

El bug: `onMissAssign` controla qué pasa cuando la tarea **expira sin acción** (miss). No debe aplicarse al `passTaskTurn` explícito del usuario. En `passTaskTurn` siempre se debe **avanzar** al siguiente en `assignmentOrder`.

### Fix

Separar las dos rutas en el callable:

- `applyTaskCompletion` / cron de expiración → consulta `onMissAssign` (comportamiento actual).
- `passTaskTurn` → ignora `onMissAssign` y avanza siempre en el orden.

En [functions/src/tasks/pass_task_turn.ts](functions/src/tasks/pass_task_turn.ts):

```ts
const currentIdx = order.indexOf(currentAssignee);
const nextIdx = (currentIdx + 1) % order.length;
const next = order[nextIdx];
```

Si al avanzar el siguiente está inactivo (vacaciones, miembro eliminado), saltar al siguiente activo. Cubrir el caso de **un único miembro activo**: si `order.length == 1`, pasar turno no cambia el asignado y devuelve warning `HttpsError("failed-precondition", "only_one_active_member")` — la UI ya tiene un fallback.

### Tests

- `pass_turn_helpers.test.ts`: nuevo caso con 2 miembros + `sameAssignee`, partiendo de A → debe devolver B; repetido → A.
- `pass_task_turn.test.ts`: integración end-to-end del callable.
- UI: si el callable devuelve el nuevo asignado correctamente, el `today_screen_v2` se refresca vía el stream del dashboard (ya lo hace).

---

## BUG-07: precarga de recurrencia al editar

### Análisis

[lib/features/tasks/application/create_edit_task_view_model.dart](lib/features/tasks/application/create_edit_task_view_model.dart) al recibir un `taskId` de edición, lee la tarea pero no hidrata el estado del `recurrence_provider` con el `RecurrenceRule` existente. El `recurrence_form` arranca vacío y la UI no refleja la recurrencia.

### Fix

En el ViewModel, al completar la carga:

```dart
final task = await tasksRepository.byId(taskId);
ref.read(recurrenceProvider.notifier).hydrateFrom(task.recurrenceRule);
```

`hydrateFrom` es un nuevo método en `RecurrenceNotifier` que mapea cada variante del sealed `RecurrenceRule` al estado interno del formulario (tipo seleccionado + campos específicos). Test unitario cubre las 7 variantes actuales + la nueva `oneTime` de la spec 1.

Adicionalmente, en [lib/features/tasks/presentation/widgets/recurrence_form.dart](lib/features/tasks/presentation/widgets/recurrence_form.dart), el método `build` debe reaccionar al estado hidratado (hoy ya lo hace vía `ref.watch`; con el `hydrateFrom` correcto queda resuelto).

---

## BUG-08: navegación tras borrar tarea

### Análisis

En [lib/features/tasks/presentation/skins/task_detail_screen_v2.dart](lib/features/tasks/presentation/skins/task_detail_screen_v2.dart), al borrar se llama al callable `deleteTask` y el `Stream` del detalle emite `null` → la UI muestra un `CircularProgressIndicator` eterno porque el provider queda sin data.

### Fix

Navegar **antes** de esperar la confirmación definitiva del callable, con optimistic UI:

```dart
Future<void> _onDelete() async {
  final confirmed = await showDeleteConfirmDialog(context, task);
  if (!confirmed || !context.mounted) return;

  // Pop primero para no quedar en una pantalla cuyo stream va a morir.
  GoRouter.of(context).pop();

  try {
    await vm.deleteTask();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar: ${e.toString()}')),
      );
    }
  }
}
```

Si falla en el backend, la tarea vuelve a aparecer en la lista en el siguiente snapshot — comportamiento aceptable porque los errores reales son raros y el usuario ve el snackbar.

### Tests

- `task_detail_delete_test.dart` (widget): confirma que tras tap en "Borrar" y confirmar, la ruta cambia.

---

## BUG-23: año en tareas anuales

### Análisis

[lib/features/tasks/presentation/widgets/upcoming_dates_preview.dart](lib/features/tasks/presentation/widgets/upcoming_dates_preview.dart) formatea cada fecha con `DateFormat('d MMM')` — sin año. Para tareas anuales (`YearlyFixedRule` / `YearlyNthRule`), esto es confuso porque el próximo evento puede ser en otro año.

### Fix

Cuando la tarea tiene una regla anual, el preview usa el helper nuevo `TokaDates.dateLongFull` (ver spec 8) que incluye año. El resto de reglas mantiene `dateMediumWithWeekday` sin año.

```dart
bool isAnnual(RecurrenceRule r) => switch (r) {
  YearlyFixedRule() || YearlyNthRule() => true,
  _ => false,
};

final formatter = isAnnual(task.recurrenceRule)
  ? TokaDates.dateLongFull
  : TokaDates.dateMediumWithWeekday;
```

Aplica también al tile de Hoy cuando el elemento es una tarea anual a más de 30 días vista.

---

## Tests globales

Los fixes comparten arnés:

- `flutter test test/unit/features/tasks/`: todos los tests de viewmodels y validators pasan tras la implementación.
- `flutter test test/ui/features/tasks/`: golden de task detail (con "Borrar" funcional), golden de create/edit (con recurrencia precargada), golden de upcoming preview anual.
- `flutter test test/integration/features/tasks/`: pasar turno con 2 miembros verifica rotación real contra emuladores.
- `npm --prefix functions test`: `pass_turn_helpers.test.ts` y `pass_task_turn.test.ts` ampliados.

---

## Orden de implementación recomendado

Dentro de esta spec:

1. BUG-07 (recurrencia al editar) — afecta al flujo más usado.
2. BUG-06 (rotación backend) — crítico para usuarios con 2 personas.
3. BUG-08 (nav tras borrar) — arregla estado "pantalla zombie".
4. BUG-23 (año anual) — depende de spec 8 (helpers de fecha) para no duplicar código.
5. BUG-01 (autocorrector email) — trivial, último.

---

## Fuera de alcance

- Rediseño del formulario de tareas (layouts, iconografía).
- Transiciones animadas tras borrar (sólo corregir el estado).
- Soporte para repetición custom con cron strings.
- Auto-asignación inteligente (Premium-only, feature separada).
