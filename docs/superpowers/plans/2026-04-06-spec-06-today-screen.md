# Spec-06: Dashboard Materializado y Pantalla Hoy — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el documento `dashboard` materializado en Firestore y la pantalla principal "Hoy" que lo consume con un único listener en tiempo real.

**Architecture:** Los modelos `HomeDashboard` y sub-modelos viven en `lib/features/tasks/domain/`. Un stream provider en `lib/features/homes/application/dashboard_provider.dart` expone el único listener. `TodayScreen` agrupa tareas por recurrencia y renderiza secciones con widgets dedicados.

**Tech Stack:** Flutter 3.x + Dart 3.x, Riverpod (riverpod_annotation), freezed, go_router, Cloud Firestore, Cloud Functions (TypeScript), intl (DateFormat), flutter_test, mocktail, fake_cloud_firestore.

---

## File Structure

**Crear:**
- `lib/features/tasks/domain/home_dashboard.dart` — HomeDashboard + 7 sub-modelos freezed
- `lib/features/tasks/domain/recurrence_order.dart` — RecurrenceOrder (constante + localización)
- `lib/features/homes/application/dashboard_provider.dart` — Stream<HomeDashboard?> provider
- `lib/features/tasks/presentation/today_screen.dart` — TodayScreen + groupByRecurrence
- `lib/features/tasks/presentation/widgets/today_header_counters.dart`
- `lib/features/tasks/presentation/widgets/today_task_section.dart`
- `lib/features/tasks/presentation/widgets/today_task_card_todo.dart`
- `lib/features/tasks/presentation/widgets/today_task_card_done.dart`
- `lib/features/tasks/presentation/widgets/today_empty_state.dart`
- `lib/features/tasks/presentation/widgets/today_skeleton_loader.dart`
- `functions/src/tasks/update_dashboard.ts` — helper updateHomeDashboard + cron

**Modificar:**
- `lib/l10n/app_es.arb` / `app_en.arb` / `app_ro.arb` — añadir claves today_ y recurrence*
- `lib/l10n/app_localizations.dart` — añadir abstract getters/métodos
- `lib/l10n/app_localizations_es.dart` / `_en.dart` / `_ro.dart` — añadir implementaciones
- `functions/src/tasks/index.ts` — exportar desde update_dashboard
- `lib/app.dart` — conectar ruta `/home` a TodayScreen

**Tests (crear):**
- `test/unit/features/tasks/recurrence_order_test.dart`
- `test/unit/features/tasks/dashboard_grouping_test.dart`
- `test/unit/features/tasks/today_task_card_test.dart`
- `test/integration/features/tasks/dashboard_stream_test.dart`
- `test/ui/features/tasks/today_screen_test.dart`
- `test/ui/features/tasks/today_task_card_todo_test.dart`
- `test/ui/features/tasks/today_task_card_done_test.dart`

---

## Task 1: Domain models HomeDashboard (freezed)

**Files:**
- Create: `lib/features/tasks/domain/home_dashboard.dart`

- [ ] **Step 1: Escribir los modelos**

```dart
// lib/features/tasks/domain/home_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_dashboard.freezed.dart';

@freezed
class TaskPreview with _$TaskPreview {
  const factory TaskPreview({
    required String taskId,
    required String title,
    required String visualKind,
    required String visualValue,
    required String recurrenceType,
    required String? currentAssigneeUid,
    required String? currentAssigneeName,
    required String? currentAssigneePhoto,
    required DateTime nextDueAt,
    required bool isOverdue,
    required String status,
  }) = _TaskPreview;

  factory TaskPreview.fromMap(Map<String, dynamic> map) => TaskPreview(
        taskId: map['taskId'] as String,
        title: map['title'] as String,
        visualKind: map['visualKind'] as String? ?? 'emoji',
        visualValue: map['visualValue'] as String? ?? '',
        recurrenceType: map['recurrenceType'] as String,
        currentAssigneeUid: map['currentAssigneeUid'] as String?,
        currentAssigneeName: map['currentAssigneeName'] as String?,
        currentAssigneePhoto: map['currentAssigneePhoto'] as String?,
        nextDueAt: (map['nextDueAt'] as Timestamp).toDate(),
        isOverdue: map['isOverdue'] as bool? ?? false,
        status: map['status'] as String? ?? 'active',
      );
}

@freezed
class DoneTaskPreview with _$DoneTaskPreview {
  const factory DoneTaskPreview({
    required String taskId,
    required String title,
    required String visualKind,
    required String visualValue,
    required String recurrenceType,
    required String completedByUid,
    required String completedByName,
    required String? completedByPhoto,
    required DateTime completedAt,
  }) = _DoneTaskPreview;

  factory DoneTaskPreview.fromMap(Map<String, dynamic> map) => DoneTaskPreview(
        taskId: map['taskId'] as String,
        title: map['title'] as String,
        visualKind: map['visualKind'] as String? ?? 'emoji',
        visualValue: map['visualValue'] as String? ?? '',
        recurrenceType: map['recurrenceType'] as String,
        completedByUid: map['completedByUid'] as String,
        completedByName: map['completedByName'] as String,
        completedByPhoto: map['completedByPhoto'] as String?,
        completedAt: (map['completedAt'] as Timestamp).toDate(),
      );
}

@freezed
class DashboardCounters with _$DashboardCounters {
  const factory DashboardCounters({
    required int totalActiveTasks,
    required int totalMembers,
    required int tasksDueToday,
    required int tasksDoneToday,
  }) = _DashboardCounters;

  factory DashboardCounters.fromMap(Map<String, dynamic> map) =>
      DashboardCounters(
        totalActiveTasks: (map['totalActiveTasks'] as int?) ?? 0,
        totalMembers: (map['totalMembers'] as int?) ?? 0,
        tasksDueToday: (map['tasksDueToday'] as int?) ?? 0,
        tasksDoneToday: (map['tasksDoneToday'] as int?) ?? 0,
      );

  factory DashboardCounters.empty() => const DashboardCounters(
        totalActiveTasks: 0,
        totalMembers: 0,
        tasksDueToday: 0,
        tasksDoneToday: 0,
      );
}

@freezed
class MemberPreview with _$MemberPreview {
  const factory MemberPreview({
    required String uid,
    required String name,
    required String? photoUrl,
    required String role,
    required String status,
    required int tasksDueCount,
  }) = _MemberPreview;

  factory MemberPreview.fromMap(Map<String, dynamic> map) => MemberPreview(
        uid: map['uid'] as String,
        name: map['name'] as String,
        photoUrl: map['photoUrl'] as String?,
        role: map['role'] as String? ?? 'member',
        status: map['status'] as String? ?? 'active',
        tasksDueCount: (map['tasksDueCount'] as int?) ?? 0,
      );
}

@freezed
class PremiumFlags with _$PremiumFlags {
  const factory PremiumFlags({
    required bool isPremium,
    required bool showAds,
    required bool canUseSmartDistribution,
    required bool canUseVacations,
    required bool canUseReviews,
  }) = _PremiumFlags;

  factory PremiumFlags.fromMap(Map<String, dynamic> map) => PremiumFlags(
        isPremium: map['isPremium'] as bool? ?? false,
        showAds: map['showAds'] as bool? ?? true,
        canUseSmartDistribution:
            map['canUseSmartDistribution'] as bool? ?? false,
        canUseVacations: map['canUseVacations'] as bool? ?? false,
        canUseReviews: map['canUseReviews'] as bool? ?? false,
      );

  factory PremiumFlags.free() => const PremiumFlags(
        isPremium: false,
        showAds: true,
        canUseSmartDistribution: false,
        canUseVacations: false,
        canUseReviews: false,
      );
}

@freezed
class AdFlags with _$AdFlags {
  const factory AdFlags({
    required bool showBanner,
    required String bannerUnit,
  }) = _AdFlags;

  factory AdFlags.fromMap(Map<String, dynamic> map) => AdFlags(
        showBanner: map['showBanner'] as bool? ?? false,
        bannerUnit: map['bannerUnit'] as String? ?? '',
      );

  factory AdFlags.empty() =>
      const AdFlags(showBanner: false, bannerUnit: '');
}

@freezed
class RescueFlags with _$RescueFlags {
  const factory RescueFlags({
    required bool isInRescue,
    required int? daysLeft,
  }) = _RescueFlags;

  factory RescueFlags.fromMap(Map<String, dynamic> map) => RescueFlags(
        isInRescue: map['isInRescue'] as bool? ?? false,
        daysLeft: map['daysLeft'] as int?,
      );

  factory RescueFlags.empty() =>
      const RescueFlags(isInRescue: false, daysLeft: null);
}

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

  factory HomeDashboard.fromFirestore(Map<String, dynamic> data) {
    final activeList =
        (data['activeTasksPreview'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(TaskPreview.fromMap)
            .toList();
    final doneList =
        (data['doneTasksPreview'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(DoneTaskPreview.fromMap)
            .toList();
    final memberList =
        (data['memberPreview'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(MemberPreview.fromMap)
            .toList();

    return HomeDashboard(
      activeTasksPreview: activeList,
      doneTasksPreview: doneList,
      counters: DashboardCounters.fromMap(
          (data['counters'] as Map<String, dynamic>?) ?? {}),
      memberPreview: memberList,
      premiumFlags: PremiumFlags.fromMap(
          (data['premiumFlags'] as Map<String, dynamic>?) ?? {}),
      adFlags: AdFlags.fromMap(
          (data['adFlags'] as Map<String, dynamic>?) ?? {}),
      rescueFlags: RescueFlags.fromMap(
          (data['rescueFlags'] as Map<String, dynamic>?) ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
```

