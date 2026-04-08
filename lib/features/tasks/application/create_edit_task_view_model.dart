// lib/features/tasks/application/create_edit_task_view_model.dart
// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../domain/recurrence_rule.dart';
import 'task_form_provider.dart';
import 'tasks_provider.dart';

part 'create_edit_task_view_model.freezed.dart';
part 'create_edit_task_view_model.g.dart';

@freezed
class _CreateEditVMState with _$CreateEditVMState {
  const factory _CreateEditVMState({
    @Default(false) bool savedSuccessfully,
    String? loadedTitle,
    String? loadedDescription,
  }) = __CreateEditVMState;
}

abstract class CreateEditTaskViewModel {
  bool get isEditing;
  TaskFormState get formState;
  bool get savedSuccessfully;
  String? get loadedTitle;
  String? get loadedDescription;
  void setTitle(String v);
  void setDescription(String v);
  void setVisual(String kind, String value);
  void setRecurrenceRule(RecurrenceRule rule);
  void setAssignmentMode(String mode);
  void setAssignmentOrder(List<String> order);
  void setDifficultyWeight(double v);
  Future<void> save();
}

@riverpod
class CreateEditTaskViewModelNotifier
    extends _$CreateEditTaskViewModelNotifier
    implements CreateEditTaskViewModel {
  TaskFormNotifier get _form => ref.read(taskFormNotifierProvider.notifier);

  @override
  _CreateEditVMState build(String? editTaskId) {
    if (editTaskId != null) {
      Future.microtask(() => _loadForEdit(editTaskId));
    } else {
      Future.microtask(() => _form.initCreate());
    }
    return const _CreateEditVMState();
  }

  Future<void> _loadForEdit(String taskId) async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    if (homeId == null) return;
    final task =
        await ref.read(tasksRepositoryProvider).fetchTask(homeId, taskId);
    _form.initEdit(task);
    state = state.copyWith(
      loadedTitle: task.title,
      loadedDescription: task.description ?? '',
    );
  }

  @override
  bool get isEditing =>
      ref.read(taskFormNotifierProvider).mode == TaskFormMode.edit;

  @override
  TaskFormState get formState => ref.read(taskFormNotifierProvider);

  @override
  bool get savedSuccessfully => state.savedSuccessfully;

  @override
  String? get loadedTitle => state.loadedTitle;

  @override
  String? get loadedDescription => state.loadedDescription;

  @override
  void setTitle(String v) => _form.setTitle(v);

  @override
  void setDescription(String v) => _form.setDescription(v);

  @override
  void setVisual(String kind, String value) => _form.setVisual(kind, value);

  @override
  void setRecurrenceRule(RecurrenceRule rule) => _form.setRecurrenceRule(rule);

  @override
  void setAssignmentMode(String mode) => _form.setAssignmentMode(mode);

  @override
  void setAssignmentOrder(List<String> order) =>
      _form.setAssignmentOrder(order);

  @override
  void setDifficultyWeight(double v) => _form.setDifficultyWeight(v);

  @override
  Future<void> save() async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    final uid =
        ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    if (homeId == null) return;
    final taskId = await _form.save(homeId, uid);
    if (taskId != null) {
      state = state.copyWith(savedSuccessfully: true);
    }
  }
}

@riverpod
CreateEditTaskViewModel createEditTaskViewModel(
  CreateEditTaskViewModelRef ref,
  String? editTaskId,
) {
  ref.watch(createEditTaskViewModelNotifierProvider(editTaskId));
  ref.watch(taskFormNotifierProvider);
  return ref.read(createEditTaskViewModelNotifierProvider(editTaskId).notifier);
}
