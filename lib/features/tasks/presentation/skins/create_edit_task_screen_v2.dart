// lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/free_limits.dart';
import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ad_aware_scaffold.dart';
import '../../../../shared/widgets/premium_upgrade_banner.dart';
import '../../../homes/application/current_home_provider.dart';
import '../../../homes/application/dashboard_provider.dart';
import '../../../members/application/members_provider.dart';
import '../../application/create_edit_task_view_model.dart';
import '../../application/task_form_provider.dart';
import '../../domain/recurrence_rule.dart';
import '../widgets/assignment_form.dart';
import '../widgets/recurrence_form.dart';
import '../widgets/task_visual_picker.dart';
import '../widgets/upcoming_dates_preview.dart';

class CreateEditTaskScreenV2 extends ConsumerStatefulWidget {
  const CreateEditTaskScreenV2({super.key, this.editTaskId});
  final String? editTaskId;

  @override
  ConsumerState<CreateEditTaskScreenV2> createState() =>
      _CreateEditTaskScreenV2State();
}

class _CreateEditTaskScreenV2State
    extends ConsumerState<CreateEditTaskScreenV2> {
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
    final CreateEditTaskViewModel vm =
        ref.watch(createEditTaskViewModelProvider(widget.editTaskId));

    final formState = ref.watch(taskFormNotifierProvider);

    // Observar el estado del VM notifier directamente para que el widget
    // reconstruya cuando cambie hasFixedTime (u otro campo del VM state).
    // Sin esto, createEditTaskViewModelProvider devuelve la misma referencia
    // del notifier → Riverpod no detecta cambio → widget no reconstruye →
    // SwitchListTile.value queda obsoleto y la semántica de accesibilidad
    // reporta checked=false aunque el estado real sea true. (Bug #13)
    ref.watch(createEditTaskViewModelNotifierProvider(widget.editTaskId));

    // Reconstruye cuando el hogar o su lista de miembros llegan de forma
    // asíncrona (apertura en frío): `vm.orderedMembers` los lee con read, así
    // que sin observar aquí la fuente la AssignmentForm se quedaría vacía
    // hasta la primera interacción que provoque otro rebuild.
    final membersHomeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    if (membersHomeId != null) {
      ref.watch(homeMembersProvider(membersHomeId));
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
    final recurrenceError = formState.fieldErrors['recurrence'];

    // Free-plan gate: lee planCounters/premiumFlags del dashboard. Si todavía
    // no ha llegado, asume Premium para no bloquear la primera render (el
    // backend y las reglas Firestore siempre son el backstop).
    final dashboard = ref.watch(dashboardProvider).valueOrNull;
    final isPremium = dashboard?.premiumFlags.isPremium ?? true;
    // Gate de la distribución inteligente. Pesimista mientras el dashboard no
    // ha llegado (default false) para que un hogar Free nunca vea el modo
    // smart como disponible; las reglas Firestore son el backstop definitivo.
    final canUseSmart =
        dashboard?.premiumFlags.canUseSmartDistribution ?? false;
    final planCounters = dashboard?.planCounters;
    final currentRule = formState.recurrenceRule;
    final isOneTimeSelected = currentRule is OneTimeRule;
    // En edición, la propia tarea ya está contada en los counters; la
    // consideramos "espacio libre" por simplicidad (si se desborda, el
    // backend/rules paran la escritura).
    final blockTasksLimit = !isPremium &&
        !vm.isEditing &&
        planCounters != null &&
        planCounters.activeTasks >= FreeLimits.maxActiveTasks;
    final blockRecurringLimit = !isPremium &&
        !vm.isEditing &&
        !isOneTimeSelected &&
        planCounters != null &&
        planCounters.automaticRecurringTasks >=
            FreeLimits.maxAutomaticRecurringTasks;
    final freeBlocked = blockTasksLimit || blockRecurringLimit;

    return AdAwareScaffold(
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
            Tooltip(
              message: vm.canSave && !freeBlocked
                  ? ''
                  : _saveDisabledReason(formState, l10n,
                      blockTasks: blockTasksLimit,
                      blockRecurring: blockRecurringLimit),
              child: TextButton(
                key: const Key('save_task_button'),
                onPressed: (vm.canSave && !freeBlocked) ? vm.save : null,
                child: Text(l10n.save),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16, 16, 16,
          AdAwareScaffold.bottomPaddingOf(context, ref),
        ),
        children: [
          if (freeBlocked)
            PremiumUpgradeBanner(
              key: const Key('free_limit_banner'),
              message: blockTasksLimit
                  ? l10n.free_limit_tasks_reached
                  : l10n.free_limit_recurring_reached,
              cta: l10n.free_go_premium_cta,
              ctaKey: const Key('free_limit_banner_cta'),
              onCta: () => context.push(AppRoutes.paywall),
            ),
          if (freeBlocked) const SizedBox(height: 12),

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
          ],
          // Checkbox "asignar también hoy": independiente del toggle "Hora fija".
          // Se muestra cuando la regla de recurrencia tiene una ocurrencia hoy
          // cuya hora ya pasó (si no, la tarea saltaría al siguiente periodo).
          if (vm.showApplyToday)
            CheckboxListTile(
              key: const Key('apply_today_checkbox'),
              title: Text(l10n.tasks_apply_today_label),
              value: vm.applyToday,
              onChanged: (v) => vm.setApplyToday(v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 16),

          // Miembros (reordenables)
          AssignmentForm(
            key: const Key('assignment_form'),
            members: vm.orderedMembers,
            onToggle: vm.toggleMember,
            onReorder: vm.reorderMember,
          ),
          // Error reactivo: se muestra en cuanto no hay ningún miembro seleccionado
          if (formState.assignmentOrder.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                l10n.tasks_validation_no_assignees,
                key: const Key('assignees_error'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),

          // Modo de asignación: rotación básica vs distribución inteligente
          // (Premium). Se persiste en task.assignmentMode y el backend lo usa
          // en applyTaskCompletion para elegir al siguiente responsable.
          _AssignmentModeSelector(vm: vm, canUseSmart: canUseSmart),

          // Comportamiento al vencer sin completar
          _OnMissAssignSelector(vm: vm),

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
              recurrenceRule: formState.recurrenceRule,
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

  String? _recurrenceErrorText(String code, AppLocalizations l10n) {
    if (code == 'tasks_validation_recurrence_required') {
      return l10n.tasks_validation_recurrence_required;
    }
    return null;
  }

  String _saveDisabledReason(
    TaskFormState state,
    AppLocalizations l10n, {
    bool blockTasks = false,
    bool blockRecurring = false,
  }) {
    if (blockTasks) return l10n.free_limit_tasks_reached;
    if (blockRecurring) return l10n.free_limit_recurring_reached;
    if (state.title.trim().isEmpty) return l10n.tasks_validation_title_empty;
    if (state.assignmentOrder.isEmpty) return l10n.tasks_validation_no_assignees;
    return '';
  }
}

/// Selector del modo de reparto del turno: rotación básica (orden fijo) vs
/// distribución inteligente (siguiente = miembro con menos carga reciente).
/// La opción smart está gated por Premium: si el hogar es Free se muestra con
/// candado y, al pulsarla, se abre el paywall en lugar de seleccionarla.
class _AssignmentModeSelector extends StatelessWidget {
  const _AssignmentModeSelector({required this.vm, required this.canUseSmart});
  final CreateEditTaskViewModel vm;
  final bool canUseSmart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assignedCount = vm.orderedMembers.where((m) => m.isAssigned).length;

    // Con 0 miembros asignados no tiene sentido elegir modo de reparto.
    if (assignedCount == 0) return const SizedBox.shrink();

    final mode = vm.formState.assignmentMode;
    // El reparto (básico o smart) solo importa con ≥2 miembros asignados.
    final isEnabled = assignedCount >= 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tasks_field_assignment_mode,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            key: const Key('assignment_mode_selector'),
            segments: [
              ButtonSegment(
                value: 'basicRotation',
                label: Text(l10n.tasks_assignment_basic_rotation),
                icon: const Icon(Icons.repeat),
              ),
              ButtonSegment(
                value: 'smartDistribution',
                label: Text(l10n.tasks_assignment_smart),
                icon: Icon(
                    canUseSmart ? Icons.auto_awesome : Icons.lock_outline),
              ),
            ],
            selected: {mode},
            onSelectionChanged: isEnabled
                ? (set) {
                    final picked = set.first;
                    // Gate Premium: no cambiamos el modo, abrimos el paywall.
                    if (picked == 'smartDistribution' && !canUseSmart) {
                      context.push(AppRoutes.paywall);
                      return;
                    }
                    vm.setAssignmentMode(picked);
                  }
                : null,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              !isEnabled
                  ? l10n.tasks_rotation_requires_two_members
                  : (canUseSmart
                      ? l10n.tasks_assignment_smart_hint
                      : l10n.tasks_assignment_premium_locked),
              key: const Key('assignment_mode_hint'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnMissAssignSelector extends StatelessWidget {
  const _OnMissAssignSelector({required this.vm});
  final CreateEditTaskViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assignedCount = vm.orderedMembers.where((m) => m.isAssigned).length;

    // Con 0 miembros no tiene sentido mostrar el selector
    if (assignedCount == 0) return const SizedBox.shrink();

    final isEnabled = assignedCount >= 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.task_on_miss_label,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            key: const Key('on_miss_assign_selector'),
            segments: [
              ButtonSegment(
                value: 'sameAssignee',
                label: Text(l10n.task_on_miss_same_assignee),
                icon: const Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: 'nextInRotation',
                label: Text(l10n.task_on_miss_next_rotation),
                icon: const Icon(Icons.swap_horiz),
              ),
            ],
            selected: {vm.onMissAssign},
            onSelectionChanged:
                isEnabled ? (set) => vm.setOnMissAssign(set.first) : null,
          ),
          if (!isEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                l10n.tasks_rotation_requires_two_members,
                key: const Key('rotation_requires_two_hint'),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
