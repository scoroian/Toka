import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/data/homes_repository_impl.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockVoidResult extends Mock implements HttpsCallableResult<void> {}

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

  group('leaveHome integration', () {
    test('miembro puede abandonar el hogar y llama a la Cloud Function',
        () async {
      const uid = 'user-member';
      const homeId = 'home-1';

      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc(homeId)
          .set({
        'homeId': homeId,
        'homeNameSnapshot': 'Casa Compartida',
        'role': 'member',
        'billingState': 'none',
        'status': 'active',
      });

      when(() => mockCallable.call<void>(any()))
          .thenAnswer((_) async => _MockVoidResult());

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      await expectLater(repo.leaveHome(homeId, uid: uid), completes);

      verify(() => mockCallable.call<void>(any())).called(1);
    });

    test(
        'owner que intenta abandonar lanza CannotLeaveAsOwnerException y NO llama a la Cloud Function',
        () async {
      const uid = 'user-owner';
      const homeId = 'home-2';

      await fakeFirestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc(homeId)
          .set({
        'homeId': homeId,
        'homeNameSnapshot': 'Mi Hogar',
        'role': 'owner',
        'billingState': 'currentPayer',
        'status': 'active',
      });

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      await expectLater(
        () => repo.leaveHome(homeId, uid: uid),
        throwsA(isA<CannotLeaveAsOwnerException>()),
      );

      verifyNever(() => mockCallable.call<void>(any()));
    });

    test(
        'usuario sin documento de membresía puede intentar abandonar sin lanzar CannotLeaveAsOwnerException',
        () async {
      const uid = 'user-no-membership';
      const homeId = 'home-3';

      // No se crea ningún documento de membresía para este usuario y hogar

      when(() => mockCallable.call<void>(any()))
          .thenAnswer((_) async => _MockVoidResult());

      final repo = HomesRepositoryImpl(
        firestore: fakeFirestore,
        functions: mockFunctions,
      );

      await expectLater(repo.leaveHome(homeId, uid: uid), completes);

      verify(() => mockCallable.call<void>(any())).called(1);
    });
  });
}
