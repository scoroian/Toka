# Tasks CRUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar CRUD completo de tareas con motor de recurrencias DST-aware, pantalla "Todas las tareas" como 5.º tab, y formulario de crear/editar pantalla completa con 7 tipos de recurrencia.

**Architecture:** Firestore directo para CRUD (`homes/{homeId}/tasks/{taskId}`). Cloud Functions solo para operaciones complejas (completar, pasar turno). Dominio freezed + sealed union para `RecurrenceRule`. `RecurrenceCalculator` puro y testeable. Riverpod para estado. Soft-delete (`status='deleted'`).

**Tech Stack:** Flutter/Dart, Riverpod + riverpod_annotation, freezed, go_router, Cloud Firestore, fake_cloud_firestore, timezone, mocktail.

---

## File Structure

**Crear:**
- `lib/features/tasks/domain/task_status.dart`
- `lib/features/tasks/domain/recurrence_rule.dart`
- `lib/features/tasks/domain/task.dart`
- `lib/features/tasks/domain/tasks_repository.dart`
- `lib/features/tasks/domain/task_validator.dart`
- `lib/core/utils/recurrence_calculator.dart`
- `lib/features/tasks/data/task_model.dart`
- `lib/features/tasks/data/tasks_repository_impl.dart`
- `lib/features/tasks/application/tasks_provider.dart`
- `lib/features/tasks/application/task_form_provider.dart`
- `lib/features/tasks/application/recurrence_provider.dart`
- `lib/features/tasks/presentation/all_tasks_screen.dart`
- `lib/features/tasks/presentation/task_detail_screen.dart`
- `lib/features/tasks/presentation/create_edit_task_screen.dart`
- `lib/features/tasks/presentation/widgets/task_card.dart`
- `lib/features/tasks/presentation/widgets/task_visual_picker.dart`
- `lib/features/tasks/presentation/widgets/recurrence_form.dart`
- `lib/features/tasks/presentation/widgets/assignment_form.dart`
- `test/unit/features/tasks/task_validator_test.dart`
- `test/unit/features/tasks/recurrence_calculator_test.dart`
- `test/integration/features/tasks/tasks_crud_test.dart`
- `test/ui/features/tasks/all_tasks_screen_test.dart`
- `test/ui/features/tasks/create_task_screen_test.dart`

**Modificar:**
- `pubspec.yaml` — añadir `timezone: ^0.9.4`
- `lib/features/homes/domain/home_limits.dart` — añadir `isPremium`
- `lib/features/homes/data/home_model.dart` — poblar `isPremium`
- `lib/main_prod.dart` + `lib/main_dev.dart` — `tz_data.initializeTimeZones()`
- `lib/l10n/app_es.arb` / `app_en.arb` / `app_ro.arb` — claves de tareas
- `lib/l10n/app_localizations.dart` — abstract getters
- `lib/l10n/app_localizations_es.dart` / `_en.dart` / `_ro.dart` — implementaciones
- `lib/core/constants/routes.dart` — rutas nuevas
- `lib/app.dart` — registrar rutas
- `lib/shared/widgets/main_shell.dart` — 5 tabs
- `lib/features/tasks/presentation/today_screen.dart` — tap → detalle

---

## Task 1: Setup — timezone + HomeLimits.isPremium

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/homes/domain/home_limits.dart`
- Modify: `lib/features/homes/data/home_model.dart`
- Modify: `lib/main_prod.dart`
- Modify: `lib/main_dev.dart`

- [ ] **Step 1: Añadir timezone a pubspec.yaml**

En `pubspec.yaml`, bajo `intl: ^0.20.0`, añadir:

```yaml
  timezone: ^0.9.4
```

- [ ] **Step 2: flutter pub get**

```bash
flutter pub get
```

Expected: resuelve sin errores, `timezone` aparece en `pubspec.lock`.

- [ ] **Step 3: Añadir `isPremium` a HomeLimits**

Reemplazar el contenido de `lib/features/homes/domain/home_limits.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_limits.freezed.dart';

@freezed
class HomeLimits with _$HomeLimits {
  const factory HomeLimits({
    required int maxMembers,
    @Default(false) bool isPremium,
  }) = _HomeLimits;
}
```

- [ ] **Step 4: Poblar `isPremium` en HomeModel**

En `lib/features/homes/data/home_model.dart`, reemplazar el bloque `limits:`:

```dart
      limits: HomeLimits(
        maxMembers: (data['limits']?['maxMembers'] as int?) ?? 5,
        isPremium: (() {
          final s = data['premiumStatus'] as String? ?? 'free';
          return s == 'active' || s == 'cancelledPendingEnd' || s == 'rescue';
        })(),
      ),
```

- [ ] **Step 5: Inicializar timezone en main_prod.dart**

Añadir la importación y la llamada al inicio de `main()` en `lib/main_prod.dart`:

```dart
import 'package:timezone/data/latest.dart' as tz_data;
```

Al inicio del cuerpo de `main()`, antes de `Firebase.initializeApp(...)`:

```dart
  tz_data.initializeTimeZones();
```

- [ ] **Step 6: Inicializar timezone en main_dev.dart**

Igual que el paso anterior pero en `lib/main_dev.dart`:

```dart
import 'package:timezone/data/latest.dart' as tz_data;
```

```dart
  tz_data.initializeTimeZones();
```

- [ ] **Step 7: Regenerar código freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `home_limits.freezed.dart` actualizado con `isPremium`. Sin errores.

- [ ] **Step 8: Verificar análisis**

```bash
flutter analyze lib/features/homes/
```

Expected: No issues found.

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/homes/domain/home_limits.dart lib/features/homes/domain/home_limits.freezed.dart lib/features/homes/data/home_model.dart lib/main_prod.dart lib/main_dev.dart
git commit -m "feat(tasks): add timezone dep, isPremium to HomeLimits"
```

---

## Task 2: Domain — TaskStatus + RecurrenceRule

**Files:**
- Create: `lib/features/tasks/domain/task_status.dart`
- Create: `lib/features/tasks/domain/recurrence_rule.dart`

- [ ] **Step 1: Crear task_status.dart**

```dart
// lib/features/tasks/domain/task_status.dart
enum TaskStatus {
  active,
  frozen,
  deleted;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.active,
    );
  }
}
```

- [ ] **Step 2: Crear recurrence_rule.dart**

```dart
// lib/features/tasks/domain/recurrence_rule.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurrence_rule.freezed.dart';

@freezed
sealed class RecurrenceRule with _$RecurrenceRule {
  const factory RecurrenceRule.hourly({
    required int every,
    required String startTime, // "HH:mm"
    String? endTime,           // "HH:mm" opcional
    required String timezone,
  }) = HourlyRule;

  const factory RecurrenceRule.daily({
    required int every,
    required String time, // "HH:mm"
    required String timezone,
  }) = DailyRule;

  const factory RecurrenceRule.weekly({
    required List<String> weekdays, // ["MON","WED","FRI"]
    required String time,
    required String timezone,
  }) = WeeklyRule;

  const factory RecurrenceRule.monthlyFixed({
    required int day, // 1-31
    required String time,
    required String timezone,
  }) = MonthlyFixedRule;

  const factory RecurrenceRule.monthlyNth({
    required int weekOfMonth, // 1-4
    required String weekday,  // "MON"-"SUN"
    required String time,
    required String timezone,
  }) = MonthlyNthRule;

  const factory RecurrenceRule.yearlyFixed({
    required int month, // 1-12
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

- [ ] **Step 3: Generar código freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `recurrence_rule.freezed.dart` creado. Sin errores.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/domain/task_status.dart lib/features/tasks/domain/recurrence_rule.dart lib/features/tasks/domain/recurrence_rule.freezed.dart
git commit -m "feat(tasks): add TaskStatus and RecurrenceRule domain models"
```

---

## Task 3: Domain — Task + TaskInput

**Files:**
- Create: `lib/features/tasks/domain/task.dart`

- [ ] **Step 1: Crear task.dart**

```dart
// lib/features/tasks/domain/task.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'recurrence_rule.dart';
import 'task_status.dart';

part 'task.freezed.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String homeId,
    required String title,
    String? description,
    required String visualKind,        // "emoji" | "icon"
    required String visualValue,       // "🏠" o nombre de icono Material
    required TaskStatus status,
    required String recurrenceType,    // "hourly"|"daily"|"weekly"|"monthly"|"yearly"
    required RecurrenceRule recurrenceRule,
    required String assignmentMode,    // "basicRotation" | "smartDistribution"
    required List<String> assignmentOrder, // UIDs en orden
    String? currentAssigneeUid,
    required DateTime nextDueAt,
    required double difficultyWeight,
    required int completedCount90d,
    required String createdByUid,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;
}

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
    @Default(1.0) double difficultyWeight,
  }) = _TaskInput;
}
```

- [ ] **Step 2: Generar código freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `task.freezed.dart` creado. Sin errores.

- [ ] **Step 3: Commit**

```bash
git add lib/features/tasks/domain/task.dart lib/features/tasks/domain/task.freezed.dart
git commit -m "feat(tasks): add Task and TaskInput domain models"
```

---

## Task 4: Domain — TasksRepository + TaskValidator + test

**Files:**
- Create: `lib/features/tasks/domain/tasks_repository.dart`
- Create: `lib/features/tasks/domain/task_validator.dart`
- Create: `test/unit/features/tasks/task_validator_test.dart`

- [ ] **Step 1: Crear tasks_repository.dart**

```dart
// lib/features/tasks/domain/tasks_repository.dart
import 'task.dart';

abstract interface class TasksRepository {
  Stream<List<Task>> watchHomeTasks(String homeId);
  Future<Task> fetchTask(String homeId, String taskId);
  Future<String> createTask(
      String homeId, TaskInput input, String createdByUid);
  Future<void> updateTask(String homeId, String taskId, TaskInput input);
  Future<void> freezeTask(String homeId, String taskId);
  Future<void> unfreezeTask(String homeId, String taskId);
  Future<void> deleteTask(String homeId, String taskId, String deletedByUid);
  Future<void> reorderAssignees(
      String homeId, String taskId, List<String> order);
}
```

- [ ] **Step 2: Crear task_validator.dart**

```dart
// lib/features/tasks/domain/task_validator.dart
import 'task.dart';

sealed class ValidationResult {
  const ValidationResult();
  static const ValidationResult ok = _Ok();
  static ValidationResult error(String field, String code) =>
      _Error(field, code);

  bool get isOk => this is _Ok;
  ({String field, String code})? get failure =>
      this is _Error
          ? (field: (this as _Error).field, code: (this as _Error).code)
          : null;
}

final class _Ok extends ValidationResult {
  const _Ok();
}

final class _Error extends ValidationResult {
  final String field;
  final String code;
  const _Error(this.field, this.code);
}

class TaskValidator {
  static ValidationResult validate(TaskInput input) {
    if (input.title.trim().isEmpty) {
      return ValidationResult.error('title', 'tasks_validation_title_empty');
    }
    if (input.title.trim().length > 60) {
      return ValidationResult.error('title', 'tasks_validation_title_too_long');
    }
    if (input.assignmentOrder.isEmpty) {
      return ValidationResult.error(
          'assignees', 'tasks_validation_no_assignees');
    }
    if (input.difficultyWeight < 0.5 || input.difficultyWeight > 3.0) {
      return ValidationResult.error(
          'difficulty', 'tasks_validation_difficulty_range');
    }
    return ValidationResult.ok;
  }
}
```

- [ ] **Step 3: Escribir el test que falla**

```dart
// test/unit/features/tasks/task_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_validator.dart';

TaskInput _validInput({
  String title = 'Fregar',
  List<String> assignees = const ['uid1'],
  double weight = 1.0,
}) =>
    TaskInput(
      title: title,
      visualKind: 'emoji',
      visualValue: '🍽️',
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '20:00', timezone: 'Europe/Madrid'),
      assignmentMode: 'basicRotation',
      assignmentOrder: assignees,
      difficultyWeight: weight,
    );

void main() {
  group('TaskValidator', () {
    test('válido → ok', () {
      final result = TaskValidator.validate(_validInput());
      expect(result.isOk, isTrue);
    });

    test('título vacío → error', () {
      final result = TaskValidator.validate(_validInput(title: ''));
      expect(result.isOk, isFalse);
      expect(result.failure?.field, 'title');
      expect(result.failure?.code, 'tasks_validation_title_empty');
    });

    test('título con espacios → error vacío', () {
      final result = TaskValidator.validate(_validInput(title: '   '));
      expect(result.isOk, isFalse);
      expect(result.failure?.field, 'title');
    });

    test('título > 60 chars → error', () {
      final result =
          TaskValidator.validate(_validInput(title: 'A' * 61));
      expect(result.isOk, isFalse);
      expect(result.failure?.code, 'tasks_validation_title_too_long');
    });

    test('sin asignados → error', () {
      final result = TaskValidator.validate(_validInput(assignees: []));
      expect(result.isOk, isFalse);
      expect(result.failure?.field, 'assignees');
    });

    test('peso fuera de rango → error', () {
      final result = TaskValidator.validate(_validInput(weight: 0.4));
      expect(result.isOk, isFalse);
      expect(result.failure?.field, 'difficulty');
    });

    test('peso en límite inferior → ok', () {
      expect(TaskValidator.validate(_validInput(weight: 0.5)).isOk, isTrue);
    });

    test('peso en límite superior → ok', () {
      expect(TaskValidator.validate(_validInput(weight: 3.0)).isOk, isTrue);
    });
  });
}
```

- [ ] **Step 4: Ejecutar test para ver que falla**

```bash
flutter test test/unit/features/tasks/task_validator_test.dart
```

Expected: FAIL (archivos no existen todavía / error de compilación).

- [ ] **Step 5: Ejecutar test para ver que pasa**

El código ya fue escrito en los pasos anteriores. Ejecutar:

```bash
flutter test test/unit/features/tasks/task_validator_test.dart
```

Expected: All 8 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/tasks/domain/tasks_repository.dart lib/features/tasks/domain/task_validator.dart test/unit/features/tasks/task_validator_test.dart
git commit -m "feat(tasks): add TasksRepository interface and TaskValidator with tests"
```

---

## Task 5: RecurrenceCalculator + tests

**Files:**
- Create: `lib/core/utils/recurrence_calculator.dart`
- Create: `test/unit/features/tasks/recurrence_calculator_test.dart`

- [ ] **Step 1: Crear recurrence_calculator.dart**

```dart
// lib/core/utils/recurrence_calculator.dart
import 'package:timezone/timezone.dart' as tz;

import '../../features/tasks/domain/recurrence_rule.dart';

class RecurrenceCalculator {
  /// Calcula la próxima ocurrencia DESPUÉS de [from].
  static DateTime nextDue(RecurrenceRule rule, DateTime from) {
    return switch (rule) {
      HourlyRule r => _nextHourly(r, from),
      DailyRule r => _nextDaily(r, from),
      WeeklyRule r => _nextWeekly(r, from),
      MonthlyFixedRule r => _nextMonthlyFixed(r, from),
      MonthlyNthRule r => _nextMonthlyNth(r, from),
      YearlyFixedRule r => _nextYearlyFixed(r, from),
      YearlyNthRule r => _nextYearlyNth(r, from),
    };
  }

  /// Devuelve las próximas [n] ocurrencias a partir de [from].
  static List<DateTime> nextNOccurrences(
      RecurrenceRule rule, DateTime from, int n) {
    final result = <DateTime>[];
    var current = from;
    for (var i = 0; i < n; i++) {
      final next = nextDue(rule, current);
      result.add(next);
      current = next;
    }
    return result;
  }

  // ── helpers ────────────────────────────────────────────────────────