- [ ] **Step 2: Ejecutar build_runner para generar `.freezed.dart`**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: se genera `lib/features/tasks/domain/home_dashboard.freezed.dart` sin errores.

- [ ] **Step 3: Confirmar compilación**

```bash
flutter analyze lib/features/tasks/domain/home_dashboard.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/domain/home_dashboard.dart lib/features/tasks/domain/home_dashboard.freezed.dart
git commit -m "feat(tasks): add HomeDashboard domain models with freezed"
```

---

## Task 2: RecurrenceOrder + i18n claves today/recurrence

**Files:**
- Create: `lib/features/tasks/domain/recurrence_order.dart`
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_es.dart`, `_en.dart`, `_ro.dart`

- [ ] **Step 1: Escribir test unitario de RecurrenceOrder**

```dart
// test/unit/features/tasks/recurrence_order_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/recurrence_order.dart';

void main() {
  group('RecurrenceOrder.all', () {
    test('tiene exactamente 5 elementos', () {
      expect(RecurrenceOrder.all.length, 5);
    });

    test('orden es hourly, daily, weekly, monthly, yearly', () {
      expect(RecurrenceOrder.all, [
        'hourly',
        'daily',
        'weekly',
        'monthly',
        'yearly',
      ]);
    });
  });
}
```

- [ ] **Step 2: Ejecutar test (debe fallar)**

```bash
flutter test test/unit/features/tasks/recurrence_order_test.dart
```

Expected: FAIL — `recurrence_order.dart` no existe aún.

- [ ] **Step 3: Crear RecurrenceOrder**

```dart
// lib/features/tasks/domain/recurrence_order.dart
import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';

