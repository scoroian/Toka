import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/task_completion_provider.dart';
import 'package:toka/features/tasks/application/task_pass_provider.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    when(() => mockFunctions.httpsCallable('passTaskTurn'))
        .thenReturn(mockCallable);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          firebaseFunctionsProvider.overrideWithValue(mockFunctions),
        ],
      );

  test('passTurn llama callable con homeId, taskId y reason', () async {
    when(() => mockCallable.call(any()))
        .thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    await container
        .read(taskPassProvider.notifier)
        .passTurn('home1', 'task1', reason: 'Viaje');

    verify(() => mockCallable.call({
          'homeId': 'home1',
          'taskId': 'task1',
          'reason': 'Viaje',
        })).called(1);
  });

  test('passTurn sin reason omite la clave reason', () async {
    when(() => mockCallable.call(any()))
        .thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    await container
        .read(taskPassProvider.notifier)
        .passTurn('home1', 'task1');

    verify(() => mockCallable.call({'homeId': 'home1', 'taskId': 'task1'}))
        .called(1);
  });

  test('fallo permission-denied → estado error', () async {
    when(() => mockCallable.call(any())).thenThrow(
      FirebaseFunctionsException(
          message: 'Not your turn', code: 'permission-denied'),
    );

    final container = makeContainer();
    await container
        .read(taskPassProvider.notifier)
        .passTurn('home1', 'task1');

    expect(container.read(taskPassProvider), isA<AsyncError<void>>());
  });
}