  static ({int h, int m}) _parseTime(String time) {
    final parts = time.split(':');
    return (h: int.parse(parts[0]), m: int.parse(parts[1]));
  }

  static int _weekdayToInt(String day) {
    const map = {
      'MON': DateTime.monday,
      'TUE': DateTime.tuesday,
      'WED': DateTime.wednesday,
      'THU': DateTime.thursday,
      'FRI': DateTime.friday,
      'SAT': DateTime.saturday,
      'SUN': DateTime.sunday,
    };
    return map[day]!;
  }

  static DateTime? _nthWeekdayOfMonth(
      int year, int month, int n, int weekday) {
    var count = 0;
    final lastDay = DateTime(year, month + 1, 0).day;
    for (var day = 1; day <= lastDay; day++) {
      if (DateTime(year, month, day).weekday == weekday) {
        count++;
        if (count == n) return DateTime(year, month, day);
      }
    }
    return null;
  }

  // ── rule implementations ────────────────────────────────────────────

  static DateTime _nextHourly(HourlyRule rule, DateTime from) {
    final location = tz.getLocation(rule.timezone);
    final tzFrom = tz.TZDateTime.from(from, location);
    var candidate = tzFrom.add(Duration(hours: rule.every));

    if (rule.endTime != null) {
      final end = _parseTime(rule.endTime!);
      final start = _parseTime(rule.startTime);
      final candidateMins = candidate.hour * 60 + candidate.minute;
      final endMins = end.h * 60 + end.m;
      if (candidateMins > endMins) {
        final nextDate =
            DateTime(candidate.year, candidate.month, candidate.day + 1);
        candidate = tz.TZDateTime(
            location, nextDate.year, nextDate.month, nextDate.day,
            start.h, start.m);
      }
    }
    return candidate.toLocal();
  }

  static DateTime _nextDaily(DailyRule rule, DateTime from) {
    final location = tz.getLocation(rule.timezone);
    final tzFrom = tz.TZDateTime.from(from, location);
    final t = _parseTime(rule.time);

    var candidate =
        tz.TZDateTime(location, tzFrom.year, tzFrom.month, tzFrom.day, t.h, t.m);
    while (!candidate.isAfter(tzFrom)) {
      final next =
          DateTime(candidate.year, candidate.month, candidate.day + rule.every);
      candidate = tz.TZDateTime(location, next.year, next.month, next.day, t.h, t.m);
    }
    return candidate.toLocal();
  }

  static DateTime _nextWeekly(WeeklyRule rule, DateTime from) {
    final location = tz.getLocation(rule.timezone);
    final tzFrom = tz.TZDateTime.from(from, location);
    final t = _parseTime(rule.time);
    final weekdayInts = rule.weekdays.map(_weekdayToInt).toSet();

    for (var i = 0; i < 8; i++) {
      final date =
          DateTime(tzFrom.year, tzFrom.month, tzFrom.day + i);
      if (weekdayInts.contains(date.weekday)) {
        final candidate = tz.TZDateTime(
            location, date.year, date.month, date.day, t.h, t.m);
        if (candidate.isAfter(tzFrom)) return candidate.toLocal();
      }
    }
    // Si todos los candidatos de esta semana ya pasaron, avanzar 7 días
    final date = DateTime(tzFrom.year, tzFrom.month, tzFrom.day + 7);
    for (var i = 0; i < 7; i++) {
      final d = DateTime(date.year, date.month, date.day + i);
      if (weekdayInts.contains(d.weekday)) {
        final candidate =
            tz.TZDateTime(location, d.year, d.month, d.day, t.h, t.m);
        if (candidate.isAfter(tzFrom)) return candidate.toLocal();
      }
    }
    throw StateError('No weekly occurrence found for weekdays=${rule.weekdays}');
  }

  static DateTime _nextMonthlyFixed(MonthlyFixedRule rule, DateTime from) {
    final location = tz.getLocation(rule.timezone);
    final tzFrom = tz.TZDateTime.from(from, location);
    final t = _parseTime(rule.time);
    var year = tzFrom.year;
    var month = tzFrom.month;

    for (var i = 0; i < 13; i++) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final day = rule.day.clamp(1, lastDay);
      final candidate =
          tz.TZDateTime(location, year, month, day, t.h, t.m);
      if (candidate.isAfter(tzFrom)) return candidate.toLocal();
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    throw StateError('No monthly fixed occurrence found');
  }

  static DateTime _nextMonthlyNth(MonthlyNthRule rule, DateTime from) {
    final location = tz.getLocation(rule.timezone);
    final tzFrom = tz.TZDateTime.from(from, location);
    final t = _parseTime(rule.time);
    final weekdayInt = _weekdayToInt(rule.weekday);
    var year = tzFrom.year;
    var month = tzFrom.month;

    for (var i = 0; i < 13; i++) {
      final date = _nthWeekdayOfMonth(year, month, rule.weekOfMonth, weekdayInt);
      if (date != null) {
        final candidate =
            tz.TZDateTime(location, date.year, date.month, date.day, t.h, t.m);
        if (candidate.isAfter(tzFrom)) return candidate.toLocal();
      }
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    throw StateError('No monthly Nth occurrence found');
  }

  static DateTime _nextYearlyFixed(YearlyFixedRule rule, DateTime from) {
    final location = tz.getLocation(rule.timezone);
    final tzFrom = tz.TZDateTime.from(from, location);
    final t = _parseTime(rule.time);
    var year = tzFrom.year;

    for (var i = 0; i < 3; i++) {
      final lastDay = DateTime(year, rule.month + 1, 0).day;
      final day = rule.day.clamp(1, lastDay);
      final candidate =
          tz.TZDateTime(location, year, rule.month, day, t.h, t.m);
      if (candidate.isAfter(tzFrom)) return candidate.toLocal();
      year++;
    }
    throw StateError('No yearly fixed occurrence found');
  }

  static DateTime _nextYearlyNth(YearlyNthRule rule, DateTime from) {
    final location = tz.getLocation(rule.timezone);
    final tzFrom = tz.TZDateTime.from(from, location);
    final t = _parseTime(rule.time);
    final weekdayInt = _weekdayToInt(rule.weekday);
    var year = tzFrom.year;

    for (var i = 0; i < 3; i++) {
      final date =
          _nthWeekdayOfMonth(year, rule.month, rule.weekOfMonth, weekdayInt);
      if (date != null) {
        final candidate =
            tz.TZDateTime(location, date.year, date.month, date.day, t.h, t.m);
        if (candidate.isAfter(tzFrom)) return candidate.toLocal();
      }
      year++;
    }
    throw StateError('No yearly Nth occurrence found');
  }
}
```

- [ ] **Step 2: Escribir tests del RecurrenceCalculator**

```dart
// test/unit/features/tasks/recurrence_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:toka/core/utils/recurrence_calculator.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';

void main() {
  setUpAll(() => tz_data.initializeTimeZones());

  // Helper: crea un DateTime en zona horaria Madrid
  DateTime madridTime(int year, int month, int day, int hour, int minute) {
    return DateTime(year, month, day, hour, minute);
  }

  group('Daily', () {
    const rule = RecurrenceRule.daily(
        every: 1, time: '20:00', timezone: 'Europe/Madrid');

    test('mismo día antes de las 20h → hoy a las 20h', () {
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.hour, 20);
      expect(next.day, 7);
    });

    test('mismo día después de las 20h → mañana a las 20h', () {
      final from = madridTime(2026, 4, 7, 21, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.day, 8);
      expect(next.hour, 20);
    });

    test('cada 3 días', () {
      final rule3 = const RecurrenceRule.daily(
          every: 3, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0); // pasó las 9h
      final next = RecurrenceCalculator.nextDue(rule3, from);
      expect(next.day, 10);
    });
  });

  group('Weekly', () {
    test('próximo lunes desde martes', () {
      final rule = const RecurrenceRule.weekly(
          weekdays: ['MON'], time: '09:00', timezone: 'Europe/Madrid');
      // 2026-04-07 es martes
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.weekday, DateTime.monday);
      expect(next.isAfter(from), isTrue);
    });

    test('mismo día pero antes de la hora → hoy', () {
      // 2026-04-06 es lunes
      final rule = const RecurrenceRule.weekly(
          weekdays: ['MON'], time: '20:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 6, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.weekday, DateTime.monday);
      expect(next.day, 6);
    });
  });

  group('Monthly Fixed', () {
    test('día 15 del mes actual si no ha pasado', () {
      final rule = const RecurrenceRule.monthlyFixed(
          day: 15, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.day, 15);
      expect(next.month, 4);
    });

    test('ya pasó el 15 → día 15 del mes siguiente', () {
      final rule = const RecurrenceRule.monthlyFixed(
          day: 15, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 16, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.month, 5);
      expect(next.day, 15);
    });

    test('día 31 en mes de 30 días → clamp a día 30', () {
      final rule = const RecurrenceRule.monthlyFixed(
          day: 31, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 1, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.month, 4);
      expect(next.day, 30);
    });
  });

  group('Monthly Nth', () {
    test('2.º martes de abril', () {
      final rule = const RecurrenceRule.monthlyNth(
          weekOfMonth: 2, weekday: 'TUE',
          time: '09:00', timezone: 'Europe/Madrid');
      // Desde el 1 de abril
      final from = madridTime(2026, 4, 1, 0, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.weekday, DateTime.tuesday);
      expect(next.month, 4);
    });
  });

  group('Yearly Fixed', () {
    test('15 de marzo cada año', () {
      final rule = const RecurrenceRule.yearlyFixed(
          month: 3, day: 15, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0); // ya pasó marzo
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.month, 3);
      expect(next.year, 2027);
    });
  });

  group('Yearly Nth', () {
    test('primer lunes de marzo', () {
      final rule = const RecurrenceRule.yearlyNth(
          month: 3, weekOfMonth: 1, weekday: 'MON',
          time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.month, 3);
      expect(next.year, 2027);
      expect(next.weekday, DateTime.monday);
    });
  });

  group('Hourly', () {
    test('añade N horas', () {
      final rule = const RecurrenceRule.hourly(
          every: 4, startTime: '08:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.hour, 14);
    });

    test('con endTime: si supera endTime → siguiente día a startTime', () {
      final rule = const RecurrenceRule.hourly(
          every: 4, startTime: '08:00', endTime: '20:00',
          timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 18, 0); // 18h + 4h = 22h > 20h
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.hour, 8);
      expect(next.day, 8);
    });
  });

  group('nextNOccurrences', () {
    test('devuelve N fechas en orden creciente', () {
      const rule = RecurrenceRule.daily(
          every: 1, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0);
      final dates = RecurrenceCalculator.nextNOccurrences(rule, from, 3);
      expect(dates.length, 3);
      expect(dates[0].isBefore(dates[1]), isTrue);
      expect(dates[1].isBefore(dates[2]), isTrue);
    });
  });
}
```

- [ ] **Step 3: Ejecutar tests**

```bash
flutter test test/unit/features/tasks/recurrence_calculator_test.dart
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/core/utils/recurrence_calculator.dart test/unit/features/tasks/recurrence_calculator_test.dart
git commit -m "feat(tasks): add RecurrenceCalculator with DST support and tests"
```

---

## Task 6: Data — TaskModel + TasksRepositoryImpl + integration test

**Files:**
- Create: `lib/features/tasks/data/task_model.dart`
- Create: `lib/features/tasks/data/tasks_repository_impl.dart`
- Create: `test/integration/features/tasks/tasks_crud_test.dart`

- [ ] **Step 1: Crear task_model.dart**

```dart
// lib/features/tasks/data/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';

