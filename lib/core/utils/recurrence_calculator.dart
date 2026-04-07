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