abstract class RecurrenceOrder {
  static const List<String> all = [
    'hourly',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  static String localizedTitle(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context);
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

- [ ] **Step 4: Añadir claves i18n a app_es.arb** (añadir antes del cierre `}`)

Abrir `lib/l10n/app_es.arb` y añadir antes del último `}`:

```json
  "recurrenceHourly": "Hora",
  "@recurrenceHourly": { "description": "Recurrence type: hourly" },
  "recurrenceDaily": "Día",
  "@recurrenceDaily": { "description": "Recurrence type: daily" },
  "recurrenceWeekly": "Semana",
  "@recurrenceWeekly": { "description": "Recurrence type: weekly" },
  "recurrenceMonthly": "Mes",
  "@recurrenceMonthly": { "description": "Recurrence type: monthly" },
  "recurrenceYearly": "Año",
  "@recurrenceYearly": { "description": "Recurrence type: yearly" },
  "today_screen_title": "Hoy",
  "@today_screen_title": { "description": "Title of the Today screen" },
  "today_tasks_due": "{count} tareas para hoy",
  "@today_tasks_due": {
    "description": "Number of tasks due today",
    "placeholders": { "count": { "type": "int" } }
  },
  "today_tasks_done_today": "{count} completadas hoy",
  "@today_tasks_done_today": {
    "description": "Number of tasks done today",
    "placeholders": { "count": { "type": "int" } }
  },
  "today_section_todo": "Por hacer",
  "@today_section_todo": { "description": "Section label: pending tasks" },
  "today_section_done": "Hechas",
  "@today_section_done": { "description": "Section label: done tasks" },
  "today_overdue": "Vencida",
  "@today_overdue": { "description": "Overdue chip label" },
  "today_due_today": "Hoy {time}",
  "@today_due_today": {
    "description": "Due today chip label",
    "placeholders": { "time": { "type": "String" } }
  },
  "today_due_weekday": "{weekday} {time}",
  "@today_due_weekday": {
    "description": "Due this week chip label",
    "placeholders": {
      "weekday": { "type": "String" },
      "time": { "type": "String" }
    }
  },
  "today_done_by": "Completada por {name} a las {time}",
  "@today_done_by": {
    "description": "Done task completion label",
    "placeholders": {
      "name": { "type": "String" },
      "time": { "type": "String" }
    }
  },
  "today_btn_done": "Hecho",
  "@today_btn_done": { "description": "Mark task done button" },
  "today_btn_pass": "Pasar",
  "@today_btn_pass": { "description": "Pass turn button" },
  "today_empty_title": "Sin tareas para hoy",
  "@today_empty_title": { "description": "Empty state title" },
  "today_empty_body": "Todas las tareas están al día",
  "@today_empty_body": { "description": "Empty state body" }
```

- [ ] **Step 5: Añadir claves a app_en.arb** (mismas claves en inglés)

Añadir antes del `}` final de `lib/l10n/app_en.arb`:

```json
  "recurrenceHourly": "Hour",
  "@recurrenceHourly": { "description": "Recurrence type: hourly" },
  "recurrenceDaily": "Day",
  "@recurrenceDaily": { "description": "Recurrence type: daily" },
  "recurrenceWeekly": "Week",
  "@recurrenceWeekly": { "description": "Recurrence type: weekly" },
  "recurrenceMonthly": "Month",
  "@recurrenceMonthly": { "description": "Recurrence type: monthly" },
  "recurrenceYearly": "Year",
  "@recurrenceYearly": { "description": "Recurrence type: yearly" },
  "today_screen_title": "Today",
  "@today_screen_title": { "description": "Title of the Today screen" },
  "today_tasks_due": "{count} tasks due today",
  "@today_tasks_due": {
    "description": "Number of tasks due today",
    "placeholders": { "count": { "type": "int" } }
  },
  "today_tasks_done_today": "{count} done today",
  "@today_tasks_done_today": {
    "description": "Number of tasks done today",
    "placeholders": { "count": { "type": "int" } }
  },
  "today_section_todo": "To do",
  "@today_section_todo": { "description": "Section label: pending tasks" },
  "today_section_done": "Done",
  "@today_section_done": { "description": "Section label: done tasks" },
  "today_overdue": "Overdue",
  "@today_overdue": { "description": "Overdue chip label" },
  "today_due_today": "Today {time}",
  "@today_due_today": {
    "description": "Due today chip label",
    "placeholders": { "time": { "type": "String" } }
  },
  "today_due_weekday": "{weekday} {time}",
  "@today_due_weekday": {
    "description": "Due this week chip label",
    "placeholders": {
      "weekday": { "type": "String" },
      "time": { "type": "String" }
    }
  },
  "today_done_by": "Done by {name} at {time}",
  "@today_done_by": {
    "description": "Done task completion label",
    "placeholders": {
      "name": { "type": "String" },
      "time": { "type": "String" }
    }
  },
  "today_btn_done": "Done",
  "@today_btn_done": { "description": "Mark task done button" },
  "today_btn_pass": "Pass",
  "@today_btn_pass": { "description": "Pass turn button" },
  "today_empty_title": "No tasks for today",
  "@today_empty_title": { "description": "Empty state title" },
  "today_empty_body": "All tasks are up to date",
  "@today_empty_body": { "description": "Empty state body" }
```

- [ ] **Step 6: Añadir claves a app_ro.arb** (mismo patrón en rumano)

Añadir antes del `}` final de `lib/l10n/app_ro.arb`:

```json
  "recurrenceHourly": "Orar",
  "@recurrenceHourly": { "description": "Recurrence type: hourly" },
  "recurrenceDaily": "Zilnic",
  "@recurrenceDaily": { "description": "Recurrence type: daily" },
  "recurrenceWeekly": "Săptămânal",
  "@recurrenceWeekly": { "description": "Recurrence type: weekly" },
  "recurrenceMonthly": "Lunar",
  "@recurrenceMonthly": { "description": "Recurrence type: monthly" },
  "recurrenceYearly": "Anual",
  "@recurrenceYearly": { "description": "Recurrence type: yearly" },
  "today_screen_title": "Azi",
  "@today_screen_title": { "description": "Title of the Today screen" },
  "today_tasks_due": "{count} sarcini pentru azi",
  "@today_tasks_due": {
    "description": "Number of tasks due today",
    "placeholders": { "count": { "type": "int" } }
  },
  "today_tasks_done_today": "{count} finalizate azi",
  "@today_tasks_done_today": {
    "description": "Number of tasks done today",
    "placeholders": { "count": { "type": "int" } }
  },
  "today_section_todo": "De făcut",
  "@today_section_todo": { "description": "Section label: pending tasks" },
  "today_section_done": "Finalizate",
  "@today_section_done": { "description": "Section label: done tasks" },
  "today_overdue": "Întârziată",
  "@today_overdue": { "description": "Overdue chip label" },
  "today_due_today": "Azi {time}",
  "@today_due_today": {
    "description": "Due today chip label",
    "placeholders": { "time": { "type": "String" } }
  },
  "today_due_weekday": "{weekday} {time}",
  "@today_due_weekday": {
    "description": "Due this week chip label",
    "placeholders": {
      "weekday": { "type": "String" },
      "time": { "type": "String" }
    }
  },
  "today_done_by": "Finalizată de {name} la {time}",
  "@today_done_by": {
    "description": "Done task completion label",
    "placeholders": {
      "name": { "type": "String" },
      "time": { "type": "String" }
    }
  },
  "today_btn_done": "Gata",
  "@today_btn_done": { "description": "Mark task done button" },
  "today_btn_pass": "Pasă",
  "@today_btn_pass": { "description": "Pass turn button" },
  "today_empty_title": "Nicio sarcină pentru azi",
  "@today_empty_title": { "description": "Empty state title" },
  "today_empty_body": "Toate sarcinile sunt la zi",
  "@today_empty_body": { "description": "Empty state body" }
```

- [ ] **Step 7: Añadir abstract getters a app_localizations.dart**

En `lib/l10n/app_localizations.dart`, añadir antes de la clase `_AppLocalizationsDelegate`:

```dart
  /// Recurrence type: hourly
  String get recurrenceHourly;

  /// Recurrence type: daily
  String get recurrenceDaily;

  /// Recurrence type: weekly
  String get recurrenceWeekly;

  /// Recurrence type: monthly
  String get recurrenceMonthly;

  /// Recurrence type: yearly
  String get recurrenceYearly;

  /// Today screen title
  String get today_screen_title;

  /// Number of tasks due today
  String today_tasks_due(int count);

  /// Number of tasks done today
  String today_tasks_done_today(int count);

  /// Section label: pending tasks
  String get today_section_todo;

  /// Section label: done tasks
  String get today_section_done;

  /// Overdue chip label
  String get today_overdue;

  /// Due today chip label with time
  String today_due_today(String time);

  /// Due this week chip label
  String today_due_weekday(String weekday, String time);

  /// Done task completion label
  String today_done_by(String name, String time);

  /// Mark task done button
  String get today_btn_done;

  /// Pass turn button
  String get today_btn_pass;

  /// Empty state title
  String get today_empty_title;

  /// Empty state body
  String get today_empty_body;
```

- [ ] **Step 8: Añadir implementaciones a app_localizations_es.dart**

En `lib/l10n/app_localizations_es.dart`, añadir al final de la clase (antes del `}`):

```dart
  @override
  String get recurrenceHourly => 'Hora';

  @override
  String get recurrenceDaily => 'Día';

  @override
  String get recurrenceWeekly => 'Semana';

  @override
  String get recurrenceMonthly => 'Mes';

  @override
  String get recurrenceYearly => 'Año';

  @override
  String get today_screen_title => 'Hoy';

  @override
  String today_tasks_due(int count) => '$count tareas para hoy';

  @override
  String today_tasks_done_today(int count) => '$count completadas hoy';

  @override
  String get today_section_todo => 'Por hacer';

  @override
  String get today_section_done => 'Hechas';

  @override
  String get today_overdue => 'Vencida';

  @override
  String today_due_today(String time) => 'Hoy $time';

  @override
  String today_due_weekday(String weekday, String time) => '$weekday $time';

  @override
  String today_done_by(String name, String time) =>
      'Completada por $name a las $time';

  @override
  String get today_btn_done => 'Hecho';

  @override
  String get today_btn_pass => 'Pasar';

  @override
  String get today_empty_title => 'Sin tareas para hoy';

  @override
  String get today_empty_body => 'Todas las tareas están al día';
```

- [ ] **Step 9: Añadir implementaciones a app_localizations_en.dart** (misma estructura)

```dart
  @override
  String get recurrenceHourly => 'Hour';

  @override
  String get recurrenceDaily => 'Day';

  @override
  String get recurrenceWeekly => 'Week';

  @override
  String get recurrenceMonthly => 'Month';

  @override
  String get recurrenceYearly => 'Year';

  @override
  String get today_screen_title => 'Today';

  @override
  String today_tasks_due(int count) => '$count tasks due today';

  @override
  String today_tasks_done_today(int count) => '$count done today';

  @override
  String get today_section_todo => 'To do';

  @override
  String get today_section_done => 'Done';

  @override
  String get today_overdue => 'Overdue';

  @override
  String today_due_today(String time) => 'Today $time';

  @override
  String today_due_weekday(String weekday, String time) => '$weekday $time';

  @override
  String today_done_by(String name, String time) => 'Done by $name at $time';

  @override
  String get today_btn_done => 'Done';

  @override
  String get today_btn_pass => 'Pass';

  @override
  String get today_empty_title => 'No tasks for today';

  @override
  String get today_empty_body => 'All tasks are up to date';
```

- [ ] **Step 10: Añadir implementaciones a app_localizations_ro.dart**

```dart
  @override
  String get recurrenceHourly => 'Orar';

  @override
  String get recurrenceDaily => 'Zilnic';

  @override
  String get recurrenceWeekly => 'Săptămânal';

  @override
  String get recurrenceMonthly => 'Lunar';

  @override
  String get recurrenceYearly => 'Anual';

  @override
  String get today_screen_title => 'Azi';

  @override
  String today_tasks_due(int count) => '$count sarcini pentru azi';

  @override
  String today_tasks_done_today(int count) => '$count finalizate azi';

  @override
  String get today_section_todo => 'De făcut';

  @override
  String get today_section_done => 'Finalizate';

  @override
  String get today_overdue => 'Întârziată';

  @override
  String today_due_today(String time) => 'Azi $time';

  @override
  String today_due_weekday(String weekday, String time) => '$weekday $time';

  @override
  String today_done_by(String name, String time) =>
      'Finalizată de $name la $time';

  @override
  String get today_btn_done => 'Gata';

  @override
  String get today_btn_pass => 'Pasă';

  @override
  String get today_empty_title => 'Nicio sarcină pentru azi';

  @override
  String get today_empty_body => 'Toate sarcinile sunt la zi';
```

- [ ] **Step 11: Verificar compilación**

```bash
flutter analyze lib/features/tasks/domain/recurrence_order.dart lib/l10n/
```

Expected: No issues found.

- [ ] **Step 12: Ejecutar test de RecurrenceOrder (debe pasar)**

```bash
flutter test test/unit/features/tasks/recurrence_order_test.dart
```

Expected: PASS — 2 tests passed.

- [ ] **Step 13: Commit**

```bash
git add lib/features/tasks/domain/recurrence_order.dart lib/l10n/ test/unit/features/tasks/recurrence_order_test.dart
git commit -m "feat(tasks): add RecurrenceOrder and today/recurrence i18n keys"
```

---

## Task 3: DashboardProvider

**Files:**
- Create: `lib/features/homes/application/dashboard_provider.dart`

- [ ] **Step 1: Crear el provider**

```dart
// lib/features/homes/application/dashboard_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../tasks/domain/home_dashboard.dart';
import 'current_home_provider.dart';

part 'dashboard_provider.g.dart';

@riverpod
Stream<HomeDashboard?> dashboard(DashboardRef ref) {
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  if (homeId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('homes')
      .doc(homeId)
      .collection('views')
      .doc('dashboard')
      .snapshots()
      .map((snap) =>
          snap.exists ? HomeDashboard.fromFirestore(snap.data()!) : null);
}
```

- [ ] **Step 2: Generar el código riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: se genera `lib/features/homes/application/dashboard_provider.g.dart`.

- [ ] **Step 3: Verificar**

```bash
flutter analyze lib/features/homes/application/dashboard_provider.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/homes/application/dashboard_provider.dart lib/features/homes/application/dashboard_provider.g.dart
git commit -m "feat(homes): add dashboardProvider stream for Today screen"
```

---

## Task 4: groupByRecurrence + tests unitarios

**Files:**
- Modify: `lib/features/tasks/presentation/today_screen.dart` (se crea aquí con la función)
- Create: `test/unit/features/tasks/dashboard_grouping_test.dart`

- [ ] **Step 1: Escribir tests de agrupación (fallarán)**

```dart
// test/unit/features/tasks/dashboard_grouping_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/today_screen.dart';

TaskPreview _makeTask({
  required String taskId,
  required String recurrenceType,
  required String title,
  bool isOverdue = false,
  DateTime? nextDueAt,
  String? currentAssigneeUid,
}) =>
    TaskPreview(
      taskId: taskId,
      title: title,
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: recurrenceType,
      currentAssigneeUid: currentAssigneeUid,
      currentAssigneeName: null,
      currentAssigneePhoto: null,
      nextDueAt: nextDueAt ?? DateTime(2026, 4, 6, 10, 0),
      isOverdue: isOverdue,
      status: 'active',
    );

DoneTaskPreview _makeDone({
  required String taskId,
  required String recurrenceType,
  required String title,
}) =>
    DoneTaskPreview(
      taskId: taskId,
      title: title,
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: recurrenceType,
      completedByUid: 'uid1',
      completedByName: 'Ana',
      completedByPhoto: null,
      completedAt: DateTime(2026, 4, 6, 8, 0),
    );

void main() {
  group('groupByRecurrence', () {
    test('agrupa tareas activas por recurrenceType', () {
      final active = [
        _makeTask(taskId: 't1', recurrenceType: 'daily', title: 'Barrer'),
        _makeTask(taskId: 't2', recurrenceType: 'weekly', title: 'Lavar ropa'),
        _makeTask(taskId: 't3', recurrenceType: 'daily', title: 'Fregar'),
      ];

      final result = groupByRecurrence(active, []);

      expect(result.keys, containsAll(['daily', 'weekly']));
      expect(result['daily']!.todos.length, 2);
      expect(result['weekly']!.todos.length, 1);
    });

    test('agrupa tareas completadas por recurrenceType', () {
      final done = [
        _makeDone(taskId: 'd1', recurrenceType: 'daily', title: 'Barrer'),
        _makeDone(taskId: 'd2', recurrenceType: 'monthly', title: 'Ventanas'),
      ];

      final result = groupByRecurrence([], done);

      expect(result['daily']!.dones.length, 1);
      expect(result['monthly']!.dones.length, 1);
    });

    test('bloque sin tareas no aparece en el resultado', () {
      final active = [
        _makeTask(taskId: 't1', recurrenceType: 'daily', title: 'Barrer'),
      ];

      final result = groupByRecurrence(active, []);

      expect(result.containsKey('weekly'), isFalse);
      expect(result.containsKey('monthly'), isFalse);
    });

    test('dentro de Por hacer: vencidas primero, luego por fecha, luego alfabético', () {
      final now = DateTime(2026, 4, 6, 12, 0);
      final active = [
        _makeTask(
            taskId: 't1',
            recurrenceType: 'daily',
            title: 'Zebra',
            nextDueAt: now.add(const Duration(hours: 2))),
        _makeTask(
            taskId: 't2',
            recurrenceType: 'daily',
            title: 'Alpha',
            isOverdue: true,
            nextDueAt: now.subtract(const Duration(hours: 1))),
        _makeTask(
            taskId: 't3',
            recurrenceType: 'daily',
            title: 'Beta',
            nextDueAt: now.add(const Duration(hours: 1))),
      ];

      final result = groupByRecurrence(active, []);
      final todos = result['daily']!.todos;

      expect(todos[0].taskId, 't2'); // vencida primero
      expect(todos[1].taskId, 't3'); // antes por fecha
      expect(todos[2].taskId, 't1'); // después por fecha
    });

    test('dentro de Por hacer con misma fecha: orden alfabético', () {
      final same = DateTime(2026, 4, 6, 15, 0);
      final active = [
        _makeTask(
            taskId: 't1',
            recurrenceType: 'daily',
            title: 'Zebra',
            nextDueAt: same),
        _makeTask(
            taskId: 't2',
            recurrenceType: 'daily',
            title: 'Alpha',
            nextDueAt: same),
      ];

      final result = groupByRecurrence(active, []);
      final todos = result['daily']!.todos;

      expect(todos[0].title, 'Alpha');
      expect(todos[1].title, 'Zebra');
    });

    test('resultado vacío cuando no hay tareas', () {
      final result = groupByRecurrence([], []);
      expect(result, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Ejecutar tests (deben fallar)**

```bash
flutter test test/unit/features/tasks/dashboard_grouping_test.dart
```

Expected: FAIL — `today_screen.dart` / `groupByRecurrence` no existe.

- [ ] **Step 3: Crear today_screen.dart con groupByRecurrence**

```dart
// lib/features/tasks/presentation/today_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../domain/home_dashboard.dart';
import '../domain/recurrence_order.dart';
import 'widgets/today_empty_state.dart';
import 'widgets/today_header_counters.dart';
import 'widgets/today_skeleton_loader.dart';
import 'widgets/today_task_section.dart';

typedef _RecurrenceGroup = ({
  List<TaskPreview> todos,
  List<DoneTaskPreview> dones,
});

@visibleForTesting
Map<String, _RecurrenceGroup> groupByRecurrence(
  List<TaskPreview> activeTasks,
  List<DoneTaskPreview> doneTasks,
) {
  final result = <String, _RecurrenceGroup>{};

  for (final task in activeTasks) {
    final key = task.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: [...(existing?.todos ?? []), task],
      dones: existing?.dones ?? [],
    );
  }

  for (final done in doneTasks) {
    final key = done.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: existing?.todos ?? [],
      dones: [...(existing?.dones ?? []), done],
    );
  }