class TaskModel {
  static Task fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Task(
      id: doc.id,
      homeId: d['homeId'] as String,
      title: d['title'] as String,
      description: d['description'] as String?,
      visualKind: d['visualKind'] as String? ?? 'emoji',
      visualValue: d['visualValue'] as String? ?? '🏠',
      status: TaskStatus.fromString(d['status'] as String? ?? 'active'),
      recurrenceType: d['recurrenceType'] as String,
      recurrenceRule: _ruleFromMap(
          d['recurrenceRule'] as Map<String, dynamic>? ?? {}),
      assignmentMode: d['assignmentMode'] as String? ?? 'basicRotation',
      assignmentOrder:
          List<String>.from(d['assignmentOrder'] as List? ?? []),
      currentAssigneeUid: d['currentAssigneeUid'] as String?,
      nextDueAt: (d['nextDueAt'] as Timestamp).toDate(),
      difficultyWeight: (d['difficultyWeight'] as num?)?.toDouble() ?? 1.0,
      completedCount90d: (d['completedCount90d'] as int?) ?? 0,
      createdByUid: d['createdByUid'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> toFirestore(
      TaskInput input, String homeId, String createdByUid, DateTime nextDueAt) {
    return {
      'homeId': homeId,
      'title': input.title.trim(),
      'description': input.description?.trim(),
      'visualKind': input.visualKind,
      'visualValue': input.visualValue,
      'status': 'active',
      'recurrenceType': _recurrenceTypeFromRule(input.recurrenceRule),
      'recurrenceRule': _ruleToMap(input.recurrenceRule),
      'assignmentMode': input.assignmentMode,
      'assignmentOrder': input.assignmentOrder,
      'currentAssigneeUid':
          input.assignmentOrder.isNotEmpty ? input.assignmentOrder.first : null,
      'nextDueAt': Timestamp.fromDate(nextDueAt),
      'difficultyWeight': input.difficultyWeight,
      'completedCount90d': 0,
      'createdByUid': createdByUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> toUpdateMap(
      TaskInput input, DateTime nextDueAt) {
    return {
      'title': input.title.trim(),
      'description': input.description?.trim(),
      'visualKind': input.visualKind,
      'visualValue': input.visualValue,
      'recurrenceType': _recurrenceTypeFromRule(input.recurrenceRule),
      'recurrenceRule': _ruleToMap(input.recurrenceRule),
      'assignmentMode': input.assignmentMode,
      'assignmentOrder': input.assignmentOrder,
      'currentAssigneeUid':
          input.assignmentOrder.isNotEmpty ? input.assignmentOrder.first : null,
      'nextDueAt': Timestamp.fromDate(nextDueAt),
      'difficultyWeight': input.difficultyWeight,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── serialización RecurrenceRule ────────────────────────────────────

  static String _recurrenceTypeFromRule(RecurrenceRule rule) => switch (rule) {
        HourlyRule _ => 'hourly',
        DailyRule _ => 'daily',
        WeeklyRule _ => 'weekly',
        MonthlyFixedRule _ => 'monthly',
        MonthlyNthRule _ => 'monthly',
        YearlyFixedRule _ => 'yearly',
        YearlyNthRule _ => 'yearly',
      };

  static Map<String, dynamic> _ruleToMap(RecurrenceRule rule) =>
      switch (rule) {
        HourlyRule r => {
            'type': 'hourly',
            'every': r.every,
            'startTime': r.startTime,
            'endTime': r.endTime,
            'timezone': r.timezone,
          },
        DailyRule r => {
            'type': 'daily',
            'every': r.every,
            'time': r.time,
            'timezone': r.timezone,
          },
        WeeklyRule r => {
            'type': 'weekly',
            'weekdays': r.weekdays,
            'time': r.time,
            'timezone': r.timezone,
          },
        MonthlyFixedRule r => {
            'type': 'monthlyFixed',
            'day': r.day,
            'time': r.time,
            'timezone': r.timezone,
          },
        MonthlyNthRule r => {
            'type': 'monthlyNth',
            'weekOfMonth': r.weekOfMonth,
            'weekday': r.weekday,
            'time': r.time,
            'timezone': r.timezone,
          },
        YearlyFixedRule r => {
            'type': 'yearlyFixed',
            'month': r.month,
            'day': r.day,
            'time': r.time,
            'timezone': r.timezone,
          },
        YearlyNthRule r => {
            'type': 'yearlyNth',
            'month': r.month,
            'weekOfMonth': r.weekOfMonth,
            'weekday': r.weekday,
            'time': r.time,
            'timezone': r.timezone,
          },
      };

  static RecurrenceRule _ruleFromMap(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'daily';
    return switch (type) {
      'hourly' => RecurrenceRule.hourly(
          every: (map['every'] as int?) ?? 1,
          startTime: map['startTime'] as String? ?? '08:00',
          endTime: map['endTime'] as String?,
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'daily' => RecurrenceRule.daily(
          every: (map['every'] as int?) ?? 1,
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'weekly' => RecurrenceRule.weekly(
          weekdays: List<String>.from(map['weekdays'] as List? ?? ['MON']),
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'monthlyFixed' => RecurrenceRule.monthlyFixed(
          day: (map['day'] as int?) ?? 1,
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'monthlyNth' => RecurrenceRule.monthlyNth(
          weekOfMonth: (map['weekOfMonth'] as int?) ?? 1,
          weekday: map['weekday'] as String? ?? 'MON',
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'yearlyFixed' => RecurrenceRule.yearlyFixed(
          month: (map['month'] as int?) ?? 1,
          day: (map['day'] as int?) ?? 1,
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      'yearlyNth' => RecurrenceRule.yearlyNth(
          month: (map['month'] as int?) ?? 1,
          weekOfMonth: (map['weekOfMonth'] as int?) ?? 1,
          weekday: map['weekday'] as String? ?? 'MON',
          time: map['time'] as String? ?? '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
      _ => RecurrenceRule.daily(
          every: 1,
          time: '09:00',
          timezone: map['timezone'] as String? ?? 'UTC',
        ),
    };
  }
}
```

- [ ] **Step 2: Crear tasks_repository_impl.dart**

```dart
// lib/features/tasks/data/tasks_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/recurrence_calculator.dart';
import '../domain/task.dart';
import '../domain/tasks_repository.dart';
import 'task_model.dart';

class TasksRepositoryImpl implements TasksRepository {
  TasksRepositoryImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _col(String homeId) =>
      _db.collection('homes').doc(homeId).collection('tasks');

  @override
  Stream<List<Task>> watchHomeTasks(String homeId) {
    return _col(homeId)
        .where('status', whereIn: ['active', 'frozen'])
        .orderBy('nextDueAt')
        .snapshots()
        .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
  }

  @override
  Future<Task> fetchTask(String homeId, String taskId) async {
    final doc = await _col(homeId).doc(taskId).get();
    return TaskModel.fromFirestore(doc);
  }

  @override
  Future<String> createTask(
      String homeId, TaskInput input, String createdByUid) async {
    final id = _uuid.v4();
    final nextDue = RecurrenceCalculator.nextDue(
        input.recurrenceRule, DateTime.now());
    final data = TaskModel.toFirestore(input, homeId, createdByUid, nextDue);
    await _col(homeId).doc(id).set(data);
    return id;
  }

  @override
  Future<void> updateTask(
      String homeId, String taskId, TaskInput input) async {
    final nextDue = RecurrenceCalculator.nextDue(
        input.recurrenceRule, DateTime.now());
    final data = TaskModel.toUpdateMap(input, nextDue);
    await _col(homeId).doc(taskId).update(data);
  }

  @override
  Future<void> freezeTask(String homeId, String taskId) =>
      _col(homeId).doc(taskId).update({
        'status': 'frozen',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> unfreezeTask(String homeId, String taskId) =>
      _col(homeId).doc(taskId).update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> deleteTask(
      String homeId, String taskId, String deletedByUid) =>
      _col(homeId).doc(taskId).update({
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> reorderAssignees(
      String homeId, String taskId, List<String> order) =>
      _col(homeId).doc(taskId).update({
        'assignmentOrder': order,
        'currentAssigneeUid': order.isNotEmpty ? order.first : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
```

- [ ] **Step 3: Escribir integration test**

```dart
// test/integration/features/tasks/tasks_crud_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:toka/features/tasks/data/tasks_repository_impl.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';

const _homeId = 'home1';
const _uid = 'user1';

TaskInput _dailyInput({String title = 'Fregar'}) => TaskInput(
      title: title,
      visualKind: 'emoji',
      visualValue: '🍽️',
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '20:00', timezone: 'Europe/Madrid'),
      assignmentMode: 'basicRotation',
      assignmentOrder: [_uid],
    );

void main() {
  setUpAll(() => tz_data.initializeTimeZones());

  late FakeFirebaseFirestore fakeDb;
  late TasksRepositoryImpl repo;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    repo = TasksRepositoryImpl(firestore: fakeDb);
  });

  test('createTask → documento creado con status active', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    final doc = await fakeDb
        .collection('homes').doc(_homeId).collection('tasks').doc(id).get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['status'], 'active');
    expect(doc.data()!['title'], 'Fregar');
    expect(doc.data()!['currentAssigneeUid'], _uid);
  });

  test('watchHomeTasks emite la tarea creada', () async {
    await repo.createTask(_homeId, _dailyInput(), _uid);
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Fregar');
    expect(tasks.first.status, TaskStatus.active);
  });

  test('updateTask → título actualizado', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    await repo.updateTask(_homeId, id, _dailyInput(title: 'Planchar'));
    final task = await repo.fetchTask(_homeId, id);
    expect(task.title, 'Planchar');
  });

  test('freezeTask → status frozen', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    await repo.freezeTask(_homeId, id);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.frozen);
  });

  test('unfreezeTask → status active', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    await repo.freezeTask(_homeId, id);
    await repo.unfreezeTask(_homeId, id);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.active);
  });

  test('deleteTask → soft delete (status=deleted), no aparece en watch', () async {
    final id = await repo.createTask(_homeId, _dailyInput(), _uid);
    await repo.deleteTask(_homeId, id, _uid);
    // fetchTask todavía puede leerlo
    final task = await repo.fetchTask(_homeId, id);
    expect(task.status, TaskStatus.deleted);
    // pero watchHomeTasks no lo incluye
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.where((t) => t.id == id), isEmpty);
  });

  test('reorderAssignees → actualiza orden y currentAssigneeUid', () async {
    final id = await repo.createTask(
        _homeId, _dailyInput().copyWith(assignmentOrder: ['u1', 'u2']), _uid);
    await repo.reorderAssignees(_homeId, id, ['u2', 'u1']);
    final task = await repo.fetchTask(_homeId, id);
    expect(task.assignmentOrder, ['u2', 'u1']);
    expect(task.currentAssigneeUid, 'u2');
  });

  test('watchHomeTasks no incluye tareas deleted', () async {
    final id1 = await repo.createTask(_homeId, _dailyInput(title: 'A'), _uid);
    final id2 = await repo.createTask(_homeId, _dailyInput(title: 'B'), _uid);
    await repo.deleteTask(_homeId, id2, _uid);
    final tasks = await repo.watchHomeTasks(_homeId).first;
    expect(tasks.length, 1);
    expect(tasks.first.id, id1);
  });
}
```

- [ ] **Step 4: Ejecutar integration test**

```bash
flutter test test/integration/features/tasks/tasks_crud_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/data/ test/integration/features/tasks/tasks_crud_test.dart
git commit -m "feat(tasks): add TaskModel, TasksRepositoryImpl, integration tests"
```

---

## Task 7: Application — providers

**Files:**
- Create: `lib/features/tasks/application/tasks_provider.dart`
- Create: `lib/features/tasks/application/task_form_provider.dart`
- Create: `lib/features/tasks/application/recurrence_provider.dart`

- [ ] **Step 1: Crear tasks_provider.dart**

```dart
// lib/features/tasks/application/tasks_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/tasks_repository_impl.dart';
import '../domain/task.dart';
import '../domain/tasks_repository.dart';
import '../../homes/application/current_home_provider.dart';

part 'tasks_provider.g.dart';

@Riverpod(keepAlive: true)
TasksRepository tasksRepository(TasksRepositoryRef ref) {
  return TasksRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<List<Task>> homeTasks(HomeTasksRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  if (homeId == null) return const Stream.empty();
  return ref.watch(tasksRepositoryProvider).watchHomeTasks(homeId);
}
```

- [ ] **Step 2: Crear task_form_provider.dart**

```dart
// lib/features/tasks/application/task_form_provider.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/recurrence_calculator.dart';
import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_validator.dart';
import 'tasks_provider.dart';

part 'task_form_provider.freezed.dart';
part 'task_form_provider.g.dart';

enum TaskFormMode { create, edit }

@freezed
class TaskFormState with _$TaskFormState {
  const factory TaskFormState({
    @Default(TaskFormMode.create) TaskFormMode mode,
    String? editingTaskId,
    @Default('') String title,
    @Default('') String description,
    @Default('emoji') String visualKind,
    @Default('🏠') String visualValue,
    RecurrenceRule? recurrenceRule,
    @Default('basicRotation') String assignmentMode,
    @Default([]) List<String> assignmentOrder,
    @Default(1.0) double difficultyWeight,
    @Default(false) bool isLoading,
    @Default({}) Map<String, String> fieldErrors,
    String? globalError,
  }) = _TaskFormState;
}

@riverpod
class TaskFormNotifier extends _$TaskFormNotifier {
  @override
  TaskFormState build() => const TaskFormState();

  void initCreate() {
    state = const TaskFormState(mode: TaskFormMode.create);
  }

  void initEdit(Task task) {
    state = TaskFormState(
      mode: TaskFormMode.edit,
      editingTaskId: task.id,
      title: task.title,
      description: task.description ?? '',
      visualKind: task.visualKind,
      visualValue: task.visualValue,
      recurrenceRule: task.recurrenceRule,
      assignmentMode: task.assignmentMode,
      assignmentOrder: task.assignmentOrder,
      difficultyWeight: task.difficultyWeight,
    );
  }

  void setTitle(String v) => state = state.copyWith(title: v, fieldErrors: {
        ...state.fieldErrors..remove('title'),
      });

  void setDescription(String v) => state = state.copyWith(description: v);

  void setVisual(String kind, String value) =>
      state = state.copyWith(visualKind: kind, visualValue: value);

  void setRecurrenceRule(RecurrenceRule rule) =>
      state = state.copyWith(recurrenceRule: rule, fieldErrors: {
        ...state.fieldErrors..remove('recurrence'),
      });

  void setAssignmentMode(String mode) =>
      state = state.copyWith(assignmentMode: mode);

  void setAssignmentOrder(List<String> order) =>
      state = state.copyWith(assignmentOrder: order, fieldErrors: {
        ...state.fieldErrors..remove('assignees'),
      });

  void setDifficultyWeight(double v) =>
      state = state.copyWith(difficultyWeight: v);

  /// Guarda la tarea. Devuelve el ID si fue exitoso, null si hay errores.
  Future<String?> save(String homeId, String createdByUid) async {
    if (state.recurrenceRule == null) {
      state = state.copyWith(fieldErrors: {
        ...state.fieldErrors,
        'recurrence': 'tasks_validation_recurrence_required',
      });
      return null;
    }

    final input = TaskInput(
      title: state.title,
      description: state.description.isEmpty ? null : state.description,
      visualKind: state.visualKind,
      visualValue: state.visualValue,
      recurrenceRule: state.recurrenceRule!,
      assignmentMode: state.assignmentMode,
      assignmentOrder: state.assignmentOrder,
      difficultyWeight: state.difficultyWeight,
    );

    final validation = TaskValidator.validate(input);
    if (!validation.isOk) {
      final f = validation.failure!;
      state = state.copyWith(fieldErrors: {
        ...state.fieldErrors,
        f.field: f.code,
      });
      return null;
    }

    state = state.copyWith(isLoading: true, globalError: null);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      String taskId;
      if (state.mode == TaskFormMode.create) {
        taskId = await repo.createTask(homeId, input, createdByUid);
      } else {
        taskId = state.editingTaskId!;
        await repo.updateTask(homeId, taskId, input);
      }
      state = state.copyWith(isLoading: false);
      return taskId;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, globalError: 'tasks_save_error');
      return null;
    }
  }
}
```

- [ ] **Step 3: Crear recurrence_provider.dart**

```dart
// lib/features/tasks/application/recurrence_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/recurrence_calculator.dart';
import '../domain/recurrence_rule.dart';

part 'recurrence_provider.g.dart';

@riverpod
List<DateTime> upcomingOccurrences(
    UpcomingOccurrencesRef ref, RecurrenceRule? rule) {
  if (rule == null) return [];
  try {
    return RecurrenceCalculator.nextNOccurrences(rule, DateTime.now(), 3);
  } catch (_) {
    return [];
  }
}
```

- [ ] **Step 4: Generar código Riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: Genera `tasks_provider.g.dart`, `task_form_provider.g.dart`, `task_form_provider.freezed.dart`, `recurrence_provider.g.dart`. Sin errores.

- [ ] **Step 5: Verificar análisis**

```bash
flutter analyze lib/features/tasks/application/
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/features/tasks/application/
git commit -m "feat(tasks): add tasks_provider, task_form_provider, recurrence_provider"
```

---

## Task 8: i18n — ARB + AppLocalizations

**Files:**
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ro.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_es.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_ro.dart`

- [ ] **Step 1: Añadir claves a app_es.arb**

Insertar antes del `}` final de `lib/l10n/app_es.arb`:

```json
  ,
  "tasks_title": "Tareas",
  "tasks_empty_title": "Sin tareas",
  "tasks_empty_body": "Crea tu primera tarea para empezar",
  "tasks_empty_cta": "Crear primera tarea",
  "tasks_create_title": "Crear tarea",
  "tasks_edit_title": "Editar tarea",
  "tasks_field_visual": "Icono o emoji",
  "tasks_field_title_hint": "Ej: Fregar los platos",
  "tasks_field_description_hint": "Descripción (opcional)",
  "tasks_field_recurrence": "Recurrencia",
  "tasks_field_assignment_mode": "Modo de asignación",
  "tasks_field_difficulty": "Dificultad",
  "tasks_assignment_basic_rotation": "Rotación básica",
  "tasks_assignment_smart": "Distribución inteligente",
  "tasks_assignment_members": "Miembros asignados",
  "tasks_recurrence_every": "Cada",
  "tasks_recurrence_hours": "horas",
  "tasks_recurrence_days": "días",
  "tasks_recurrence_start_time": "Hora inicio",
  "tasks_recurrence_end_time": "Hora fin (opcional)",
  "tasks_recurrence_time": "Hora",
  "tasks_recurrence_day_of_month": "Día del mes",
  "tasks_recurrence_week_of_month": "Semana del mes",
  "tasks_recurrence_weekday": "Día de la semana",
  "tasks_recurrence_month": "Mes",
  "tasks_recurrence_timezone": "Zona horaria",
  "tasks_recurrence_upcoming": "Próximas fechas",
  "tasks_recurrence_hourly_label": "Cada hora",
  "tasks_recurrence_daily_label": "Diario",
  "tasks_recurrence_weekly_label": "Semanal",
  "tasks_recurrence_monthly_fixed_label": "Mensual (día fijo)",
  "tasks_recurrence_monthly_nth_label": "Mensual (Nth semana)",
  "tasks_recurrence_yearly_fixed_label": "Anual (fecha fija)",
  "tasks_recurrence_yearly_nth_label": "Anual (Nth semana)",
  "tasks_section_active": "Activas",
  "tasks_section_frozen": "Congeladas",
  "tasks_action_edit": "Editar",
  "tasks_action_freeze": "Congelar",
  "tasks_action_unfreeze": "Descongelar",
  "tasks_action_delete": "Eliminar",
  "tasks_delete_confirm_title": "¿Eliminar tarea?",
  "tasks_delete_confirm_body": "Esta acción no se puede deshacer.",
  "tasks_delete_confirm_btn": "Sí, eliminar",
  "tasks_freeze_success": "Tarea congelada",
  "tasks_unfreeze_success": "Tarea activada",
  "tasks_save_error": "Error al guardar la tarea",
  "tasks_detail_next_occurrences": "Próximas fechas",
  "tasks_detail_assignment_order": "Orden de asignación",
  "tasks_validation_title_empty": "El título es obligatorio",
  "tasks_validation_title_too_long": "Máximo 60 caracteres",
  "tasks_validation_no_assignees": "Selecciona al menos un miembro",
  "tasks_validation_difficulty_range": "El peso debe estar entre 0.5 y 3.0",
  "tasks_validation_recurrence_required": "Elige un tipo de recurrencia",
  "weekday_mon": "Lunes",
  "weekday_tue": "Martes",
  "weekday_wed": "Miércoles",
  "weekday_thu": "Jueves",
  "weekday_fri": "Viernes",
  "weekday_sat": "Sábado",
  "weekday_sun": "Domingo",
  "tasks_week_1st": "Primera",
  "tasks_week_2nd": "Segunda",
  "tasks_week_3rd": "Tercera",
  "tasks_week_4th": "Cuarta",
  "month_jan": "Enero", "month_feb": "Febrero", "month_mar": "Marzo",
  "month_apr": "Abril", "month_may": "Mayo", "month_jun": "Junio",
  "month_jul": "Julio", "month_aug": "Agosto", "month_sep": "Septiembre",
  "month_oct": "Octubre", "month_nov": "Noviembre", "month_dec": "Diciembre"
```

- [ ] **Step 2: Añadir claves a app_en.arb**

Insertar antes del `}` final de `lib/l10n/app_en.arb`:

```json
  ,
  "tasks_title": "Tasks",
  "tasks_empty_title": "No tasks",
  "tasks_empty_body": "Create your first task to get started",
  "tasks_empty_cta": "Create first task",
  "tasks_create_title": "Create task",
  "tasks_edit_title": "Edit task",
  "tasks_field_visual": "Icon or emoji",
  "tasks_field_title_hint": "E.g. Do the dishes",
  "tasks_field_description_hint": "Description (optional)",
  "tasks_field_recurrence": "Recurrence",
  "tasks_field_assignment_mode": "Assignment mode",
  "tasks_field_difficulty": "Difficulty",
  "tasks_assignment_basic_rotation": "Basic rotation",
  "tasks_assignment_smart": "Smart distribution",
  "tasks_assignment_members": "Assigned members",
  "tasks_recurrence_every": "Every",
  "tasks_recurrence_hours": "hours",
  "tasks_recurrence_days": "days",
  "tasks_recurrence_start_time": "Start time",
  "tasks_recurrence_end_time": "End time (optional)",
  "tasks_recurrence_time": "Time",
  "tasks_recurrence_day_of_month": "Day of month",
  "tasks_recurrence_week_of_month": "Week of month",
  "tasks_recurrence_weekday": "Day of week",
  "tasks_recurrence_month": "Month",
  "tasks_recurrence_timezone": "Timezone",
  "tasks_recurrence_upcoming": "Upcoming dates",
  "tasks_recurrence_hourly_label": "Hourly",
  "tasks_recurrence_daily_label": "Daily",
  "tasks_recurrence_weekly_label": "Weekly",
  "tasks_recurrence_monthly_fixed_label": "Monthly (fixed day)",
  "tasks_recurrence_monthly_nth_label": "Monthly (Nth week)",
  "tasks_recurrence_yearly_fixed_label": "Yearly (fixed date)",
  "tasks_recurrence_yearly_nth_label": "Yearly (Nth week)",
  "tasks_section_active": "Active",
  "tasks_section_frozen": "Frozen",
  "tasks_action_edit": "Edit",
  "tasks_action_freeze": "Freeze",
  "tasks_action_unfreeze": "Unfreeze",
  "tasks_action_delete": "Delete",
  "tasks_delete_confirm_title": "Delete task?",
  "tasks_delete_confirm_body": "This action cannot be undone.",
  "tasks_delete_confirm_btn": "Yes, delete",
  "tasks_freeze_success": "Task frozen",
  "tasks_unfreeze_success": "Task activated",
  "tasks_save_error": "Error saving task",
  "tasks_detail_next_occurrences": "Upcoming dates",
  "tasks_detail_assignment_order": "Assignment order",
  "tasks_validation_title_empty": "Title is required",
  "tasks_validation_title_too_long": "Maximum 60 characters",
  "tasks_validation_no_assignees": "Select at least one member",
  "tasks_validation_difficulty_range": "Weight must be between 0.5 and 3.0",
  "tasks_validation_recurrence_required": "Choose a recurrence type",
  "weekday_mon": "Monday",
  "weekday_tue": "Tuesday",
  "weekday_wed": "Wednesday",
  "weekday_thu": "Thursday",
  "weekday_fri": "Friday",
  "weekday_sat": "Saturday",
  "weekday_sun": "Sunday",
  "tasks_week_1st": "First",
  "tasks_week_2nd": "Second",
  "tasks_week_3rd": "Third",
  "tasks_week_4th": "Fourth",
  "month_jan": "January", "month_feb": "February", "month_mar": "March",
  "month_apr": "April", "month_may": "May", "month_jun": "June",
  "month_jul": "July", "month_aug": "August", "month_sep": "September",
  "month_oct": "October", "month_nov": "November", "month_dec": "December"
```

- [ ] **Step 3: Añadir claves a app_ro.arb**

Insertar antes del `}` final de `lib/l10n/app_ro.arb`:

```json
  ,
  "tasks_title": "Sarcini",
  "tasks_empty_title": "Nicio sarcină",
  "tasks_empty_body": "Creează prima sarcină pentru a începe",
  "tasks_empty_cta": "Creează prima sarcină",
  "tasks_create_title": "Creează sarcină",
  "tasks_edit_title": "Editează sarcină",
  "tasks_field_visual": "Pictogramă sau emoji",
  "tasks_field_title_hint": "Ex: Spălat vasele",
  "tasks_field_description_hint": "Descriere (opțional)",
  "tasks_field_recurrence": "Recurență",
  "tasks_field_assignment_mode": "Mod de atribuire",
  "tasks_field_difficulty": "Dificultate",
  "tasks_assignment_basic_rotation": "Rotație de bază",
  "tasks_assignment_smart": "Distribuție inteligentă",
  "tasks_assignment_members": "Membri atribuiți",
  "tasks_recurrence_every": "La fiecare",
  "tasks_recurrence_hours": "ore",
  "tasks_recurrence_days": "zile",
  "tasks_recurrence_start_time": "Ora de început",
  "tasks_recurrence_end_time": "Ora de sfârșit (opțional)",
  "tasks_recurrence_time": "Ora",
  "tasks_recurrence_day_of_month": "Ziua lunii",
  "tasks_recurrence_week_of_month": "Săptămâna lunii",
  "tasks_recurrence_weekday": "Ziua săptămânii",
  "tasks_recurrence_month": "Luna",
  "tasks_recurrence_timezone": "Fus orar",
  "tasks_recurrence_upcoming": "Datele următoare",
  "tasks_recurrence_hourly_label": "Orar",
  "tasks_recurrence_daily_label": "Zilnic",
  "tasks_recurrence_weekly_label": "Săptămânal",
  "tasks_recurrence_monthly_fixed_label": "Lunar (zi fixă)",
  "tasks_recurrence_monthly_nth_label": "Lunar (a N-a săptămână)",
  "tasks_recurrence_yearly_fixed_label": "Anual (dată fixă)",
  "tasks_recurrence_yearly_nth_label": "Anual (a N-a săptămână)",
  "tasks_section_active": "Active",
  "tasks_section_frozen": "Înghețate",
  "tasks_action_edit": "Editează",
  "tasks_action_freeze": "Îngheață",
  "tasks_action_unfreeze": "Dezghețează",
  "tasks_action_delete": "Șterge",
  "tasks_delete_confirm_title": "Ștergi sarcina?",
  "tasks_delete_confirm_body": "Această acțiune nu poate fi anulată.",
  "tasks_delete_confirm_btn": "Da, șterge",
  "tasks_freeze_success": "Sarcină înghețată",
  "tasks_unfreeze_success": "Sarcină activată",
  "tasks_save_error": "Eroare la salvarea sarcinii",
  "tasks_detail_next_occurrences": "Datele următoare",
  "tasks_detail_assignment_order": "Ordinea de atribuire",
  "tasks_validation_title_empty": "Titlul este obligatoriu",
  "tasks_validation_title_too_long": "Maximum 60 de caractere",
  "tasks_validation_no_assignees": "Selectează cel puțin un membru",
  "tasks_validation_difficulty_range": "Greutatea trebuie să fie între 0.5 și 3.0",
  "tasks_validation_recurrence_required": "Alege un tip de recurență",
  "weekday_mon": "Luni",
  "weekday_tue": "Marți",
  "weekday_wed": "Miercuri",
  "weekday_thu": "Joi",
  "weekday_fri": "Vineri",
  "weekday_sat": "Sâmbătă",
  "weekday_sun": "Duminică",
  "tasks_week_1st": "Prima",
  "tasks_week_2nd": "A doua",
  "tasks_week_3rd": "A treia",
  "tasks_week_4th": "A patra",
  "month_jan": "Ianuarie", "month_feb": "Februarie", "month_mar": "Martie",
  "month_apr": "Aprilie", "month_may": "Mai", "month_jun": "Iunie",
  "month_jul": "Iulie", "month_aug": "August", "month_sep": "Septembrie",
  "month_oct": "Octombrie", "month_nov": "Noiembrie", "month_dec": "Decembrie"
```

- [ ] **Step 4: Añadir abstract getters a app_localizations.dart**

Insertar justo antes de la línea `}` que cierra la clase `AppLocalizations` (antes de `class _AppLocalizationsDelegate`):

```dart
  String get tasks_title;
  String get tasks_empty_title;
  String get tasks_empty_body;
  String get tasks_empty_cta;
  String get tasks_create_title;
  String get tasks_edit_title;
  String get tasks_field_visual;
  String get tasks_field_title_hint;
  String get tasks_field_description_hint;
  String get tasks_field_recurrence;
  String get tasks_field_assignment_mode;
  String get tasks_field_difficulty;
  String get tasks_assignment_basic_rotation;
  String get tasks_assignment_smart;
  String get tasks_assignment_members;
  String get tasks_recurrence_every;
  String get tasks_recurrence_hours;
  String get tasks_recurrence_days;
  String get tasks_recurrence_start_time;
  String get tasks_recurrence_end_time;
  String get tasks_recurrence_time;
  String get tasks_recurrence_day_of_month;
  String get tasks_recurrence_week_of_month;
  String get tasks_recurrence_weekday;
  String get tasks_recurrence_month;
  String get tasks_recurrence_timezone;
  String get tasks_recurrence_upcoming;
  String get tasks_recurrence_hourly_label;
  String get tasks_recurrence_daily_label;
  String get tasks_recurrence_weekly_label;
  String get tasks_recurrence_monthly_fixed_label;
  String get tasks_recurrence_monthly_nth_label;
  String get tasks_recurrence_yearly_fixed_label;
  String get tasks_recurrence_yearly_nth_label;
  String get tasks_section_active;
  String get tasks_section_frozen;
  String get tasks_action_edit;
  String get tasks_action_freeze;
  String get tasks_action_unfreeze;
  String get tasks_action_delete;
  String get tasks_delete_confirm_title;
  String get tasks_delete_confirm_body;
  String get tasks_delete_confirm_btn;
  String get tasks_freeze_success;
  String get tasks_unfreeze_success;
  String get tasks_save_error;
  String get tasks_detail_next_occurrences;
  String get tasks_detail_assignment_order;
  String get tasks_validation_title_empty;
  String get tasks_validation_title_too_long;
  String get tasks_validation_no_assignees;
  String get tasks_validation_difficulty_range;
  String get tasks_validation_recurrence_required;
  String get weekday_mon;
  String get weekday_tue;
  String get weekday_wed;
  String get weekday_thu;
  String get weekday_fri;
  String get weekday_sat;
  String get weekday_sun;
  String get tasks_week_1st;
  String get tasks_week_2nd;
  String get tasks_week_3rd;
  String get tasks_week_4th;
  String get month_jan;
  String get month_feb;
  String get month_mar;
  String get month_apr;
  String get month_may;
  String get month_jun;
  String get month_jul;
  String get month_aug;
  String get month_sep;
  String get month_oct;
  String get month_nov;
  String get month_dec;
```

- [ ] **Step 5: Añadir implementaciones a app_localizations_es.dart**

Al final de la clase `AppLocalizationsEs` (antes del `}`), añadir:

```dart
  @override String get tasks_title => 'Tareas';
  @override String get tasks_empty_title => 'Sin tareas';
  @override String get tasks_empty_body => 'Crea tu primera tarea para empezar';
  @override String get tasks_empty_cta => 'Crear primera tarea';
  @override String get tasks_create_title => 'Crear tarea';
  @override String get tasks_edit_title => 'Editar tarea';
  @override String get tasks_field_visual => 'Icono o emoji';
  @override String get tasks_field_title_hint => 'Ej: Fregar los platos';
  @override String get tasks_field_description_hint => 'Descripción (opcional)';
  @override String get tasks_field_recurrence => 'Recurrencia';
  @override String get tasks_field_assignment_mode => 'Modo de asignación';
  @override String get tasks_field_difficulty => 'Dificultad';
  @override String get tasks_assignment_basic_rotation => 'Rotación básica';
  @override String get tasks_assignment_smart => 'Distribución inteligente';
  @override String get tasks_assignment_members => 'Miembros asignados';
  @override String get tasks_recurrence_every => 'Cada';
  @override String get tasks_recurrence_hours => 'horas';
  @override String get tasks_recurrence_days => 'días';
  @override String get tasks_recurrence_start_time => 'Hora inicio';
  @override String get tasks_recurrence_end_time => 'Hora fin (opcional)';
  @override String get tasks_recurrence_time => 'Hora';
  @override String get tasks_recurrence_day_of_month => 'Día del mes';
  @override String get tasks_recurrence_week_of_month => 'Semana del mes';
  @override String get tasks_recurrence_weekday => 'Día de la semana';
  @override String get tasks_recurrence_month => 'Mes';
  @override String get tasks_recurrence_timezone => 'Zona horaria';
  @override String get tasks_recurrence_upcoming => 'Próximas fechas';
  @override String get tasks_recurrence_hourly_label => 'Cada hora';
  @override String get tasks_recurrence_daily_label => 'Diario';
  @override String get tasks_recurrence_weekly_label => 'Semanal';
  @override String get tasks_recurrence_monthly_fixed_label => 'Mensual (día fijo)';
  @override String get tasks_recurrence_monthly_nth_label => 'Mensual (Nth semana)';
  @override String get tasks_recurrence_yearly_fixed_label => 'Anual (fecha fija)';
  @override String get tasks_recurrence_yearly_nth_label => 'Anual (Nth semana)';
  @override String get tasks_section_active => 'Activas';
  @override String get tasks_section_frozen => 'Congeladas';
  @override String get tasks_action_edit => 'Editar';
  @override String get tasks_action_freeze => 'Congelar';
  @override String get tasks_action_unfreeze => 'Descongelar';
  @override String get tasks_action_delete => 'Eliminar';
  @override String get tasks_delete_confirm_title => '¿Eliminar tarea?';
  @override String get tasks_delete_confirm_body => 'Esta acción no se puede deshacer.';
  @override String get tasks_delete_confirm_btn => 'Sí, eliminar';
  @override String get tasks_freeze_success => 'Tarea congelada';
  @override String get tasks_unfreeze_success => 'Tarea activada';
  @override String get tasks_save_error => 'Error al guardar la tarea';
  @override String get tasks_detail_next_occurrences => 'Próximas fechas';
  @override String get tasks_detail_assignment_order => 'Orden de asignación';
  @override String get tasks_validation_title_empty => 'El título es obligatorio';
  @override String get tasks_validation_title_too_long => 'Máximo 60 caracteres';
  @override String get tasks_validation_no_assignees => 'Selecciona al menos un miembro';
  @override String get tasks_validation_difficulty_range => 'El peso debe estar entre 0.5 y 3.0';
  @override String get tasks_validation_recurrence_required => 'Elige un tipo de recurrencia';
  @override String get weekday_mon => 'Lunes';
  @override String get weekday_tue => 'Martes';
  @override String get weekday_wed => 'Miércoles';
  @override String get weekday_thu => 'Jueves';
  @override String get weekday_fri => 'Viernes';
  @override String get weekday_sat => 'Sábado';
  @override String get weekday_sun => 'Domingo';
  @override String get tasks_week_1st => 'Primera';
  @override String get tasks_week_2nd => 'Segunda';
  @override String get tasks_week_3rd => 'Tercera';
  @override String get tasks_week_4th => 'Cuarta';
  @override String get month_jan => 'Enero';
  @override String get month_feb => 'Febrero';
  @override String get month_mar => 'Marzo';
  @override String get month_apr => 'Abril';
  @override String get month_may => 'Mayo';
  @override String get month_jun => 'Junio';
  @override String get month_jul => 'Julio';
  @override String get month_aug => 'Agosto';
  @override String get month_sep => 'Septiembre';
  @override String get month_oct => 'Octubre';
  @override String get month_nov => 'Noviembre';
  @override String get month_dec => 'Diciembre';
```

- [ ] **Step 6: Añadir implementaciones a app_localizations_en.dart**

Al final de la clase `AppLocalizationsEn`:

```dart
  @override String get tasks_title => 'Tasks';
  @override String get tasks_empty_title => 'No tasks';
  @override String get tasks_empty_body => 'Create your first task to get started';
  @override String get tasks_empty_cta => 'Create first task';
  @override String get tasks_create_title => 'Create task';
  @override String get tasks_edit_title => 'Edit task';
  @override String get tasks_field_visual => 'Icon or emoji';
  @override String get tasks_field_title_hint => 'E.g. Do the dishes';
  @override String get tasks_field_description_hint => 'Description (optional)';
  @override String get tasks_field_recurrence => 'Recurrence';
  @override String get tasks_field_assignment_mode => 'Assignment mode';
  @override String get tasks_field_difficulty => 'Difficulty';
  @override String get tasks_assignment_basic_rotation => 'Basic rotation';
  @override String get tasks_assignment_smart => 'Smart distribution';
  @override String get tasks_assignment_members => 'Assigned members';
  @override String get tasks_recurrence_every => 'Every';
  @override String get tasks_recurrence_hours => 'hours';
  @override String get tasks_recurrence_days => 'days';
  @override String get tasks_recurrence_start_time => 'Start time';
  @override String get tasks_recurrence_end_time => 'End time (optional)';
  @override String get tasks_recurrence_time => 'Time';
  @override String get tasks_recurrence_day_of_month => 'Day of month';
  @override String get tasks_recurrence_week_of_month => 'Week of month';
  @override String get tasks_recurrence_weekday => 'Day of week';
  @override String get tasks_recurrence_month => 'Month';
  @override String get tasks_recurrence_timezone => 'Timezone';
  @override String get tasks_recurrence_upcoming => 'Upcoming dates';
  @override String get tasks_recurrence_hourly_label => 'Hourly';
  @override String get tasks_recurrence_daily_label => 'Daily';
  @override String get tasks_recurrence_weekly_label => 'Weekly';
  @override String get tasks_recurrence_monthly_fixed_label => 'Monthly (fixed day)';
  @override String get tasks_recurrence_monthly_nth_label => 'Monthly (Nth week)';
  @override String get tasks_recurrence_yearly_fixed_label => 'Yearly (fixed date)';
  @override String get tasks_recurrence_yearly_nth_label => 'Yearly (Nth week)';
  @override String get tasks_section_active => 'Active';
  @override String get tasks_section_frozen => 'Frozen';
  @override String get tasks_action_edit => 'Edit';
  @override String get tasks_action_freeze => 'Freeze';
  @override String get tasks_action_unfreeze => 'Unfreeze';
  @override String get tasks_action_delete => 'Delete';
  @override String get tasks_delete_confirm_title => 'Delete task?';
  @override String get tasks_delete_confirm_body => 'This action cannot be undone.';
  @override String get tasks_delete_confirm_btn => 'Yes, delete';
  @override String get tasks_freeze_success => 'Task frozen';
  @override String get tasks_unfreeze_success => 'Task activated';
  @override String get tasks_save_error => 'Error saving task';
  @override String get tasks_detail_next_occurrences => 'Upcoming dates';
  @override String get tasks_detail_assignment_order => 'Assignment order';
  @override String get tasks_validation_title_empty => 'Title is required';
  @override String get tasks_validation_title_too_long => 'Maximum 60 characters';
  @override String get tasks_validation_no_assignees => 'Select at least one member';
  @override String get tasks_validation_difficulty_range => 'Weight must be between 0.5 and 3.0';
  @override String get tasks_validation_recurrence_required => 'Choose a recurrence type';
  @override String get weekday_mon => 'Monday';
  @override String get weekday_tue => 'Tuesday';
  @override String get weekday_wed => 'Wednesday';
  @override String get weekday_thu => 'Thursday';
  @override String get weekday_fri => 'Friday';
  @override String get weekday_sat => 'Saturday';
  @override String get weekday_sun => 'Sunday';
  @override String get tasks_week_1st => 'First';
  @override String get tasks_week_2nd => 'Second';
  @override String get tasks_week_3rd => 'Third';
  @override String get tasks_week_4th => 'Fourth';
  @override String get month_jan => 'January';
  @override String get month_feb => 'February';
  @override String get month_mar => 'March';
  @override String get month_apr => 'April';
  @override String get month_may => 'May';
  @override String get month_jun => 'June';
  @override String get month_jul => 'July';
  @override String get month_aug => 'August';
  @override String get month_sep => 'September';
  @override String get month_oct => 'October';
  @override String get month_nov => 'November';
  @override String get month_dec => 'December';
```

- [ ] **Step 7: Añadir implementaciones a app_localizations_ro.dart**

Al final de la clase `AppLocalizationsRo`:

```dart
  @override String get tasks_title => 'Sarcini';
  @override String get tasks_empty_title => 'Nicio sarcină';
  @override String get tasks_empty_body => 'Creează prima sarcină pentru a începe';
  @override String get tasks_empty_cta => 'Creează prima sarcină';
  @override String get tasks_create_title => 'Creează sarcină';
  @override String get tasks_edit_title => 'Editează sarcină';
  @override String get tasks_field_visual => 'Pictogramă sau emoji';
  @override String get tasks_field_title_hint => 'Ex: Spălat vasele';
  @override String get tasks_field_description_hint => 'Descriere (opțional)';
  @override String get tasks_field_recurrence => 'Recurență';
  @override String get tasks_field_assignment_mode => 'Mod de atribuire';
  @override String get tasks_field_difficulty => 'Dificultate';
  @override String get tasks_assignment_basic_rotation => 'Rotație de bază';
  @override String get tasks_assignment_smart => 'Distribuție inteligentă';
  @override String get tasks_assignment_members => 'Membri atribuiți';
  @override String get tasks_recurrence_every => 'La fiecare';
  @override String get tasks_recurrence_hours => 'ore';
  @override String get tasks_recurrence_days => 'zile';
  @override String get tasks_recurrence_start_time => 'Ora de început';
  @override String get tasks_recurrence_end_time => 'Ora de sfârșit (opțional)';
  @override String get tasks_recurrence_time => 'Ora';
  @override String get tasks_recurrence_day_of_month => 'Ziua lunii';
  @override String get tasks_recurrence_week_of_month => 'Săptămâna lunii';
  @override String get tasks_recurrence_weekday => 'Ziua săptămânii';
  @override String get tasks_recurrence_month => 'Luna';
  @override String get tasks_recurrence_timezone => 'Fus orar';
  @override String get tasks_recurrence_upcoming => 'Datele următoare';
  @override String get tasks_recurrence_hourly_label => 'Orar';
  @override String get tasks_recurrence_daily_label => 'Zilnic';
  @override String get tasks_recurrence_weekly_label => 'Săptămânal';
  @override String get tasks_recurrence_monthly_fixed_label => 'Lunar (zi fixă)';
  @override String get tasks_recurrence_monthly_nth_label => 'Lunar (a N-a săptămână)';
  @override String get tasks_recurrence_yearly_fixed_label => 'Anual (dată fixă)';
  @override String get tasks_recurrence_yearly_nth_label => 'Anual (a N-a săptămână)';
  @override String get tasks_section_active => 'Active';
  @override String get tasks_section_frozen => 'Înghețate';
  @override String get tasks_action_edit => 'Editează';
  @override String get tasks_action_freeze => 'Îngheață';
  @override String get tasks_action_unfreeze => 'Dezghețează';
  @override String get tasks_action_delete => 'Șterge';
  @override String get tasks_delete_confirm_title => 'Ștergi sarcina?';
  @override String get tasks_delete_confirm_body => 'Această acțiune nu poate fi anulată.';
  @override String get tasks_delete_confirm_btn => 'Da, șterge';
  @override String get tasks_freeze_success => 'Sarcină înghețată';
  @override String get tasks_unfreeze_success => 'Sarcină activată';
  @override String get tasks_save_error => 'Eroare la salvarea sarcinii';
  @override String get tasks_detail_next_occurrences => 'Datele următoare';
  @override String get tasks_detail_assignment_order => 'Ordinea de atribuire';
  @override String get tasks_validation_title_empty => 'Titlul este obligatoriu';
  @override String get tasks_validation_title_too_long => 'Maximum 60 de caractere';
  @override String get tasks_validation_no_assignees => 'Selectează cel puțin un membru';
  @override String get tasks_validation_difficulty_range => 'Greutatea trebuie să fie între 0.5 și 3.0';
  @override String get tasks_validation_recurrence_required => 'Alege un tip de recurență';
  @override String get weekday_mon => 'Luni';
  @override String get weekday_tue => 'Marți';
  @override String get weekday_wed => 'Miercuri';
  @override String get weekday_thu => 'Joi';
  @override String get weekday_fri => 'Vineri';
  @override String get weekday_sat => 'Sâmbătă';
  @override String get weekday_sun => 'Duminică';
  @override String get tasks_week_1st => 'Prima';
  @override String get tasks_week_2nd => 'A doua';
  @override String get tasks_week_3rd => 'A treia';
  @override String get tasks_week_4th => 'A patra';
  @override String get month_jan => 'Ianuarie';
  @override String get month_feb => 'Februarie';
  @override String get month_mar => 'Martie';
  @override String get month_apr => 'Aprilie';
  @override String get month_may => 'Mai';
  @override String get month_jun => 'Iunie';
  @override String get month_jul => 'Iulie';
  @override String get month_aug => 'August';
  @override String get month_sep => 'Septembrie';
  @override String get month_oct => 'Octombrie';
  @override String get month_nov => 'Noiembrie';
  @override String get month_dec => 'Decembrie';
```

- [ ] **Step 8: Verificar que compila**

```bash
flutter analyze lib/l10n/
```

Expected: No issues found.

- [ ] **Step 9: Commit**

```bash
git add lib/l10n/
git commit -m "feat(tasks): add i18n keys for tasks CRUD (es/en/ro)"
```

---

## Task 9: Presentation — TaskCard + TaskVisualPicker

**Files:**
- Create: `lib/features/tasks/presentation/widgets/task_card.dart`
- Create: `lib/features/tasks/presentation/widgets/task_visual_picker.dart`

- [ ] **Step 1: Crear task_card.dart**

```dart
// lib/features/tasks/presentation/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/task.dart';
import '../../domain/task_status.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFrozen = task.status == TaskStatus.frozen;
    final dateStr = DateFormat.MMMd(Localizations.localeOf(context).toString())
        .add_Hm()
        .format(task.nextDueAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isFrozen
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _VisualWidget(
                  kind: task.visualKind, value: task.visualValue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration: isFrozen
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: task.nextDueAt.isBefore(DateTime.now())
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                    ),
                  ],
                ),
              ),
              if (isFrozen)
                Icon(Icons.ac_unit,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualWidget extends StatelessWidget {
  const _VisualWidget({required this.kind, required this.value});
  final String kind;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (kind == 'emoji') {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(value, style: const TextStyle(fontSize: 24)),
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.task_alt,
          color: Theme.of(context).colorScheme.onPrimaryContainer),
    );
  }
}
```

- [ ] **Step 2: Crear task_visual_picker.dart**

```dart
// lib/features/tasks/presentation/widgets/task_visual_picker.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class TaskVisualPicker extends StatefulWidget {
  const TaskVisualPicker({
    super.key,
    required this.selectedKind,
    required this.selectedValue,
    required this.onChanged,
  });

  final String selectedKind;
  final String selectedValue;
  final void Function(String kind, String value) onChanged;

  @override
  State<TaskVisualPicker> createState() => _TaskVisualPickerState();
}

class _TaskVisualPickerState extends State<TaskVisualPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _emojis = [
    '🏠', '🍽️', '🧹', '🧺', '🛒', '🌿', '🐾', '🚗',
    '💰', '🔧', '📦', '🗑️', '🛁', '🪴', '🧴', '🍳',
    '🥗', '🧃', '☕', '🍰', '🛋️', '🪟', '🚿', '🪣',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.selectedKind == 'icon' ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tasks_field_visual,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        // Preview del seleccionado
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: widget.selectedKind == 'emoji'
                  ? Text(widget.selectedValue,
                      style: const TextStyle(fontSize: 32))
                  : Icon(Icons.task_alt,
                      size: 36,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Emoji'), Tab(text: 'Icono')],
        ),
        SizedBox(
          height: 160,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab Emojis
              GridView.count(
                crossAxisCount: 6,
                padding: const EdgeInsets.all(8),
                children: _emojis
                    .map((e) => GestureDetector(
                          onTap: () => widget.onChanged('emoji', e),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: widget.selectedKind == 'emoji' &&
                                      widget.selectedValue == e
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(e,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              // Tab Iconos
              GridView.count(
                crossAxisCount: 6,
                padding: const EdgeInsets.all(8),
                children: [
                  Icons.home,
                  Icons.kitchen,
                  Icons.local_laundry_service,
                  Icons.cleaning_services,
                  Icons.shopping_cart,
                  Icons.directions_car,
                  Icons.pets,
                  Icons.yard,
                  Icons.build,
                  Icons.recycling,
                  Icons.bathtub,
                  Icons.wb_sunny,
                ]
                    .map((icon) => GestureDetector(
                          onTap: () =>
                              widget.onChanged('icon', icon.codePoint.toString()),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: widget.selectedKind == 'icon' &&
                                      widget.selectedValue ==
                                          icon.codePoint.toString()
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, size: 22),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Verificar análisis**

```bash
flutter analyze lib/features/tasks/presentation/widgets/task_card.dart lib/features/tasks/presentation/widgets/task_visual_picker.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/presentation/widgets/task_card.dart lib/features/tasks/presentation/widgets/task_visual_picker.dart
git commit -m "feat(tasks): add TaskCard and TaskVisualPicker widgets"
```

---

## Task 10: Presentation — RecurrenceForm

**Files:**
- Create: `lib/features/tasks/presentation/widgets/recurrence_form.dart`

- [ ] **Step 1: Crear recurrence_form.dart**

```dart
// lib/features/tasks/presentation/widgets/recurrence_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/recurrence_provider.dart';
import '../../application/task_form_provider.dart';
import '../../domain/recurrence_rule.dart';

class RecurrenceForm extends ConsumerStatefulWidget {
  const RecurrenceForm({super.key});

  @override
  ConsumerState<RecurrenceForm> createState() => _RecurrenceFormState();
}

class _RecurrenceFormState extends ConsumerState<RecurrenceForm> {
  String _selectedType = 'daily';
  // Campos compartidos
  int _every = 1;
  String _time = '09:00';
  String _startTime = '08:00';
  String? _endTime;
  List<String> _weekdays = ['MON'];
  int _dayOfMonth = 1;
  int _weekOfMonth = 1;
  String _weekday = 'MON';
  int _month = 1;
  String _timezone = 'Europe/Madrid';

  static const _types = [
    'hourly', 'daily', 'weekly',
    'monthlyFixed', 'monthlyNth',
    'yearlyFixed', 'yearlyNth',
  ];

  static const _weekdayKeys = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _commonTimezones = [
    'Europe/Madrid', 'Europe/Bucharest', 'Europe/London',
    'America/New_York', 'America/Chicago', 'America/Los_Angeles',
    'Asia/Tokyo', 'Asia/Shanghai', 'Australia/Sydney', 'UTC',
  ];

  @override
  void initState() {
    super.initState();
    final existing = ref.read(taskFormNotifierProvider).recurrenceRule;
    if (existing != null) _loadFromRule(existing);
  }

  void _loadFromRule(RecurrenceRule rule) {
    switch (rule) {
      case HourlyRule r:
        _selectedType = 'hourly';
        _every = r.every;
        _startTime = r.startTime;
        _endTime = r.endTime;
        _timezone = r.timezone;
      case DailyRule r:
        _selectedType = 'daily';
        _every = r.every;
        _time = r.time;
        _timezone = r.timezone;
      case WeeklyRule r:
        _selectedType = 'weekly';
        _weekdays = List.from(r.weekdays);
        _time = r.time;
        _timezone = r.timezone;
      case MonthlyFixedRule r:
        _selectedType = 'monthlyFixed';
        _dayOfMonth = r.day;
        _time = r.time;
        _timezone = r.timezone;
      case MonthlyNthRule r:
        _selectedType = 'monthlyNth';
        _weekOfMonth = r.weekOfMonth;
        _weekday = r.weekday;
        _time = r.time;
        _timezone = r.timezone;
      case YearlyFixedRule r:
        _selectedType = 'yearlyFixed';
        _month = r.month;
        _dayOfMonth = r.day;
        _time = r.time;
        _timezone = r.timezone;
      case YearlyNthRule r:
        _selectedType = 'yearlyNth';
        _month = r.month;
        _weekOfMonth = r.weekOfMonth;
        _weekday = r.weekday;
        _time = r.time;
        _timezone = r.timezone;
    }
  }

  RecurrenceRule _buildRule() {
    return switch (_selectedType) {
      'hourly' => RecurrenceRule.hourly(
          every: _every, startTime: _startTime,
          endTime: _endTime, timezone: _timezone),
      'weekly' => RecurrenceRule.weekly(
          weekdays: _weekdays, time: _time, timezone: _timezone),
      'monthlyFixed' => RecurrenceRule.monthlyFixed(
          day: _dayOfMonth, time: _time, timezone: _timezone),
      'monthlyNth' => RecurrenceRule.monthlyNth(
          weekOfMonth: _weekOfMonth, weekday: _weekday,
          time: _time, timezone: _timezone),
      'yearlyFixed' => RecurrenceRule.yearlyFixed(
          month: _month, day: _dayOfMonth, time: _time, timezone: _timezone),
      'yearlyNth' => RecurrenceRule.yearlyNth(
          month: _month, weekOfMonth: _weekOfMonth, weekday: _weekday,
          time: _time, timezone: _timezone),
      _ => RecurrenceRule.daily(
          every: _every, time: _time, timezone: _timezone),
    };
  }

  void _notifyChange() {
    ref.read(taskFormNotifierProvider.notifier).setRecurrenceRule(_buildRule());
  }

  String _typeLabel(String type, AppLocalizations l10n) => switch (type) {
        'hourly' => l10n.tasks_recurrence_hourly_label,
        'daily' => l10n.tasks_recurrence_daily_label,
        'weekly' => l10n.tasks_recurrence_weekly_label,
        'monthlyFixed' => l10n.tasks_recurrence_monthly_fixed_label,
        'monthlyNth' => l10n.tasks_recurrence_monthly_nth_label,
        'yearlyFixed' => l10n.tasks_recurrence_yearly_fixed_label,
        'yearlyNth' => l10n.tasks_recurrence_yearly_nth_label,
        _ => type,
      };

  String _weekdayLabel(String key, AppLocalizations l10n) => switch (key) {
        'MON' => l10n.weekday_mon,
        'TUE' => l10n.weekday_tue,
        'WED' => l10n.weekday_wed,
        'THU' => l10n.weekday_thu,
        'FRI' => l10n.weekday_fri,
        'SAT' => l10n.weekday_sat,
        'SUN' => l10n.weekday_sun,
        _ => key,
      };

  String _weekLabel(int n, AppLocalizations l10n) => switch (n) {
        1 => l10n.tasks_week_1st,
        2 => l10n.tasks_week_2nd,
        3 => l10n.tasks_week_3rd,
        _ => l10n.tasks_week_4th,
      };

  String _monthLabel(int m, AppLocalizations l10n) {
    const keys = [
      '', 'month_jan', 'month_feb', 'month_mar', 'month_apr',
      'month_may', 'month_jun', 'month_jul', 'month_aug',
      'month_sep', 'month_oct', 'month_nov', 'month_dec',
    ];
    // Access via reflection-like approach using switch
    return switch (m) {
      1 => l10n.month_jan, 2 => l10n.month_feb, 3 => l10n.month_mar,
      4 => l10n.month_apr, 5 => l10n.month_may, 6 => l10n.month_jun,
      7 => l10n.month_jul, 8 => l10n.month_aug, 9 => l10n.month_sep,
      10 => l10n.month_oct, 11 => l10n.month_nov, _ => l10n.month_dec,
    };
  }

  Future<void> _pickTime(
      BuildContext context, String current, void Function(String) onPick) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked != null) {
      onPick(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final upcoming = ref.watch(
        upcomingOccurrencesProvider(_buildRule()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Selector de tipo ──────────────────────────────────────────
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: InputDecoration(label: Text(l10n.tasks_field_recurrence)),
          items: _types
              .map((t) => DropdownMenuItem(
                  value: t, child: Text(_typeLabel(t, l10n))))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selectedType = v);
            _notifyChange();
          },
        ),
        const SizedBox(height: 12),

        // ── Sub-formulario contextual ─────────────────────────────────
        _buildSubForm(context, l10n),

        // ── Timezone ─────────────────────────────────────────────────
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _commonTimezones.contains(_timezone) ? _timezone : 'UTC',
          decoration:
              InputDecoration(label: Text(l10n.tasks_recurrence_timezone)),
          items: _commonTimezones
              .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _timezone = v);
            _notifyChange();
          },
        ),

        // ── Preview próximas ocurrencias ──────────────────────────────
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.tasks_recurrence_upcoming,
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          ...upcoming.map((d) => Text(
                DateFormat.yMMMd(Localizations.localeOf(context).toString())
                    .add_Hm()
                    .format(d),
                style: Theme.of(context).textTheme.bodySmall,
              )),
        ],
      ],
    );
  }

  Widget _buildSubForm(BuildContext context, AppLocalizations l10n) {
    return switch (_selectedType) {
      'hourly' => _HourlySubForm(
          every: _every, startTime: _startTime, endTime: _endTime,
          onEveryChanged: (v) { setState(() => _every = v); _notifyChange(); },
          onStartTimeChanged: (v) { setState(() => _startTime = v); _notifyChange(); },
          onEndTimeChanged: (v) { setState(() => _endTime = v); _notifyChange(); },
          l10n: l10n,
        ),
      'daily' => _DailySubForm(
          every: _every, time: _time,
          onEveryChanged: (v) { setState(() => _every = v); _notifyChange(); },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'weekly' => _WeeklySubForm(
          weekdays: _weekdays, time: _time,
          weekdayLabel: (k) => _weekdayLabel(k, l10n),
          onWeekdaysChanged: (v) { setState(() => _weekdays = v); _notifyChange(); },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'monthlyFixed' => _MonthlyFixedSubForm(
          day: _dayOfMonth, time: _time,
          onDayChanged: (v) { setState(() => _dayOfMonth = v); _notifyChange(); },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'monthlyNth' => _MonthlyNthSubForm(
          weekOfMonth: _weekOfMonth, weekday: _weekday, time: _time,
          weekLabel: (n) => _weekLabel(n, l10n),
          weekdayLabel: (k) => _weekdayLabel(k, l10n),
          onWeekOfMonthChanged: (v) { setState(() => _weekOfMonth = v); _notifyChange(); },
          onWeekdayChanged: (v) { setState(() => _weekday = v); _notifyChange(); },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'yearlyFixed' => _YearlyFixedSubForm(
          month: _month, day: _dayOfMonth, time: _time,
          monthLabel: (m) => _monthLabel(m, l10n),
          onMonthChanged: (v) { setState(() => _month = v); _notifyChange(); },
          onDayChanged: (v) { setState(() => _dayOfMonth = v); _notifyChange(); },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      'yearlyNth' => _YearlyNthSubForm(
          month: _month, weekOfMonth: _weekOfMonth,
          weekday: _weekday, time: _time,
          monthLabel: (m) => _monthLabel(m, l10n),
          weekLabel: (n) => _weekLabel(n, l10n),
          weekdayLabel: (k) => _weekdayLabel(k, l10n),
          onMonthChanged: (v) { setState(() => _month = v); _notifyChange(); },
          onWeekOfMonthChanged: (v) { setState(() => _weekOfMonth = v); _notifyChange(); },
          onWeekdayChanged: (v) { setState(() => _weekday = v); _notifyChange(); },
          onTimeTap: () => _pickTime(context, _time, (v) {
                setState(() => _time = v);
                _notifyChange();
              }),
          l10n: l10n,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── Sub-formularios ─────────────────────────────────────────────────────────

class _HourlySubForm extends StatelessWidget {
  const _HourlySubForm({
    required this.every, required this.startTime, required this.endTime,
    required this.onEveryChanged, required this.onStartTimeChanged,
    required this.onEndTimeChanged, required this.l10n,
  });
  final int every; final String startTime; final String? endTime;
  final void Function(int) onEveryChanged;
  final void Function(String) onStartTimeChanged;
  final void Function(String?) onEndTimeChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text(l10n.tasks_recurrence_every),
        const SizedBox(width: 8),
        SizedBox(width: 60,
          child: TextFormField(
            initialValue: every.toString(),
            keyboardType: TextInputType.number,
            onChanged: (v) => onEveryChanged(int.tryParse(v) ?? 1),
          ),
        ),
        const SizedBox(width: 8),
        Text(l10n.tasks_recurrence_hours),
      ]),
      const SizedBox(height: 8),
      ListTile(dense: true,
        leading: const Icon(Icons.access_time),
        title: Text(l10n.tasks_recurrence_start_time),
        trailing: Text(startTime),
        onTap: () async {
          final parts = startTime.split(':');
          final t = await showTimePicker(context: context,
            initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
          if (t != null) onStartTimeChanged(
              '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}');
        },
      ),
      ListTile(dense: true,
        leading: const Icon(Icons.access_time_outlined),
        title: Text(l10n.tasks_recurrence_end_time),
        trailing: Text(endTime ?? '—'),
        onTap: () async {
          final current = endTime ?? '20:00';
          final parts = current.split(':');
          final t = await showTimePicker(context: context,
            initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
          if (t != null) onEndTimeChanged(
              '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}');
        },
      ),
    ]);
  }
}

class _DailySubForm extends StatelessWidget {
  const _DailySubForm({
    required this.every, required this.time,
    required this.onEveryChanged, required this.onTimeTap, required this.l10n,
  });
  final int every; final String time;
  final void Function(int) onEveryChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Text(l10n.tasks_recurrence_every), const SizedBox(width: 8),
      SizedBox(width: 60, child: TextFormField(
        initialValue: every.toString(), keyboardType: TextInputType.number,
        onChanged: (v) => onEveryChanged(int.tryParse(v) ?? 1),
      )),
      const SizedBox(width: 8), Text(l10n.tasks_recurrence_days),
    ]),
    ListTile(dense: true,
      leading: const Icon(Icons.access_time),
      title: Text(l10n.tasks_recurrence_time),
      trailing: Text(time),
      onTap: onTimeTap,
    ),
  ]);
}

class _WeeklySubForm extends StatelessWidget {
  const _WeeklySubForm({
    required this.weekdays, required this.time,
    required this.weekdayLabel, required this.onWeekdaysChanged,
    required this.onTimeTap, required this.l10n,
  });
  final List<String> weekdays; final String time;
  final String Function(String) weekdayLabel;
  final void Function(List<String>) onWeekdaysChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  static const _keys = ['MON','TUE','WED','THU','FRI','SAT','SUN'];

  @override
  Widget build(BuildContext context) => Column(children: [
    Wrap(spacing: 4, children: _keys.map((k) {
      final selected = weekdays.contains(k);
      return FilterChip(
        label: Text(weekdayLabel(k).substring(0, 2)),
        selected: selected,
        onSelected: (v) {
          final updated = List<String>.from(weekdays);
          if (v) updated.add(k); else updated.remove(k);
          if (updated.isNotEmpty) onWeekdaysChanged(updated);
        },
      );
    }).toList()),
    ListTile(dense: true,
      leading: const Icon(Icons.access_time),
      title: Text(l10n.tasks_recurrence_time),
      trailing: Text(time), onTap: onTimeTap,
    ),
  ]);
}

class _MonthlyFixedSubForm extends StatelessWidget {
  const _MonthlyFixedSubForm({
    required this.day, required this.time,
    required this.onDayChanged, required this.onTimeTap, required this.l10n,
  });
  final int day; final String time;
  final void Function(int) onDayChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(children: [
    DropdownButtonFormField<int>(
      value: day,
      decoration: InputDecoration(label: Text(l10n.tasks_recurrence_day_of_month)),
      items: List.generate(31, (i) => DropdownMenuItem(value: i+1, child: Text('${i+1}'))),
      onChanged: (v) => onDayChanged(v ?? 1),
    ),
    ListTile(dense: true,
      leading: const Icon(Icons.access_time),
      title: Text(l10n.tasks_recurrence_time),
      trailing: Text(time), onTap: onTimeTap,
    ),
  ]);
}

class _MonthlyNthSubForm extends StatelessWidget {
  const _MonthlyNthSubForm({
    required this.weekOfMonth, required this.weekday, required this.time,
    required this.weekLabel, required this.weekdayLabel,
    required this.onWeekOfMonthChanged, required this.onWeekdayChanged,
    required this.onTimeTap, required this.l10n,
  });
  final int weekOfMonth; final String weekday; final String time;
  final String Function(int) weekLabel;
  final String Function(String) weekdayLabel;
  final void Function(int) onWeekOfMonthChanged;
  final void Function(String) onWeekdayChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  static const _dayKeys = ['MON','TUE','WED','THU','FRI','SAT','SUN'];

  @override
  Widget build(BuildContext context) => Column(children: [
    DropdownButtonFormField<int>(
      value: weekOfMonth,
      decoration: InputDecoration(label: Text(l10n.tasks_recurrence_week_of_month)),
      items: [1,2,3,4].map((n) => DropdownMenuItem(value: n, child: Text(weekLabel(n)))).toList(),
      onChanged: (v) => onWeekOfMonthChanged(v ?? 1),
    ),
    DropdownButtonFormField<String>(
      value: weekday,
      decoration: InputDecoration(label: Text(l10n.tasks_recurrence_weekday)),
      items: _dayKeys.map((k) => DropdownMenuItem(value: k, child: Text(weekdayLabel(k)))).toList(),
      onChanged: (v) => onWeekdayChanged(v ?? 'MON'),
    ),
    ListTile(dense: true,
      leading: const Icon(Icons.access_time),
      title: Text(l10n.tasks_recurrence_time),
      trailing: Text(time), onTap: onTimeTap,
    ),
  ]);
}

class _YearlyFixedSubForm extends StatelessWidget {
  const _YearlyFixedSubForm({
    required this.month, required this.day, required this.time,
    required this.monthLabel,
    required this.onMonthChanged, required this.onDayChanged,
    required this.onTimeTap, required this.l10n,
  });
  final int month; final int day; final String time;
  final String Function(int) monthLabel;
  final void Function(int) onMonthChanged;
  final void Function(int) onDayChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(children: [
    DropdownButtonFormField<int>(
      value: month,
      decoration: InputDecoration(label: Text(l10n.tasks_recurrence_month)),
      items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(monthLabel(i+1)))),
      onChanged: (v) => onMonthChanged(v ?? 1),
    ),
    DropdownButtonFormField<int>(
      value: day,
      decoration: InputDecoration(label: Text(l10n.tasks_recurrence_day_of_month)),
      items: List.generate(31, (i) => DropdownMenuItem(value: i+1, child: Text('${i+1}'))),
      onChanged: (v) => onDayChanged(v ?? 1),
    ),
    ListTile(dense: true,
      leading: const Icon(Icons.access_time),
      title: Text(l10n.tasks_recurrence_time),
      trailing: Text(time), onTap: onTimeTap,
    ),
  ]);
}

class _YearlyNthSubForm extends StatelessWidget {
  const _YearlyNthSubForm({
    required this.month, required this.weekOfMonth,
    required this.weekday, required this.time,
    required this.monthLabel, required this.weekLabel, required this.weekdayLabel,
    required this.onMonthChanged, required this.onWeekOfMonthChanged,
    required this.onWeekdayChanged, required this.onTimeTap, required this.l10n,
  });
  final int month; final int weekOfMonth; final String weekday; final String time;
  final String Function(int) monthLabel;
  final String Function(int) weekLabel;
  final String Function(String) weekdayLabel;
  final void Function(int) onMonthChanged;
  final void Function(int) onWeekOfMonthChanged;
  final void Function(String) onWeekdayChanged;
  final VoidCallback onTimeTap;
  final AppLocalizations l10n;

