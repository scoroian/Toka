// test/unit/features/tasks/recurrence_notifier_test.dart
//
// BUG-07 — tests unitarios del mapeo entre cada variante de RecurrenceRule
// y el estado interno del formulario vía RecurrenceNotifier.hydrateFrom.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/recurrence_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('RecurrenceNotifier.hydrateFrom — 8 variantes', () {
    test('estado inicial tiene hydrationVersion=0 y tipo daily', () {
      final container = makeContainer();
      final state = container.read(recurrenceNotifierProvider);
      expect(state.hydrationVersion, 0);
      expect(state.selectedType, 'daily');
    });

    test('hydrateFrom(null) mantiene defaults e incrementa la versión', () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(null);
      final state = container.read(recurrenceNotifierProvider);
      expect(state.hydrationVersion, 1);
      expect(state.selectedType, 'daily');
    });

    test('oneTime → selectedType=oneTime + date/time/timezone', () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(
            const RecurrenceRule.oneTime(
              date: '2027-04-25',
              time: '10:30',
              timezone: 'Europe/Madrid',
            ),
          );
      final state = container.read(recurrenceNotifierProvider);
      expect(state.selectedType, 'oneTime');
      expect(state.oneTimeDate, '2027-04-25');
      expect(state.oneTimeTime, '10:30');
      expect(state.timezone, 'Europe/Madrid');
      expect(state.hydrationVersion, 1);
    });

    test('hourly → selectedType=hourly + every/startTime/endTime', () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(
            const RecurrenceRule.hourly(
              every: 3,
              startTime: '08:00',
              endTime: '20:00',
              timezone: 'Europe/Bucharest',
            ),
          );
      final state = container.read(recurrenceNotifierProvider);
      expect(state.selectedType, 'hourly');
      expect(state.every, 3);
      expect(state.startTime, '08:00');
      expect(state.endTime, '20:00');
      expect(state.timezone, 'Europe/Bucharest');
    });

    test('daily → selectedType=daily + every/time/timezone', () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(
            const RecurrenceRule.daily(
              every: 2,
              time: '07:15',
              timezone: 'UTC',
            ),
          );
      final state = container.read(recurrenceNotifierProvider);
      expect(state.selectedType, 'daily');
      expect(state.every, 2);
      expect(state.time, '07:15');
      expect(state.timezone, 'UTC');
    });

    test('weekly → selectedType=weekly + weekdays/time', () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(
            const RecurrenceRule.weekly(
              weekdays: ['MON', 'WED', 'FRI'],
              time: '09:00',
              timezone: 'Europe/Madrid',
            ),
          );
      final state = container.read(recurrenceNotifierProvider);
      expect(state.selectedType, 'weekly');
      expect(state.weekdays, ['MON', 'WED', 'FRI']);
      expect(state.time, '09:00');
    });

    test('monthlyFixed → selectedType=monthlyFixed + dayOfMonth/time', () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(
            const RecurrenceRule.monthlyFixed(
              day: 15,
              time: '12:00',
              timezone: 'Europe/Madrid',
            ),
          );
      final state = container.read(recurrenceNotifierProvider);
      expect(state.selectedType, 'monthlyFixed');
      expect(state.dayOfMonth, 15);
      expect(state.time, '12:00');
    });

    test('monthlyNth → selectedType=monthlyNth + weekOfMonth/weekday/time',
        () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(
            const RecurrenceRule.monthlyNth(
              weekOfMonth: 2,
              weekday: 'THU',
              time: '18:30',
              timezone: 'Europe/Madrid',
            ),
          );
      final state = container.read(recurrenceNotifierProvider);
      expect(state.selectedType, 'monthlyNth');
      expect(state.weekOfMonth, 2);
      expect(state.weekday, 'THU');
      expect(state.time, '18:30');
    });

    test('yearlyFixed → selectedType=yearlyFixed + month/day/time', () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(
            const RecurrenceRule.yearlyFixed(
              month: 4,
              day: 25,
              time: '10:00',
              timezone: 'Europe/Madrid',
            ),
          );
      final state = container.read(recurrenceNotifierProvider);
      expect(state.selectedType, 'yearlyFixed');
      expect(state.month, 4);
      expect(state.dayOfMonth, 25);
      expect(state.time, '10:00');
    });

    test('yearlyNth → selectedType=yearlyNth + month/weekOfMonth/weekday/time',
        () {
      final container = makeContainer();
      container.read(recurrenceNotifierProvider.notifier).hydrateFrom(
            const RecurrenceRule.yearlyNth(
              month: 12,
              weekOfMonth: 1,
              weekday: 'SUN',
              time: '08:00',
              timezone: 'Europe/Madrid',
            ),
          );
      final state = container.read(recurrenceNotifierProvider);
      expect(state.selectedType, 'yearlyNth');
      expect(state.month, 12);
      expect(state.weekOfMonth, 1);
      expect(state.weekday, 'SUN');
      expect(state.time, '08:00');
    });

    test('hidrataciones consecutivas incrementan hydrationVersion', () {
      final container = makeContainer();
      final notifier = container.read(recurrenceNotifierProvider.notifier);
      notifier.hydrateFrom(const RecurrenceRule.daily(
        every: 1,
        time: '09:00',
        timezone: 'UTC',
      ));
      notifier.hydrateFrom(const RecurrenceRule.weekly(
        weekdays: ['MON'],
        time: '09:00',
        timezone: 'UTC',
      ));
      expect(
        container.read(recurrenceNotifierProvider).hydrationVersion,
        2,
      );
    });
  });
}
