import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';

void main() {
  group('RecurrenceRule.oneTime', () {
    test('construye OneTimeRule con date/time/timezone', () {
      const rule = RecurrenceRule.oneTime(
        date: '2026-04-25',
        time: '10:30',
        timezone: 'Europe/Madrid',
      );
      expect(rule, isA<OneTimeRule>());
      final ot = rule as OneTimeRule;
      expect(ot.date, '2026-04-25');
      expect(ot.time, '10:30');
      expect(ot.timezone, 'Europe/Madrid');
    });

    test('es distinguible de DailyRule', () {
      const oneTime = RecurrenceRule.oneTime(
        date: '2026-04-25',
        time: '10:30',
        timezone: 'UTC',
      );
      const daily = RecurrenceRule.daily(
        every: 1,
        time: '10:30',
        timezone: 'UTC',
      );
      expect(oneTime, isA<OneTimeRule>());
      expect(oneTime, isNot(isA<DailyRule>()));
      expect(daily, isA<DailyRule>());
      expect(daily, isNot(isA<OneTimeRule>()));
    });
  });

  group('isAutomaticRecurring', () {
    test('false para oneTime', () {
      const rule = RecurrenceRule.oneTime(
        date: '2026-04-25',
        time: '10:30',
        timezone: 'UTC',
      );
      expect(isAutomaticRecurring(rule), isFalse);
    });

    test('true para daily/weekly/monthly/yearly/hourly', () {
      expect(
        isAutomaticRecurring(const RecurrenceRule.hourly(
            every: 2, startTime: '08:00', timezone: 'UTC')),
        isTrue,
      );
      expect(
        isAutomaticRecurring(const RecurrenceRule.daily(
            every: 1, time: '09:00', timezone: 'UTC')),
        isTrue,
      );
      expect(
        isAutomaticRecurring(const RecurrenceRule.weekly(
            weekdays: ['MON'], time: '09:00', timezone: 'UTC')),
        isTrue,
      );
      expect(
        isAutomaticRecurring(const RecurrenceRule.monthlyFixed(
            day: 1, time: '09:00', timezone: 'UTC')),
        isTrue,
      );
      expect(
        isAutomaticRecurring(const RecurrenceRule.monthlyNth(
            weekOfMonth: 1,
            weekday: 'MON',
            time: '09:00',
            timezone: 'UTC')),
        isTrue,
      );
      expect(
        isAutomaticRecurring(const RecurrenceRule.yearlyFixed(
            month: 3, day: 14, time: '09:00', timezone: 'UTC')),
        isTrue,
      );
      expect(
        isAutomaticRecurring(const RecurrenceRule.yearlyNth(
            month: 3,
            weekOfMonth: 2,
            weekday: 'MON',
            time: '09:00',
            timezone: 'UTC')),
        isTrue,
      );
    });
  });
}