  static const _dayKeys = ['MON','TUE','WED','THU','FRI','SAT','SUN'];

  @override
  Widget build(BuildContext context) => Column(children: [
    DropdownButtonFormField<int>(
      value: month,
      decoration: InputDecoration(label: Text(l10n.tasks_recurrence_month)),
      items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(monthLabel(i+1)))),
      onChanged: (v) => onMonthChanged(v ?? 1),
    ),
    DropdownButtonFormField<int>(
      value: weekOfMonth,
      decoration: InputDecoration(label: Text(l10n.tasks_recurrence_week_of_month)),
      items: [1,2,3,4].map((n) => DropdownMenuItem(value: n, child: Text(weekLabel(n)))).toList(),
      onChanged: (v) => onWeekOfMonthChanged(v ?? 1),
    ),
    DropdownButtonFormField<String>(
      value: weekday,
      decoration: InputDecoration(label: Text(l10n.tasks_recurrence_weekday)),
      items: _dayKeys.map((k) => DropdownMenuItem(value: k, child: Text(weekdayLabel(k)))).toList(),
      onChanged: (v) => onWeekdayChanged(v ?? 'MON'),
    ),
    ListTile(dense: true,
      leading: const Icon(Icons.access_time),
      title: Text(l10n.tasks_recurrence_time),
      trailing: Text(time), onTap: onTimeTap,
    ),
  ]);
}
```

- [ ] **Step 2: Verificar análisis**

```bash
flutter analyze lib/features/tasks/presentation/widgets/recurrence_form.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/tasks/presentation/widgets/recurrence_form.dart
git commit -m "feat(tasks): add RecurrenceForm widget with 7 rule types"
```

---

## Task 11: Presentation — AssignmentForm

**Files:**
- Create: `lib/features/tasks/presentation/widgets/assignment_form.dart`

- [ ] **Step 1: Crear assignment_form.dart**

```dart
// lib/features/tasks/presentation/widgets/assignment_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../members/application/members_provider.dart';
import '../../../members/domain/member.dart';
import '../../application/task_form_provider.dart';

