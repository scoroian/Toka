import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:toka/core/utils/toka_dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
    await initializeDateFormatting('ro');
  });

  const esLocale = Locale('es');
  const enLocale = Locale('en');
  const roLocale = Locale('ro');

  // sábado 25 abril 2026 09:30
  final date = DateTime(2026, 4, 25, 9, 30);

  group('TokaDates.timeShort', () {
    test('es usa 24h', () {
      expect(TokaDates.timeShort(date, esLocale), '09:30');
    });
    test('en usa 24h (consistencia interna)', () {
      expect(TokaDates.timeShort(date, enLocale), '09:30');
    });
    test('ro usa 24h', () {
      expect(TokaDates.timeShort(date, roLocale), '09:30');
    });
  });

  group('TokaDates.dateMediumWithWeekday', () {
    test('es contiene abr y 25', () {
      final r = TokaDates.dateMediumWithWeekday(date, esLocale);
      expect(r, contains('25'));
      expect(r.toLowerCase(), contains('abr'));
    });
    test('en contiene Apr y 25', () {
      final r = TokaDates.dateMediumWithWeekday(date, enLocale);
      expect(r, contains('25'));
      expect(r, contains('Apr'));
    });
    test('ro contiene apr y 25', () {
      final r = TokaDates.dateMediumWithWeekday(date, roLocale);
      expect(r, contains('25'));
      expect(r.toLowerCase(), contains('apr'));
    });
  });

  group('TokaDates.dateLongDayMonth', () {
    test('es: día + mes largo en español', () {
      final r = TokaDates.dateLongDayMonth(date, esLocale);
      expect(r, contains('25'));
      expect(r.toLowerCase(), contains('abril'));
    });
    test('en: mes largo en inglés', () {
      final r = TokaDates.dateLongDayMonth(date, enLocale);
      expect(r, contains('April'));
    });
    test('ro: mes largo en rumano', () {
      final r = TokaDates.dateLongDayMonth(date, roLocale);
      expect(r.toLowerCase(), contains('aprilie'));
    });
  });

  group('TokaDates.dateLongFull', () {
    test('es incluye año 2026 y abril', () {
      final r = TokaDates.dateLongFull(date, esLocale);
      expect(r, contains('2026'));
      expect(r.toLowerCase(), contains('abril'));
    });
    test('en incluye año 2026 y April', () {
      final r = TokaDates.dateLongFull(date, enLocale);
      expect(r, contains('2026'));
      expect(r, contains('April'));
    });
    test('ro incluye año 2026 y aprilie', () {
      final r = TokaDates.dateLongFull(date, roLocale);
      expect(r, contains('2026'));
      expect(r.toLowerCase(), contains('aprilie'));
    });
  });

  group('TokaDates.dateShort', () {
    test('es: contiene día, mes y año', () {
      final r = TokaDates.dateShort(date, esLocale);
      expect(r, contains('25'));
      expect(r, contains('2026'));
    });
    test('en: contiene día, mes y año', () {
      final r = TokaDates.dateShort(date, enLocale);
      expect(r, contains('25'));
      expect(r, contains('2026'));
    });
    test('ro: contiene día, mes y año', () {
      final r = TokaDates.dateShort(date, roLocale);
      expect(r, contains('25'));
      expect(r, contains('2026'));
    });
  });

  group('TokaDates.dateTimeShort', () {
    test('es compone fecha + " — " + hora', () {
      final r = TokaDates.dateTimeShort(date, esLocale);
      expect(r, contains('2026'));
      expect(r, contains('09:30'));
      expect(r, contains('—'));
    });
    test('en compone fecha + " — " + hora', () {
      final r = TokaDates.dateTimeShort(date, enLocale);
      expect(r, contains('2026'));
      expect(r, contains('09:30'));
      expect(r, contains('—'));
    });
    test('ro compone fecha + " — " + hora', () {
      final r = TokaDates.dateTimeShort(date, roLocale);
      expect(r, contains('2026'));
      expect(r, contains('09:30'));
      expect(r, contains('—'));
    });
  });

  group('meses límite en ro (ianuarie / decembrie)', () {
    test('enero -> ianuarie en ro', () {
      final d = DateTime(2026, 1, 10);
      expect(
        TokaDates.dateLongDayMonth(d, roLocale).toLowerCase(),
        contains('ianuarie'),
      );
    });
    test('diciembre -> decembrie en ro', () {
      final d = DateTime(2026, 12, 20);
      expect(
        TokaDates.dateLongDayMonth(d, roLocale).toLowerCase(),
        contains('decembrie'),
      );
    });
  });

  // Helpers auxiliares exigidos por los widgets migrados (card V2, task_card…).
  group('helpers auxiliares', () {
    test('monthYearLong en los 3 locales', () {
      expect(
        TokaDates.monthYearLong(date, esLocale).toLowerCase(),
        allOf(contains('abril'), contains('2026')),
      );
      expect(
        TokaDates.monthYearLong(date, enLocale),
        allOf(contains('April'), contains('2026')),
      );
      expect(
        TokaDates.monthYearLong(date, roLocale).toLowerCase(),
        allOf(contains('aprilie'), contains('2026')),
      );
    });

    test('weekdayShort en los 3 locales (sábado 25-abr-2026)', () {
      expect(
        TokaDates.weekdayShort(date, esLocale).toLowerCase(),
        contains('sáb'),
      );
      expect(TokaDates.weekdayShort(date, enLocale), contains('Sat'));
      expect(
        TokaDates.weekdayShort(date, roLocale).toLowerCase(),
        contains('sâm'),
      );
    });

    test('dayMonthTimeShort incluye día, mes y hora 24h', () {
      final r = TokaDates.dayMonthTimeShort(date, esLocale);
      expect(r, contains('25'));
      expect(r.toLowerCase(), contains('abr'));
      expect(r, contains('09:30'));
    });
  });
}
