# Spec-06: Dashboard materializado y pantalla Hoy

**Dependencias previas:** Spec-00 → Spec-05  
**Oleada:** Oleada 1

---

## Objetivo

Implementar el documento `dashboard` materializado en Firestore y la pantalla principal "Hoy" que lo consume con un único listener.

---

## Reglas de negocio

1. La pantalla Hoy lee **un único documento**: `homes/{homeId}/views/dashboard`.
2. El dashboard se ordena por recurrencia: **Hora → Día → Semana → Mes → Año**.
3. Dentro de cada bloque: subgrupos **Por hacer** (tareas pendientes) y **Hechas** (completadas hoy).
4. Dentro de "Por hacer": primero las vencidas, luego las próximas, luego orden alfabético.
5. El botón "Hecho" solo aparece si la tarea está asignada al usuario actual.
6. El botón "Pasar turno" solo aparece si la tarea está asignada al usuario actual.
7. Si un bloque de recurrencia no tiene tareas, se oculta (no se muestra vacío).
8. El dashboard se actualiza mediante Cloud Functions en cada completado, pase de turno o cambio de asignación.
9. En Free: se muestra un banner de AdMob al final de la pantalla.

---

## Estructura del dashboard (documento en Firestore)

```
homes/{homeId}/views/dashboard
{
  activeTasksPreview: [
    {
      taskId: string,
      title: string,
      visualKind: string,
      visualValue: string,
      recurrenceType: string,   // "hourly"|"daily"|"weekly"|"monthly"|"yearly"
      currentAssigneeUid: string | null,
      currentAssigneeName: string | null,
      currentAssigneePhoto: string | null,
      nextDueAt: Timestamp,
      isOverdue: boolean,
      status: "active"
    }
  ],
  doneTasksPreview: [
    {
      taskId: string,
      title: string,
      visualKind: string,
      visualValue: string,
      recurrenceType: string,
      completedByUid: string,
      completedByName: string,
      completedByPhoto: string | null,
      completedAt: Timestamp
    }
  ],
  counters: {
    totalActiveTasks: number,
    totalMembers: number,
    tasksDueToday: number,
    tasksDoneToday: number
  },
  memberPreview: [
    {
      uid: string,
      name: string,
      photoUrl: string | null,
      role: string,
      status: string,
      tasksDueCount: number
    }
  ],
  premiumFlags: {
    isPremium: boolean,
    showAds: boolean,
    canUseSmartDistribution: boolean,
    canUseVacations: boolean,
    canUseReviews: boolean
  },
  adFlags: { showBanner: boolean, bannerUnit: string },
  rescueFlags: { isInRescue: boolean, daysLeft: number | null },
  updatedAt: Timestamp
}
```

---

## Archivos a crear

```
lib/features/tasks/
└── presentation/
    ├── today_screen.dart
    └── widgets/
        ├── today_task_section.dart          (bloque por tipo de recurrencia)
        ├── today_task_card_todo.dart        (tarjeta Por hacer)
        ├── today_task_card_done.dart        (tarjeta Hecha)
        ├── today_empty_state.dart
        └── today_header_counters.dart       (contadores de la cabecera)

lib/features/homes/
└── application/
    └── dashboard_provider.dart              (stream del dashboard)

functions/src/
└── tasks/
    └── update_dashboard.ts                  (función que actualiza el dashboard)
```

---

## Implementación

### DashboardProvider

```dart
// Solo UN stream activo
@riverpod
Stream<HomeDashboard?> dashboard(Ref ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  if (homeId == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('homes')
      .doc(homeId)
      .collection('views')
      .doc('dashboard')
      .snapshots()
      .map((snap) => snap.exists ? HomeDashboard.fromFirestore(snap.data()!) : null);
}
```

### HomeDashboard (modelo)

```dart
@freezed
class HomeDashboard with _$HomeDashboard {
  const factory HomeDashboard({
    required List<TaskPreview> activeTasksPreview,
    required List<DoneTaskPreview> doneTasksPreview,
    required DashboardCounters counters,
    required List<MemberPreview> memberPreview,
    required PremiumFlags premiumFlags,
    required AdFlags adFlags,
    required RescueFlags rescueFlags,
    required DateTime updatedAt,
  }) = _HomeDashboard;
}
```

### TodayScreen (estructura)

```dart
class TodayScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final currentUid = ref.watch(authProvider).valueOrNull?.uid;
    
    return dashboard.when(
      loading: () => const TodaySkeletonLoader(),
      error: (e, _) => TodayErrorState(onRetry: () => ref.invalidate(dashboardProvider)),
      data: (data) {
        if (data == null) return const TodayEmptyState();
        
        // Agrupar y ordenar
        final grouped = _groupByRecurrence(data.activeTasksPreview, data.doneTasksPreview);
        
        return CustomScrollView(
          slivers: [
            TodayHeaderCounters(counters: data.counters),
            for (final recurrenceType in RecurrenceOrder.all)
              if (grouped[recurrenceType] != null) ...[
                TodayRecurrenceSection(
                  type: recurrenceType,
                  todos: grouped[recurrenceType]!.todos,
                  dones: grouped[recurrenceType]!.dones,
                  currentUid: currentUid,
                ),
              ],
            if (data.adFlags.showBanner)
              AdBannerSliver(unitId: data.adFlags.bannerUnit),
          ],
        );
      },
    );
  }
}
```

### Orden de recurrencia (constante)