class AssignmentForm extends ConsumerWidget {
  const AssignmentForm({super.key, required this.homeId});
  final String homeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formState = ref.watch(taskFormNotifierProvider);
    final notifier = ref.read(taskFormNotifierProvider.notifier);
    final membersAsync = ref.watch(homeMembersProvider(homeId));

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(l10n.error_generic),
      data: (members) {
        final activeMembers =
            members.where((m) => m.status.name == 'active').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Modo ─────────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: formState.assignmentMode,
              decoration: InputDecoration(
                  label: Text(l10n.tasks_field_assignment_mode)),
              items: [
                DropdownMenuItem(
                  value: 'basicRotation',
                  child: Text(l10n.tasks_assignment_basic_rotation),
                ),
                DropdownMenuItem(
                  value: 'smartDistribution',
                  child: Text(l10n.tasks_assignment_smart),
                ),
              ],
              onChanged: (v) {
                if (v != null) notifier.setAssignmentMode(v);
              },
            ),
            const SizedBox(height: 12),

            // ── Lista de miembros reordenable ─────────────────────────
            Text(l10n.tasks_assignment_members,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                final order =
                    List<String>.from(formState.assignmentOrder);
                if (newIndex > oldIndex) newIndex--;
                final item = order.removeAt(oldIndex);
                order.insert(newIndex, item);
                notifier.setAssignmentOrder(order);
              },
              children: [
                for (final member in activeMembers)
                  CheckboxListTile(
                    key: ValueKey(member.uid),
                    title: Text(member.nickname),
                    subtitle: formState.assignmentOrder.contains(member.uid)
                        ? Text(
                            '#${formState.assignmentOrder.indexOf(member.uid) + 1}')
                        : null,
                    value: formState.assignmentOrder.contains(member.uid),
                    onChanged: (checked) {
                      final order =
                          List<String>.from(formState.assignmentOrder);
                      if (checked == true) {
                        order.add(member.uid);
                      } else {
                        order.remove(member.uid);
                      }
                      notifier.setAssignmentOrder(order);
                    },
                    secondary: const Icon(Icons.drag_handle),
                  ),
              ],
            ),

            // ── Dificultad (solo smartDistribution) ───────────────────
            if (formState.assignmentMode == 'smartDistribution') ...[
              const SizedBox(height: 12),
              Text(
                  '${l10n.tasks_field_difficulty}: ${formState.difficultyWeight.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: formState.difficultyWeight,
                min: 0.5,
                max: 3.0,
                divisions: 25,
                label:
                    formState.difficultyWeight.toStringAsFixed(1),
                onChanged: notifier.setDifficultyWeight,
              ),
            ],

            // ── Error de asignados ────────────────────────────────────
            if (formState.fieldErrors.containsKey('assignees'))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.tasks_validation_no_assignees,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Verificar análisis**

