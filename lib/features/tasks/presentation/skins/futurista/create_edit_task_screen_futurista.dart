// lib/features/tasks/presentation/skins/futurista/create_edit_task_screen_futurista.dart
//
// Pantalla Crear/Editar tarea en skin Futurista. Consume el mismo
// `CreateEditTaskViewModel` que `CreateEditTaskScreenV2` (mismo notifier y
// `TaskFormNotifier`) y sólo cambia la presentación. Layout según canvas
// `skin_futurista/screens-tareas.jsx`:
//
//   1. Header row: botón X (38x38) + título + botón Guardar (TockaBtn primary).
//   2. Icon + Title row: slot 56x56 con TaskGlyph + card con label TÍTULO y TextField.
//   3. Glyph palette card: 10 slots 36x36 (uno por TaskGlyphKind).
//   4. Recurrencia card: 5 botones (Hora/Día/Semana/Mes/Año) + chips de semana +
//      preview de hora + acceso a RecurrenceForm completo por bottom sheet.
//   5. Reparto card: pill Premium + 2 cards (Rotación / Inteligente).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/task_glyph.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../../homes/application/dashboard_provider.dart';
import '../../../application/create_edit_task_view_model.dart';
import '../../../application/task_form_provider.dart';
import '../../../domain/recurrence_rule.dart';
import '../../widgets/recurrence_form.dart';

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

  static const _mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  // Mapeo entre el `visualValue` persistido (string) y el `TaskGlyphKind` que
  // pinta el CustomPainter. Usamos el nombre del enum como clave estable.
  static const List<TaskGlyphKind> _glyphKinds = TaskGlyphKind.values;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
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
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
        if (notifier.savedSuccessfully && context.canPop()) {
          context.pop();
        }
      },
    );

    final dashboard = ref.watch(dashboardProvider).valueOrNull;
    final isPremium = dashboard?.premiumFlags.isPremium ?? true;

    final group = _recurrenceGroup(formState.recurrenceRule);
    final selectedGlyphKind = _glyphFromValue(formState.visualValue);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            adAwareBottomPadding(context, ref, extra: 16),
          ),
          children: [
            _HeaderRow(
              title: vm.isEditing
                  ? l10n.tasks_edit_title
                  : l10n.tasks_create_title,
              onClose: () {
                if (context.canPop()) context.pop();
              },
              onSave: vm.canSave ? vm.save : null,
              saveLabel: l10n.save,
              isLoading: formState.isLoading,
            ),
            const SizedBox(height: 14),
            _IconTitleRow(
              controller: _titleController,
              glyph: selectedGlyphKind,
              onChanged: vm.setTitle,
              hint: l10n.tasks_field_title_hint,
            ),
            const SizedBox(height: 12),
            _GlyphPaletteCard(
              selected: selectedGlyphKind,
              onSelect: (kind) => vm.setVisual('glyph', kind.name),
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
          ],
        ),
      ),
    );
  }

  TaskGlyphKind _glyphFromValue(String value) {
    // `visualValue` puede ser un emoji legacy o el nombre de un TaskGlyphKind.
    for (final k in _glyphKinds) {
      if (k.name == value) return k;
    }
    return TaskGlyphKind.ring;
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
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
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
        if (isLoading)
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          TockaBtn(
            key: const Key('fut_btn_save'),
            variant: TockaBtnVariant.primary,
            size: TockaBtnSize.sm,
            onPressed: onSave,
            child: Text(saveLabel),
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
    required this.glyph,
    required this.onChanged,
    required this.hint,
  });

  final TextEditingController controller;
  final TaskGlyphKind glyph;
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: TaskGlyph(kind: glyph, color: cs.primary, size: 26),
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
                    'TÍTULO',
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
// Glyph palette card
// -----------------------------------------------------------------------------

class _GlyphPaletteCard extends StatelessWidget {
  const _GlyphPaletteCard({
    required this.selected,
    required this.onSelect,
  });

  final TaskGlyphKind selected;
  final ValueChanged<TaskGlyphKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'VISUAL',
              style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
                color: cs.onSurface.withValues(alpha: 0.42),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in TaskGlyphKind.values)
                _GlyphSlot(
                  key: Key('fut_glyph_${kind.name}'),
                  kind: kind,
                  selected: kind == selected,
                  onTap: () => onSelect(kind),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlyphSlot extends StatelessWidget {
  const _GlyphSlot({
    super.key,
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final TaskGlyphKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = selected
        ? cs.primary.withValues(alpha: 0.10)
        : theme.scaffoldBackgroundColor;
    final borderColor = selected
        ? cs.primary.withValues(alpha: 0.33)
        : theme.dividerColor;
    final glyphColor =
        selected ? cs.primary : cs.onSurface.withValues(alpha: 0.64);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: TaskGlyph(kind: kind, color: glyphColor, size: 18),
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

  static const _groups = <({String key, String label})>[
    (key: 'hourly', label: 'Hora'),
    (key: 'daily', label: 'Día'),
    (key: 'weekly', label: 'Semana'),
    (key: 'monthly', label: 'Mes'),
    (key: 'yearly', label: 'Año'),
  ];

  static const _weekdayKeys = <({String code, String label})>[
    (code: 'MON', label: 'L'),
    (code: 'TUE', label: 'M'),
    (code: 'WED', label: 'X'),
    (code: 'THU', label: 'J'),
    (code: 'FRI', label: 'V'),
    (code: 'SAT', label: 'S'),
    (code: 'SUN', label: 'D'),
  ];

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
            'RECURRENCIA',
            style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
              color: cs.onSurface.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < _groups.length; i++) ...[
                Expanded(
                  child: _GroupButton(
                    key: Key('fut_rec_${_groups[i].key}'),
                    label: _groups[i].label,
                    active: _groups[i].key == group,
                    onTap: () => onSelectGroup(_groups[i].key),
                  ),
                ),
                if (i < _groups.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
          if (group == 'weekly') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final wd in _weekdayKeys)
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
                    'Vence a las',
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
              child: const Text('Más opciones'),
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
                'REPARTO',
                style: _CreateEditTaskScreenFuturistaState._mono.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              if (!isPremium)
                TockaPill(
                  color: cs.primary,
                  child: const Text('Premium'),
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
                  label: 'Rotación',
                  selected: mode == 'basicRotation',
                  onTap: () => onSelect('basicRotation'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AssignmentOption(
                  key: const Key('fut_assign_smart'),
                  icon: Icons.auto_awesome,
                  label: 'Inteligente',
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

// Evita unused_import si en el futuro se elimina el uso de HapticFeedback.
// ignore: unused_element
void _keepHaptics() => HapticFeedback.selectionClick();
