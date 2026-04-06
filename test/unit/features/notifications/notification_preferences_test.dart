// test/unit/features/notifications/notification_preferences_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/notifications/domain/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('serializa a map correctamente', () {
      const prefs = NotificationPreferences(
        homeId: 'h1',
        uid: 'u1',
        notifyOnDue: true,
        notifyBefore: true,
        minutesBefore: 30,
        dailySummary: false,
      );
      final map = prefs.toMap();
      expect(map['notifyOnDue'], true);
      expect(map['minutesBefore'], 30);
      expect(map['dailySummary'], false);
      expect(map['notifyBefore'], true);
    });

    test('deserializa desde map con valores por defecto', () {
      final prefs = NotificationPreferences.fromMap('h1', 'u1', {});
      expect(prefs.notifyOnDue, true);
      expect(prefs.notifyBefore, false);
      expect(prefs.minutesBefore, 30);
      expect(prefs.dailySummary, false);
    });

    test('token FCM nulo en fromMap si no está en el mapa', () {
      final prefs = NotificationPreferences.fromMap('h1', 'u1', {});
      expect(prefs.fcmToken, isNull);
    });

    test('silencedTypes deserializa lista correctamente', () {
      final prefs = NotificationPreferences.fromMap('h1', 'u1', {
        'silencedTypes': ['task_due', 'task_reminder'],
      });
      expect(prefs.silencedTypes, equals(['task_due', 'task_reminder']));
    });
  });
}
