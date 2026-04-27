// lib/features/tasks/presentation/skins/futurista/create_edit_task_screen_futurista.dart
//
// Pantalla Crear/Editar tarea en skin Futurista. Consume el mismo
// `CreateEditTaskViewModel` que `CreateEditTaskScreenV2` (mismo notifier y
// `TaskFormNotifier`) y sólo cambia la presentación. Layout:
//
//   1. Header row: botón X (38x38) + título + botón Guardar (TockaBtn primary).
//   2. Icon + Title row: slot 56x56 con TaskVisualFuturista (respeta
//      visualKind/visualValue del task; fallback a glyph derivado de
//      recurrencia) + card con label TÍTULO y TextField.
//   3. Visual picker card: tabs Icono/Emoji con paletas idénticas a v2 —
//      12 Material Icons descriptivos y 24 emojis. UI con slots futuristas
//      (border + glow primary on selected).
//   4. Recurrencia card: 5 botones (Hora/Día/Semana/Mes/Año) + chips de semana +
//      preview de hora + acceso a RecurrenceForm completo por bottom sheet.
//   5. Reparto card: pill Premium + 2 cards (Rotación / Inteligente).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/free_limits.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../../../../shared/widgets/futurista/task_glyph.dart';
import '../../../../../shared/widgets/futurista/task_visual_futurista.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../../../shared/widgets/premium_upgrade_banner.dart';
import '../../../../homes/application/dashboard_provider.dart';
import '../../../application/create_edit_task_view_model.dart';
import '../../../application/task_form_provider.dart';
import '../../../domain/recurrence_rule.dart';
import '../../widgets/recurrence_form.dart';
import '../../widgets/upcoming_dates_preview.dart';

class CreateEditTaskScreenFuturista extends ConsumerStatefulWidget {
  const CreateEditTaskScreenFuturista({super.key, this.editTaskId});

  final String? editTaskId;

  @override
  ConsumerState<CreateEditTaskScreenFuturista> createState() =>
      _CreateEditTaskScreenFuturistaState();
}

