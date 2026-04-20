# P1 — Horas de tareas en UTC en lugar de hora local

## Bug que corrige
- **Bug #9** — Las horas de las tareas se muestran en UTC en lugar de en hora local del usuario. Ejemplo: una tarea con hora 09:00 Europe/Madrid (UTC+2) se muestra como "07:00" en "Próximas fechas" y en la tarjeta de Hoy.

## Causa raíz probable

Las horas se almacenan en Firestore como `Timestamp` UTC o como string "HH:mm" en UTC. Al mostrarlas en Flutter, se usa `DateTime.fromMillisecondsSinceEpoch()` sin conversión a hora local, o se parsea el string "HH:mm" sin aplicar el offset de zona horaria del dispositivo.

## Archivos a investigar

| Archivo | Qué buscar |
|---------|-----------|
| `lib/features/tasks/domain/task.dart` | Cómo se almacena el campo de hora (`time`, `scheduledTime`, etc.) |
| `lib/features/tasks/data/task_repository.dart` | Cómo se serializa/deserializa el Timestamp |
| `lib/features/tasks/presentation/skins/today_screen_v2.dart` | Cómo se formatea la hora para mostrar |
| `lib/features/tasks/presentation/widgets/task_card.dart` | Formato de hora en las tarjetas |
| `lib/core/utils/date_utils.dart` (si existe) | Utilidades de fecha |

## Cambios requeridos

### 1. Almacenamiento de hora

**Recomendación**: almacenar la hora de la tarea como string "HH:mm" en hora local del creador, junto con la zona horaria del hogar:
```
tasks/{id}:
  timeOfDay: "09:00"        // hora local
  timezone: "Europe/Madrid" // IANA timezone del hogar
```

O bien, almacenar solo la hora local como minutos desde medianoche:
```
tasks/{id}:
  minuteOfDay: 540  // 9 * 60 = 540 (09:00 local)
```

### 2. Conversión al mostrar

Si las horas están almacenadas como UTC `Timestamp`, convertir a hora local al mostrar:

```dart
// MAL — muestra en UTC
final displayTime = DateFormat('HH:mm').format(task.scheduledTime);

// BIEN — convierte a hora local del dispositivo
final localTime = task.scheduledTime.toLocal();
final displayTime = DateFormat('HH:mm').format(localTime);
```

Si las horas están almacenadas como string "HH:mm" en UTC, aplicar el offset:

```dart
// Parsear como UTC y convertir a local
final utcHour = int.parse(timeString.split(':')[0]);
final utcMinute = int.parse(timeString.split(':')[1]);
final utcDt = DateTime.utc(0, 1, 1, utcHour, utcMinute);
final localDt = utcDt.toLocal();
final displayTime = '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
```

### 3. Al crear la tarea

En `CreateEditTaskScreenV2`, asegurar que la hora seleccionada en el `TimePicker` se guarda correctamente:

```dart
// Si se guarda como UTC Timestamp:
final selectedTime = TimeOfDay(hour: 9, minute: 0);
final now = DateTime.now();
final localDt = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
final utcDt = localDt.toUtc(); // Convertir a UTC para Firestore
await taskRepository.createTask(task.copyWith(scheduledTime: Timestamp.fromDate(utcDt)));
```

### 4. Uniformidad en "Próximas fechas"

La sección "Próximas fechas" del `TaskDetailScreenV2` debe aplicar la misma conversión:

```dart
// Para cada fecha próxima mostrada
Text(DateFormat('EEE dd MMM · HH:mm').format(nextDate.toLocal()))
```

## Criterios de aceptación

- [ ] Una tarea creada a las 09:00 (hora local) se muestra como "09:00" en la pantalla Hoy.
- [ ] La misma tarea se muestra como "09:00" en "Próximas fechas" del detalle.
- [ ] Si el dispositivo cambia de zona horaria, las horas se recalculan correctamente.
- [ ] Las tareas sin hora fija (`timeOfDay: null`) no muestran hora alguna.

## Tests requeridos

- Test unitario: `formatTaskTime(utcTimestamp)` con dispositivo en UTC+2 → devuelve la hora local correcta.
- Test de widget: `TodayTaskCard` con tarea a las 09:00 UTC → muestra "11:00" en dispositivo UTC+2.
