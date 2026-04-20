# P1 — Tareas completadas no se mueven a sección "Hechas" en pantalla Hoy

## Bug que corrige
- **Bug #10** — Tras completar una tarea en la pantalla Hoy, la tarea completada no aparece en la sección "Hechas". En su lugar, la pantalla muestra directamente la **siguiente ocurrencia** de la tarea en "Por hacer". El usuario no puede ver visualmente qué ha completado en el día actual.

## Causa raíz probable

La pantalla Hoy probablemente lee las tareas directamente del stream de tareas recurrentes (próximas ocurrencias) sin considerar el histórico de eventos del día actual. Al completar una tarea:

1. La Cloud Function registra un evento en `taskEvents`.
2. La próxima ocurrencia se genera o ya existe.
3. El stream que alimenta "Por hacer" devuelve la próxima ocurrencia (que es para hoy o futura).
4. No hay lógica que mueva la ocurrencia completada a "Hechas".

## Archivos a investigar

| Archivo | Qué buscar |
|---------|-----------|
| `lib/features/tasks/application/today_view_model.dart` | Cómo se distinguen tareas por hacer y hechas |
| `lib/features/tasks/data/today_repository.dart` | Qué queries se hacen a Firestore |
| `lib/features/tasks/presentation/skins/today_screen_v2.dart` | Cómo se renderizan los subgrupos "Por hacer" / "Hechas" |
| `functions/src/tasks/apply_task_completion.ts` | ¿Marca la ocurrencia actual como completada en el doc de la tarea? |

## Cambios requeridos

### 1. Modelo de datos: marcar ocurrencia actual como completada

La tarea recurrente debe tener un campo que indique si la ocurrencia del día ha sido completada:

```
tasks/{id}:
  lastCompletedDate: "2026-04-15"  // fecha de la última completación
  lastCompletedByUid: "uid123"
```

O bien usar los `taskEvents` para determinar qué ocurrencias de hoy están completadas.

### 2. Query en la pantalla Hoy

El `TodayViewModel` debe hacer dos queries:

**Tareas por hacer**: Ocurrencias programadas para hoy cuya `lastCompletedDate != today`.

**Tareas hechas**: Eventos de `taskEvents` con `type == 'completed'` y `date == today`.

```dart
// En TodayRepository
Future<TodayData> getTodayTasks(String homeId) async {
  final today = DateUtils.dateOnly(DateTime.now());
  final todayStr = DateFormat('yyyy-MM-dd').format(today);
  
  // Query 1: tareas pendientes de hoy
  final pendingTasks = await _getPendingTasksForToday(homeId, todayStr);
  
  // Query 2: eventos completados hoy
  final completedEvents = await _getCompletedEventsToday(homeId, todayStr);
  
  return TodayData(pending: pendingTasks, completed: completedEvents);
}
```

### 3. UI: renderizar dos secciones

En `TodayScreenV2`, mostrar dos secciones diferenciadas:

```dart
// Sección "Por hacer"
if (todayData.pending.isNotEmpty)
  SectionHeader(title: l10n.toDo),
  ...todayData.pending.map((task) => TodayTaskCard(task: task)),

// Sección "Hechas"
if (todayData.completed.isNotEmpty)
  SectionHeader(title: l10n.done),
  ...todayData.completed.map((event) => TodayCompletedCard(event: event)),
```

### 4. Actualización en tiempo real

Usar streams en lugar de Futures para que la UI se actualice automáticamente al completar una tarea:

```dart
// En TodayViewModel — usar StreamProvider o AsyncNotifier con streams
@riverpod
Stream<TodayData> todayData(TodayDataRef ref) {
  final homeId = ref.watch(currentHomeIdProvider);
  return ref.read(todayRepositoryProvider).watchTodayTasks(homeId);
}
```

## Criterios de aceptación

- [ ] Al cargar la pantalla Hoy, las tareas pendientes de hoy aparecen en "Por hacer".
- [ ] Al completar una tarea, desaparece de "Por hacer" y aparece en "Hechas" en menos de 2 segundos.
- [ ] Si todas las tareas del día están completadas, "Por hacer" muestra un estado vacío y "Hechas" las lista todas.
- [ ] Al día siguiente, "Hechas" del día anterior no aparece (solo el día actual).

## Tests requeridos

- Test unitario: `TodayViewModel` con 2 tareas pendientes y 1 evento completado → `pending.length == 2`, `completed.length == 1`.
- Test de integración: completar tarea via CF → leer `todayData` → la tarea aparece en `completed`.
- Test de widget: `TodayScreenV2` con tarea completada → renderiza la sección "Hechas".