  // Sort todos within each group
  for (final key in result.keys) {
    final group = result[key]!;
    final sorted = [...group.todos];
    sorted.sort((a, b) {
      // 1. Overdue first
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      // 2. By nextDueAt ascending
      final dateCmp = a.nextDueAt.compareTo(b.nextDueAt);
      if (dateCmp != 0) return dateCmp;
      // 3. Alphabetically
      return a.title.compareTo(b.title);
    });
    result[key] = (todos: sorted, dones: group.dones);
  }

  return result;
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dashboardAsync = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider);
    final currentUid = auth.whenOrNull(authenticated: (u) => u.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.today_screen_title),
      ),
      body: dashboardAsync.when(
        loading: () => const TodaySkeletonLoader(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.error_generic),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null) return const TodayEmptyState();

          final grouped = groupByRecurrence(
            data.activeTasksPreview,
            data.doneTasksPreview,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TodayHeaderCounters(counters: data.counters),
              ),
              for (final recurrenceType in RecurrenceOrder.all)
                if (grouped[recurrenceType] != null) ...[
                  TodayTaskSection(
                    recurrenceType: recurrenceType,
                    todos: grouped[recurrenceType]!.todos,
                    dones: grouped[recurrenceType]!.dones,
                    currentUid: currentUid,
                  ),
                ],
              if (data.adFlags.showBanner)
                SliverToBoxAdapter(
                  child: _AdBannerPlaceholder(
                    key: const Key('ad_banner'),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _AdBannerPlaceholder extends StatelessWidget {
  const _AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Ad')),
    );
  }
}
```

- [ ] **Step 4: Ejecutar tests de agrupación (deben pasar)**

```bash
flutter test test/unit/features/tasks/dashboard_grouping_test.dart
```

Expected: PASS — 6 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/today_screen.dart test/unit/features/tasks/dashboard_grouping_test.dart
git commit -m "feat(tasks): add TodayScreen skeleton and groupByRecurrence logic"
```

