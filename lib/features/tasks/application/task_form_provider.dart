import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/recurrence_rule.dart';
import '../domain/task.dart';
import '../domain/task_validator.dart';
import 'tasks_provider.dart';

part 'task_form_provider.freezed.dart';
part 'task_form_provider.g.dart';

enum TaskFormMode { create, edit }

@freezed
class TaskFormState with _$TaskFormState {
  const factory TaskFormState({
    @Default(TaskFormMode.create) TaskFormMode mode,
    String? editingTaskId,
    @Default('') String title,
    @Default('') String description,
    @Default('emoji') String visualKind,
    @Default('🏠') String visualValue,
    RecurrenceRule? recurrenceRule,
    @Default('basicRotation') String assignmentMode,
    @Default([]) List<String> assignmentOrder,
    @Default(1.0) double difficultyWeight,
    @Default('sameAssignee') String onMissAssign,
    @Default(false) bool isLoading,
    @Default({}) Map<String, String> fieldErrors,
    String? globalError,
  }) = _TaskFormState;
}

@riverpod
class TaskFormNotifier extends _$TaskFormNotifier {
  @override
  TaskFormState build() => const TaskFormState();

  void initCreate() {
    state = const TaskFormState(
      mode: TaskFormMode.create,
      // Ponemos una regla diaria por defecto para que el formulario nunca
      // empiece con recurrenceRule == null. Esto elimina la race condition
      // entre el microtask de initCreate y el postFrameCallback del RecurrenceForm.
      recurrenceRule: RecurrenceRule.daily(
        every: 1,
        time: '09:00',
        timezone: 'Europe/Madrid',
      ),
    );
  }

  void initEdit(Task task) {
    state = TaskFormState(
      mode: TaskFormMode.edit,
      editingTaskId: task.id,
      title: task.title,
      description: task.description ?? '',
      visualKind: task.visualKind,
      visualValue: task.visualValue,
      recurrenceRule: task.recurrenceRule,
      assignmentMode: task.assignmentMode,
      assignmentOrder: task.assignmentOrder,
      difficultyWeight: task.difficultyWeight,
      onMissAssign: task.onMissAssign,
    );
  }

  void setTitle(String v) => state = state.copyWith(title: v, fieldErrors: {
        ...Map.of(state.fieldErrors)..remove('title'),
      });

  void setDescription(String v) => state = state.copyWith(description: v);

  void setVisual(String kind, String value) =>
      state = state.copyWith(visualKind: kind, visualValue: value);

  void setRecurrenceRule(RecurrenceRule rule) =>
      state = state.copyWith(recurrenceRule: rule, fieldErrors: {
        ...Map.of(state.fieldErrors)..remove('recurrence'),
      });

  void setAssignmentMode(String mode) =>
      state = state.copyWith(assignmentMode: mode);

  void setAssignmentOrder(List<String> order) {
    // Si quedan menos de 2 miembros, la rotación no tiene sentido: resetear a sameAssignee
    final newOnMissAssign =
        order.length < 2 ? 'sameAssignee' : state.onMissAssign;
    state = state.copyWith(
      assignmentOrder: order,
      onMissAssign: newOnMissAssign,
      fieldErrors: {
        ...Map.of(state.fieldErrors)..remove('assignees'),
      },
    );
  }

  void setDifficultyWeight(double v) =>
      state = state.copyWith(difficultyWeight: v);

  void setOnMissAssign(String value) =>
      state = state.copyWith(onMissAssign: value);

  /// Guarda la tarea. Devuelve el ID si fue exitoso, null si hay errores.
  Future<String?> save(String homeId, String createdByUid) async {
    if (state.recurrenceRule == null) {
      state = state.copyWith(fieldErrors: {
        ...state.fieldErrors,
        'recurrence': 'tasks_validation_recurrence_required',
      });
      return null;
    }

    final input = TaskInput(
      title: state.title,
      description: state.description.isEmpty ? null : state.description,
      visualKind: state.visualKind,
      visualValue: state.visualValue,
      recurrenceRule: state.recurrenceRule!,
      assignmentMode: state.assignmentMode,
      assignmentOrder: state.assignmentOrder,
      difficultyWeight: state.difficultyWeight,
      onMissAssign: state.onMissAssign,
    );

    final validation = TaskValidator.validate(input);
    if (!validation.isOk) {
      final f = validation.failure!;
      state = state.copyWith(fieldErrors: {
        ...state.fieldErrors,
        f.field: f.code,
      });
      return null;
    }

    state = state.copyWith(isLoading: true, globalError: null);
    try {
      final repo = ref.read(tasksRepositoryProvider);
      String taskId;
      if (state.mode == TaskFormMode.create) {
        taskId = await repo.createTask(homeId, input, createdByUid);
      } else {
        taskId = state.editingTaskId!;
        await repo.updateTask(homeId, taskId, input);
      }
      state = state.copyWith(isLoading: false);
      return taskId;
    } catch (e) {
      state =
          state.copyWith(isLoading: false, globalError: 'tasks_save_error');
      return null;
    }
  }

}
