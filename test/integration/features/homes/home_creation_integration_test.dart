import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/data/homes_repository_impl.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late _MockFunctions mockFunctions;
  late _MockCallable mockCallable;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = _MockFunctions();
    mockCallable = _MockCallable();
    when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
  });

  group('createHome integration', () {
    test('retorna homeId de la respuesta de Cloud Function', () async {
      final mockResult = _MockResult();
      when(() => mockResult.data).thenReturn({'homeId': 'home-abc-123'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final homeId = await repo.createHome('Mi Casa');
      expect(homeId, 'home-abc-123');
    });

    test('segunda creación retorna homeId diferente', () async {
      int callCount = 0;
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async {
        callCount++;
        final result = _MockResult();
        when(() => result.data).thenReturn({'homeId': 'home-$callCount'});
        return result;
      });

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final homeId1 = await repo.createHome('Casa Uno');
      final homeId2 = await repo.createHome('Casa Dos');

      expect(homeId1, 'home-1');
      expect(homeId2, 'home-2');
      expect(homeId1, isNot(equals(homeId2)));
    });

    test('lanza NoAvailableSlotsException en error resource-exhausted',
        () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
            message: 'no slots', code: 'resource-exhausted'),
      );

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      await expectLater(
        () => repo.createHome('Casa'),
        throwsA(isA<NoAvailableSlotsException>()),
      );
    });
  });

  group('getAvailableSlots integration', () {
    test('retorna baseSlots + lifetimeUnlocked - currentCount', () async {
      const uid = 'user-slots-test';

      await fakeFirestore.collection('users').doc(uid).set({
        'baseSlots': 3,
        'lifetimeUnlocked': 2,
      });

      // Añadir 2 membresías activas
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc('home-a')
          .set({'homeId': 'home-a', 'role': 'member'});
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc('home-b')
          .set({'homeId': 'home-b', 'role': 'owner'});

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      // 3 + 2 - 2 = 3
      final slots = await repo.getAvailableSlots(uid);
      expect(slots, 3);
    });

    test('retorna 2 para usuario nuevo sin membresías', () async {
      const uid = 'user-new';

      await fakeFirestore.collection('users').doc(uid).set({
        // Sin baseSlots ni lifetimeUnlocked → defaults a 2 y 0
      });

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      // 2 (default) + 0 (default) - 0 (sin membresías) = 2
      final slots = await repo.getAvailableSlots(uid);
      expect(slots, 2);
    });
  });

  group('watchUserMemberships integration', () {
    test('emite lista de membresías cuando hay documentos', () async {
      const uid = 'user-watch';

      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc('h1')
          .set({
        'homeId': 'h1',
        'homeNameSnapshot': 'Casa Test',
        'role': 'owner',
        'billingState': 'none',
        'status': 'active',
        'joinedAt': Timestamp.fromDate(DateTime(2025)),
      });

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      final memberships = await repo.watchUserMemberships(uid).first;

      expect(memberships, hasLength(1));
      expect(memberships.first.homeId, 'h1');
      expect(memberships.first.homeNameSnapshot, 'Casa Test');
    });
  });
}
