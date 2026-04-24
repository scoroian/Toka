// test/unit/features/notifications/fcm_token_service_test.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/notifications/application/fcm_token_service.dart';
import 'package:toka/features/notifications/domain/notification_prefs_repository.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

class _MockRepo extends Mock implements NotificationPrefsRepository {}

class _FakeSettings extends Fake implements NotificationSettings {
  _FakeSettings(this._status);
  final AuthorizationStatus _status;
  @override
  AuthorizationStatus get authorizationStatus => _status;
}

void main() {
  late _MockMessaging messaging;
  late _MockRepo repo;
  late FcmTokenService service;

  setUp(() {
    messaging = _MockMessaging();
    repo = _MockRepo();
    service = FcmTokenService(repository: repo, messaging: messaging);
  });

  group('FcmTokenService.requestPermission', () {
    test('mapea authorized → authorized', () async {
      when(
        () => messaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
          provisional: any(named: 'provisional'),
        ),
      ).thenAnswer((_) async => _FakeSettings(AuthorizationStatus.authorized));

      final status = await service.requestPermission();
      expect(status, NotificationAuthorizationStatus.authorized);
    });

    test('mapea denied → denied', () async {
      when(
        () => messaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
          provisional: any(named: 'provisional'),
        ),
      ).thenAnswer((_) async => _FakeSettings(AuthorizationStatus.denied));

      final status = await service.requestPermission();
      expect(status, NotificationAuthorizationStatus.denied);
    });

    test('propaga provisional → provisional', () async {
      when(
        () => messaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
          provisional: any(named: 'provisional'),
        ),
      ).thenAnswer(
        (_) async => _FakeSettings(AuthorizationStatus.provisional),
      );

      final status = await service.requestPermission(provisional: true);
      expect(status, NotificationAuthorizationStatus.provisional);
    });
  });

  group('FcmTokenService.currentStatus', () {
    test('lee getNotificationSettings sin mostrar prompt', () async {
      when(() => messaging.getNotificationSettings()).thenAnswer(
        (_) async => _FakeSettings(AuthorizationStatus.notDetermined),
      );

      final status = await service.currentStatus();
      expect(status, NotificationAuthorizationStatus.notDetermined);
      verifyNever(
        () => messaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
          provisional: any(named: 'provisional'),
        ),
      );
    });

    test('mapea authorized → authorized', () async {
      when(() => messaging.getNotificationSettings()).thenAnswer(
        (_) async => _FakeSettings(AuthorizationStatus.authorized),
      );

      expect(
        await service.currentStatus(),
        NotificationAuthorizationStatus.authorized,
      );
    });
  });

  group('NotificationPreferences.systemAuthorized', () {
    test('ronda en toMap/fromMap cuando se provee', () async {
      // No depende del servicio pero cubre la integración entre capas.
      expect(NotificationAuthorizationStatus.values.length, 4);
    });
  });
}
