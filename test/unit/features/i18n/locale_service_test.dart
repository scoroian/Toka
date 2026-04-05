import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/services/locale_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  Future<LocaleService> buildService({Locale? overrideDevice}) async {
    final prefs = await SharedPreferences.getInstance();
    return LocaleService(
      prefs: prefs,
      firestore: fakeFirestore,
      overrideDeviceLocale: overrideDevice,
    );
  }

  group('getCurrentLocale', () {
    test('returns SharedPreferences locale when no uid', () async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final service = await buildService();
      final locale = await service.getCurrentLocale(null);
      expect(locale, const Locale('en'));
    });

    test('returns Firestore locale when uid is provided', () async {
      await fakeFirestore
          .collection('users')
          .doc('uid123')
          .set({'locale': 'ro'});
      final service = await buildService();
      final locale = await service.getCurrentLocale('uid123');
      expect(locale, const Locale('ro'));
    });

    test('falls back to SharedPreferences if Firestore has no locale field',
        () async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      await fakeFirestore
          .collection('users')
          .doc('uid456')
          .set({'displayName': 'Test'});
      final service = await buildService();
      final locale = await service.getCurrentLocale('uid456');
      expect(locale, const Locale('en'));
    });

    test('returns fallback es when device locale is unsupported', () async {
      final service = await buildService(overrideDevice: const Locale('de'));
      final locale = await service.getCurrentLocale(null);
      expect(locale, const Locale('es'));
    });

    test('returns device locale when it is supported', () async {
      final service = await buildService(overrideDevice: const Locale('en'));
      final locale = await service.getCurrentLocale(null);
      expect(locale, const Locale('en'));
    });
  });

  group('saveLocale', () {
    test('always saves to SharedPreferences', () async {
      final service = await buildService();
      await service.saveLocale('ro', null);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), 'ro');
    });

    test('also saves to Firestore when uid is provided', () async {
      final service = await buildService();
      await service.saveLocale('en', 'uid789');
      final doc =
          await fakeFirestore.collection('users').doc('uid789').get();
      expect(doc.data()?['locale'], 'en');
    });
  });
}
