// Los mocks de CollectionReference/Query implementan clases sealed de
// cloud_firestore (necesario para inyectar un fallo de lectura); el propio
// código generado de Riverpod silencia este mismo aviso.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/i18n/data/language_repository_impl.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionRef extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class _MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class _MockSnapshotMetadata extends Mock implements SnapshotMetadata {}

/// Construye un repositorio cuyo `.get()` resuelve a un snapshot vacío con la
/// metadata indicada (para distinguir "vacío offline/caché" de "vacío servidor").
LanguageRepositoryImpl _repoWithEmptySnapshot({required bool isFromCache}) {
  final fs = _MockFirestore();
  final col = _MockCollectionRef();
  final q1 = _MockQuery();
  final q2 = _MockQuery();
  final snap = _MockQuerySnapshot();
  final meta = _MockSnapshotMetadata();
  when(() => fs.collection('languages')).thenReturn(col);
  when(() => col.where('enabled', isEqualTo: true)).thenReturn(q1);
  when(() => q1.orderBy('sort_order')).thenReturn(q2);
  when(() => q2.get()).thenAnswer((_) async => snap);
  when(() => snap.docs).thenReturn([]);
  when(() => snap.metadata).thenReturn(meta);
  when(() => meta.isFromCache).thenReturn(isFromCache);
  return LanguageRepositoryImpl(firestore: fs);
}

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
    final result = await repo.fetchAvailableLanguages();
    expect(result.languages.length, 3);
    expect(result.languages[0].code, 'es');
    expect(result.languages[1].code, 'en');
    expect(result.languages[2].code, 'ro');
    expect(result.isFallback, isFalse);
  });

  test('filters out disabled languages', () async {
    await seedLanguages();
    await fakeFirestore
        .collection('languages')
        .doc('ro')
        .update({'enabled': false});
    final result = await repo.fetchAvailableLanguages();
    expect(result.languages.length, 2);
    expect(result.languages.any((l) => l.code == 'ro'), isFalse);
  });

  test('returns default languages when collection is empty without writing to Firestore',
      () async {
    // Collection vacía — no hay documentos
    final result = await repo.fetchAvailableLanguages();
    expect(result.languages.length, 3);
    expect(result.languages.map((l) => l.code).toList(),
        containsAll(['es', 'en', 'ro']));
    // Colección vacía es lectura correcta, NO fallback de error.
    expect(result.isFallback, isFalse);

    // NO debe haber escrito nada en Firestore (el cliente no tiene permiso)
    final snap = await fakeFirestore.collection('languages').get();
    expect(snap.docs.length, 0);
  });

  test('returns default languages as fallback when the read fails (offline)',
      () async {
    // Firestore que lanza al leer (p. ej. sin red / modo avión).
    final fs = _MockFirestore();
    final col = _MockCollectionRef();
    final q1 = _MockQuery();
    final q2 = _MockQuery();
    when(() => fs.collection('languages')).thenReturn(col);
    when(() => col.where('enabled', isEqualTo: true)).thenReturn(q1);
    when(() => q1.orderBy('sort_order')).thenReturn(q2);
    when(() => q2.get()).thenThrow(
      FirebaseException(
          plugin: 'cloud_firestore', code: 'unavailable', message: 'offline'),
    );
    final offlineRepo = LanguageRepositoryImpl(firestore: fs);

    // No debe lanzar: el onboarding no puede quedarse sin idiomas.
    final result = await offlineRepo.fetchAvailableLanguages();

    expect(result.isFallback, isTrue);
    expect(result.languages.map((l) => l.code).toList(), ['es', 'en', 'ro']);
  });

  test('empty query FROM CACHE (offline, no cached docs) → defaults as fallback',
      () async {
    // Una query Firestore sin red y sin caché NO lanza: devuelve un snapshot
    // vacío con metadata.isFromCache=true. Debe tratarse como fallback (retry),
    // no como "colección remota vacía".
    final result =
        await _repoWithEmptySnapshot(isFromCache: true).fetchAvailableLanguages();
    expect(result.isFallback, isTrue);
    expect(result.languages.map((l) => l.code).toList(), ['es', 'en', 'ro']);
  });

  test('empty query FROM SERVER (initial deploy) → defaults WITHOUT fallback',
      () async {
    // El servidor respondió vacío de verdad: los defaults son el comportamiento
    // correcto, no un error → sin retry.
    final result =
        await _repoWithEmptySnapshot(isFromCache: false).fetchAvailableLanguages();
    expect(result.isFallback, isFalse);
    expect(result.languages.map((l) => l.code).toList(), ['es', 'en', 'ro']);
  });
}
