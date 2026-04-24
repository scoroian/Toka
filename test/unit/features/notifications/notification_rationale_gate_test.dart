// test/unit/features/notifications/notification_rationale_gate_test.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/onboarding/presentation/notification_rationale_screen.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

class _FakeSettings extends Fake implements NotificationSettings {
  _FakeSettings(this._status);
  final AuthorizationStatus _status;
  @override
  AuthorizationStatus get authorizationStatus => _status;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'shouldShowNotificationRationale devuelve true si la flag local NO está puesta',
    () async {
      final messaging = _MockMessaging();

      final result =
          await shouldShowNotificationRationale(messaging: messaging);

      expect(result, isTrue);
      verifyNever(() => messaging.getNotificationSettings());
    },
  );

  test(
    'shouldShowNotificationRationale devuelve true si flag puesta pero status == notDetermined',
    () async {
      SharedPreferences.setMockInitialValues({
        kNotifRationaleShownPrefKey: true,
      });
      final messaging = _MockMessaging();
      when(() => messaging.getNotificationSettings()).thenAnswer(
        (_) async => _FakeSettings(AuthorizationStatus.notDetermined),
      );

      final result =
          await shouldShowNotificationRationale(messaging: messaging);

      expect(result, isTrue);
    },
  );

  test(
    'shouldShowNotificationRationale devuelve false si flag puesta y status == authorized',
    () async {
      SharedPreferences.setMockInitialValues({
        kNotifRationaleShownPrefKey: true,
      });
      final messaging = _MockMessaging();
      when(() => messaging.getNotificationSettings()).thenAnswer(
        (_) async => _FakeSettings(AuthorizationStatus.authorized),
      );

      final result =
          await shouldShowNotificationRationale(messaging: messaging);

      expect(result, isFalse);
    },
  );

  test(
    'shouldShowNotificationRationale devuelve false si flag puesta y status == denied',
    () async {
      SharedPreferences.setMockInitialValues({
        kNotifRationaleShownPrefKey: true,
      });
      final messaging = _MockMessaging();
      when(() => messaging.getNotificationSettings()).thenAnswer(
        (_) async => _FakeSettings(AuthorizationStatus.denied),
      );

      final result =
          await shouldShowNotificationRationale(messaging: messaging);

      expect(result, isFalse);
    },
  );

  test('markNotificationRationaleShown persiste la flag', () async {
    await markNotificationRationaleShown();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kNotifRationaleShownPrefKey), isTrue);
  });
}