```bash
flutter analyze lib/features/tasks/presentation/widgets/assignment_form.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/tasks/presentation/widgets/assignment_form.dart
git commit -m "feat(tasks): add AssignmentForm widget"
```

---

## Task 12: Presentation — AllTasksScreen + UI test

**Files:**
- Create: `lib/features/tasks/presentation/all_tasks_screen.dart`
- Create: `test/ui/features/tasks/all_tasks_screen_test.dart`

- [ ] **Step 1: Crear all_tasks_screen.dart**

```dart
// lib/features/tasks/presentation/all_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../homes/application/current_home_provider.dart';
import '../application/tasks_provider.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import 'widgets/task_card.dart';

class AllTasksScreen extends ConsumerWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    final tasksAsync = ref.watch(homeTasksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tasks_title)),
      floatingActionButton: homeId != null
          ? FloatingActionButton(
              key: const Key('create_task_fab'),
              onPressed: () => context.push(AppRoutes.createTask),
              child: const Icon(Icons.add),
            )
          : null,
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.error_generic),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(homeTasksProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return _EmptyState(onCreateTap: homeId != null
                ? () => context.push(AppRoutes.createTask)
                : null);
          }

          final active =
              tasks.where((t) => t.status == TaskStatus.active).toList();
          final frozen =
              tasks.where((t) => t.status == TaskStatus.frozen).toList();

          return ListView(
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader(title: l10n.tasks_section_active),
                ...active.map((t) => TaskCard(
                      task: t,
                      onTap: () => context.push(
                        AppRoutes.taskDetail.replaceFirst(':id', t.id),
                        extra: {'homeId': homeId},
                      ),
                    )),
              ],
              if (frozen.isNotEmpty) ...[
                _SectionHeader(title: l10n.tasks_section_frozen),
                ...frozen.map((t) => TaskCard(
                      task: t,
                      onTap: () => context.push(
                        AppRoutes.taskDetail.replaceFirst(':id', t.id),
                        extra: {'homeId': homeId},
                      ),
                    )),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});
  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(l10n.tasks_empty_title,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.tasks_empty_body,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          if (onCreateTap != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('empty_create_btn'),
              onPressed: onCreateTap,
              icon: const Icon(Icons.add),
              label: Text(l10n.tasks_empty_cta),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}
```

