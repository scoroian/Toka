import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/notifications/data/notification_prefs_repository_impl.dart';
import 'package:toka/features/notifications/domain/notification_preferences.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late NotificationPrefsRepositoryImpl repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = NotificationPrefsRepositoryImpl(firestore: fakeFirestore);
  });

  group('NotificationPrefsRepositoryImpl', () {
    const homeId = 'h1';
    const uid = 'u1';

    test('watchPrefs emite defaults cuando el documento no existe', () async {
      final stream = repo.watchPrefs(homeId, uid);
      final prefs = await stream.first;
      expect(prefs.notifyOnDue, true);
      expect(prefs.homeId, homeId);
    });

    test('savePrefs guarda las preferencias en Firestore', () async {
      await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .set({'nickname': 'Test'});

      const prefs = NotificationPreferences(
        homeId: homeId,
        uid: uid,
        notifyOnDue: false,
        minutesBefore: 60,
      );

      await repo.savePrefs(prefs);

      final doc = await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .get();
      expect(doc.data()!['notificationPrefs']['notifyOnDue'], false);
      expect(doc.data()!['notificationPrefs']['minutesBefore'], 60);
    });

    test('savePrefs funciona aunque el documento no exista previamente', () async {
      // No se crea el documento previamente — savePrefs debe usar set+merge
      const prefs = NotificationPreferences(homeId: homeId, uid: uid);
      await expectLater(repo.savePrefs(prefs), completes);
    });

    test('updateFcmToken guarda el token FCM', () async {
      await repo.updateFcmToken(homeId, uid, 'test-token-123');

      final doc = await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .get();
      expect(doc.data()!['notificationPrefs']['fcmToken'], 'test-token-123');
    });
  });
}
