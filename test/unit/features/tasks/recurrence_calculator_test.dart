import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:toka/core/utils/recurrence_calculator.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';

void main() {
  setUpAll(() => tz_data.initializeTimeZones());

  // Crea un DateTime que representa la hora indicada en Europe/Madrid.
  DateTime madridTime(int year, int month, int day, int hour, int minute) {
    final location = tz.getLocation('Europe/Madrid');
    return tz.TZDateTime(location, year, month, day, hour, minute).toUtc();
  }

  // Convierte un DateTime al equivalente en Europe/Madrid.
  tz.TZDateTime toMadrid(DateTime dt) {
    final location = tz.getLocation('Europe/Madrid');
    return tz.TZDateTime.from(dt, location);
  }

  group('Daily', () {
    const rule = RecurrenceRule.daily(
        every: 1, time: '20:00', timezone: 'Europe/Madrid');

    test('mismo día antes de las 20h → hoy a las 20h', () {
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).hour, 20);
      expect(toMadrid(next).day, 7);
    });

    test('mismo día después de las 20h → mañana a las 20h', () {
      final from = madridTime(2026, 4, 7, 21, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).day, 8);
      expect(toMadrid(next).hour, 20);
    });

    test('cada 3 días', () {
      const rule3 = RecurrenceRule.daily(
          every: 3, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0); // pasó las 9h
      final next = RecurrenceCalculator.nextDue(rule3, from);
      expect(toMadrid(next).day, 10);
    });
  });

  group('Weekly', () {
    test('próximo lunes desde martes', () {
      const rule = RecurrenceRule.weekly(
          weekdays: ['MON'], time: '09:00', timezone: 'Europe/Madrid');
      // 2026-04-07 es martes
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(next.toLocal().weekday, DateTime.monday);
      expect(next.isAfter(from), isTrue);
    });

    test('mismo día pero antes de la hora → hoy', () {
      // 2026-04-06 es lunes
      const rule = RecurrenceRule.weekly(
          weekdays: ['MON'], time: '20:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 6, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).weekday, DateTime.monday);
      expect(toMadrid(next).day, 6);
    });
  });

  group('Monthly Fixed', () {
    test('día 15 del mes actual si no ha pasado', () {
      const rule = RecurrenceRule.monthlyFixed(
          day: 15, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).day, 15);
      expect(toMadrid(next).month, 4);
    });

    test('ya pasó el 15 → día 15 del mes siguiente', () {
      const rule = RecurrenceRule.monthlyFixed(
          day: 15, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 16, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).month, 5);
      expect(toMadrid(next).day, 15);
    });

    test('día 31 en mes de 30 días → clamp a día 30', () {
      const rule = RecurrenceRule.monthlyFixed(
          day: 31, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 1, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).month, 4);
      expect(toMadrid(next).day, 30);
    });
  });

  group('Monthly Nth', () {
    test('2.º martes de abril', () {
      const rule = RecurrenceRule.monthlyNth(
          weekOfMonth: 2,
          weekday: 'TUE',
          time: '09:00',
          timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 1, 0, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).weekday, DateTime.tuesday);
      expect(toMadrid(next).month, 4);
    });
  });

  group('Yearly Fixed', () {
    test('15 de marzo cada año', () {
      const rule = RecurrenceRule.yearlyFixed(
          month: 3, day: 15, time: '09:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0); // ya pasó marzo
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).month, 3);
      expect(toMadrid(next).year, 2027);
    });
  });

  group('Yearly Nth', () {
    test('primer lunes de marzo', () {
      const rule = RecurrenceRule.yearlyNth(
          month: 3,
          weekOfMonth: 1,
          weekday: 'MON',
          time: '09:00',
          timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).month, 3);
      expect(toMadrid(next).year, 2027);
      expect(toMadrid(next).weekday, DateTime.monday);
    });
  });

  group('Hourly', () {
    test('añade N horas', () {
      const rule = RecurrenceRule.hourly(
          every: 4, startTime: '08:00', timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 10, 0);
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).hour, 14);
    });

    test('con endTime: si supera endTime → siguiente día a startTime', () {
      const rule = RecurrenceRule.hourly(
          every: 4,
          startTime: '08:00',
          endTime: '20:00',
          timezone: 'Europe/Madrid');
      final from = madridTime(2026, 4, 7, 18, 0); // 18h + 4h = 22h > 20h
      final next = RecurrenceCalculator.nextDue(rule, from);
      expect(toMadrid(next).hour, 8);
      expect(toMadrid(next).day, 8);
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
