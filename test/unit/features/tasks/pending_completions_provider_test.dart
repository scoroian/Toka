// Tests del provider de "completar con Deshacer" (commit diferido, patrón Gmail)
// + manejo de fallos del commit (Hallazgo #02).
//
// La completación NO se escribe en el backend al instante: se marca pendiente
// (la tarjeta se oculta de "Por hacer") y se confirma tras la ventana de
// Deshacer. "Deshacer" cancela el commit; "flush" (app en background) lo
// adelanta. Si el commit FALLA, la tarea sale de `pending` y entra en `failed`
// (vuelve a ser visible) con su naturaleza (transient/conflict); el usuario
// puede reintentar reutilizando la MISMA `completionId` (idempotencia).
// Usamos fake_async para controlar el Timer sin esperas reales.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/pending_completions_provider.dart';
import 'package:toka/features/tasks/application/task_completion_provider.dart';
import 'package:toka/features/tasks/domain/failed_completion.dart';

typedef _Call = ({String homeId, String taskId, String? completionId});

/// Doble del notifier de completación real. Registra cada llamada (con su
/// `completionId`) en una lista EXTERNA compartida y, opcionalmente, lanza un
/// error en la N-ésima llamada (`errorFor`) para simular fallos del backend.
class _FakeTaskCompletion extends TaskCompletion {
  _FakeTaskCompletion(this.calls, {this.errorFor});

  final List<_Call> calls;

  /// Dado el índice de llamada (0-based), devuelve el error a lanzar o null
  /// para que la llamada tenga éxito.
  final Object? Function(int callIndex)? errorFor;

  @override
  AsyncValue<void> build() => const AsyncValue<void>.data(null);

  @override
  Future<void> completeTask(String homeId, String taskId,
      {String? completionId}) async {
    final idx = calls.length;
    calls.add((homeId: homeId, taskId: taskId, completionId: completionId));
    final err = errorFor?.call(idx);
    if (err != null) throw err;
  }
}

FirebaseFunctionsException _ffx(String code) =>
    FirebaseFunctionsException(message: code, code: code);

