import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/onboarding/data/home_creation_repository_impl.dart';
import 'package:toka/features/onboarding/domain/home_creation_repository.dart';

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

    test('re-lanza otros errores (p. ej. rate limit) sin enmascararlos', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(
            message: 'too many', code: 'resource-exhausted'),
      );

      await expectLater(
        () => buildRepo().joinHome(code: 'ABC123'),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });
  });
}