- [ ] **Step 2: Escribir UI test**

```dart
// test/ui/features/tasks/all_tasks_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/all_tasks_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

// Minimal fake Home for tests
Home _fakeHome() => Home(
      id: 'h1',
      name: 'Test',
      ownerUid: 'u1',
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: HomePremiumStatus.free,
      premiumPlan: null,
      premiumEndsAt: null,
      restoreUntil: null,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 5),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Task _fakeTask(String id, {TaskStatus status = TaskStatus.active}) => Task(
      id: id,
      homeId: 'h1',
      title: 'Tarea $id',
      visualKind: 'emoji',
      visualValue: '🍽️',
      status: status,
      recurrenceType: 'daily',
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '20:00', timezone: 'UTC'),
      assignmentMode: 'basicRotation',
      assignmentOrder: ['u1'],
      currentAssigneeUid: 'u1',
      nextDueAt: DateTime(2026, 4, 8, 20, 0),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: 'u1',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Widget _wrap(Widget child,
    {List<Task> tasks = const [], Home? home}) {
  return ProviderScope(
    overrides: [
      currentHomeProvider.overrideWith((_) async => home ?? _fakeHome()),
      homeTasksProvider.overrideWith((_) => Stream.value(tasks)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      locale: const Locale('es'),
      home: child,
    ),
  );
}

void main() {
  testWidgets('empty state muestra CTA', (tester) async {
    await tester.pumpWidget(_wrap(const AllTasksScreen(), tasks: []));
    await tester.pump();
    expect(find.byKey(const Key('empty_create_btn')), findsOneWidget);
  });

  testWidgets('lista con tareas activas', (tester) async {
    final tasks = [_fakeTask('1'), _fakeTask('2')];
    await tester.pumpWidget(_wrap(const AllTasksScreen(), tasks: tasks));
    await tester.pump();
    expect(find.text('Tarea 1'), findsOneWidget);
    expect(find.text('Tarea 2'), findsOneWidget);
  });

  testWidgets('tareas congeladas aparecen en sección Congeladas', (tester) async {
    final tasks = [
      _fakeTask('1'),
      _fakeTask('2', status: TaskStatus.frozen),
    ];
    await tester.pumpWidget(_wrap(const AllTasksScreen(), tasks: tasks));
    await tester.pump();
    expect(find.text('Activas'), findsOneWidget);
    expect(find.text('Congeladas'), findsOneWidget);
  });

  testWidgets('FAB presente cuando hay homeId', (tester) async {
    await tester.pumpWidget(_wrap(const AllTasksScreen(), tasks: []));
    await tester.pump();
    expect(find.byKey(const Key('create_task_fab')), findsOneWidget);
  });
}
```

- [ ] **Step 3: Ejecutar test**

```bash
flutter test test/ui/features/tasks/all_tasks_screen_test.dart
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/presentation/all_tasks_screen.dart test/ui/features/tasks/all_tasks_screen_test.dart
git commit -m "feat(tasks): add AllTasksScreen with empty state and section headers"
```

---

## Task 13: Presentation — CreateEditTaskScreen + UI test

**Files:**
- Create: `lib/features/tasks/presentation/create_edit_task_screen.dart`
- Create: `test/ui/features/tasks/create_task_screen_test.dart`

- [ ] **Step 1: Crear create_edit_task_screen.dart**

```dart
// lib/features/tasks/presentation/create_edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../application/task_form_provider.dart';
import '../domain/task.dart';
import 'widgets/assignment_form.dart';
import 'widgets/recurrence_form.dart';
import 'widgets/task_visual_picker.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  const CreateEditTaskScreen({super.key, this.existingTask});

  /// Null → modo crear. Non-null → modo editar.
  final Task? existingTask;

  @override
  ConsumerState<CreateEditTaskScreen> createState() =>
      _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState
    extends ConsumerState<CreateEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleCtrl = TextEditingController(text: task?.title ?? '');
    _descCtrl =
        TextEditingController(text: task?.description ?? '');

    // Inicializar el form provider en el siguiente frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(taskFormNotifierProvider.notifier);
      if (task != null) {
        notifier.initEdit(task);
      } else {
        notifier.initCreate();
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    final uid = ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid);
    if (homeId == null || uid == null) return;

    final taskId = await ref
        .read(taskFormNotifierProvider.notifier)
        .save(homeId, uid);

    if (taskId != null && mounted) {
      Navigator.of(context).pop(taskId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formState = ref.watch(taskFormNotifierProvider);
    final notifier = ref.read(taskFormNotifierProvider.notifier);
    final homeId =
        ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
    final isEdit = widget.existingTask != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEdit ? l10n.tasks_edit_title : l10n.tasks_create_title),
        actions: [
          TextButton(
            key: const Key('save_task_btn'),
            onPressed: formState.isLoading ? null : _save,
            child: formState.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Visual ────────────────────────────────────────────────
            TaskVisualPicker(
              selectedKind: formState.visualKind,
              selectedValue: formState.visualValue,
              onChanged: notifier.setVisual,
            ),
            const SizedBox(height: 20),

            // ── Título ────────────────────────────────────────────────
            TextFormField(
              key: const Key('task_title_field'),
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: l10n.save, // reuse existing key
                hintText: l10n.tasks_field_title_hint,
                errorText: formState.fieldErrors.containsKey('title')
                    ? _resolveError(
                        context, formState.fieldErrors['title']!)
                    : null,
              ),
              maxLength: 60,
              onChanged: notifier.setTitle,
            ),
            const SizedBox(height: 12),

            // ── Descripción ───────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: l10n.tasks_field_description_hint,
              ),
              maxLines: 3,
              maxLength: 300,
              onChanged: notifier.setDescription,
            ),
            const SizedBox(height: 20),

            // ── Recurrencia ───────────────────────────────────────────
            const Divider(),
            const SizedBox(height: 8),
            const RecurrenceForm(),
            if (formState.fieldErrors.containsKey('recurrence'))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.tasks_validation_recurrence_required,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

            // ── Asignación ────────────────────────────────────────────
            const Divider(),
            const SizedBox(height: 8),
            if (homeId.isNotEmpty) AssignmentForm(homeId: homeId),

            // ── Error global ─────────────────────────────────────────
            if (formState.globalError != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.tasks_save_error,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _resolveError(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context);
    return switch (code) {
      'tasks_validation_title_empty' => l10n.tasks_validation_title_empty,
      'tasks_validation_title_too_long' =>
        l10n.tasks_validation_title_too_long,
      _ => code,
    };
  }
}
```

