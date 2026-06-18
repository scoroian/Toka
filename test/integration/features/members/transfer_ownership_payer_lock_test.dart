import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/members/data/members_repository_impl.dart';
import 'package:toka/features/members/domain/members_repository.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<dynamic> {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late _MockFunctions mockFunctions;
  late _MockCallable mockCallable;
  late MembersRepositoryImpl repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = _MockFunctions();
    mockCallable = _MockCallable();
    when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
    repo = MembersRepositoryImpl(
      firestore: fakeFirestore,
      functions: mockFunctions,
    );
  });

  group('transferOwnership payer-lock mapping', () {
    test(
        'mapea failed-precondition payer-cannot-transfer a PayerLockedException',
        () async {
      when(() => mockCallable.call(any())).thenThrow(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'payer-cannot-transfer-ownership-while-premium-active',
        ),
      );

      await expectLater(
        () => repo.transferOwnership('home1', 'newOwner'),
        throwsA(isA<PayerLockedException>()),
      );
    });

    test('relanza otras FirebaseFunctionsException sin mapear', () async {
      when(() => mockCallable.call(any())).thenThrow(
        FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Only the current owner can transfer ownership',
        ),
      );

      await expectLater(
        () => repo.transferOwnership('home1', 'newOwner'),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });

    test('caso feliz completa y llama a la Cloud Function', () async {
      when(() => mockCallable.call(any()))
          .thenAnswer((_) async => _MockResult());

      await expectLater(
        repo.transferOwnership('home1', 'newOwner'),
        completes,
      );
      verify(() => mockCallable.call(any())).called(1);
    });
  });
}
