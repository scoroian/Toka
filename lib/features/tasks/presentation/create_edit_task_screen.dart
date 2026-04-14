// lib/features/tasks/presentation/create_edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/create_edit_task_view_model.dart';
import 'widgets/assignment_form.dart';
import 'widgets/recurrence_form.dart';
import 'widgets/task_visual_picker.dart';
import 'widgets/upcoming_dates_preview.dart';

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

  Future<void> _pickTime(
      BuildContext context, CreateEditTaskViewModel vm) async {
    final initial = vm.fixedTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      vm.setFixedTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(createEditTaskViewModelProvider(widget.editTaskId));

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
              onPressed: vm.canSave ? vm.save : null,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Visual picker
          TaskVisualPicker(
            selectedKind: formState.visualKind,
            selectedValue: formState.visualValue,
            onChanged: vm.setVisual,
          ),
          const SizedBox(height: 12),

          // Título
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

          // Descripción
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

          // Recurrencia
          const RecurrenceForm(key: Key('recurrence_form')),
          const SizedBox(height: 16),

          // Hora fija
          SwitchListTile(
            key: const Key('fixed_time_toggle'),
            title: Text(l10n.tasks_fixed_time_label),
            value: vm.hasFixedTime,
            onChanged: vm.setHasFixedTime,
          ),
          if (vm.hasFixedTime) ...[
            ListTile(
              key: const Key('fixed_time_picker_tile'),
              leading: const Icon(Icons.access_time),
              title: Text(vm.fixedTime != null
                  ? vm.fixedTime!.format(context)
                  : l10n.tasks_fixed_time_pick),
              onTap: () => _pickTime(context, vm),
            ),
            if (vm.showApplyToday)
              CheckboxListTile(
                key: const Key('apply_today_checkbox'),
                title: Text(l10n.tasks_apply_today_label),
                value: vm.applyToday,
                onChanged: (v) => vm.setApplyToday(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
          ],
          const SizedBox(height: 16),

          // Miembros (reordenables)
          AssignmentForm(
            key: const Key('assignment_form'),
            members: vm.orderedMembers,
            onToggle: vm.toggleMember,
            onReorder: vm.reorderMember,
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

          // Dificultad
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

          // Fechas próximas
          if (vm.upcomingDates.isNotEmpty) ...[
            const SizedBox(height: 16),
            UpcomingDatesPreview(
              key: const Key('upcoming_dates_preview'),
              dates: vm.upcomingDates,
            ),
          ],

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
