# Spec-09: Pantalla Historial

**Dependencias previas:** Spec-00 → Spec-07  
**Oleada:** Oleada 2

---

## Objetivo

Implementar la pantalla de historial del hogar: cronología de eventos (completados y pases de turno), paginación, filtros y detalle de evento.

---

## Reglas de negocio

1. El historial muestra eventos de tipo `completed` y `passed` en orden cronológico inverso.
2. En **Free**: historial visible de los últimos **30 días**.
3. En **Premium**: historial visible de los últimos **90 días**.
4. El historial está **paginado** (20 eventos por página, cursor-based).
5. Filtros disponibles: por miembro, por tarea, por tipo de evento (completado/pase).
6. Cada evento muestra: tipo, tarea, actor, timestamp, y en caso de pase: el motivo y el nuevo responsable.
7. Las estadísticas acumuladas del miembro se mantienen más allá del historial visible.
8. Las acciones destructivas (eliminar tarea, congelar miembro) también deben tener un rastro en el historial (auditoría básica).

---

## Archivos a crear

```
lib/features/history/
├── data/
│   └── history_repository_impl.dart
├── domain/
│   ├── history_repository.dart
│   └── task_event.dart              (modelo freezed — completed y passed)
├── application/
│   └── history_provider.dart        (paginación con AsyncNotifier)
└── presentation/
    ├── history_screen.dart
    └── widgets/
        ├── history_event_tile.dart
        ├── history_filter_bar.dart
        └── history_empty_state.dart
```

---

## Implementación

### TaskEvent (modelo)

```dart
@freezed
sealed class TaskEvent with _$TaskEvent {
  const factory TaskEvent.completed({
    required String id,
    required String taskId,
    required String taskTitleSnapshot,
    required TaskVisual taskVisualSnapshot,
    required String actorUid,
    required String performerUid,
    required DateTime completedAt,
    required DateTime createdAt,
  }) = CompletedEvent;
  
  const factory TaskEvent.passed({
    required String id,
    required String taskId,
    required String taskTitleSnapshot,
    required TaskVisual taskVisualSnapshot,
    required String actorUid,
    required String fromUid,
    required String toUid,
    String? reason,
    required bool penaltyApplied,
    required double? complianceBefore,
    required double? complianceAfter,
    required DateTime createdAt,
  }) = PassedEvent;
}
```

### HistoryProvider (paginación)

```dart
@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  static const _pageSize = 20;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  
  @override
  AsyncValue<List<TaskEvent>> build(String homeId) => const AsyncValue.data([]);
  
  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    // Cargar siguiente página desde Firestore con startAfter(_lastDoc)
  }
  
  void applyFilter(HistoryFilter filter) {
    // Reset paginación y recargar
    _lastDoc = null;
    _hasMore = true;
    state = const AsyncValue.data([]);
    loadMore();
  }
}
```

### HistoryFilter

```dart
@freezed
class HistoryFilter with _$HistoryFilter {
  const factory HistoryFilter({
    String? memberUid,
    String? taskId,
    String? eventType,   // "completed" | "passed" | null (todos)
  }) = _HistoryFilter;
}
```

### Pantalla Historial

- AppBar con filtros (chips horizontales scrollables).
- Lista de eventos con `ListView.builder`.
- "Cargar más" al final (infinite scroll o botón).
- Banner de upgrade si es Free y hay eventos > 30 días ocultos.

### HistoryEventTile

**Evento completado:**
```
[Avatar] [Nombre] completó [emoji Tarea]
          "Limpiar baño"
          hace 2 horas · Lun 14 ene, 20:03
```

**Evento pasado:**
```
[Avatar] [Nombre A] → [Nombre B]  [emoji ↷]
          "Aspirar el salón" — pase de turno
          Motivo: "Me voy de viaje"
          hace 1 día · Dom 13 ene, 11:30
```

### Límite de historial en Free

Al llegar a los 30 días, mostrar un bloque:
```
┌─────────────────────────────┐
│ 🔒 Más historial con Premium│
│ Accede a 90 días de historial│
│ [Actualizar a Premium]       │
└─────────────────────────────┘
```

---

## Tests requeridos

### Unitarios

- `TaskEvent.fromFirestore` distingue correctamente `completed` y `passed`.
- `HistoryFilter` aplicado a una lista filtra por `memberUid` correctamente.
- `HistoryFilter` con `eventType: "passed"` excluye eventos `completed`.
- La paginación resetea al cambiar filtros.

### De integración

- Cargar primera página → devuelve primeros 20 eventos.
- `loadMore` → devuelve siguientes 20 eventos (cursor correcto).
- Sin más eventos → `_hasMore = false`.
- Filtro por `memberUid` → solo eventos de ese miembro.
- Free con eventos > 30 días → no devuelve esos eventos.

### UI

- Lista vacía: muestra empty state.
- Evento completado: muestra nombre, tarea y timestamp.
- Evento pasado: muestra motivo si existe.
- Infinite scroll: al llegar al final, carga más automáticamente.
- Banner de upgrade visible en Free al llegar al límite de 30 días.
- Golden tests de los tiles.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Historial básico:** Completar 3 tareas → ir a Historial → ver los 3 eventos con nombre, tarea y tiempo.
2. **Historial de pases:** Pasar turno 2 veces con motivos distintos → ver los eventos con motivo en el historial.
3. **Filtrar por miembro:** Aplicar filtro → solo aparecen eventos de ese miembro.
4. **Filtrar por tipo:** Filtro "Solo pases" → desaparecen los completados.
5. **Paginación:** Crear 25 eventos → el historial carga 20 → al bajar, aparecen los 5 restantes.
6. **Límite Free (30 días):** Si hay eventos de hace más de 30 días → no aparecen en Free, aparece el banner de upgrade.