void main() {
  late List<_Call> calls;

  ProviderContainer makeContainer({Object? Function(int)? errorFor}) {
    calls = [];
    final container = ProviderContainer(
      overrides: [
        taskCompletionProvider
            .overrideWith(() => _FakeTaskCompletion(calls, errorFor: errorFor)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  const window = Duration(seconds: 10);

  void scheduleT1(ProviderContainer c) =>
      c.read(pendingCompletionsProvider.notifier).schedule(
            homeId: 'h1',
            taskId: 't1',
            taskTitle: 'Barrer',
            window: window,
          );

  test('schedule marca la tarea como pendiente y NO llama al backend al instante',
      () {
    fakeAsync((async) {
      final c = makeContainer();
      scheduleT1(c);

      expect(c.read(pendingCompletionsProvider).pending, contains('t1'));
      expect(calls, isEmpty, reason: 'el commit se difiere');
    });
  });

  test('al expirar la ventana confirma el commit UNA vez y limpia el pendiente',
      () {
    fakeAsync((async) {
      final c = makeContainer();
      scheduleT1(c);

      async.elapse(const Duration(seconds: 9));
      expect(calls, isEmpty, reason: 'aún dentro de la ventana');

      async.elapse(const Duration(seconds: 1)); // total 10s
      async.flushMicrotasks();
      expect(calls.map((e) => (e.homeId, e.taskId)), [('h1', 't1')]);
      expect(c.read(pendingCompletionsProvider).pending, isNot(contains('t1')));
      expect(c.read(pendingCompletionsProvider).failed, isEmpty);
    });
  });

  test('undo dentro de la ventana cancela el commit (backend nunca se llama)',
      () {
    fakeAsync((async) {
      final c = makeContainer();
      final notifier = c.read(pendingCompletionsProvider.notifier);
      scheduleT1(c);

      async.elapse(const Duration(seconds: 5));
      notifier.undo('t1');
      expect(c.read(pendingCompletionsProvider).pending, isNot(contains('t1')));

      async.elapse(const Duration(seconds: 30));
      expect(calls, isEmpty, reason: 'deshacer = sin escritura en backend');
    });
  });

  test('flush confirma de inmediato todo lo pendiente (app en background)', () {
    fakeAsync((async) {
      final c = makeContainer();
      final notifier = c.read(pendingCompletionsProvider.notifier);
      notifier.schedule(homeId: 'h1', taskId: 't1', taskTitle: 'A', window: window);
      notifier.schedule(homeId: 'h2', taskId: 't2', taskTitle: 'B', window: window);

      notifier.flush();
      async.flushMicrotasks();

      expect(calls.map((e) => (e.homeId, e.taskId)),
          containsAll(<(String, String)>[('h1', 't1'), ('h2', 't2')]));
      expect(c.read(pendingCompletionsProvider).pending, isEmpty);
    });
  });

  test('programar el mismo taskId dos veces es idempotente (un solo commit)', () {
    fakeAsync((async) {
      final c = makeContainer();
      scheduleT1(c);
      scheduleT1(c);

      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(calls.length, 1);
    });
  });

  // --- Hallazgo #02: manejo de fallos del commit ----------------------------

  test('commit transitorio falla → sale de pending y entra en failed (1 llamada)',
      () {
    fakeAsync((async) {
      final c = makeContainer(errorFor: (_) => _ffx('unavailable'));
      scheduleT1(c);

      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();

      final state = c.read(pendingCompletionsProvider);
      expect(state.pending, isNot(contains('t1')),
          reason: 'ya no está oculta optimistamente');
      expect(state.failed.containsKey('t1'), isTrue);
      expect(state.failed['t1']!.kind, CompletionFailureKind.transient);
      expect(state.failed['t1']!.taskTitle, 'Barrer');
      expect(calls.length, 1, reason: 'no reintenta solo');
    });
  });

  test('commit con conflicto (permission-denied) → failed kind conflict', () {
    fakeAsync((async) {
      final c = makeContainer(errorFor: (_) => _ffx('permission-denied'));
      scheduleT1(c);

      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();

      final state = c.read(pendingCompletionsProvider);
      expect(state.failed['t1']!.kind, CompletionFailureKind.conflict);
    });
  });

  test('retry reutiliza la MISMA completionId (idempotencia)', () {
    fakeAsync((async) {
      // Falla en la 1.ª llamada (idx 0), éxito en la 2.ª (idx 1).
      final c = makeContainer(errorFor: (i) => i == 0 ? _ffx('unavailable') : null);
      scheduleT1(c);

      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(c.read(pendingCompletionsProvider).failed.containsKey('t1'), isTrue);

      c.read(pendingCompletionsProvider.notifier).retry('t1');
      async.flushMicrotasks();

      expect(calls.length, 2);
      expect(calls[0].completionId, isNotNull);
      expect(calls[1].completionId, calls[0].completionId,
          reason: 'la clave de idempotencia se conserva al reintentar');
    });
  });

  test('retry exitoso limpia failed y no deja pending', () {
    fakeAsync((async) {
      final c = makeContainer(errorFor: (i) => i == 0 ? _ffx('unavailable') : null);
      scheduleT1(c);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();

      c.read(pendingCompletionsProvider.notifier).retry('t1');
      async.flushMicrotasks();

      final state = c.read(pendingCompletionsProvider);
      expect(state.failed, isEmpty);
      expect(state.pending, isEmpty);
    });
  });

  test('retry que vuelve a fallar deja la tarea en failed otra vez', () {
    fakeAsync((async) {
      final c = makeContainer(errorFor: (_) => _ffx('unavailable')); // siempre falla
      scheduleT1(c);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();

      c.read(pendingCompletionsProvider.notifier).retry('t1');
      async.flushMicrotasks();

      expect(c.read(pendingCompletionsProvider).failed.containsKey('t1'), isTrue);
      expect(calls.length, 2);
    });
  });

  test('flush con commit que falla → la tarea cae en failed (background)', () {
    fakeAsync((async) {
      final c = makeContainer(errorFor: (_) => _ffx('unavailable'));
      scheduleT1(c);

      c.read(pendingCompletionsProvider.notifier).flush();
      async.flushMicrotasks();

      final state = c.read(pendingCompletionsProvider);
      expect(state.pending, isEmpty);
      expect(state.failed.containsKey('t1'), isTrue);
    });
  });

  test('dismiss limpia un failed', () {
    fakeAsync((async) {
      final c = makeContainer(errorFor: (_) => _ffx('permission-denied'));
      scheduleT1(c);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(c.read(pendingCompletionsProvider).failed.containsKey('t1'), isTrue);

      c.read(pendingCompletionsProvider.notifier).dismiss('t1');
      expect(c.read(pendingCompletionsProvider).failed, isEmpty);
    });
  });
}
