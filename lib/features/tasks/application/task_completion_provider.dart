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

  Future<void> completeTask(String homeId, String taskId) async {
    state = const AsyncValue.loading();
    try {
      final functions = ref.read(firebaseFunctionsProvider);
      await functions.httpsCallable('applyTaskCompletion').call({
        'homeId': homeId,
        'taskId': taskId,
      });
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
