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

    test('savePrefs NO crea el doc de miembro si no existe (update deliberado)', () async {
      // Por diseño savePrefs usa update() para NO crear members/{uid} desde el
      // cliente (las reglas lo prohíben; solo lo crea una Cloud Function). Si el
      // doc no existe, la operación falla en lugar de crearlo. (El test anterior
      // afirmaba lo contrario y estaba en rojo antes de este cambio — ver H-002.)
      const prefs = NotificationPreferences(homeId: homeId, uid: uid);
      await expectLater(repo.savePrefs(prefs), throwsA(anything));
    });

    test('updateFcmToken guarda el token en users/{uid} (privado), NO en el member doc', () async {
      // Privacidad (Hallazgo #01): el token FCM no debe quedar en el doc de
      // miembro (legible por todo el hogar), sino en users/{uid} (privado).
      await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .set({'nickname': 'Test'});

      await repo.updateFcmToken(homeId, uid, 'test-token-123');

      final userDoc = await fakeFirestore.collection('users').doc(uid).get();
      expect(userDoc.data()!['fcmToken'], 'test-token-123');

      final memberDoc = await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .get();
      final prefs =
          memberDoc.data()!['notificationPrefs'] as Map<String, dynamic>?;
      expect(prefs?['fcmToken'], isNull);
    });

    test('savePrefs NO escribe el token FCM en el member doc', () async {
      await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .set({'nickname': 'Test'});

      const prefs = NotificationPreferences(
        homeId: homeId,
        uid: uid,
        fcmToken: 'should-not-be-persisted',
      );
      await repo.savePrefs(prefs);

      final doc = await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .get();
      expect(doc.data()!['notificationPrefs'].containsKey('fcmToken'), false);
    });
  });
}