class _CreateEditTaskScreenFuturistaState
    extends ConsumerState<CreateEditTaskScreenFuturista> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  static const _mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

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

  // ---------------------------------------------------------------------------
  // Recurrencia helpers — lectura y escritura en RecurrenceRule
  // ---------------------------------------------------------------------------

  String _recurrenceGroup(RecurrenceRule? rule) {
    if (rule == null) return 'daily';
    return switch (rule) {
      HourlyRule _ => 'hourly',
      DailyRule _ || OneTimeRule _ => 'daily',
      WeeklyRule _ => 'weekly',
      MonthlyFixedRule _ || MonthlyNthRule _ => 'monthly',
      YearlyFixedRule _ || YearlyNthRule _ => 'yearly',
    };
  }

  String _timeOf(RecurrenceRule rule) => switch (rule) {
        OneTimeRule r => r.time,
        HourlyRule r => r.startTime,
        DailyRule r => r.time,
        WeeklyRule r => r.time,
        MonthlyFixedRule r => r.time,
        MonthlyNthRule r => r.time,
        YearlyFixedRule r => r.time,
        YearlyNthRule r => r.time,
      };

  String _tzOf(RecurrenceRule rule) => switch (rule) {
        OneTimeRule r => r.timezone,
        HourlyRule r => r.timezone,
        DailyRule r => r.timezone,
        WeeklyRule r => r.timezone,
        MonthlyFixedRule r => r.timezone,
        MonthlyNthRule r => r.timezone,
        YearlyFixedRule r => r.timezone,
        YearlyNthRule r => r.timezone,
      };

  List<String> _weekdaysOf(RecurrenceRule? rule) {
    if (rule is WeeklyRule) return rule.weekdays;
    return const <String>[];
  }

  void _setRecurrenceGroup(String group, CreateEditTaskViewModel vm) {
    final current = vm.formState.recurrenceRule;
    final time = current != null ? _timeOf(current) : '09:00';
    final tz = current != null ? _tzOf(current) : 'Europe/Madrid';
    final RecurrenceRule next = switch (group) {
      'hourly' => RecurrenceRule.hourly(
          every: 1,
          startTime: time,
          timezone: tz,
        ),
      'weekly' => RecurrenceRule.weekly(
          weekdays: const ['MON'],
          time: time,
          timezone: tz,
        ),
      'monthly' => RecurrenceRule.monthlyFixed(
          day: 1,
          time: time,
          timezone: tz,
        ),
      'yearly' => RecurrenceRule.yearlyFixed(
          month: 1,
          day: 1,
          time: time,
          timezone: tz,
        ),
      _ => RecurrenceRule.daily(
          every: 1,
          time: time,
          timezone: tz,
        ),
    };
    vm.setRecurrenceRule(next);
  }

  void _toggleWeekday(String weekday, CreateEditTaskViewModel vm) {
    final current = vm.formState.recurrenceRule;
    if (current is! WeeklyRule) return;
    final list = List<String>.from(current.weekdays);
    if (list.contains(weekday)) {
      if (list.length > 1) list.remove(weekday);
    } else {
      list.add(weekday);
    }
    vm.setRecurrenceRule(RecurrenceRule.weekly(
      weekdays: list,
      time: current.time,
      timezone: current.timezone,
    ));
  }

  void _openRecurrenceSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Forzar tope máximo para que el contenido ocupe casi toda la pantalla
      // (evita que un RecurrenceForm largo quede recortado contra la
      // gesture area / banner superior del shell).
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      builder: (sheetCtx) => Padding(
        // bottomSheetSafeBottom suma viewInsets (teclado) + padding.bottom
        // (gesture area). Sin esto, el último botón del RecurrenceForm
        // queda tras la home indicator en dispositivos sin home button.
        padding: EdgeInsets.only(
          bottom: bottomSheetSafeBottom(sheetCtx, ref, hasNavBar: true),
        ),
        child: const SingleChildScrollView(child: RecurrenceForm()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final CreateEditTaskViewModel vm =
        ref.watch(createEditTaskViewModelProvider(widget.editTaskId));
    // Observar el state interno para reconstruir al cargar tarea en edit.
    ref.watch(createEditTaskViewModelNotifierProvider(widget.editTaskId));
    final formState = ref.watch(taskFormNotifierProvider);

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

    final dashboard = ref.watch(dashboardProvider).valueOrNull;
    final isPremium = dashboard?.premiumFlags.isPremium ?? true;
    final planCounters = dashboard?.planCounters;
    final currentRule = formState.recurrenceRule;
    final isOneTimeSelected = currentRule is OneTimeRule;
    // Free-plan gate (paridad con CreateEditTaskScreenV2). El backend y las
    // reglas Firestore son el backstop final.
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

    final group = _recurrenceGroup(formState.recurrenceRule);
    // Glyph fallback derivado de la recurrencia para cuando el usuario aún
    // no ha elegido visual (visualKind/visualValue vacíos al crear). Se
    // muestra en la cabecera y como icono por defecto.
    final fallbackGlyph = _glyphFromRecurrenceGroup(group);
    final disabledReason = _saveDisabledReason(
      formState,
      l10n,
      blockTasks: blockTasksLimit,
      blockRecurring: blockRecurringLimit,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header fijo: sacado del ListView para que los botones de cerrar
            // y guardar queden anclados arriba mientras el formulario scrollea.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _HeaderRow(
                title: vm.isEditing
                    ? l10n.tasks_edit_title
                    : l10n.tasks_create_title,
                onClose: () {
                  if (context.canPop()) context.pop();
                },
                onSave: (vm.canSave && !freeBlocked) ? vm.save : null,
                saveLabel: l10n.save,
                isLoading: formState.isLoading,
                disabledReason: disabledReason,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  adAwareBottomPadding(context, ref, extra: 16),
                ),
                children: [
                  if (freeBlocked) ...[
                    PremiumUpgradeBanner(
                      key: const Key('free_limit_banner'),
                      message: blockTasksLimit
                          ? l10n.free_limit_tasks_reached
                          : l10n.free_limit_recurring_reached,
                      cta: l10n.free_go_premium_cta,
                      ctaKey: const Key('free_limit_banner_cta'),
                      onCta: () => context.push(AppRoutes.paywall),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _IconTitleRow(
                    controller: _titleController,
                    visualKind: formState.visualKind,
                    visualValue: formState.visualValue,
                    fallbackGlyph: fallbackGlyph,
                    onChanged: vm.setTitle,
                    hint: l10n.tasks_field_title_hint,
                  ),
                  const SizedBox(height: 12),
                  _DescriptionCard(
                    controller: _descController,
                    onChanged: vm.setDescription,
                    hint: l10n.tasks_field_description_hint,
                  ),
                  const SizedBox(height: 12),
                  // Picker dual emoji/icono — paridad con TaskVisualPicker
                  // de v2, mismas paletas, callbacks (`emoji`,emoji) y
                  // (`icon`,codePoint). UI con cards futuristas + chips
                  // mono uppercase como tabs.
                  _VisualPickerCardFuturista(
                    visualKind: formState.visualKind,
                    visualValue: formState.visualValue,
                    onChanged: vm.setVisual,
                  ),
                  const SizedBox(height: 12),
                  _RecurrenceCard(
                    group: group,
                    rule: formState.recurrenceRule,
                    weekdays: _weekdaysOf(formState.recurrenceRule),
                    time: formState.recurrenceRule != null
                        ? _timeOf(formState.recurrenceRule!)
                        : '—',
                    onSelectGroup: (g) => _setRecurrenceGroup(g, vm),
                    onToggleWeekday: (w) => _toggleWeekday(w, vm),
                    onOpenSheet: _openRecurrenceSheet,
                  ),
                  const SizedBox(height: 12),
                  _AssignmentCard(
                    mode: formState.assignmentMode,
                    onSelect: vm.setAssignmentMode,
                    isPremium: isPremium,
                  ),
                  const SizedBox(height: 12),
                  // Card "ASIGNADOS": chips toggle por miembro del hogar.
                  // Sin esto, `assignmentOrder` queda vacío y `vm.canSave`
                  // siempre es false, dejando el botón Guardar deshabilitado
                  // sin pista visible al usuario (paridad funcional con el
                  // AssignmentForm de la skin v2).
                  _AssignedMembersCard(
                    members: vm.orderedMembers,
                    onToggle: vm.toggleMember,
                    emptyHint: l10n.tasks_validation_no_assignees,
                  ),
                  const SizedBox(height: 12),
                  _OnMissCardFuturista(
                    vm: vm,
                    label: l10n.task_on_miss_label,
                    sameLabel: l10n.task_on_miss_same_assignee,
                    nextLabel: l10n.task_on_miss_next_rotation,
                    requiresTwoHint: l10n.tasks_rotation_requires_two_members,
                  ),
                  const SizedBox(height: 12),
                  _DifficultyCard(
                    value: formState.difficultyWeight,
                    onChanged: vm.setDifficultyWeight,
                    label: l10n.tasks_field_difficulty,
                  ),
                  if (vm.upcomingDates.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    UpcomingDatesPreview(
                      key: const Key('upcoming_dates_preview'),
                      dates: vm.upcomingDates,
                      recurrenceRule: formState.recurrenceRule,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Glyph fallback por familia de recurrencia, para que la cabecera muestre
  /// algo "futurista" mientras el usuario no haya elegido icono/emoji.
  TaskGlyphKind _glyphFromRecurrenceGroup(String group) {
    switch (group) {
      case 'hourly':
        return TaskGlyphKind.arcs;
      case 'weekly':
        return TaskGlyphKind.hex;
      case 'monthly':
        return TaskGlyphKind.diamond;
      case 'yearly':
        return TaskGlyphKind.star4;
      case 'daily':
      default:
        return TaskGlyphKind.ring;
    }
  }

  /// Mensaje humano explicando por qué `vm.canSave` es false. Vacío cuando
  /// el formulario está listo para guardar. Paridad con la skin v2.
  String _saveDisabledReason(
    TaskFormState state,
    AppLocalizations l10n, {
    bool blockTasks = false,
    bool blockRecurring = false,
  }) {
    if (blockTasks) return l10n.free_limit_tasks_reached;
    if (blockRecurring) return l10n.free_limit_recurring_reached;
    if (state.title.trim().isEmpty) return l10n.tasks_validation_title_empty;
    if (state.assignmentOrder.isEmpty) {
      return l10n.tasks_validation_no_assignees;
    }
    return '';
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.onClose,
    required this.onSave,
    required this.saveLabel,
    required this.isLoading,
    this.disabledReason = '',
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool isLoading;

  /// Texto explicando por qué `onSave` es null (campo faltante). Cuando no
  /// está vacío, se pinta debajo del header como microcopy para que el
  /// usuario entienda qué hacer y se envuelve el botón Save en un Tooltip
  /// con el mismo mensaje.
  final String disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final saveButton = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : TockaBtn(
            key: const Key('fut_btn_save'),
            variant: TockaBtnVariant.primary,
            size: TockaBtnSize.sm,
            onPressed: onSave,
            child: Text(saveLabel),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            InkWell(
              key: const Key('fut_btn_close'),
              onTap: onClose,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Icon(Icons.close, size: 20, color: cs.onSurface),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            if (!isLoading && disabledReason.isNotEmpty)
              Tooltip(message: disabledReason, child: saveButton)
            else
              saveButton,
          ],
        ),
        if (disabledReason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 4),
            child: Text(
              disabledReason,
              key: const Key('fut_save_disabled_reason'),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: cs.error,
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Icon + Title row
// -----------------------------------------------------------------------------

class _IconTitleRow extends StatelessWidget {
  const _IconTitleRow({
    required this.controller,
    required this.visualKind,
    required this.visualValue,
    required this.fallbackGlyph,
    required this.onChanged,
    required this.hint,
  });

  final TextEditingController controller;
  final String visualKind;
  final String visualValue;
  final TaskGlyphKind fallbackGlyph;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Slot 56x56 con border + glow primario; muestra el visual elegido
          // por el usuario o el glyph fallback derivado de recurrencia.
          TaskVisualFuturista(
            visualKind: visualKind,
            visualValue: visualValue,
            color: cs.primary,
            size: 26,
            slotSize: 56,
            slotRadius: 16,
            glow: true,
            fallbackGlyph: fallbackGlyph,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).tasks_section_label_title,
                    style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.42),
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    key: const Key('task_title_field'),
                    controller: controller,
                    onChanged: onChanged,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Visual picker card — emoji + Material Icons (paridad con TaskVisualPicker
// de v2). Mismas paletas, callbacks `setVisual('emoji', emoji)` /
// `setVisual('icon', codePoint.toString())`. UI con dos chips mono uppercase
// que actúan como tabs y un grid de slots 36×36 estilo futurista.
// -----------------------------------------------------------------------------

class _VisualPickerCardFuturista extends StatefulWidget {
  const _VisualPickerCardFuturista({
    required this.visualKind,
    required this.visualValue,
    required this.onChanged,
  });

  final String visualKind;
  final String visualValue;
  final void Function(String kind, String value) onChanged;

  // Emojis y Material Icons EXACTAMENTE iguales que los de v2 para que un
  // mismo task se vea idéntico al alternar de skin (ver task_visual_picker.dart).
  static const _emojis = <String>[
    '🏠', '🍽️', '🧹', '🧺', '🛒', '🌿', '🐾', '🚗',
    '💰', '🔧', '📦', '🗑️', '🛁', '🪴', '🧴', '🍳',
    '🥗', '🧃', '☕', '🍰', '🛋️', '🪟', '🚿', '🪣',
  ];

  static const _iconData = <IconData>[
    Icons.home,
    Icons.kitchen,
    Icons.local_laundry_service,
    Icons.cleaning_services,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.pets,
    Icons.yard,
    Icons.build,
    Icons.recycling,
    Icons.bathtub,
    Icons.wb_sunny,
  ];

  @override
  State<_VisualPickerCardFuturista> createState() =>
      _VisualPickerCardFuturistaState();
}

class _VisualPickerCardFuturistaState
    extends State<_VisualPickerCardFuturista> {
  // Tab activa: 'icon' (Material) o 'emoji'. Se inicializa según el visual
  // actual del task; si está vacío arrancamos en 'icon' por consistencia
  // con el orden de tabs del v2 (allí el primero era emoji, pero icon es
  // más legible en la skin futurista — decisión deliberada).
  late String _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.visualKind == 'emoji' ? 'emoji' : 'icon';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header VISUAL + tabs Iconos / Emojis con chips mono.
          Row(
            children: [
              Text(
                l10n.tasks_section_label_visual,
                style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              _PickerTab(
                key: const Key('fut_visual_tab_icon'),
                label: 'Icono',
                active: _tab == 'icon',
                onTap: () => setState(() => _tab = 'icon'),
              ),
              const SizedBox(width: 6),
              _PickerTab(
                key: const Key('fut_visual_tab_emoji'),
                label: 'Emoji',
                active: _tab == 'emoji',
                onTap: () => setState(() => _tab = 'emoji'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_tab == 'icon')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in _VisualPickerCardFuturista._iconData)
                  _IconSlotFuturista(
                    key: Key('fut_icon_${icon.codePoint}'),
                    icon: icon,
                    selected: widget.visualKind == 'icon' &&
                        widget.visualValue == icon.codePoint.toString(),
                    onTap: () =>
                        widget.onChanged('icon', icon.codePoint.toString()),
                  ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _VisualPickerCardFuturista._emojis)
                  _EmojiSlotFuturista(
                    key: Key('fut_emoji_$e'),
                    emoji: e,
                    selected: widget.visualKind == 'emoji' &&
                        widget.visualValue == e,
                    onTap: () => widget.onChanged('emoji', e),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PickerTab extends StatelessWidget {
  const _PickerTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? cs.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? cs.primary.withValues(alpha: 0.40)
                : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            color: active ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _IconSlotFuturista extends StatelessWidget {
  const _IconSlotFuturista({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = selected
        ? cs.primary.withValues(alpha: 0.14)
        : theme.scaffoldBackgroundColor;
    final borderColor = selected
        ? cs.primary.withValues(alpha: 0.40)
        : theme.dividerColor;
    final iconColor =
        selected ? cs.primary : cs.onSurface.withValues(alpha: 0.64);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.20),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}

class _EmojiSlotFuturista extends StatelessWidget {
  const _EmojiSlotFuturista({
    super.key,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = selected
        ? cs.primary.withValues(alpha: 0.14)
        : theme.scaffoldBackgroundColor;
    final borderColor = selected
        ? cs.primary.withValues(alpha: 0.40)
        : theme.dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.20),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Recurrence card
// -----------------------------------------------------------------------------

class _RecurrenceCard extends StatelessWidget {
  const _RecurrenceCard({
    required this.group,
    required this.rule,
    required this.weekdays,
    required this.time,
    required this.onSelectGroup,
    required this.onToggleWeekday,
    required this.onOpenSheet,
  });

  final String group;
  final RecurrenceRule? rule;
  final List<String> weekdays;
  final String time;
  final ValueChanged<String> onSelectGroup;
  final ValueChanged<String> onToggleWeekday;
  final VoidCallback onOpenSheet;

  // Listas dinámicas (no static const) — necesitan AppLocalizations para
  // los labels traducidos. Se reconstruyen cada build, OK para MVP: la
  // recurrence card sólo se rebuildea al cambiar selección.
  List<({String key, String label})> _groups(AppLocalizations l10n) =>
      <({String key, String label})>[
        (key: 'hourly', label: l10n.recurrence_label_hourly),
        (key: 'daily', label: l10n.recurrence_label_daily),
        (key: 'weekly', label: l10n.recurrence_label_weekly),
        (key: 'monthly', label: l10n.recurrence_label_monthly),
        (key: 'yearly', label: l10n.recurrence_label_yearly),
      ];

  List<({String code, String label})> _weekdayKeys(AppLocalizations l10n) =>
      <({String code, String label})>[
        (code: 'MON', label: l10n.weekday_mon_short),
        (code: 'TUE', label: l10n.weekday_tue_short),
        (code: 'WED', label: l10n.weekday_wed_short),
        (code: 'THU', label: l10n.weekday_thu_short),
        (code: 'FRI', label: l10n.weekday_fri_short),
        (code: 'SAT', label: l10n.weekday_sat_short),
        (code: 'SUN', label: l10n.weekday_sun_short),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final groups = _groups(l10n);
    final weekdayKeys = _weekdayKeys(l10n);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tasks_section_label_recurrence,
            style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
              color: cs.onSurface.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < groups.length; i++) ...[
                Expanded(
                  child: _GroupButton(
                    key: Key('fut_rec_${groups[i].key}'),
                    label: groups[i].label,
                    active: groups[i].key == group,
                    onTap: () => onSelectGroup(groups[i].key),
                  ),
                ),
                if (i < groups.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
          if (group == 'weekly') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final wd in weekdayKeys)
                  _WeekdayChip(
                    label: wd.label,
                    active: weekdays.contains(wd.code),
                    onTap: () => onToggleWeekday(wd.code),
                  ),
              ],
            ),
          ],
          if (rule != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: cs.onSurface.withValues(alpha: 0.64),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.task_due_at_label,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.64),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    time,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TockaBtn(
              key: const Key('fut_btn_recurrence_more'),
              variant: TockaBtnVariant.ghost,
              size: TockaBtnSize.sm,
              onPressed: onOpenSheet,
              child: Text(l10n.common_more_options),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupButton extends StatelessWidget {
  const _GroupButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = active ? cs.primary : theme.scaffoldBackgroundColor;
    final fg = active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.64);
    final border = active ? Colors.transparent : theme.dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = active
        ? cs.primary.withValues(alpha: 0.14)
        : theme.scaffoldBackgroundColor;
    final border = active
        ? cs.primary.withValues(alpha: 0.33)
        : theme.dividerColor;
    final fg = active ? cs.primary : cs.onSurface.withValues(alpha: 0.64);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Assignment card
// -----------------------------------------------------------------------------

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.mode,
    required this.onSelect,
    required this.isPremium,
  });

  final String mode;
  final ValueChanged<String> onSelect;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context).tasks_section_label_assignment,
                style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              if (!isPremium)
                TockaPill(
                  color: cs.primary,
                  child: Text(AppLocalizations.of(context).homes_plan_premium),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AssignmentOption(
                  key: const Key('fut_assign_rotation'),
                  icon: Icons.arrow_forward,
                  label: AppLocalizations.of(context).assignment_rotation,
                  selected: mode == 'basicRotation',
                  onTap: () => onSelect('basicRotation'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AssignmentOption(
                  key: const Key('fut_assign_smart'),
                  icon: Icons.auto_awesome,
                  label: AppLocalizations.of(context).assignment_smart,
                  selected: mode == 'smartDistribution',
                  onTap: () => onSelect('smartDistribution'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignmentOption extends StatelessWidget {
  const _AssignmentOption({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = selected
        ? cs.primary.withValues(alpha: 0.14)
        : theme.scaffoldBackgroundColor;
    final border = selected
        ? cs.primary.withValues(alpha: 0.33)
        : theme.dividerColor;
    final fg = selected ? cs.primary : cs.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Assigned members card
// -----------------------------------------------------------------------------

/// Card "ASIGNADOS" del formulario futurista. Lista los miembros del hogar
/// como chips toggle (avatar + nombre); pulsar uno lo añade/quita del
/// `assignmentOrder`. Esto es lo que destraba `vm.canSave`: sin al menos un
/// miembro asignado el botón Guardar permanece deshabilitado.
class _AssignedMembersCard extends StatelessWidget {
  const _AssignedMembersCard({
    required this.members,
    required this.onToggle,
    required this.emptyHint,
  });

  final List<MemberOrderItem> members;
  final ValueChanged<String> onToggle;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasAnyAssigned = members.any((m) => m.isAssigned);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).tasks_section_label_assigned,
            style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
              color: cs.onSurface.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 10),
          if (members.isEmpty)
            Text(
              '—',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in members)
                  _MemberChip(
                    key: Key('fut_assignee_${m.uid}'),
                    name: m.name,
                    selected: m.isAssigned,
                    position: m.isAssigned ? m.position + 1 : null,
                    onTap: () => onToggle(m.uid),
                  ),
              ],
            ),
          if (members.isNotEmpty && !hasAnyAssigned) ...[
            const SizedBox(height: 8),
            Text(
              emptyHint,
              key: const Key('fut_assignees_error'),
              style: TextStyle(fontSize: 12, color: cs.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    super.key,
    required this.name,
    required this.selected,
    required this.position,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final int? position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = selected
        ? cs.primary.withValues(alpha: 0.14)
        : theme.scaffoldBackgroundColor;
    final border = selected
        ? cs.primary.withValues(alpha: 0.40)
        : theme.dividerColor;
    final fg = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.75);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: Text(
                position != null
                    ? '$position'
                    : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Description card — paridad con campo descripción de v2
// -----------------------------------------------------------------------------

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).tasks_section_label_description,
            style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
              color: cs.onSurface.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('task_desc_field'),
            controller: controller,
            onChanged: onChanged,
            maxLines: 2,
            style: TextStyle(fontSize: 14, color: cs.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// On-miss card — paridad con _OnMissAssignSelector de v2
// -----------------------------------------------------------------------------

class _OnMissCardFuturista extends StatelessWidget {
  const _OnMissCardFuturista({
    required this.vm,
    required this.label,
    required this.sameLabel,
    required this.nextLabel,
    required this.requiresTwoHint,
  });

  final CreateEditTaskViewModel vm;
  final String label;
  final String sameLabel;
  final String nextLabel;
  final String requiresTwoHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final assignedCount = vm.orderedMembers.where((m) => m.isAssigned).length;
    if (assignedCount == 0) return const SizedBox.shrink();
    final isEnabled = assignedCount >= 2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
              color: cs.onSurface.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OnMissOption(
                  key: const Key('on_miss_assign_same'),
                  icon: Icons.person_outline,
                  label: sameLabel,
                  selected: vm.onMissAssign == 'sameAssignee',
                  onTap: isEnabled
                      ? () => vm.setOnMissAssign('sameAssignee')
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OnMissOption(
                  key: const Key('on_miss_assign_next'),
                  icon: Icons.swap_horiz,
                  label: nextLabel,
                  selected: vm.onMissAssign == 'nextInRotation',
                  onTap: isEnabled
                      ? () => vm.setOnMissAssign('nextInRotation')
                      : null,
                ),
              ),
            ],
          ),
          if (!isEnabled) ...[
            const SizedBox(height: 8),
            Text(
              requiresTwoHint,
              key: const Key('rotation_requires_two_hint'),
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnMissOption extends StatelessWidget {
  const _OnMissOption({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final disabled = onTap == null;
    final bg = selected
        ? cs.primary.withValues(alpha: 0.14)
        : theme.scaffoldBackgroundColor;
    final border = selected
        ? cs.primary.withValues(alpha: 0.40)
        : theme.dividerColor;
    final fg = disabled
        ? cs.onSurface.withValues(alpha: 0.32)
        : (selected ? cs.primary : cs.onSurface);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Difficulty card — paridad con Slider de dificultad de v2
// -----------------------------------------------------------------------------

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.toUpperCase(),
                style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          Slider(
            key: const Key('difficulty_slider'),
            value: value,
            min: 0.5,
            max: 3.0,
            divisions: 5,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// Evita unused_import si en el futuro se elimina el uso de HapticFeedback.
// ignore: unused_element
void _keepHaptics() => HapticFeedback.selectionClick();
