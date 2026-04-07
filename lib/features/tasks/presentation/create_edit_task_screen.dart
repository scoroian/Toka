import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../application/task_form_provider.dart';
import '../application/tasks_provider.dart';
import 'widgets/assignment_form.dart';
import 'widgets/recurrence_form.dart';
import 'widgets/task_visual_picker.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  const CreateEditTaskScreen({super.key, this.editTaskId});
  final String? editTaskId;

  @override
  ConsumerState<CreateEditTaskScreen> createState() =>
      _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  bool get isEditing => widget.editTaskId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();

    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final home = ref.read(currentHomeProvider).valueOrNull;
        if (home == null) return;
        final task = await ref
            .read(tasksRepositoryProvider)
            .fetchTask(home.id, widget.editTaskId!);
        ref.read(taskFormNotifierProvider.notifier).initEdit(task);
        _titleController.text = task.title;
        _descController.text = task.description ?? '';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formState = ref.watch(taskFormNotifierProvider);
    final homeAsync = ref.watch(currentHomeProvider);
    final authState = ref.watch(authProvider);
    final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.tasks_edit_title : l10n.tasks_create_title),
        actions: [
          if (formState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              key: const Key('save_task_button'),
              onPressed: () => _submit(context, uid),
              child: Text(l10n.save),
            ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (home) {
          if (home == null) return Center(child: Text(l10n.error_generic));

          final membershipsAsync =
              uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
          final memberships = membershipsAsync?.valueOrNull ?? [];
          final homeMembers = memberships
              .where((m) => m.homeId == home.id)
              .map((m) => m.homeId)
              .toList();

          final titleError = formState.fieldErrors['title'];
          final assigneesError = formState.fieldErrors['assignees'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TaskVisualPicker(
                selectedKind: formState.visualKind,
                selectedValue: formState.visualValue,
                onChanged: (kind, value) =>
                    ref.read(taskFormNotifierProvider.notifier).setVisual(kind, value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('task_title_field'),
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.tasks_field_title_hint,
                  border: const OutlineInputBorder(),
                  errorText: titleError != null
                      ? _titleErrorText(titleError, l10n)
                      : null,
                ),
                onChanged: (v) =>
                    ref.read(taskFormNotifierProvider.notifier).setTitle(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('task_desc_field'),
                controller: _descController,
                decoration: InputDecoration(
                  labelText: l10n.tasks_field_description_hint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (v) =>
                    ref.read(taskFormNotifierProvider.notifier).setDescription(v),
              ),
              const SizedBox(height: 16),
              const RecurrenceForm(key: Key('recurrence_form')),
              const SizedBox(height: 16),
              AssignmentForm(
                availableMembers: homeMembers,
                selectedOrder: formState.assignmentOrder,
                onChanged: (order) => ref
                    .read(taskFormNotifierProvider.notifier)
                    .setAssignmentOrder(order),
              ),
              if (assigneesError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.tasks_validation_no_assignees,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              Text(l10n.tasks_field_difficulty,
                  style: Theme.of(context).textTheme.titleSmall),
              Slider(
                key: const Key('difficulty_slider'),
                value: formState.difficultyWeight,
                min: 0.5,
                max: 3.0,
                divisions: 5,
                label: formState.difficultyWeight.toStringAsFixed(1),
                onChanged: (v) => ref
                    .read(taskFormNotifierProvider.notifier)
                    .setDifficultyWeight(v),
              ),
              if (formState.globalError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.error_generic,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                    key: const Key('task_form_error'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String? _titleErrorText(String code, AppLocalizations l10n) {
    if (code == 'tasks_validation_title_empty') {
      return l10n.tasks_validation_title_empty;
    }
    if (code == 'tasks_validation_title_too_long') {
      return l10n.tasks_validation_title_too_long;
    }
    return null;
  }

  Future<void> _submit(BuildContext context, String uid) async {
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;

    final taskId =
        await ref.read(taskFormNotifierProvider.notifier).save(home.id, uid);
    if (taskId != null && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