```dart
class RecurrenceOrder {
  static const all = ['hourly', 'daily', 'weekly', 'monthly', 'yearly'];
  
  static String localizedTitle(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type) {
      'hourly' => l10n.recurrenceHourly,
      'daily' => l10n.recurrenceDaily,
      'weekly' => l10n.recurrenceWeekly,
      'monthly' => l10n.recurrenceMonthly,
      'yearly' => l10n.recurrenceYearly,
      _ => type,
    };
  }
}
```

### TodayTaskCardTodo

- Avatar del responsable actual (foto o iniciales).
- Nombre de la tarea con icono/emoji.
- Chip de vencimiento (ej: "Hoy 20:00", "Vencida", "Lun 19:00").
- Si `currentAssigneeUid == currentUid`:
  - Botón "✓ Hecho" (coral, prominente).
  - Botón "↷ Pasar" (gris, secundario).
- Si es otro responsable:
  - Solo se muestra el responsable sin botones de acción.

### TodayTaskCardDone

- Tachado visual suave o fondo más claro.
- Nombre de la tarea.
- "Completada por [nombre] a las HH:mm".

### Cloud Function: updateDashboard

Esta función se llama desde las funciones de completar tarea y pasar turno (specs siguientes). Por ahora, implementar el esqueleto que reconstruye el dashboard leyendo las colecciones necesarias:

```typescript
// functions/src/tasks/update_dashboard.ts
export async function updateHomeDashboard(homeId: string): Promise<void> {
  // 1. Leer todas las tareas activas del hogar
  // 2. Calcular cuáles son de "hoy" por recurrenceType
  // 3. Leer completados de hoy
  // 4. Leer miembros activos
  // 5. Construir el documento dashboard
  // 6. Escribir en homes/{homeId}/views/dashboard
}
```

Esta función debe ser llamada también en un cron diario a medianoche para resetear el dashboard.

### Skeleton loader

Mostrar un esqueleto animado (shimmer) mientras carga el dashboard por primera vez.

---

## Tests requeridos

### Unitarios

**`test/unit/features/tasks/dashboard_grouping_test.dart`**
- `_groupByRecurrence` agrupa correctamente por tipo.
- Dentro de cada grupo, "Por hacer" viene antes que "Hechas".
- Dentro de "Por hacer": vencidas primero, luego próximas, luego alfabético.
- Si un bloque no tiene tareas, no aparece en el resultado.

**`test/unit/features/tasks/today_task_card_test.dart`** (lógica)
- Botones "Hecho" y "Pasar" solo presentes si `currentAssigneeUid == currentUid`.
- Chip de vencimiento muestra "Vencida" si `nextDueAt` es anterior a ahora.
- Chip muestra "Hoy HH:mm" si vence hoy.
- Chip muestra "Lun HH:mm" si vence esta semana.

**`test/unit/features/tasks/recurrence_order_test.dart`**
- `RecurrenceOrder.all` tiene exactamente 5 elementos en el orden correcto.
- `localizedTitle` devuelve string no vacío para cada tipo.

### De integración

**`test/integration/features/tasks/dashboard_stream_test.dart`** (emuladores)
- Escribir un dashboard en Firestore → el stream del provider emite el objeto.
- Actualizar el dashboard → el stream emite el nuevo valor.
- Documento inexistente → stream emite null.

### UI

**`test/ui/features/tasks/today_screen_test.dart`**
- Estado de carga: muestra skeleton.
- Estado vacío: muestra empty state.
- Con datos: muestra secciones por recurrencia.
- Sección sin tareas: no aparece.
- Usuario responsable ve botones de acción.
- Usuario no responsable no ve botones de acción.
- Golden test de la pantalla con datos de ejemplo.

**`test/ui/features/tasks/today_task_card_todo_test.dart`**
- Golden test del card "Por hacer" con botones visibles.
- Golden test del card "Por hacer" sin botones (otro responsable).

**`test/ui/features/tasks/today_task_card_done_test.dart`**
- Golden test del card "Hecha".

---

## Pruebas manuales requeridas al terminar esta spec

1. **Pantalla Hoy con tareas:**
   - Crear tareas de distintos tipos (diaria, semanal, mensual).
   - Abrir pantalla Hoy.
   - Verificar que aparecen las secciones "Día", "Semana", "Mes" en ese orden.
   - Verificar que las tareas sin vencer hoy no aparecen en "Hoy" (o aparecen en la sección correcta).

2. **Un solo listener activo:**
   - Abrir la app en pantalla Hoy.
   - Verificar en las herramientas de red / Firestore Emulator que hay exactamente **una** lectura activa del documento `dashboard`.
   - Navegar a otra pantalla (Tareas) y volver → no debe haber múltiples listeners acumulados.

3. **Botones de acción:**
   - Estar asignado a una tarea → ver botones "Hecho" y "Pasar turno".
   - Cambiar el responsable de la tarea (desde otro dispositivo/cuenta) → los botones desaparecen.

4. **Contador de cabecera:**
   - La cabecera debe mostrar "X tareas para hoy" y "Y completadas hoy".
   - Los números deben coincidir con la realidad.

5. **Banner de publicidad (Free):**
   - Con un hogar Free, al final de la pantalla Hoy debe aparecer un banner AdMob (en dev, aparecerá el banner de prueba de Google).
   - Con un hogar Premium, el banner no debe aparecer.

6. **Skeleton al cargar:**
   - Con conexión lenta (throttle en red), verificar que mientras carga aparece el skeleton animado, no una pantalla en blanco.

7. **Actualización en tiempo real:**
   - Abrir la app en la pantalla Hoy.
   - Desde otra cuenta (admin), crear una nueva tarea en el mismo hogar.
   - La pantalla Hoy debe actualizarse automáticamente sin recargar.