---

## Task 5: Widgets de la pantalla Hoy

**Files:**
- Create: `lib/features/tasks/presentation/widgets/today_skeleton_loader.dart`
- Create: `lib/features/tasks/presentation/widgets/today_empty_state.dart`
- Create: `lib/features/tasks/presentation/widgets/today_header_counters.dart`
- Create: `lib/features/tasks/presentation/widgets/today_task_card_todo.dart`
- Create: `lib/features/tasks/presentation/widgets/today_task_card_done.dart`
- Create: `lib/features/tasks/presentation/widgets/today_task_section.dart`

- [ ] **Step 1: Crear TodaySkeletonLoader**

```dart
// lib/features/tasks/presentation/widgets/today_skeleton_loader.dart
import 'package:flutter/material.dart';

class TodaySkeletonLoader extends StatefulWidget {
  const TodaySkeletonLoader({super.key});

  @override
  State<TodaySkeletonLoader> createState() => _TodaySkeletonLoaderState();
}

class _TodaySkeletonLoaderState extends State<TodaySkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(height: 80, borderRadius: 12),
              const SizedBox(height: 16),
              for (int i = 0; i < 3; i++) ...[
                _SkeletonBox(height: 20, width: 100),
                const SizedBox(height: 8),
                _SkeletonBox(height: 72, borderRadius: 12),
                const SizedBox(height: 8),
                _SkeletonBox(height: 72, borderRadius: 12),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const _SkeletonBox({
    required this.height,
    this.width,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
```

- [ ] **Step 2: Crear TodayEmptyState**

