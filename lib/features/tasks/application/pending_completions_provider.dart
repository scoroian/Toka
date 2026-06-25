// lib/features/tasks/application/pending_completions_provider.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../domain/failed_completion.dart';
import 'completion_failure_classifier.dart';
import 'task_completion_provider.dart';

part 'pending_completions_provider.g.dart';

/// Ventana de "Deshacer" tras tocar Hecho (patrón Gmail). Durante este tiempo la
/// tarea se oculta de "Por hacer" de forma optimista y NO se ha escrito nada en
/// el backend: tocar "Deshacer" cancela el commit sin coste.
const kUndoWindow = Duration(seconds: 10);

/// Estado del provider de completaciones diferidas:
///   - [pending]: `taskId` ocultos optimistamente (en su ventana de Deshacer o
///     con el commit en vuelo). `todayViewModel` los filtra de "Por hacer".
///   - [failed]: completaciones cuyo commit FALLÓ (Hallazgo #02). La tarea
///     vuelve a ser visible y la tarjeta muestra una marca de "no se guardó".
typedef PendingCompletionsState = ({
  Set<String> pending,
  Map<String, FailedCompletion> failed,
});

const _uuid = Uuid();

/// Gestiona las completaciones "diferidas": al tocar Hecho se marca la tarea
/// como pendiente (la pantalla la oculta) y se programa el commit real al
/// backend tras [kUndoWindow]. Mantiene el conjunto de `taskId` pendientes y el
/// mapa de fallos como estado para que `todayViewModel` y las tarjetas reaccionen.
///
/// keepAlive: los temporizadores deben sobrevivir a reconstrucciones de la
/// pantalla Hoy. El flush por ciclo de vida (app en background) lo dispara
/// `app.dart` para no perder un completado si el proceso muere dentro de la
/// ventana.
@Riverpod(keepAlive: true)
class PendingCompletions extends _$PendingCompletions {
  final Map<String, _Pending> _pending = {};
  final Map<String, FailedCompletion> _failed = {};
  bool _disposed = false;

  @override
  PendingCompletionsState build() {
    ref.onDispose(() {
      _disposed = true;
      for (final p in _pending.values) {
        p.timer?.cancel();
      }
      _pending.clear();
      _failed.clear();
    });
    return (pending: const {}, failed: const {});
  }

  /// Marca [taskId] como completado de forma optimista y programa el commit al
  /// backend tras [window]. Genera una `completionId` (clave de idempotencia)
  /// que se reutiliza en los reintentos. Idempotente: si ya está pendiente, no
  /// hace nada (no reinicia el temporizador ni duplica el commit).
  void schedule({
    required String homeId,
    required String taskId,
    required String taskTitle,
    Duration window = kUndoWindow,
  }) {
    if (_pending.containsKey(taskId)) return;
    // Un nuevo intento "limpio" descarta cualquier fallo previo de esa tarea.
    _failed.remove(taskId);
    final timer = Timer(window, () => _commit(taskId));
    _pending[taskId] = _Pending(
      homeId: homeId,
      taskTitle: taskTitle,
      completionId: _uuid.v4(),
      timer: timer,
    );
    _publish();
  }

  /// Cancela una completación pendiente (botón "Deshacer"). No toca el backend.
  void undo(String taskId) {
    final p = _pending.remove(taskId);
    if (p == null) return;
    p.timer?.cancel();
    _publish();
  }

  /// Reintenta un commit que falló, REUTILIZANDO la misma `completionId` para no
  /// duplicar el evento si la escritura previa sí se aplicó. Oculta la tarea de
  /// nuevo y confirma de inmediato (sin ventana de Deshacer).
  void retry(String taskId) {
    final f = _failed.remove(taskId);
    if (f == null) return;
    // Sin temporizador: el reintento confirma de inmediato (sin nueva ventana
    // de Deshacer).
    _pending[taskId] = _Pending(
      homeId: f.homeId,
      taskTitle: f.taskTitle,
      completionId: f.completionId,
    );
    _publish();
    _commit(taskId);
  }

  /// Descarta un fallo sin reintentar (p. ej. tras un conflicto ya resuelto por
  /// otra persona: la lista se refresca y la tarea refleja el estado real).
  void dismiss(String taskId) {
    if (_failed.remove(taskId) != null) _publish();
  }

  /// Confirma de inmediato TODAS las completaciones pendientes. Se llama cuando
  /// la app pasa a segundo plano o se cierra, para no perder un completado que
  /// aún estaba en su ventana de Deshacer.
  void flush() {
    for (final taskId in [..._pending.keys]) {
      _pending[taskId]?.timer?.cancel();
      _commit(taskId);
    }
  }

  /// ¿Está [taskId] pendiente de confirmación (oculto optimistamente)?
  bool isPending(String taskId) => _pending.containsKey(taskId);

  void _commit(String taskId) {
    final p = _pending[taskId];
    if (p == null) return;
    // Se mantiene en `_pending` (oculta) hasta que la escritura resuelve. En
    // éxito el dashboard ya la movió a "Hechas"; en error se mueve a `_failed`
    // (vuelve a ser visible con marca) — Hallazgo #02: nunca en silencio.
    // ignore: discarded_futures
    ref
        .read(taskCompletionProvider.notifier)
        .completeTask(p.homeId, taskId, completionId: p.completionId)
        .then((_) {
      _pending.remove(taskId);
      _publish();
    }, onError: (Object error, StackTrace _) {
      _pending.remove(taskId);
      _failed[taskId] = FailedCompletion(
        homeId: p.homeId,
        taskId: taskId,
        taskTitle: p.taskTitle,
        completionId: p.completionId,
        kind: classifyCompletionFailure(error),
      );
      _publish();
    });
  }

  void _publish() {
    if (_disposed) return;
    state = (
      pending: Set.unmodifiable(_pending.keys),
      failed: Map.unmodifiable(_failed),
    );
  }
}

class _Pending {
  _Pending({
    required this.homeId,
    required this.taskTitle,
    required this.completionId,
    this.timer,
  });
  final String homeId;
  final String taskTitle;
  final String completionId;

  /// Temporizador de la ventana de Deshacer. Null en un reintento (commit
  /// inmediato, sin ventana).
  final Timer? timer;
}
