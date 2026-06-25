import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/task_completion_provider.dart';

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
    when(() => mockFunctions.httpsCallable('applyTaskCompletion'))
        .thenReturn(mockCallable);
  });

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          firebaseFunctionsProvider.overrideWithValue(mockFunctions),
        ],
      );

  test('completeTask llama callable con homeId y taskId correctos', () async {
    when(() => mockCallable.call(any()))
        .thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    await container
        .read(taskCompletionProvider.notifier)
        .completeTask('home1', 'task1');

    verify(() => mockCallable.call({'homeId': 'home1', 'taskId': 'task1'}))
        .called(1);
  });

  test('completeTask reenvía completionId al callable cuando se provee', () async {
    when(() => mockCallable.call(any()))
        .thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    await container
        .read(taskCompletionProvider.notifier)
        .completeTask('home1', 'task1', completionId: 'cid-123');

    verify(() => mockCallable.call(
            {'homeId': 'home1', 'taskId': 'task1', 'completionId': 'cid-123'}))
        .called(1);
  });

  test('estado loading → data en flujo exitoso', () async {
    when(() => mockCallable.call(any()))
        .thenAnswer((_) async => MockHttpsCallableResult());

    final container = makeContainer();
    final notifier = container.read(taskCompletionProvider.notifier);

    expect(
        container.read(taskCompletionProvider), const AsyncValue<void>.data(null));
    final future = notifier.completeTask('home1', 'task1');
    expect(container.read(taskCompletionProvider), isA<AsyncLoading<void>>());
    await future;
    expect(
        container.read(taskCompletionProvider), const AsyncValue<void>.data(null));
  });

  test('fallo permission-denied → estado error y RELANZA (Hallazgo #02)',
      () async {
    when(() => mockCallable.call(any())).thenThrow(
      FirebaseFunctionsException(
          message: 'Not your turn', code: 'permission-denied'),
    );

    final container = makeContainer();
    final notifier = container.read(taskCompletionProvider.notifier);

    // Regresión #02: el error ya NO se traga. Se relanza para que el llamante
    // (PendingCompletions._commit) pueda avisar al usuario.
    await expectLater(
      () => notifier.completeTask('home1', 'task1'),
      throwsA(isA<FirebaseFunctionsException>()),
    );
    expect(container.read(taskCompletionProvider), isA<AsyncError<void>>());
  });

  test('fallo not-found → estado error y RELANZA', () async {
    when(() => mockCallable.call(any())).thenThrow(
      FirebaseFunctionsException(
          message: 'Task not found', code: 'not-found'),
    );

    final container = makeContainer();
    final notifier = container.read(taskCompletionProvider.notifier);

    await expectLater(
      () => notifier.completeTask('home1', 'task1'),
      throwsA(isA<FirebaseFunctionsException>()),
    );
    expect(container.read(taskCompletionProvider), isA<AsyncError<void>>());
  });
}