- [ ] **Step 2: Escribir UI test**

```dart
// test/ui/features/tasks/create_task_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/tasks/application/task_form_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';
import 'package:toka/features/tasks/presentation/create_edit_task_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class MockTasksRepository extends Mock implements TasksRepository {}

Home _fakeHome() => Home(
      id: 'h1', name: 'Test', ownerUid: 'u1',
      currentPayerUid: null, lastPayerUid: null,
      premiumStatus: HomePremiumStatus.free,
      premiumPlan: null, premiumEndsAt: null,
      restoreUntil: null, autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 5),
      createdAt: DateTime(2026), updatedAt: DateTime(2026),
    );

Member _fakeMember() => Member(
      uid: 'u1', homeId: 'h1', nickname: 'Alice',
      photoUrl: null, bio: null, phone: null,
      phoneVisibility: 'private',
      role: MemberRole.owner, status: MemberStatus.active,
      joinedAt: DateTime(2026), tasksCompleted: 0,
      passedCount: 0, complianceRate: 1.0,
      currentStreak: 0, averageScore: 0,
    );

Widget _wrap(Widget child, {MockTasksRepository? mockRepo}) {
  final repo = mockRepo ?? MockTasksRepository();
  when(() => repo.createTask(any(), any(), any()))
      .thenAnswer((_) async => 'new_task_id');

  return ProviderScope(
    overrides: [
      currentHomeProvider.overrideWith((_) async => _fakeHome()),
      authProvider.overrideWith((_) => const AuthState.authenticated(
          AuthUser(uid: 'u1', email: 'a@b.com',
              emailVerified: true, displayName: null, photoUrl: null))),
      tasksRepositoryProvider.overrideWithValue(repo),
      homeMembersProvider('h1')
          .overrideWith((_) => Stream.value([_fakeMember()])),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      locale: const Locale('es'),
      home: child,
    ),
  );
}

void main() {
  testWidgets('muestra AppBar con título "Crear tarea"', (tester) async {
    await tester.pumpWidget(_wrap(const CreateEditTaskScreen()));
    await tester.pump();
    expect(find.text('Crear tarea'), findsOneWidget);
  });

  testWidgets('botón Guardar presente', (tester) async {
    await tester.pumpWidget(_wrap(const CreateEditTaskScreen()));
    await tester.pump();
    expect(find.byKey(const Key('save_task_btn')), findsOneWidget);
  });

  testWidgets('campo título presente', (tester) async {
    await tester.pumpWidget(_wrap(const CreateEditTaskScreen()));
    await tester.pump();
    expect(find.byKey(const Key('task_title_field')), findsOneWidget);
  });

  testWidgets('guardar sin título muestra error de validación',
      (tester) async {
    await tester.pumpWidget(_wrap(const CreateEditTaskScreen()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save_task_btn')));
    await tester.pump();
    expect(find.text('El título es obligatorio'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Ejecutar test**

```bash
flutter test test/ui/features/tasks/create_task_screen_test.dart
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/presentation/create_edit_task_screen.dart test/ui/features/tasks/create_task_screen_test.dart
git commit -m "feat(tasks): add CreateEditTaskScreen with validation and tests"
```

---

## Task 14: Presentation — TaskDetailScreen

**Files:**
- Create: `lib/features/tasks/presentation/task_detail_screen.dart`

- [ ] **Step 1: Crear task_detail_screen.dart**

```dart
// lib/features/tasks/presentation/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../members/application/members_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../application/recurrence_provider.dart';
import '../application/tasks_provider.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({
    super.key,
    required this.homeId,
    required this.taskId,
  });

  final String homeId;
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final taskAsync = ref.watch(
      _taskDetailProvider((homeId: homeId, taskId: taskId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: taskAsync.maybeWhen(
          data: (t) => Text(t.title, overflow: TextOverflow.ellipsis),
          orElse: () => const Text(''),
        ),
        actions: taskAsync.maybeWhen(
          data: (task) => [
            PopupMenuButton<_TaskAction>(
              onSelected: (action) => _handleAction(context, ref, task, action),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _TaskAction.edit,
                  child: Text(l10n.tasks_action_edit),
                ),
                PopupMenuItem(
                  value: task.status == TaskStatus.frozen
                      ? _TaskAction.unfreeze
                      : _TaskAction.freeze,
                  child: Text(task.status == TaskStatus.frozen
                      ? l10n.tasks_action_unfreeze
                      : l10n.tasks_action_freeze),
                ),
                PopupMenuItem(
                  value: _TaskAction.delete,
                  child: Text(l10n.tasks_action_delete,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              ],
            ),
          ],
          orElse: () => null,
        ),
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.error_generic),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                    _taskDetailProvider((homeId: homeId, taskId: taskId))),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (task) => _TaskDetailBody(task: task, homeId: homeId),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    Task task,
    _TaskAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(tasksRepositoryProvider);

    switch (action) {
      case _TaskAction.edit:
        await context.push(
          AppRoutes.editTask
              .replaceFirst(':id', task.id),
          extra: {'task': task},
        );
        ref.invalidate(_taskDetailProvider((homeId: homeId, taskId: taskId)));

      case _TaskAction.freeze:
        await repo.freezeTask(homeId, task.id);
        ref.invalidate(_taskDetailProvider((homeId: homeId, taskId: taskId)));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.tasks_freeze_success)));
        }

      case _TaskAction.unfreeze:
        await repo.unfreezeTask(homeId, task.id);
        ref.invalidate(_taskDetailProvider((homeId: homeId, taskId: taskId)));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.tasks_unfreeze_success)));
        }

      case _TaskAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.tasks_delete_confirm_title),
            content: Text(l10n.tasks_delete_confirm_body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.tasks_delete_confirm_btn,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          final uid = ref
              .read(currentHomeProvider)
              .valueOrNull
              ?.ownerUid ?? '';
          await repo.deleteTask(homeId, task.id, uid);
          if (context.mounted) context.pop();
        }
    }
  }
}

enum _TaskAction { edit, freeze, unfreeze, delete }

// Provider para leer una sola tarea del repositorio
final _taskDetailProvider =
    FutureProvider.family<Task, ({String homeId, String taskId})>(
  (ref, params) => ref
      .read(tasksRepositoryProvider)
      .fetchTask(params.homeId, params.taskId),
);

class _TaskDetailBody extends ConsumerWidget {
  const _TaskDetailBody({required this.task, required this.homeId});
  final Task task;
  final String homeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final upcoming = ref.watch(upcomingOccurrencesProvider(task.recurrenceRule));
    final membersAsync = ref.watch(homeMembersProvider(homeId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Visual + título ───────────────────────────────────────────
        Center(
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: task.visualKind == 'emoji'
                  ? Text(task.visualValue,
                      style: const TextStyle(fontSize: 36))
                  : Icon(Icons.task_alt, size: 40,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(task.title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
        ),
        if (task.description != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(task.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ),
        ],
        if (task.status == TaskStatus.frozen)
          Chip(
            avatar: const Icon(Icons.ac_unit, size: 16),
            label: Text(l10n.tasks_section_frozen),
          ),
        const SizedBox(height: 24),
        const Divider(),

        // ── Próximas ocurrencias ──────────────────────────────────────
        Text(l10n.tasks_detail_next_occurrences,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 8),
        ...upcoming.map((d) => ListTile(
              dense: true,
              leading: const Icon(Icons.calendar_today, size: 18),
              title: Text(
                DateFormat.yMMMd(
                        Localizations.localeOf(context).toString())
                    .add_Hm()
                    .format(d),
              ),
            )),
        const Divider(),

        // ── Orden de asignación ───────────────────────────────────────
        Text(l10n.tasks_detail_assignment_order,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 8),
        membersAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (members) {
            final memberMap = {for (final m in members) m.uid: m.nickname};
            return Column(
              children: task.assignmentOrder
                  .asMap()
                  .entries
                  .map((e) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                            radius: 12,
                            child: Text('${e.key + 1}',
                                style: const TextStyle(fontSize: 10))),
                        title: Text(memberMap[e.value] ?? e.value),
                        trailing: e.value == task.currentAssigneeUid
                            ? const Icon(Icons.arrow_right_alt)
                            : null,
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
```

- [ ] **Step 2: Verificar análisis**

```bash
flutter analyze lib/features/tasks/presentation/task_detail_screen.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/tasks/presentation/task_detail_screen.dart
git commit -m "feat(tasks): add TaskDetailScreen with freeze/unfreeze/delete actions"
```

---

## Task 15: Navigation — routes + app.dart + MainShell + TodayScreen

**Files:**
- Modify: `lib/core/constants/routes.dart`
- Modify: `lib/app.dart`
- Modify: `lib/shared/widgets/main_shell.dart`
- Modify: `lib/features/tasks/presentation/today_screen.dart`

- [ ] **Step 1: Actualizar routes.dart**

Reemplazar el contenido completo de `lib/core/constants/routes.dart`:

```dart
abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String allTasks = '/tasks';
  static const String taskDetail = '/tasks/:id';
  static const String createTask = '/tasks/create';
  static const String editTask = '/tasks/:id/edit';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String paywall = '/subscription/paywall';
  static const String rescueScreen = '/subscription/rescue';
  static const String downgradePlanner = '/subscription/downgrade-planner';
  static const String myHomes = '/my-homes';
  static const String homeSettings = '/home-settings';
  static const String editProfile = '/profile/edit';
  static const String members = '/members';
  static const String memberProfile = '/member/:uid';
  static const String vacation = '/vacation';
  static const String history = '/history';
  static const String notificationSettings = '/notification-settings';

  static const List<String> all = [
    splash, login, register, forgotPassword, verifyEmail, onboarding,
    home, allTasks, taskDetail, createTask, editTask,
    profile, settings, subscription, paywall, rescueScreen,
    downgradePlanner, myHomes, homeSettings, editProfile,
    members, memberProfile, vacation, history, notificationSettings,
  ];
}
```

- [ ] **Step 2: Actualizar app.dart — añadir imports y rutas**

Añadir import después de la línea `import 'features/tasks/presentation/today_screen.dart';`:

```dart
import 'features/tasks/presentation/all_tasks_screen.dart';
import 'features/tasks/presentation/task_detail_screen.dart';
import 'features/tasks/presentation/create_edit_task_screen.dart';
```

En el `ShellRoute`, añadir `/tasks` al lado de `/home`. El bloque `ShellRoute` completo debe quedar:

```dart
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const TodayScreen(),
          ),
          GoRoute(
            path: AppRoutes.allTasks,
            builder: (_, __) => const AllTasksScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, __) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.members,
            builder: (_, __) => const MembersScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
```

Añadir también las 3 nuevas rutas fuera del shell (junto al resto de pantallas fuera del shell):

```dart
      GoRoute(
        path: AppRoutes.taskDetail,
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          final homeId = extra?['homeId'] as String? ?? '';
          return TaskDetailScreen(homeId: homeId, taskId: taskId);
        },
      ),
      GoRoute(
        path: AppRoutes.createTask,
        builder: (_, __) => const CreateEditTaskScreen(),
      ),
      GoRoute(
        path: AppRoutes.editTask,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final task = extra?['task'];
          return CreateEditTaskScreen(existingTask: task);
        },
      ),
```

- [ ] **Step 3: Actualizar MainShell — añadir tab Tareas**

Reemplazar el contenido completo de `lib/shared/widgets/main_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static int _tabIndex(String location) {
    if (location.startsWith(AppRoutes.allTasks)) return 1;
    if (location.startsWith(AppRoutes.history)) return 2;
    if (location.startsWith(AppRoutes.members)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex(location),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.allTasks);
            case 2:
              context.go(AppRoutes.history);
            case 3:
              context.go(AppRoutes.members);
            case 4:
              context.go(AppRoutes.settings);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.today_screen_title,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: l10n.tasks_title,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.history_title,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.members_title,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings_title,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Actualizar TodayScreen — tap en tarea navega a detalle**

En `lib/features/tasks/presentation/today_screen.dart`, añadir el import:

```dart
import '../../../core/constants/routes.dart';
import 'package:go_router/go_router.dart';
```

En el `Widget build`, añadir el parámetro `onTaskTap` a cada `TodayTaskSection`. Primero localizar el bloque que construye `TodayTaskSection` y añadir `onTaskTap`:

```dart
                  TodayTaskSection(
                    recurrenceType: recurrenceType,
                    todos: grouped[recurrenceType]!.todos,
                    dones: grouped[recurrenceType]!.dones,
                    currentUid: currentUid,
                    onDone: homeId != null
                        ? (task) => _onDone(context, ref, task, homeId)
                        : null,
                    onPass: homeId != null
                        ? (task) =>
                            _onPass(context, ref, task, homeId, currentUid)
                        : null,
                    onTaskTap: homeId != null
                        ? (task) => context.push(
                              AppRoutes.taskDetail
                                  .replaceFirst(':id', task.taskId),
                              extra: {'homeId': homeId},
                            )
                        : null,
                  ),
```

Abrir `lib/features/tasks/presentation/widgets/today_task_section.dart` y añadir el parámetro `onTaskTap` de tipo `void Function(TaskPreview)?`. Luego pasarlo a `TodayTaskCardTodo` para que el tap en el título navegue al detalle.

- [ ] **Step 5: Verificar análisis completo**

```bash
flutter analyze lib/
```

Expected: No issues found (o solo warnings menores no relacionados con los cambios).

- [ ] **Step 6: Ejecutar todos los tests**

```bash
flutter test test/unit/features/tasks/ test/integration/features/tasks/ test/ui/features/tasks/
```

Expected: All tests pass.

- [ ] **Step 7: Commit final**

```bash
git add lib/core/constants/routes.dart lib/app.dart lib/shared/widgets/main_shell.dart lib/features/tasks/presentation/today_screen.dart lib/features/tasks/presentation/widgets/today_task_section.dart
git commit -m "feat(tasks): wire up navigation — 5 tabs, task routes, TodayScreen tap-to-detail"
```

---

## Pruebas manuales requeridas al terminar

1. **Compilar y ejecutar**: `flutter run --target lib/main_prod.dart`
2. **Tab Tareas**: tocar el tab → aparece `AllTasksScreen` con FAB `+`
3. **Crear tarea**: FAB → formulario completo → cambiar recurrencia → ver preview de próximas fechas → guardar → aparece en la lista
4. **Detalle**: tocar tarea → ver detalle con próximas fechas y orden de asignación
5. **Editar**: desde detalle → menú → Editar → campos pre-rellenos → guardar cambios
6. **Congelar/Descongelar**: desde detalle → menú → snackbar de confirmación → tarea aparece en sección "Congeladas"
7. **Eliminar**: desde detalle → menú → diálogo → confirmar → vuelve a la lista sin la tarea
8. **TodayScreen**: tap en título de tarea → navega a detalle
9. **i18n**: cambiar idioma a inglés/rumano → labels del formulario actualizados
