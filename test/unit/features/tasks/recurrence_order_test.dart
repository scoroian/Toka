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