```dart
// lib/features/tasks/presentation/widgets/today_empty_state.dart
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class TodayEmptyState extends StatelessWidget {
  const TodayEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.today_empty_title,
            style: Theme.of(context).textTheme.titleLarge,
            key: const Key('today_empty_title'),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.today_empty_body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            key: const Key('today_empty_body'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Crear TodayHeaderCounters**

```dart
// lib/features/tasks/presentation/widgets/today_header_counters.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class TodayHeaderCounters extends StatelessWidget {
  final DashboardCounters counters;

  const TodayHeaderCounters({super.key, required this.counters});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _CounterChip(
              key: const Key('counter_due'),
              label: l10n.today_tasks_due(counters.tasksDueToday),
              icon: Icons.assignment_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CounterChip(
              key: const Key('counter_done'),
              label: l10n.today_tasks_done_today(counters.tasksDoneToday),
              icon: Icons.check_circle_outline,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _CounterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Escribir tests de lógica de TodayTaskCardTodo (fallarán)**

```dart
// test/unit/features/tasks/today_task_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/today_task_card_todo.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

TaskPreview _makeTask({
  String? currentAssigneeUid,
  bool isOverdue = false,
  DateTime? nextDueAt,
}) =>
    TaskPreview(
      taskId: 't1',
      title: 'Barrer',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: currentAssigneeUid,
      currentAssigneeName: currentAssigneeUid != null ? 'Ana' : null,
      currentAssigneePhoto: null,
      nextDueAt: nextDueAt ?? DateTime(2026, 4, 6, 20, 0),
      isOverdue: isOverdue,
      status: 'active',
    );

void main() {
  group('TodayTaskCardTodo — botones de acción', () {
    testWidgets('muestra botones si currentAssigneeUid == currentUid',
        (tester) async {
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(currentAssigneeUid: 'uid1'),
          currentUid: 'uid1',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsOneWidget);
      expect(find.byKey(const Key('btn_pass')), findsOneWidget);
    });

    testWidgets('no muestra botones si currentAssigneeUid != currentUid',
        (tester) async {
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(currentAssigneeUid: 'uid2'),
          currentUid: 'uid1',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsNothing);
      expect(find.byKey(const Key('btn_pass')), findsNothing);
    });

    testWidgets('no muestra botones si currentUid es null', (tester) async {
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(currentAssigneeUid: 'uid1'),
          currentUid: null,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsNothing);
      expect(find.byKey(const Key('btn_pass')), findsNothing);
    });

    testWidgets('chip muestra "Vencida" si isOverdue == true', (tester) async {
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(isOverdue: true),
          currentUid: null,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vencida'), findsOneWidget);
    });

    testWidgets('chip muestra "Hoy HH:mm" si vence hoy', (tester) async {
      final today = DateTime(2026, 4, 6, 20, 0);
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(nextDueAt: today),
          currentUid: null,
          now: DateTime(2026, 4, 6, 10, 0),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hoy 20:00'), findsOneWidget);
    });

    testWidgets('chip muestra "Weekday HH:mm" si vence otra fecha',
        (tester) async {
      final nextWeek = DateTime(2026, 4, 7, 15, 30); // Martes
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(nextDueAt: nextWeek),
          currentUid: null,
          now: DateTime(2026, 4, 6, 10, 0),
        )),
      );
      await tester.pumpAndSettle();

      // La etiqueta depende de la localización, debe contener la hora
      expect(find.textContaining('15:30'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 5: Ejecutar tests (deben fallar)**

```bash
flutter test test/unit/features/tasks/today_task_card_test.dart
```

Expected: FAIL — `TodayTaskCardTodo` no existe.

- [ ] **Step 6: Crear TodayTaskCardTodo**

```dart
// lib/features/tasks/presentation/widgets/today_task_card_todo.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class TodayTaskCardTodo extends StatelessWidget {
  final TaskPreview task;
  final String? currentUid;
  final VoidCallback? onDone;
  final VoidCallback? onPass;
  /// Inyectable para tests — por defecto DateTime.now()
  final DateTime? now;

  const TodayTaskCardTodo({
    super.key,
    required this.task,
    required this.currentUid,
    this.onDone,
    this.onPass,
    this.now,
  });

  String _dueDateLabel(BuildContext context, AppLocalizations l10n) {
    if (task.isOverdue) return l10n.today_overdue;
    final effectiveNow = now ?? DateTime.now();
    final dueDate = task.nextDueAt;
    final timeStr = DateFormat('HH:mm').format(dueDate);
    final isToday = dueDate.year == effectiveNow.year &&
        dueDate.month == effectiveNow.month &&
        dueDate.day == effectiveNow.day;
    if (isToday) return l10n.today_due_today(timeStr);
    final weekday = DateFormat('EEE', Localizations.localeOf(context).toString())
        .format(dueDate);
    return l10n.today_due_weekday(weekday, timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAssignedToMe =
        task.currentAssigneeUid != null && task.currentAssigneeUid == currentUid;
    final dueLabel = _dueDateLabel(context, l10n);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AssigneeAvatar(
                  name: task.currentAssigneeName,
                  photoUrl: task.currentAssigneePhoto,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${task.visualValue} ${task.title}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _DueDateChip(
                  label: dueLabel,
                  isOverdue: task.isOverdue,
                ),
              ],
            ),
            if (isAssignedToMe) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    key: const Key('btn_done'),
                    onPressed: onDone ?? () {},
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(l10n.today_btn_done),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('btn_pass'),
                    onPressed: onPass ?? () {},
                    icon: const Icon(Icons.sync, size: 16),
                    label: Text(l10n.today_btn_pass),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssigneeAvatar extends StatelessWidget {
  final String? name;
  final String? photoUrl;

  const _AssigneeAvatar({this.name, this.photoUrl});

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.secondary,
      child: Text(
        _initials,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final String label;
  final bool isOverdue;

  const _DueDateChip({required this.label, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withOpacity(0.15)
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isOverdue ? AppColors.error : AppColors.textSecondary,
          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Crear TodayTaskCardDone**

```dart
// lib/features/tasks/presentation/widgets/today_task_card_done.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class TodayTaskCardDone extends StatelessWidget {
  final DoneTaskPreview task;

  const TodayTaskCardDone({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeStr = DateFormat('HH:mm').format(task.completedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: AppColors.surface.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${task.visualValue} ${task.title}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.textSecondary,
                          color: AppColors.textSecondary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.today_done_by(task.completedByName, timeStr),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    key: const Key('done_by_label'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Crear TodayTaskSection**

```dart
// lib/features/tasks/presentation/widgets/today_task_section.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';
import '../../domain/recurrence_order.dart';
import 'today_task_card_done.dart';
import 'today_task_card_todo.dart';

class TodayTaskSection extends StatelessWidget {
  final String recurrenceType;
  final List<TaskPreview> todos;
  final List<DoneTaskPreview> dones;
  final String? currentUid;

  const TodayTaskSection({
    super.key,
    required this.recurrenceType,
    required this.todos,
    required this.dones,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sectionTitle = RecurrenceOrder.localizedTitle(context, recurrenceType);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              sectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              key: Key('section_title_$recurrenceType'),
            ),
          ),
        ),
        if (todos.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                l10n.today_section_todo,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) => TodayTaskCardTodo(
              task: todos[index],
              currentUid: currentUid,
            ),
          ),
        ],
        if (dones.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: Text(
                l10n.today_section_done,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: dones.length,
            itemBuilder: (context, index) =>
                TodayTaskCardDone(task: dones[index]),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 9: Ejecutar tests de lógica de tarjetas (deben pasar)**

```bash
flutter test test/unit/features/tasks/today_task_card_test.dart
```

Expected: PASS — 6 tests passed.

- [ ] **Step 10: Verificar compilación de todos los widgets**

```bash
flutter analyze lib/features/tasks/
```

Expected: No issues found.

- [ ] **Step 11: Commit**

```bash
git add lib/features/tasks/presentation/widgets/ test/unit/features/tasks/today_task_card_test.dart
git commit -m "feat(tasks): add Today screen widgets (skeleton, empty, header, cards, section)"
```

---

## Task 6: Conectar ruta /home a TodayScreen

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Actualizar la ruta `/home`**

En `lib/app.dart`, cambiar el import y el builder de la ruta `/home`:

Añadir import:
```dart
import 'features/tasks/presentation/today_screen.dart';
```

Cambiar el GoRoute de `/home`:
```dart
GoRoute(
  path: AppRoutes.home,
  builder: (_, __) => const TodayScreen(),
),
```

Eliminar la clase `_HomePlaceholder` si queda sin uso.

- [ ] **Step 2: Verificar**

```bash
flutter analyze lib/app.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/app.dart
git commit -m "feat(nav): wire /home route to TodayScreen"
```

---

## Task 7: Cloud Function updateHomeDashboard

**Files:**
- Create: `functions/src/tasks/update_dashboard.ts`
- Modify: `functions/src/tasks/index.ts`
- Modify: `functions/src/jobs/index.ts`

- [ ] **Step 1: Crear update_dashboard.ts**

```typescript
// functions/src/tasks/update_dashboard.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ---------------------------------------------------------------------------
// updateHomeDashboard
// Reconstruye el documento homes/{homeId}/views/dashboard.
// Llamada internamente desde funciones de completar tarea y pasar turno.
// ---------------------------------------------------------------------------
export async function updateHomeDashboard(homeId: string): Promise<void> {
  logger.info(`Rebuilding dashboard for home ${homeId}`);

  const homeRef = db.collection("homes").doc(homeId);
  const homeDoc = await homeRef.get();
  if (!homeDoc.exists) {
    logger.warn(`updateHomeDashboard: home ${homeId} not found`);
    return;
  }
  const homeData = homeDoc.data()!;

  // --- 1. Leer tareas activas del hogar ---
  const tasksSnap = await homeRef.collection("tasks")
    .where("status", "==", "active")
    .get();

  // --- 2. Determinar qué tareas son "de hoy" ---
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

  const activeTasksPreview: Record<string, unknown>[] = [];
  for (const doc of tasksSnap.docs) {
    const t = doc.data();
    const nextDueAt = (t["nextDueAt"] as admin.firestore.Timestamp | undefined)?.toDate();
    if (!nextDueAt) continue;
    const isOverdue = nextDueAt < todayStart;
    const isDueToday = nextDueAt >= todayStart && nextDueAt < todayEnd;
    if (!isDueToday && !isOverdue) continue;

    activeTasksPreview.push({
      taskId: doc.id,
      title: t["title"] ?? "",
      visualKind: t["visualKind"] ?? "emoji",
      visualValue: t["visualValue"] ?? "",
      recurrenceType: t["recurrenceType"] ?? "daily",
      currentAssigneeUid: t["currentAssigneeUid"] ?? null,
      currentAssigneeName: t["currentAssigneeName"] ?? null,
      currentAssigneePhoto: t["currentAssigneePhoto"] ?? null,
      nextDueAt: t["nextDueAt"],
      isOverdue,
      status: "active",
    });
  }

  // --- 3. Leer completados de hoy ---
  const completedSnap = await homeRef.collection("task_completions")
    .where("completedAt", ">=", admin.firestore.Timestamp.fromDate(todayStart))
    .where("completedAt", "<", admin.firestore.Timestamp.fromDate(todayEnd))
    .get();

  const doneTasksPreview: Record<string, unknown>[] = [];
  for (const doc of completedSnap.docs) {
    const c = doc.data();
    doneTasksPreview.push({
      taskId: c["taskId"] ?? doc.id,
      title: c["title"] ?? "",
      visualKind: c["visualKind"] ?? "emoji",
      visualValue: c["visualValue"] ?? "",
      recurrenceType: c["recurrenceType"] ?? "daily",
      completedByUid: c["completedByUid"] ?? "",
      completedByName: c["completedByName"] ?? "",
      completedByPhoto: c["completedByPhoto"] ?? null,
      completedAt: c["completedAt"],
    });
  }

  // --- 4. Leer miembros activos ---
  const membersSnap = await db.collectionGroup("memberships")
    .where("status", "==", "active")
    .get();

  const memberPreview: Record<string, unknown>[] = [];
  for (const doc of membersSnap.docs) {
    if (doc.ref.parent.parent?.id !== homeId) continue;
    const m = doc.data();
    const memberTaskCount = activeTasksPreview.filter(
      (t) => t["currentAssigneeUid"] === doc.id
    ).length;
    memberPreview.push({
      uid: doc.id,
      name: m["name"] ?? "",
      photoUrl: m["photoUrl"] ?? null,
      role: m["role"] ?? "member",
      status: "active",
      tasksDueCount: memberTaskCount,
    });
  }

  // --- 5. Flags premium ---
  const isPremium = homeData["premiumStatus"] !== "free" &&
    homeData["premiumStatus"] !== "expiredFree";
  const premiumFlags = {
    isPremium,
    showAds: !isPremium,
    canUseSmartDistribution: isPremium,
    canUseVacations: isPremium,
    canUseReviews: isPremium,
  };
  const adFlags = {
    showBanner: !isPremium,
    bannerUnit: "ca-app-pub-3940256099942544/6300978111", // test unit
  };
  const rescueFlags = {
    isInRescue: homeData["premiumStatus"] === "rescue",
    daysLeft: null as number | null,
  };

  // --- 6. Contadores ---
  const counters = {
    totalActiveTasks: tasksSnap.size,
    totalMembers: memberPreview.length,
    tasksDueToday: activeTasksPreview.length,
    tasksDoneToday: doneTasksPreview.length,
  };

  // --- 7. Escribir dashboard ---
  const dashboardRef = homeRef.collection("views").doc("dashboard");
  await dashboardRef.set({
    activeTasksPreview,
    doneTasksPreview,
    counters,
    memberPreview,
    premiumFlags,
    adFlags,
    rescueFlags,
    updatedAt: FieldValue.serverTimestamp(),
  });

  logger.info(`Dashboard updated for home ${homeId}`);
}

// ---------------------------------------------------------------------------
// Cron: reset diario a medianoche (00:00 UTC)
// ---------------------------------------------------------------------------
export const resetDashboardsDaily = onSchedule(
  { schedule: "0 0 * * *", timeZone: "UTC" },
  async () => {
    logger.info("Starting daily dashboard reset for all homes");

    const homesSnap = await db.collection("homes")
      .where("premiumStatus", "!=", "purged")
      .get();

    const updates = homesSnap.docs.map((doc) =>
      updateHomeDashboard(doc.id).catch((err) =>
        logger.error(`Failed to reset dashboard for ${doc.id}:`, err)
      )
    );

    await Promise.all(updates);
    logger.info(`Daily dashboard reset complete for ${homesSnap.size} homes`);
  }
);
```

- [ ] **Step 2: Exportar desde tasks/index.ts**

Reemplazar el contenido de `functions/src/tasks/index.ts`:

```typescript
export * from "./update_dashboard";
```

- [ ] **Step 3: Verificar TypeScript**

```bash
cd functions && npm run build 2>&1 | head -30
```

Expected: Sin errores de compilación TypeScript.

- [ ] **Step 4: Commit**

```bash
git add functions/src/tasks/ && git commit -m "feat(functions): add updateHomeDashboard helper and daily cron reset"
```

---

## Task 8: Tests de integración (dashboard stream)

**Files:**
- Create: `test/integration/features/tasks/dashboard_stream_test.dart`

- [ ] **Step 1: Escribir tests de integración (fallarán)**

```dart
// test/integration/features/tasks/dashboard_stream_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

Future<void> _writeDashboard(
  FakeFirebaseFirestore firestore,
  String homeId, {
  List<Map<String, dynamic>> activeTasks = const [],
  List<Map<String, dynamic>> doneTasks = const [],
}) {
  return firestore
      .collection('homes')
      .doc(homeId)
      .collection('views')
      .doc('dashboard')
      .set({
    'activeTasksPreview': activeTasks,
    'doneTasksPreview': doneTasks,
    'counters': {
      'totalActiveTasks': activeTasks.length,
      'totalMembers': 2,
      'tasksDueToday': activeTasks.length,
      'tasksDoneToday': doneTasks.length,
    },
    'memberPreview': [],
    'premiumFlags': {
      'isPremium': false,
      'showAds': true,
      'canUseSmartDistribution': false,
      'canUseVacations': false,
      'canUseReviews': false,
    },
    'adFlags': {'showBanner': true, 'bannerUnit': 'test-unit'},
    'rescueFlags': {'isInRescue': false, 'daysLeft': null},
    'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 6)),
  });
}

Stream<HomeDashboard?> _watchDashboard(
    FakeFirebaseFirestore firestore, String homeId) {
  return firestore
      .collection('homes')
      .doc(homeId)
      .collection('views')
      .doc('dashboard')
      .snapshots()
      .map((snap) =>
          snap.exists ? HomeDashboard.fromFirestore(snap.data()!) : null);
}

void main() {
  group('dashboard stream', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('emite HomeDashboard cuando existe el documento', () async {
      await _writeDashboard(firestore, 'home1');

      final dashboard = await _watchDashboard(firestore, 'home1').first;

      expect(dashboard, isNotNull);
      expect(dashboard!.counters.totalMembers, 2);
    });

    test('emite null cuando el documento no existe', () async {
      final dashboard = await _watchDashboard(firestore, 'home-noexiste').first;
      expect(dashboard, isNull);
    });

    test('emite nuevo valor al actualizar el documento', () async {
      await _writeDashboard(firestore, 'home2',
          activeTasks: [
            {
              'taskId': 't1',
              'title': 'Barrer',
              'visualKind': 'emoji',
              'visualValue': '🧹',
              'recurrenceType': 'daily',
              'currentAssigneeUid': null,
              'currentAssigneeName': null,
              'currentAssigneePhoto': null,
              'nextDueAt': Timestamp.fromDate(DateTime(2026, 4, 6, 10)),
              'isOverdue': false,
              'status': 'active',
            }
          ]);

      final stream = _watchDashboard(firestore, 'home2');
      final first = await stream.first;
      expect(first!.activeTasksPreview.length, 1);

      // Actualizar
      await _writeDashboard(firestore, 'home2', activeTasks: []);
      final values = await stream.take(2).toList();
      expect(values.last!.activeTasksPreview, isEmpty);
    });

    test('HomeDashboard.fromFirestore parsea activeTasksPreview correctamente',
        () async {
      final taskTime = DateTime(2026, 4, 6, 20, 0);
      await _writeDashboard(firestore, 'home3', activeTasks: [
        {
          'taskId': 'task-abc',
          'title': 'Fregar',
          'visualKind': 'emoji',
          'visualValue': '🍽️',
          'recurrenceType': 'weekly',
          'currentAssigneeUid': 'uid-x',
          'currentAssigneeName': 'Carlos',
          'currentAssigneePhoto': null,
          'nextDueAt': Timestamp.fromDate(taskTime),
          'isOverdue': false,
          'status': 'active',
        }
      ]);

      final dashboard = await _watchDashboard(firestore, 'home3').first;

      expect(dashboard!.activeTasksPreview.length, 1);
      final task = dashboard.activeTasksPreview.first;
      expect(task.taskId, 'task-abc');
      expect(task.title, 'Fregar');
      expect(task.recurrenceType, 'weekly');
      expect(task.currentAssigneeUid, 'uid-x');
      expect(task.nextDueAt, taskTime);
    });

    test('adFlags.showBanner es false cuando isPremium', () async {
      await firestore
          .collection('homes')
          .doc('home-premium')
          .collection('views')
          .doc('dashboard')
          .set({
        'activeTasksPreview': [],
        'doneTasksPreview': [],
        'counters': {
          'totalActiveTasks': 0,
          'totalMembers': 1,
          'tasksDueToday': 0,
          'tasksDoneToday': 0,
        },
        'memberPreview': [],
        'premiumFlags': {
          'isPremium': true,
          'showAds': false,
          'canUseSmartDistribution': true,
          'canUseVacations': true,
          'canUseReviews': true,
        },
        'adFlags': {'showBanner': false, 'bannerUnit': ''},
        'rescueFlags': {'isInRescue': false, 'daysLeft': null},
        'updatedAt': Timestamp.fromDate(DateTime(2026, 4, 6)),
      });

      final dashboard =
          await _watchDashboard(firestore, 'home-premium').first;

      expect(dashboard!.adFlags.showBanner, isFalse);
      expect(dashboard.premiumFlags.isPremium, isTrue);
    });
  });
}
```

- [ ] **Step 2: Ejecutar tests de integración**

```bash
flutter test test/integration/features/tasks/dashboard_stream_test.dart
```

Expected: PASS — 5 tests passed.

- [ ] **Step 3: Commit**

```bash
git add test/integration/features/tasks/dashboard_stream_test.dart
git commit -m "test(tasks): add dashboard stream integration tests"
```

---

## Task 9: Tests de UI (TodayScreen + golden tests)

**Files:**
- Create: `test/ui/features/tasks/today_screen_test.dart`
- Create: `test/ui/features/tasks/today_task_card_todo_test.dart`
- Create: `test/ui/features/tasks/today_task_card_done_test.dart`

- [ ] **Step 1: Crear test de UI de TodayScreen**

```dart
// test/ui/features/tasks/today_screen_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/today_screen.dart';
import 'package:toka/features/tasks/presentation/widgets/today_skeleton_loader.dart';
import 'package:toka/features/tasks/presentation/widgets/today_empty_state.dart';
import 'package:toka/l10n/app_localizations.dart';

const _fakeUser = AuthUser(
  uid: 'uid1',
  email: 'u@u.com',
  displayName: 'User',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

class _FakeAuth extends Auth {
  final AuthState _state;
  _FakeAuth(this._state);
  @override
  AuthState build() => _state;
}

HomeDashboard _buildDashboard({
  List<TaskPreview> activeTasks = const [],
  List<DoneTaskPreview> doneTasks = const [],
  bool showBanner = false,
}) =>
    HomeDashboard(
      activeTasksPreview: activeTasks,
      doneTasksPreview: doneTasks,
      counters: DashboardCounters(
          totalActiveTasks: activeTasks.length,
          totalMembers: 2,
          tasksDueToday: activeTasks.length,
          tasksDoneToday: doneTasks.length),
      memberPreview: const [],
      premiumFlags: PremiumFlags.free(),
      adFlags: AdFlags(showBanner: showBanner, bannerUnit: ''),
      rescueFlags: RescueFlags.empty(),
      updatedAt: DateTime(2026, 4, 6),
    );

Widget _wrap(Widget child, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: child,
      ),
    );

List<Override> _baseOverrides({
  AsyncValue<HomeDashboard?> dashboardValue =
      const AsyncValue.data(null),
}) =>
    [
      authProvider.overrideWith(
          () => _FakeAuth(const AuthState.authenticated(_fakeUser))),
      dashboardProvider.overrideWith((ref) => switch (dashboardValue) {
            AsyncData(value: final v) => Stream.value(v),
            _ => const Stream.empty(),
          }),
    ];

void main() {
  group('TodayScreen', () {
    testWidgets('estado de carga: muestra TodaySkeletonLoader', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_fakeUser))),
            dashboardProvider
                .overrideWith((ref) => const Stream.empty()),
          ],
        ),
      );
      // pump sin settle para ver el loading state
      await tester.pump();

      expect(find.byType(TodaySkeletonLoader), findsOneWidget);
    });

    testWidgets('estado vacío: muestra TodayEmptyState cuando data es null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _baseOverrides(
              dashboardValue: const AsyncData(null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TodayEmptyState), findsOneWidget);
    });

    testWidgets('con datos: muestra sección daily', (tester) async {
      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: 'uid1',
            currentAssigneeName: 'Ana',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _baseOverrides(
              dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_title_daily')), findsOneWidget);
      expect(find.text('Barrer'), findsOneWidget);
    });

    testWidgets('sección sin tareas no aparece', (tester) async {
      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: null,
            currentAssigneeName: null,
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _baseOverrides(
              dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      // weekly no debe aparecer
      expect(find.byKey(const Key('section_title_weekly')), findsNothing);
      expect(find.byKey(const Key('section_title_monthly')), findsNothing);
    });

    testWidgets('usuario responsable ve botones de acción', (tester) async {
      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: 'uid1', // mismo que _fakeUser.uid
            currentAssigneeName: 'Ana',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _baseOverrides(
              dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsOneWidget);
      expect(find.byKey(const Key('btn_pass')), findsOneWidget);
    });

    testWidgets('usuario no responsable NO ve botones de acción',
        (tester) async {
      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: 'uid-otro', // diferente al usuario actual
            currentAssigneeName: 'Carlos',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _baseOverrides(
              dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsNothing);
      expect(find.byKey(const Key('btn_pass')), findsNothing);
    });

    testWidgets('golden: pantalla con datos de ejemplo', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dashboard = _buildDashboard(
        activeTasks: [
          TaskPreview(
            taskId: 't1',
            title: 'Barrer cocina',
            visualKind: 'emoji',
            visualValue: '🧹',
            recurrenceType: 'daily',
            currentAssigneeUid: 'uid1',
            currentAssigneeName: 'Ana',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 6, 18, 0),
            isOverdue: false,
            status: 'active',
          ),
          TaskPreview(
            taskId: 't2',
            title: 'Lavar ropa',
            visualKind: 'emoji',
            visualValue: '👕',
            recurrenceType: 'weekly',
            currentAssigneeUid: 'uid2',
            currentAssigneeName: 'Carlos',
            currentAssigneePhoto: null,
            nextDueAt: DateTime(2026, 4, 8, 10, 0),
            isOverdue: false,
            status: 'active',
          ),
        ],
        doneTasks: [
          DoneTaskPreview(
            taskId: 'd1',
            title: 'Fregar platos',
            visualKind: 'emoji',
            visualValue: '🍽️',
            recurrenceType: 'daily',
            completedByUid: 'uid2',
            completedByName: 'Carlos',
            completedByPhoto: null,
            completedAt: DateTime(2026, 4, 6, 9, 30),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          const TodayScreen(),
          overrides: _baseOverrides(
              dashboardValue: AsyncData(dashboard)),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/today_screen.png'),
      );
    });
  });
}
```

- [ ] **Step 2: Crear tests golden de TodayTaskCardTodo**

```dart
// test/ui/features/tasks/today_task_card_todo_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/today_task_card_todo.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

TaskPreview _makeTask({
  String uid = 'uid1',
  bool isOverdue = false,
}) =>
    TaskPreview(
      taskId: 't1',
      title: 'Barrer la cocina',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: uid,
      currentAssigneeName: 'Ana',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 6, 18, 0),
      isOverdue: isOverdue,
      status: 'active',
    );

void main() {
  testWidgets('golden: card Por hacer con botones visibles', (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(uid: 'uid1'),
        currentUid: 'uid1',
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_with_buttons.png'),
    );
  });

  testWidgets('golden: card Por hacer sin botones (otro responsable)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(uid: 'uid2'),
        currentUid: 'uid1',
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_no_buttons.png'),
    );
  });

  testWidgets('golden: card vencida', (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(isOverdue: true),
        currentUid: null,
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_overdue.png'),
    );
  });
}
```

- [ ] **Step 3: Crear tests golden de TodayTaskCardDone**

```dart
// test/ui/features/tasks/today_task_card_done_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/today_task_card_done.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  testWidgets('golden: card Hecha', (tester) async {
    final task = DoneTaskPreview(
      taskId: 'd1',
      title: 'Fregar platos',
      visualKind: 'emoji',
      visualValue: '🍽️',
      recurrenceType: 'daily',
      completedByUid: 'uid1',
      completedByName: 'Carlos',
      completedByPhoto: null,
      completedAt: DateTime(2026, 4, 6, 9, 30),
    );

    await tester.pumpWidget(_wrap(TodayTaskCardDone(task: task)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_done.png'),
    );
  });

  testWidgets('muestra nombre del completado y la hora', (tester) async {
    final task = DoneTaskPreview(
      taskId: 'd2',
      title: 'Sacar basura',
      visualKind: 'emoji',
      visualValue: '🗑️',
      recurrenceType: 'weekly',
      completedByUid: 'uid2',
      completedByName: 'María',
      completedByPhoto: null,
      completedAt: DateTime(2026, 4, 6, 14, 45),
    );

    await tester.pumpWidget(_wrap(TodayTaskCardDone(task: task)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('done_by_label')), findsOneWidget);
    expect(find.textContaining('María'), findsOneWidget);
    expect(find.textContaining('14:45'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Ejecutar todos los tests de UI**

```bash
flutter test test/ui/features/tasks/ --update-goldens
```

Expected: PASS — tests pasan y se generan los archivos golden en `test/ui/features/tasks/goldens/`.

- [ ] **Step 5: Ejecutar de nuevo sin --update-goldens para verificar que los goldens son estables**

```bash
flutter test test/ui/features/tasks/
```

Expected: PASS — todos los goldens coinciden.

- [ ] **Step 6: Commit**

```bash
git add test/ui/features/tasks/ && git commit -m "test(tasks): add UI tests and golden files for Today screen"
```

---

## Task 10: Ejecutar suite completa y verificar

- [ ] **Step 1: Ejecutar todos los tests unitarios de tasks**

```bash
flutter test test/unit/features/tasks/
```

Expected: PASS — todos los tests pasan (recurrence_order, dashboard_grouping, today_task_card).

- [ ] **Step 2: Ejecutar tests de integración de tasks**

```bash
flutter test test/integration/features/tasks/
```

Expected: PASS — 5 tests pasan.

- [ ] **Step 3: Ejecutar tests de UI de tasks**

```bash
flutter test test/ui/features/tasks/
```

Expected: PASS — todos los golden y widget tests pasan.

- [ ] **Step 4: Ejecutar análisis estático**

```bash
flutter analyze lib/
```

Expected: No issues found.

- [ ] **Step 5: Ejecutar toda la suite de tests**

```bash
flutter test test/
```

Expected: PASS — todos los tests del proyecto pasan (sin regresiones).

- [ ] **Step 6: Commit final**

```bash
git add .
git commit -m "feat(spec-06): implement Today screen with materialized dashboard"
```

---

## Pruebas manuales requeridas al terminar

1. **Pantalla Hoy con tareas:** Crear tareas de tipos diaria, semanal y mensual → abrir la pantalla Hoy → verificar secciones "Día", "Semana", "Mes" en ese orden.

2. **Un solo listener activo:** Abrir la app en pantalla Hoy → verificar en Firestore Emulator que hay exactamente **una** lectura activa del documento `dashboard` → navegar a otra pantalla y volver → no debe haber listeners acumulados.

3. **Botones de acción:** Estar asignado a una tarea → ver "Hecho" y "Pasar turno" → cambiar responsable → botones desaparecen.

4. **Contador de cabecera:** La cabecera muestra "X tareas para hoy" y "Y completadas hoy" con valores reales.

5. **Banner Free/Premium:** Con hogar Free → banner aparece al final. Con hogar Premium → banner no aparece.

6. **Skeleton al cargar:** Con conexión lenta (throttle), aparece el skeleton animado en lugar de pantalla en blanco.

7. **Actualización en tiempo real:** Desde otra cuenta, crear tarea en el mismo hogar → la pantalla Hoy se actualiza sin recargar.
