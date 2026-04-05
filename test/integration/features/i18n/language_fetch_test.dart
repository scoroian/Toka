// Uses fake_cloud_firestore — no real emulators needed.
// Run with: flutter test test/integration/features/i18n/language_fetch_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/i18n/data/language_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late LanguageRepositoryImpl repo;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    repo = LanguageRepositoryImpl(firestore: fakeFirestore);

    final col = fakeFirestore.collection('languages');
    await col.doc('es').set({
      'code': 'es', 'name': 'Español', 'flag': '🇪🇸',
      'arb_key': 'app_es', 'enabled': true, 'sort_order': 1,
    });
    await col.doc('en').set({
      'code': 'en', 'name': 'English', 'flag': '🇬🇧',
      'arb_key': 'app_en', 'enabled': true, 'sort_order': 2,
    });
    await col.doc('ro').set({
      'code': 'ro', 'name': 'Română', 'flag': '🇷🇴',
      'arb_key': 'app_ro', 'enabled': true, 'sort_order': 3,
    });
  });

  test('fetches all enabled languages ordered by sort_order', () async {
    final langs = await repo.fetchAvailableLanguages();
    expect(langs.length, 3);
    expect(langs.map((l) => l.code).toList(), ['es', 'en', 'ro']);
  });

  test('collection is readable without authentication (fake bypasses rules)',
      () async {
    final langs = await repo.fetchAvailableLanguages();
    expect(langs, isNotEmpty);
  });

  test('returns only enabled languages', () async {
    await fakeFirestore
        .collection('languages')
        .doc('ro')
        .update({'enabled': false});
    final langs = await repo.fetchAvailableLanguages();
    expect(langs.length, 2);
    expect(langs.any((l) => l.code == 'ro'), isFalse);
  });
}
