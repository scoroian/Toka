import 'dart:ui' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/domain/task_actionability.dart';

TaskPreview _t({
  required String recurrence,
  required DateTime due,
}) =>
    TaskPreview(
      taskId: 't1',
      title: 'Test task',
      visualKind: 'icon',
      visualValue: 'task',
      recurrenceType: recurrence,
      currentAssigneeUid: null,
      currentAssigneeName: null,
      currentAssigneePhoto: null,
      nextDueAt: due,
      isOverdue: due.isBefore(DateTime.now()),
      status: 'active',
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
    await initializeDateFormatting('ro');
    tz_data.initializeTimeZones();
  });

  const es = Locale('es');

  group('TaskActionability.isActionable', () {
    test('overdue is always actionable', () {
      final t = _t(
        recurrence: 'weekly',
        due: DateTime(2026, 1, 1, 10, 0),
      );
      expect(
        TaskActionability.isActionable(t, now: DateTime(2026, 4, 26, 12, 0)),
        isTrue,
      );
    });

    test('hourly: due in current hour is actionable', () {
      final now = DateTime(2026, 4, 26, 14, 30);
      final t = _t(recurrence: 'hourly', due: DateTime(2026, 4, 26, 14, 45));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('hourly: due in next hour is NOT actionable', () {
      final now = DateTime(2026, 4, 26, 14, 30);
      final t = _t(recurrence: 'hourly', due: DateTime(2026, 4, 26, 15, 5));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('daily: due today is actionable', () {
      final now = DateTime(2026, 4, 26, 8, 0);
      final t = _t(recurrence: 'daily', due: DateTime(2026, 4, 26, 22, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('daily: due tomorrow is NOT actionable', () {
      final now = DateTime(2026, 4, 26, 8, 0);
      final t = _t(recurrence: 'daily', due: DateTime(2026, 4, 27, 1, 0));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('weekly: due this ISO week is actionable', () {
      final now = DateTime(2026, 4, 22, 10, 0); // Wednesday
      final t = _t(recurrence: 'weekly', due: DateTime(2026, 4, 26, 23, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('weekly: due next week is NOT actionable', () {
      final now = DateTime(2026, 4, 22, 10, 0);
      final t = _t(recurrence: 'weekly', due: DateTime(2026, 4, 27, 1, 0));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('monthly: due this month is actionable', () {
      final now = DateTime(2026, 4, 5, 10, 0);
      final t = _t(recurrence: 'monthly', due: DateTime(2026, 4, 28, 12, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('monthly: due next month is NOT actionable', () {
      final now = DateTime(2026, 4, 5, 10, 0);
      final t = _t(recurrence: 'monthly', due: DateTime(2026, 5, 1, 0, 0));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('yearly: due this year is actionable', () {
      final now = DateTime(2026, 4, 5, 10, 0);
      final t = _t(recurrence: 'yearly', due: DateTime(2026, 12, 31, 23, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
    });

    test('yearly: due next year is NOT actionable', () {
      final now = DateTime(2026, 4, 5, 10, 0);
      final t = _t(recurrence: 'yearly', due: DateTime(2027, 1, 1, 0, 0));
      expect(TaskActionability.isActionable(t, now: now), isFalse);
    });

    test('default (oneTime / unknown): behaves like daily', () {
      final now = DateTime(2026, 4, 26, 8, 0);
      final t = _t(recurrence: 'oneTime', due: DateTime(2026, 4, 26, 22, 0));
      expect(TaskActionability.isActionable(t, now: now), isTrue);
      final t2 = _t(recurrence: 'unknown', due: DateTime(2026, 4, 27, 1, 0));
      expect(TaskActionability.isActionable(t2, now: now), isFalse);
    });
  });

  // Hallazgo #2-QA (extensión): la decisión "accionable hoy" debe evaluarse en
  // la zona del HOGAR, igual que el label de hora, para que no haya desajuste
  // sección/label cuando el dispositivo está en otra zona.
  group('TaskActionability.isActionable con zona del hogar', () {
    // due = 25 jun 09:00 Madrid (07:00 UTC); now = 25 jun 00:30 Madrid (22:30 UTC del 24).
    final due = DateTime.utc(2026, 6, 25, 7);
    final now = DateTime.utc(2026, 6, 24, 22, 30);

    test('daily due hoy en la zona del hogar ES accionable aunque el device '
        'esté en otra zona', () {
      final t = _t(recurrence: 'daily', due: due);
      expect(
        TaskActionability.isActionable(t, now: now, timezone: 'Europe/Madrid'),
        isTrue,
      );
    });

    test('la MISMA tarea evaluada en la zona del dispositivo (GMT) NO sería '
        'accionable (era el bug)', () {
      final t = _t(recurrence: 'daily', due: due);
      expect(
        TaskActionability.isActionable(t, now: now, timezone: 'Etc/GMT'),
        isFalse,
      );
    });

    test('timezone null conserva el comportamiento previo (zona dispositivo)',
        () {
      final localNow = DateTime(2026, 4, 26, 8);
      final t = _t(recurrence: 'daily', due: DateTime(2026, 4, 26, 22));
      expect(TaskActionability.isActionable(t, now: localNow), isTrue);
      expect(
        TaskActionability.isActionable(t, now: localNow, timezone: null),
        isTrue,
      );
    });

    test('timezone desconocido no lanza (cae a zona del dispositivo)', () {
      final t = _t(recurrence: 'daily', due: DateTime(2026, 4, 26, 22));
      expect(
        () => TaskActionability.isActionable(t,
            now: DateTime(2026, 4, 26, 8), timezone: 'No/Existe'),
        returnsNormally,
      );
    });
  });

  group('TaskActionability.formatDueForMessage', () {
    test('hourly: returns short time only', () {
      final t = _t(recurrence: 'hourly', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      expect(out, contains('14'));
    });

    test('daily: returns weekday + date + time', () {
      final t = _t(recurrence: 'daily', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      expect(out, contains('·'));
    });

    test('weekly: returns weekday + date (no time)', () {
      final t = _t(recurrence: 'weekly', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      expect(out, isNot(contains(':')));
    });

    test('monthly: returns long day-month format', () {
      final t = _t(recurrence: 'monthly', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      expect(out, isNotEmpty);
    });

    test('yearly: returns month-year format', () {
      final t = _t(recurrence: 'yearly', due: DateTime(2026, 4, 26, 14, 30));
      final out = TaskActionability.formatDueForMessage(t, es);
      expect(out, isNotEmpty);
    });
  });
}
