import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/members/domain/vacation.dart';

void main() {
  group('Vacation.isAbsent', () {
    test('isActive false → isAbsent false', () {
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: false,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, false);
    });

    test('isActive true sin rango de fechas → isAbsent true', () {
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, true);
    });

    test('isActive true, fecha actual en rango → isAbsent true', () {
      final now = DateTime.now();
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: true,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, true);
    });

    test('isActive true, endDate ya pasó → isAbsent false', () {
      final now = DateTime.now();
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: true,
        endDate: now.subtract(const Duration(days: 1)),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, false);
    });

    test('isActive true, startDate en el futuro → isAbsent false', () {
      final now = DateTime.now();
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: true,
        startDate: now.add(const Duration(days: 2)),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, false);
    });
  });
}
