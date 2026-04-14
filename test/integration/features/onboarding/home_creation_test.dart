import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/onboarding/data/home_creation_repository_impl.dart';
import 'package:toka/features/onboarding/domain/home_creation_repository.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

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

  group('createHome', () {
    test('returns homeId from Cloud Function response', () async {
      final mockResult = _MockResult();
      when(() => mockResult.data).thenReturn({'homeId': 'new-home-id'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      final homeId = await repo.createHome(name: 'Casa Test');
      expect(homeId, 'new-home-id');
    });

    test('throws NoHomeSlotsException on resource-exhausted error', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
            message: 'no slots', code: 'resource-exhausted'),
      );

      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      await expectLater(
        () => repo.createHome(name: 'Casa'),
        throwsA(isA<NoHomeSlotsException>()),
      );
    });
  });

  group('joinHome', () {
    test('throws InvalidInviteCodeException when no matching invitation',
        () async {
      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      await expectLater(
        () => repo.joinHome(code: 'XXXXXX'),
        throwsA(isA<InvalidInviteCodeException>()),
      );
    });

    test('throws ExpiredInviteCodeException when invitation is expired',
        () async {
      await fakeFirestore
          .collection('homes')
          .doc('home-1')
          .collection('invitations')
          .doc('inv-1')
          .set({
        'code': 'EXPIRD',
        'used': false,
        'expiresAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      });

      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      await expectLater(
        () => repo.joinHome(code: 'EXPIRD'),
        throwsA(isA<ExpiredInviteCodeException>()),
      );
    });

    test('calls joinHome function and returns homeId on valid code', () async {
      await fakeFirestore
          .collection('homes')
          .doc('home-2')
          .collection('invitations')
          .doc('inv-2')
          .set({
        'code': 'VALID1',
        'used': false,
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7))),
      });

      when(() => mockCallable.call<void>(any()))
          .thenAnswer((_) async => _MockVoidResult());

      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      final homeId = await repo.joinHome(code: 'VALID1');
      expect(homeId, 'home-2');
    });
  });
}
