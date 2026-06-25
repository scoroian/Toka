import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/core/errors/exceptions.dart';
import 'package:toka/features/onboarding/data/home_creation_repository_impl.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late _MockFunctions mockFunctions;
  late _MockCallable mockCallable;

  setUp(() {
    mockFunctions = _MockFunctions();
    mockCallable = _MockCallable();
    when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
  });

  HomeCreationRepositoryImpl buildRepo() =>
      HomeCreationRepositoryImpl(functions: mockFunctions);

  group('createHome', () {
    test('returns homeId from Cloud Function response', () async {
      final mockResult = _MockResult();
      when(() => mockResult.data).thenReturn({'homeId': 'new-home-id'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final homeId = await buildRepo().createHome(name: 'Casa Test');
      expect(homeId, 'new-home-id');
    });

    test('throws NoHomeSlotsException on resource-exhausted error', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
            message: 'no slots', code: 'resource-exhausted'),
      );

      await expectLater(
        () => buildRepo().createHome(name: 'Casa'),
        throwsA(isA<NoHomeSlotsException>()),
      );
    });
  });

  group('joinHome (vía callable joinHomeByCode — Hallazgo #01)', () {
    test('llama a joinHomeByCode con el código y devuelve el homeId', () async {
      final mockResult = _MockResult();
      when(() => mockResult.data).thenReturn({'homeId': 'home-2'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final homeId = await buildRepo().joinHome(code: 'VALID1');

      expect(homeId, 'home-2');
      // Debe usar la callable server-side, NUNCA consultar invitations.
      verify(() => mockFunctions.httpsCallable('joinHomeByCode')).called(1);
      final captured =
          verify(() => mockCallable.call<Map<String, dynamic>>(captureAny()))
              .captured;
      expect((captured.single as Map)['code'], 'VALID1');
    });

    test('traduce not-found a InvalidInviteCodeException', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(message: 'invalid', code: 'not-found'),
      );

      await expectLater(
        () => buildRepo().joinHome(code: 'XXXXXX'),
        throwsA(isA<InvalidInviteCodeException>()),
      );
    });

    test('traduce deadline-exceeded a ExpiredInviteCodeException', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(message: 'expired', code: 'deadline-exceeded'),
      );

      await expectLater(
        () => buildRepo().joinHome(code: 'EXPIRD'),
        throwsA(isA<ExpiredInviteCodeException>()),
      );
    });

    test('rate limit (resource-exhausted) → TooManyAttemptsException', () async {
      // Hallazgo #04: el mismo mapeo unificado que el repo del selector. El
      // rate-limit es el único resource-exhausted que no es no-account-slots.
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
            message: 'too-many-join-attempts', code: 'resource-exhausted'),
      );

      await expectLater(
        () => buildRepo().joinHome(code: 'ABC123'),
        throwsA(isA<TooManyAttemptsException>()),
      );
    });

    test('resource-exhausted + no-account-slots → NoAccountSlotsException',
        () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
            message: 'no-account-slots', code: 'resource-exhausted'),
      );

      await expectLater(
        () => buildRepo().joinHome(code: 'ABC123'),
        throwsA(isA<NoAccountSlotsException>()),
      );
    });

    test('failed-precondition + free_limit_members → MaxMembersReachedException',
        () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
            message: 'free_limit_members', code: 'failed-precondition'),
      );

      await expectLater(
        () => buildRepo().joinHome(code: 'ABC123'),
        throwsA(isA<MaxMembersReachedException>()),
      );
    });

    test('code desconocido se re-lanza tal cual (sin enmascararlo)', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(message: 'boom', code: 'internal'),
      );

      await expectLater(
        () => buildRepo().joinHome(code: 'ABC123'),
        throwsA(isA<FirebaseFunctionsException>()
            .having((e) => e.code, 'code', 'internal')),
      );
    });
  });
}
