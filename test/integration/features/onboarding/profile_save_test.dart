import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/onboarding/data/onboarding_repository_impl.dart';

class _MockStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late _MockStorage mockStorage;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockStorage = _MockStorage();
  });

  test('saveProfile writes nickname to users/{uid}', () async {
    final repo = OnboardingRepositoryImpl(
      firestore: fakeFirestore,
      storage: mockStorage,
    );

    await repo.saveProfile(
      uid: 'test-uid',
      nickname: 'Carlos',
      phoneVisible: false,
      locale: 'es',
    );

    final doc =
        await fakeFirestore.collection('users').doc('test-uid').get();
    expect(doc.data()?['nickname'], 'Carlos');
  });

  test('saveProfile writes locale to users/{uid}', () async {
    final repo = OnboardingRepositoryImpl(
      firestore: fakeFirestore,
      storage: mockStorage,
    );

    await repo.saveProfile(
      uid: 'test-uid',
      nickname: 'Ana',
      phoneVisible: false,
      locale: 'en',
    );

    final doc =
        await fakeFirestore.collection('users').doc('test-uid').get();
    expect(doc.data()?['locale'], 'en');
  });

  test('saveProfile with phoneVisible=true stores members visibility',
      () async {
    final repo = OnboardingRepositoryImpl(
      firestore: fakeFirestore,
      storage: mockStorage,
    );

    await repo.saveProfile(
      uid: 'uid-2',
      nickname: 'María',
      phoneNumber: '+34600000000',
      phoneVisible: true,
      locale: 'es',
    );

    final doc = await fakeFirestore.collection('users').doc('uid-2').get();
    expect(doc.data()?['phoneVisibility'], 'members');
    expect(doc.data()?['phoneNumber'], '+34600000000');
  });

  test('saveProfile without photo returns null photoUrl', () async {
    final repo = OnboardingRepositoryImpl(
      firestore: fakeFirestore,
      storage: mockStorage,
    );

    final photoUrl = await repo.saveProfile(
      uid: 'uid-3',
      nickname: 'Test',
      phoneVisible: false,
      locale: 'es',
    );

    expect(photoUrl, isNull);
  });
}
