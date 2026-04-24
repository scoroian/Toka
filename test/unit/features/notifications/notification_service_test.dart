// test/unit/features/notifications/notification_service_test.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/notifications/application/notification_service.dart';
import 'package:toka/features/notifications/application/notification_tap_handler.dart';

void main() {
  group('kTokaChannels', () {
    test('define un canal por cada tipo (6 en total)', () {
      expect(kTokaChannels.length, TokaNotificationType.values.length);
      for (final type in TokaNotificationType.values) {
        expect(kTokaChannels.containsKey(type), isTrue,
            reason: 'Falta el canal para $type');
      }
    });

    test('ids son únicos y con prefijo toka_', () {
      final ids = kTokaChannels.values.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'Hay ids duplicados');
      for (final id in ids) {
        expect(id.startsWith('toka_'), isTrue, reason: 'Id sin prefijo: $id');
      }
    });

    test('deadline y assignment son High importance con sonido', () {
      expect(kTokaChannels[TokaNotificationType.deadline]!.importance,
          Importance.high);
      expect(kTokaChannels[TokaNotificationType.deadline]!.playSound, isTrue);
      expect(kTokaChannels[TokaNotificationType.assignment]!.importance,
          Importance.high);
      expect(
          kTokaChannels[TokaNotificationType.assignment]!.playSound, isTrue);
    });

    test('reminder es default y sin sonido (nudge silencioso)', () {
      final ch = kTokaChannels[TokaNotificationType.reminder]!;
      expect(ch.importance, Importance.defaultImportance);
      expect(ch.playSound, isFalse);
      expect(ch.enableVibration, isTrue);
    });

    test('dailySummary es Low y totalmente silencioso', () {
      final ch = kTokaChannels[TokaNotificationType.dailySummary]!;
      expect(ch.importance, Importance.low);
      expect(ch.playSound, isFalse);
      expect(ch.enableVibration, isFalse);
    });

    test('feedback suena pero no vibra', () {
      final ch = kTokaChannels[TokaNotificationType.feedback]!;
      expect(ch.importance, Importance.defaultImportance);
      expect(ch.playSound, isTrue);
      expect(ch.enableVibration, isFalse);
    });

    test('rotation es default sin sonido pero con vibración', () {
      final ch = kTokaChannels[TokaNotificationType.rotation]!;
      expect(ch.importance, Importance.defaultImportance);
      expect(ch.playSound, isFalse);
      expect(ch.enableVibration, isTrue);
    });
  });

  group('TokaNotificationPayload round-trip', () {
    test('encode → tryParse recupera todos los campos', () {
      const original = TokaNotificationPayload(
        type: TokaNotificationType.assignment,
        route: '/tasks/abc',
        homeId: 'home_1',
        homeName: 'Casa Lavapiés',
        entityId: 'abc',
      );
      final parsed = TokaNotificationPayload.tryParse(original.encode());
      expect(parsed, isNotNull);
      expect(parsed!.type, original.type);
      expect(parsed.route, original.route);
      expect(parsed.homeId, original.homeId);
      expect(parsed.homeName, original.homeName);
      expect(parsed.entityId, original.entityId);
    });

    test('tryParse devuelve null con payload inválido', () {
      expect(TokaNotificationPayload.tryParse(null), isNull);
      expect(TokaNotificationPayload.tryParse(''), isNull);
      expect(TokaNotificationPayload.tryParse('not-json'), isNull);
    });

    test('tryParse con type desconocido cae a deadline', () {
      final parsed = TokaNotificationPayload.tryParse(
          '{"type":"bogus","route":"/home","homeId":"h","homeName":"H"}');
      expect(parsed, isNotNull);
      expect(parsed!.type, TokaNotificationType.deadline);
    });

    test('entityId opcional no se serializa si es null', () {
      const payload = TokaNotificationPayload(
        type: TokaNotificationType.dailySummary,
        route: '/home',
        homeId: 'h',
        homeName: 'H',
      );
      expect(payload.encode().contains('entityId'), isFalse);
    });
  });

  group('NotificationTapHandler.resolveRoute', () {
    TokaNotificationPayload payloadOf(TokaNotificationType type,
            {String? entityId}) =>
        TokaNotificationPayload(
          type: type,
          route: '/placeholder',
          homeId: 'h',
          homeName: 'H',
          entityId: entityId,
        );

    test('deadline/assignment/reminder → /tasks/{entityId}', () {
      for (final t in const [
        TokaNotificationType.deadline,
        TokaNotificationType.assignment,
        TokaNotificationType.reminder,
      ]) {
        expect(
          NotificationTapHandler.resolveRoute(payloadOf(t, entityId: 'abc')),
          '/tasks/abc',
          reason: 'Para $t',
        );
      }
    });

    test('deadline sin entityId cae a /tasks', () {
      expect(
        NotificationTapHandler.resolveRoute(
            payloadOf(TokaNotificationType.deadline)),
        '/tasks',
      );
    });

    test('dailySummary → /home', () {
      expect(
        NotificationTapHandler.resolveRoute(
            payloadOf(TokaNotificationType.dailySummary)),
        '/home',
      );
    });

    test('feedback con id → /history?feedbackId=...', () {
      expect(
        NotificationTapHandler.resolveRoute(
          payloadOf(TokaNotificationType.feedback, entityId: 'fb123'),
        ),
        '/history?feedbackId=fb123',
      );
    });

    test('feedback sin id → /history', () {
      expect(
        NotificationTapHandler.resolveRoute(
            payloadOf(TokaNotificationType.feedback)),
        '/history',
      );
    });

    test('rotation → /tasks', () {
      expect(
        NotificationTapHandler.resolveRoute(
            payloadOf(TokaNotificationType.rotation)),
        '/tasks',
      );
    });
  });
}
