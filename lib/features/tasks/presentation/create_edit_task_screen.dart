// lib/features/tasks/presentation/create_edit_task_screen.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../application/create_edit_task_view_model.dart';
import '../application/task_form_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
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
  bool _repairAttempted = false;

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

  /// Llama a la Cloud Function repairMemberDocument para crear el documento
  /// homes/{homeId}/members/{uid} si no existe (usuarios creados antes del fix).
  Future<void> _tryRepairMemberDocument(String homeId) async {
    if (_repairAttempted) return;
    _repairAttempted = true;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('repairMemberDocument')
          .call({'homeId': homeId});
      // Invalidar el provider para que re-lea la subcolección
      if (mounted) {
        ref.invalidate(homeMembersProvider(homeId));
      }
    } catch (_) {
      // Si falla la reparación no bloqueamos al usuario
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(createEditTaskViewModelProvider(widget.editTaskId));

    // Observamos el taskFormNotifierProvider directamente para que la pantalla
    // se reconstruya cada vez que cambia el estado del formulario (slider,
    // emoji picker, etc.). El wrapper createEditTaskViewModelProvider devuelve
    // siempre la misma instancia del notifier, por lo que Riverpod no detecta
    // cambio sin esta suscripción directa.
    final formState = ref.watch(taskFormNotifierProvider);

    final currentHomeAsync = ref.watch(currentHomeProvider);
    final homeId = currentHomeAsync.valueOrNull?.id;

    // Si currentHomeProvider todavía está cargando, propagamos ese estado
    // de carga para que no aparezca una lista vacía de miembros mientras
    // el provider resuelve el hogar actual.
    final membersAsync = currentHomeAsync.isLoading
        ? const AsyncValue<List<Member>>.loading()
        : homeId == null
            ? const AsyncValue<List<Member>>.data([])
            : ref.watch(homeMembersProvider(homeId));
    final members = membersAsync.valueOrNull ?? [];

    // Auto-reparación: si el stream de miembros termina de cargar y devuelve
    // lista vacía, significa que el documento homes/{homeId}/members/{uid}
    // no fue creado por la Cloud Function (bug histórico). Llamamos a la
    // función repairMemberDocument para crearlo.
    if (homeId != null) {
      ref.listen<AsyncValue<List<Member>>>(
        homeMembersProvider(homeId),
        (_, next) {
          if (!next.isLoading && next.valueOrNull?.isEmpty == true) {
            _tryRepairMemberDocument(homeId);
          }
        },
      );
    }

    ref.listen(
      createEditTaskViewModelNotifierProvider(widget.editTaskId),
      (prev, next) {
        final notifier = ref.read(
          createEditTaskViewModelNotifierProvider(widget.editTaskId).notifier,
        );
        if (notifier.loadedTitle != null &&
            _titleController.text != notifier.loadedTitle) {
          _titleController.text = notifier.loadedTitle!;
        }
        if (notifier.loadedDescription != null &&
            _descController.text != notifier.loadedDescription) {
          _descController.text = notifier.loadedDescription!;
        }
        if (notifier.savedSuccessfully && context.canPop()) {
          context.pop();
        }
      },
    );

    final titleError = formState.fieldErrors['title'];
    final assigneesError = formState.fieldErrors['assignees'];
    final recurrenceError = formState.fieldErrors['recurrence'];

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
          if (recurrenceError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _recurrenceErrorText(recurrenceError, l10n) ?? recurrenceError,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12),
                key: const Key('recurrence_error'),
              ),
            ),
          const SizedBox(height: 16),
          if (membersAsync.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            AssignmentForm(
              availableMembers: members,
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

  String? _recurrenceErrorText(String code, AppLocalizations l10n) {
    if (code == 'tasks_validation_recurrence_required') {
      return l10n.tasks_validation_recurrence_required;
    }
    return null;
  }
}
