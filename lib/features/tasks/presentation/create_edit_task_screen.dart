// lib/features/tasks/presentation/create_edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/create_edit_task_view_model.dart';
import '../../homes/application/current_home_provider.dart';
import '../../members/application/members_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
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
    final vm = ref.watch(createEditTaskViewModelProvider(widget.editTaskId));
    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    final memberUids = homeId == null
        ? <String>[]
        : ref.watch(homeMembersProvider(homeId)).valueOrNull
                ?.map((m) => m.uid)
                .toList() ??
            [];

    ref.listen<CreateEditTaskViewModel>(
      createEditTaskViewModelProvider(widget.editTaskId),
      (prev, next) {
        if (next.loadedTitle != null &&
            next.loadedTitle != prev?.loadedTitle) {
          _titleController.text = next.loadedTitle!;
        }
        if (next.loadedDescription != null &&
            next.loadedDescription != prev?.loadedDescription) {
          _descController.text = next.loadedDescription!;
        }
        if (next.savedSuccessfully) {
          Navigator.of(context).pop();
        }
      },
    );

    final formState = vm.formState;
    final titleError = formState.fieldErrors['title'];
    final assigneesError = formState.fieldErrors['assignees'];

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isEditing
            ? l10n.tasks_edit_title
            : l10n.tasks_create_title),
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
              onPressed: vm.save,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TaskVisualPicker(
            selectedKind: formState.visualKind,
            selectedValue: formState.visualValue,
            onChanged: vm.setVisual,
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
            onChanged: vm.setTitle,
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
            onChanged: vm.setDescription,
          ),
          const SizedBox(height: 16),
          const RecurrenceForm(key: Key('recurrence_form')),
          const SizedBox(height: 16),
          AssignmentForm(
            availableMembers: memberUids,
            selectedOrder: formState.assignmentOrder,
            onChanged: vm.setAssignmentOrder,
          ),
          if (assigneesError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.tasks_validation_no_assignees,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12),
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
            onChanged: vm.setDifficultyWeight,
          ),
          if (formState.globalError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.error_generic,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                key: const Key('task_form_error'),
              ),
            ),
        ],
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
}
