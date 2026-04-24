// test/unit/features/subscription/days_left_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/application/days_left.dart';

void main() {
  final now = DateTime.utc(2026, 4, 21, 12);

  group('daysLeftFrom', () {
    test('devuelve 0 si endsAt ya ha pasado', () {
      final past = now.subtract(const Duration(hours: 1));
      expect(daysLeftFrom(past, now: now), 0);
    });

    test('devuelve 0 si endsAt coincide con now', () {
      expect(daysLeftFrom(now, now: now), 0);
    });

    test('23h59 restantes → 1 (ceil, no 0)', () {
      final endsAt = now.add(const Duration(hours: 23, minutes: 59));
      expect(daysLeftFrom(endsAt, now: now), 1);
    });

    test('24h exactas → 1', () {
      final endsAt = now.add(const Duration(hours: 24));
      expect(daysLeftFrom(endsAt, now: now), 1);
    });

    test('24h + 1 min → 2 (ceil)', () {
      final endsAt = now.add(const Duration(hours: 24, minutes: 1));
      expect(daysLeftFrom(endsAt, now: now), 2);
    });

    test('2.9 días restantes → 3 (evita BUG-16)', () {
      final endsAt = now.add(
        const Duration(days: 2, hours: 21, minutes: 30),
      );
      expect(daysLeftFrom(endsAt, now: now), 3);
    });

    test('1 minuto restante → 1, no 0', () {
      final endsAt = now.add(const Duration(minutes: 1));
      expect(daysLeftFrom(endsAt, now: now), 1);
    });
  });

  group('hoursLeftFrom', () {
    test('devuelve 0 si endsAt ya ha pasado', () {
      final past = now.subtract(const Duration(hours: 1));
      expect(hoursLeftFrom(past, now: now), 0);
    });

    test('59 minutos restantes → 1 (ceil)', () {
      final endsAt = now.add(const Duration(minutes: 59));
      expect(hoursLeftFrom(endsAt, now: now), 1);
    });

    test('7h exactas restantes → 7', () {
      final endsAt = now.add(const Duration(hours: 7));
      expect(hoursLeftFrom(endsAt, now: now), 7);
    });

    test('7h + 1 min → 8 (ceil)', () {
      final endsAt = now.add(const Duration(hours: 7, minutes: 1));
      expect(hoursLeftFrom(endsAt, now: now), 8);
    });
  });
}
