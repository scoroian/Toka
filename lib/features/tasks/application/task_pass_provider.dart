import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'task_completion_provider.dart';

part 'task_pass_provider.g.dart';

@riverpod
class TaskPass extends _$TaskPass {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> passTurn(
    String homeId,
    String taskId, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final functions = ref.read(firebaseFunctionsProvider);
      final data = <String, dynamic>{
        'homeId': homeId,
        'taskId': taskId,
      };
      if (reason != null) data['reason'] = reason;
      await functions.httpsCallable('passTaskTurn').call(data);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
