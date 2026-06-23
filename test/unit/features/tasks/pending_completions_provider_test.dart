// Tests del provider de "completar con Deshacer" (commit diferido, patrón Gmail).
//
// La completación NO se escribe en el backend al instante: se marca pendiente
// (la tarjeta se oculta de "Por hacer") y se confirma tras la ventana de
// Deshacer. "Deshacer" cancela el commit; "flush" (app en background) lo
// adelanta. Usamos fake_async para controlar el Timer sin esperas reales.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/pending_completions_provider.dart';
import 'package:toka/features/tasks/application/task_completion_provider.dart';

/// Doble del notifier de completación real: registra las llamadas en una lista
/// EXTERNA compartida en vez de invocar la callable `applyTaskCompletion`. La
/// lista externa es deliberada: `taskCompletionProvider` es auto-dispose, así
/// que entre el commit diferido y la aserción la instancia puede recrearse;
/// observar una lista compartida verifica el comportamiento (se llamó al
/// backend) sin atarse a una instancia concreta. Sin Firebase.
class _FakeTaskCompletion extends TaskCompletion {
  _FakeTaskCompletion(this.calls);

  final List<(String homeId, String taskId)> calls;

  @override
  AsyncValue<void> build() => const AsyncValue<void>.data(null);

  @override
  Future<void> completeTask(String homeId, String taskId) async {
    calls.add((homeId, taskId));
  }
}

void main() {
  late List<(String homeId, String taskId)> calls;

  ProviderContainer makeContainer() {
    calls = [];
    final container = ProviderContainer(
      overrides: [
        taskCompletionProvider.overrideWith(() => _FakeTaskCompletion(calls)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  const window = Duration(seconds: 10);

  test('schedule marca la tarea como pendiente y NO llama al backend al instante',
      () {
    fakeAsync((async) {
      final c = makeContainer();
      c.read(pendingCompletionsProvider.notifier)
          .schedule(homeId: 'h1', taskId: 't1', window: window);

      expect(c.read(pendingCompletionsProvider), contains('t1'));
      expect(calls, isEmpty, reason: 'el commit se difiere');
    });
  });

  test('al expirar la ventana confirma el commit UNA vez y limpia el pendiente',
      () {
    fakeAsync((async) {
      final c = makeContainer();
      c.read(pendingCompletionsProvider.notifier)
          .schedule(homeId: 'h1', taskId: 't1', window: window);

      async.elapse(const Duration(seconds: 9));
      expect(calls, isEmpty, reason: 'aún dentro de la ventana');

      async.elapse(const Duration(seconds: 1)); // total 10s
      expect(calls, [('h1', 't1')]);
      expect(c.read(pendingCompletionsProvider), isNot(contains('t1')));
    });
  });

  test('undo dentro de la ventana cancela el commit (backend nunca se llama)',
      () {
    fakeAsync((async) {
      final c = makeContainer();
      final notifier = c.read(pendingCompletionsProvider.notifier);
      notifier.schedule(homeId: 'h1', taskId: 't1', window: window);

      async.elapse(const Duration(seconds: 5));
      notifier.undo('t1');
      expect(c.read(pendingCompletionsProvider), isNot(contains('t1')));

      async.elapse(const Duration(seconds: 30));
      expect(calls, isEmpty, reason: 'deshacer = sin escritura en backend');
    });
  });

  test('flush confirma de inmediato todo lo pendiente (app en background)', () {
    fakeAsync((async) {
      final c = makeContainer();
      final notifier = c.read(pendingCompletionsProvider.notifier);
      notifier.schedule(homeId: 'h1', taskId: 't1', window: window);
      notifier.schedule(homeId: 'h2', taskId: 't2', window: window);

      notifier.flush();
      async.flushMicrotasks();

      expect(calls, containsAll(<(String, String)>[('h1', 't1'), ('h2', 't2')]));
      expect(c.read(pendingCompletionsProvider), isEmpty);
    });
  });

  test('programar el mismo taskId dos veces es idempotente (un solo commit)', () {
    fakeAsync((async) {
      final c = makeContainer();
      final notifier = c.read(pendingCompletionsProvider.notifier);
      notifier.schedule(homeId: 'h1', taskId: 't1', window: window);
      notifier.schedule(homeId: 'h1', taskId: 't1', window: window);

      async.elapse(const Duration(seconds: 10));
      expect(calls, [('h1', 't1')]);
    });
  });
}
