import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_completion_provider.g.dart';

@Riverpod(keepAlive: false)
FirebaseFunctions firebaseFunctions(FirebaseFunctionsRef ref) {
  return FirebaseFunctions.instance;
}

@riverpod
class TaskCompletion extends _$TaskCompletion {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Confirma la completación en el backend. [completionId] es la clave de
  /// idempotencia (uuid generado por el cliente y reutilizado al reintentar):
  /// si se provee, el callable la usa como id determinista del `taskEvent` para
  /// no duplicar el evento si una escritura previa se aplicó pero se perdió la
  /// respuesta.
  ///
  /// Hallazgo #02: el error ya NO se traga. Se publica en el estado (para
  /// observabilidad) y se RELANZA para que el llamante pueda avisar al usuario
  /// y dejar la tarea en un estado consistente.
  Future<void> completeTask(
    String homeId,
    String taskId, {
    String? completionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final functions = ref.read(firebaseFunctionsProvider);
      await functions.httpsCallable('applyTaskCompletion').call({
        'homeId': homeId,
        'taskId': taskId,
        if (completionId != null) 'completionId': completionId,
      });
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }
}
