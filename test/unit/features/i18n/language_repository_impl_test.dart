import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/errors/exceptions.dart';
import 'package:toka/features/i18n/data/language_repository_impl.dart';
import 'package:toka/features/i18n/domain/language.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late LanguageRepositoryImpl repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = LanguageRepositoryImpl(firestore: fakeFirestore);
  });

  Future<void> seedLanguages() async {
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
  }

  test('returns languages ordered by sort_order', () async {
    await seedLanguages();
    final langs = await repo.fetchAvailableLanguages();
    expect(langs.length, 3);
    expect(langs[0].code, 'es');
    expect(langs[1].code, 'en');
    expect(langs[2].code, 'ro');
  });

  test('filters out disabled languages', () async {
    await seedLanguages();
    await fakeFirestore
        .collection('languages')
        .doc('ro')
        .update({'enabled': false});
    final langs = await repo.fetchAvailableLanguages();
    expect(langs.length, 2);
    expect(langs.any((l) => l.code == 'ro'), isFalse);
  });

  test('returns default languages when collection is empty without writing to Firestore',
      () async {
    // Collection vacía — no hay documentos
    final langs = await repo.fetchAvailableLanguages();
    expect(langs.length, 3);
    expect(langs.map((l) => l.code).toList(), containsAll(['es', 'en', 'ro']));

    // NO debe haber escrito nada en Firestore (el cliente no tiene permiso)
    final snap = await fakeFirestore.collection('languages').get();
    expect(snap.docs.length, 0);
  });

  test('throws LanguagesFetchException on failure', () async {
    final throwingRepo = _ThrowingRepo();
    expect(
      () => throwingRepo.fetchAvailableLanguages(),
      throwsA(isA<LanguagesFetchException>()),
    );
  });
}

class _ThrowingRepo extends LanguageRepositoryImpl {
  _ThrowingRepo() : super(firestore: FakeFirebaseFirestore());

  @override
  Future<List<Language>> fetchAvailableLanguages() async {
    throw const LanguagesFetchException('simulated failure');
  }
}
