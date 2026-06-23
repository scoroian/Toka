// lib/features/tasks/application/pending_completions_provider.dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'task_completion_provider.dart';

part 'pending_completions_provider.g.dart';

/// Ventana de "Deshacer" tras tocar Hecho (patrón Gmail). Durante este tiempo la
/// tarea se oculta de "Por hacer" de forma optimista y NO se ha escrito nada en
/// el backend: tocar "Deshacer" cancela el commit sin coste.
const kUndoWindow = Duration(seconds: 10);

/// Gestiona las completaciones "diferidas": al tocar Hecho se marca la tarea
/// como pendiente (la pantalla la oculta) y se programa el commit real al
/// backend tras [kUndoWindow]. Mantiene el conjunto de `taskId` pendientes como
/// estado para que `todayViewModel` los filtre.
///
/// keepAlive: los temporizadores deben sobrevivir a reconstrucciones de la
/// pantalla Hoy. El flush por ciclo de vida (app en background) lo dispara
/// `app.dart` para no perder un completado si el proceso muere dentro de la
/// ventana.
@Riverpod(keepAlive: true)
class PendingCompletions extends _$PendingCompletions {
  final Map<String, _Pending> _pending = {};
  bool _disposed = false;

  @override
  Set<String> build() {
    ref.onDispose(() {
      _disposed = true;
      for (final p in _pending.values) {
        p.timer.cancel();
      }
      _pending.clear();
    });
    return const {};
  }

  /// Marca [taskId] como completado de forma optimista y programa el commit al
  /// backend tras [window]. Idempotente: si ya está pendiente, no hace nada (no
  /// reinicia el temporizador ni duplica el commit).
  void schedule({
    required String homeId,
    required String taskId,
    Duration window = kUndoWindow,
  }) {
    if (_pending.containsKey(taskId)) return;
    final timer = Timer(window, () => _commit(taskId));
    _pending[taskId] = _Pending(homeId: homeId, timer: timer);
    _publish();
  }

  /// Cancela una completación pendiente (botón "Deshacer"). No toca el backend.
  void undo(String taskId) {
    final p = _pending.remove(taskId);
    if (p == null) return;
    p.timer.cancel();
    _publish();
  }

  /// Confirma de inmediato TODAS las completaciones pendientes. Se llama cuando
  /// la app pasa a segundo plano o se cierra, para no perder un completado que
  /// aún estaba en su ventana de Deshacer.
  void flush() {
    for (final taskId in [..._pending.keys]) {
      _pending[taskId]?.timer.cancel();
      _commit(taskId);
    }
  }

  /// ¿Está [taskId] pendiente de confirmación (oculto optimistamente)?
  bool isPending(String taskId) => _pending.containsKey(taskId);

  void _commit(String taskId) {
    final p = _pending[taskId];
    if (p == null) return;
    // Se mantiene en `_pending` (oculta) hasta que la escritura resuelve. En
    // éxito el dashboard ya la movió a "Hechas"; en error reaparece en "Por
    // hacer" (no se perdió la tarea, solo no se completó).
    // ignore: discarded_futures
    ref
        .read(taskCompletionProvider.notifier)
        .completeTask(p.homeId, taskId)
        .whenComplete(() {
      _pending.remove(taskId);
      _publish();
    });
  }

  void _publish() {
    if (_disposed) return;
    state = Set.unmodifiable(_pending.keys);
  }
}

class _Pending {
  _Pending({required this.homeId, required this.timer});
  final String homeId;
  final Timer timer;
}
