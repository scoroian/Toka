// lib/features/tasks/presentation/skins/futurista/all_tasks_screen_futurista.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/free_limits.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/task_glyph.dart';
import '../../../../../shared/widgets/futurista/task_visual_futurista.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_chip.dart';
import '../../../../../shared/widgets/futurista/tocka_top_bar.dart';
import '../../../../homes/application/current_home_provider.dart';
import '../../../../homes/application/dashboard_provider.dart';
import '../../../../homes/presentation/home_selector_widget.dart';
import '../../../../members/application/members_provider.dart';
import '../../../../members/domain/member.dart';
import '../../../application/all_tasks_view_model.dart';
import '../../../domain/recurrence_rule.dart';
import '../../../domain/task.dart';
import '../../../domain/task_status.dart';
import '../../widgets/unfreeze_blocked_dialog.dart';

/// Filtros visuales secundarios (cliente-side) de la pantalla de tareas
/// futurista. El filtro primario Activas/Congeladas vive en el VM via
/// `vm.setStatusFilter`.
enum _TaskListFilter { all, mine, dueSoon, weekly, monthly }

final _taskListFilterProvider =
    StateProvider<_TaskListFilter>((_) => _TaskListFilter.all);

class AllTasksScreenFuturista extends ConsumerStatefulWidget {
  const AllTasksScreenFuturista({super.key});

  @override
  ConsumerState<AllTasksScreenFuturista> createState() =>
      _AllTasksScreenFuturistaState();
}

class _AllTasksScreenFuturistaState
    extends ConsumerState<AllTasksScreenFuturista> {
  Future<void> _handleToggleFreeze(
      AllTasksViewModel vm, Task task) async {
    final dashboard = ref.read(dashboardProvider).valueOrNull;
    final isPremium = dashboard?.premiumFlags.isPremium ?? true;
    final planCounters = dashboard?.planCounters;
    final isUnfreezing = task.status == TaskStatus.frozen;
    if (isUnfreezing &&
        !isPremium &&
        planCounters != null &&
        planCounters.activeTasks >= FreeLimits.maxActiveTasks) {
      await showUnfreezeBlockedDialog(
        context,
        current: planCounters.activeTasks,
        limit: FreeLimits.maxActiveTasks,
      );
      return;
    }
    await vm.toggleFreeze(task);
  }

  Future<bool> _confirmDelete(AppLocalizations l10n) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.tasks_delete_confirm_title),
          content: Text(l10n.tasks_delete_confirm_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              key: const Key('btn_delete_confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      ) ??
      false;

  Future<bool> _confirmBulkDelete(AppLocalizations l10n, int count) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.tasks_bulk_delete_confirm_title(count)),
          content: Text(l10n.tasks_bulk_delete_confirm_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = ref.watch(allTasksViewModelProvider);
    final currentFilter = ref.watch(_taskListFilterProvider);
    final statusFilter =
        vm.viewData.valueOrNull?.filter.status ?? TaskStatus.active;

    final homeAsync = ref.watch(currentHomeProvider);
    final homeName = homeAsync.valueOrNull?.name ?? '';
    final homeId = homeAsync.valueOrNull?.id;
    final membersAsync = homeId == null
        ? const AsyncValue<List<Member>>.data(<Member>[])
        : ref.watch(homeMembersProvider(homeId));
    final members = membersAsync.valueOrNull ?? const <Member>[];
    final topBarMembers = members
        .map<MemberAvatar>((m) => (name: m.nickname, color: cs.primary))
        .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TockaTopBar(
              homeName: homeName,
              members: topBarMembers,
              onHomeTap: () => showHomeSelectorSheet(context, ref),
            ),
            // Header — varía según modo selección, paridad con AllTasksScreenV2.
            if (vm.isSelectionMode)
              _SelectionHeader(
                count: vm.selectedIds.length,
                onClose: vm.clearSelection,
                onBulkFreeze: () async => vm.bulkFreeze(),
                onBulkDelete: () async {
                  final ok = await _confirmBulkDelete(
                    l10n,
                    vm.selectedIds.length,
                  );
                  if (ok && mounted) await vm.bulkDelete();
                },
                countLabel:
                    l10n.tasks_selection_count(vm.selectedIds.length),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tasks_title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (vm.viewData.valueOrNull?.canManage == true)
                      TockaBtn(
                        key: const Key('create_task_fab'),
                        variant: TockaBtnVariant.soft,
                        size: TockaBtnSize.sm,
                        icon: const Icon(Icons.add),
                        onPressed: () => context.push(AppRoutes.createTask),
                        child: Text(l10n.tasks_create_title),
                      ),
                  ],
                ),
              ),
            if (!vm.isSelectionMode) ...[
              // Filtro primario Activas/Congeladas — paridad con _FilterBarV2.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _StatusChip(
                      key: const Key('filter_active'),
                      label: l10n.tasks_section_active,
                      active: statusFilter == TaskStatus.active,
                      onTap: () => vm.setStatusFilter(TaskStatus.active),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      key: const Key('filter_frozen'),
                      label: l10n.tasks_section_frozen,
                      active: statusFilter == TaskStatus.frozen,
                      onTap: () => vm.setStatusFilter(TaskStatus.frozen),
                    ),
                  ],
                ),
              ),
              // Chips secundarios cliente-side (UI extra).
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip(ref, _TaskListFilter.all, currentFilter,
                        l10n.tasks_filter_all),
                    const SizedBox(width: 8),
                    _filterChip(ref, _TaskListFilter.mine, currentFilter,
                        l10n.tasks_filter_mine),
                    const SizedBox(width: 8),
                    _filterChip(ref, _TaskListFilter.dueSoon, currentFilter,
                        l10n.tasks_filter_due_soon),
                    const SizedBox(width: 8),
                    _filterChip(ref, _TaskListFilter.weekly, currentFilter,
                        l10n.tasks_filter_weekly_chip),
                    const SizedBox(width: 8),
                    _filterChip(ref, _TaskListFilter.monthly, currentFilter,
                        l10n.tasks_filter_monthly_chip),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: vm.viewData.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.error_generic)),
                data: (data) {
                  if (data == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.tasks_no_home_title,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  final myUid = data.uid;
                  final tasks = _applyFilter(data.tasks, currentFilter, myUid);
                  if (tasks.isEmpty) {
                    return Center(
                      key: const Key('tasks_empty_state'),
                      child: Text(
                        l10n.tasks_empty_title,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.separated(
                    key: const Key('tasks_list'),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom: adAwareBottomPadding(context, ref, extra: 16),
                    ),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final task = tasks[i];
                      final assigneeName =
                          _nicknameFor(members, task.currentAssigneeUid);
                      if (vm.isSelectionMode) {
                        return _SelectableTaskRow(
                          task: task,
                          assigneeName: assigneeName,
                          isMine: task.currentAssigneeUid == myUid,
                          isSelected: vm.selectedIds.contains(task.id),
                          onTap: () => vm.toggleSelection(task.id),
                        );
                      }
                      return Dismissible(
                        key: Key('dismissible_${task.id}'),
                        background: _FreezeBackground(l10n: l10n, cs: cs),
                        secondaryBackground:
                            _DeleteBackground(l10n: l10n, cs: cs),
                        confirmDismiss: (dir) async {
                          if (dir == DismissDirection.startToEnd) {
                            await _handleToggleFreeze(vm, task);
                            return false;
                          }
                          return _confirmDelete(l10n);
                        },
                        onDismissed: (dir) async {
                          if (dir == DismissDirection.endToStart) {
                            await vm.deleteTask(task);
                          }
                        },
                        child: _TaskRowFuturista(
                          task: task,
                          assigneeName: assigneeName,
                          isMine: task.currentAssigneeUid == myUid,
                          onTap: () => context.push(
                            AppRoutes.taskDetail.replaceAll(':id', task.id),
                          ),
                          onLongPress: () => vm.toggleSelection(task.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    WidgetRef ref,
    _TaskListFilter filter,
    _TaskListFilter current,
    String label,
  ) {
    return TockaChip(
      active: filter == current,
      onTap: () => ref.read(_taskListFilterProvider.notifier).state = filter,
      child: Text(label),
    );
  }

  List<Task> _applyFilter(
      List<Task> tasks, _TaskListFilter filter, String myUid) {
    switch (filter) {
      case _TaskListFilter.all:
        return tasks;
      case _TaskListFilter.mine:
        return tasks.where((t) => t.currentAssigneeUid == myUid).toList();
      case _TaskListFilter.dueSoon:
        final now = DateTime.now();
        final horizon = now.add(const Duration(hours: 48));
        return tasks.where((t) => t.nextDueAt.isBefore(horizon)).toList();
      case _TaskListFilter.weekly:
        return tasks.where((t) => t.recurrenceRule is WeeklyRule).toList();
      case _TaskListFilter.monthly:
        return tasks
            .where((t) =>
                t.recurrenceRule is MonthlyFixedRule ||
                t.recurrenceRule is MonthlyNthRule)
            .toList();
    }
  }

  String _nicknameFor(List<Member> members, String? uid) {
    if (uid == null) return '—';
    final m = members.where((m) => m.uid == uid).cast<Member?>().firstOrNull;
    return m?.nickname ?? '—';
  }
}

// -----------------------------------------------------------------------------
// Header de modo selección (paridad con AppBar de selección de v2)
// -----------------------------------------------------------------------------

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.count,
    required this.onClose,
    required this.onBulkFreeze,
    required this.onBulkDelete,
    required this.countLabel,
  });

  final int count;
  final String countLabel;
  final VoidCallback onClose;
  final VoidCallback onBulkFreeze;
  final VoidCallback onBulkDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          IconButton(
            key: const Key('exit_selection_button'),
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
          Expanded(
            child: Text(
              countLabel,
              key: const Key('selection_count_text'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            key: const Key('bulk_freeze_button'),
            icon: const Icon(Icons.pause_circle_outline),
            onPressed: onBulkFreeze,
          ),
          IconButton(
            key: const Key('bulk_delete_button'),
            icon: const Icon(Icons.delete_outline),
            onPressed: onBulkDelete,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Status chip Activas/Congeladas
// -----------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
    final bg = active
        ? cs.primary.withValues(alpha: 0.14)
        : theme.scaffoldBackgroundColor;
    final fg = active ? cs.primary : cs.onSurface.withValues(alpha: 0.64);
    final border = active
        ? cs.primary.withValues(alpha: 0.40)
        : theme.dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
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

// -----------------------------------------------------------------------------
// Backgrounds del Dismissible
// -----------------------------------------------------------------------------

class _FreezeBackground extends StatelessWidget {
  const _FreezeBackground({required this.l10n, required this.cs});
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cs.tertiary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Icon(Icons.pause_circle_outline, color: cs.tertiary),
            const SizedBox(width: 8),
            Text(
              l10n.tasks_action_freeze,
              style: TextStyle(
                color: cs.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.l10n, required this.cs});
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          children: [
            const Spacer(),
            Icon(Icons.delete_outline, color: cs.error),
            const SizedBox(width: 8),
            Text(
              l10n.delete,
              style: TextStyle(
                color: cs.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// Fila de tarea (modo selección)
// -----------------------------------------------------------------------------

class _SelectableTaskRow extends StatelessWidget {
  const _SelectableTaskRow({
    required this.task,
    required this.assigneeName,
    required this.isMine,
    required this.isSelected,
    required this.onTap,
  });

  final Task task;
  final String assigneeName;
  final bool isMine;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('selectable_task_${task.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.10)
                : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.45)
                  : theme.dividerColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TockaAvatar(
                name: assigneeName,
                color: cs.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskRowFuturista extends StatelessWidget {
  const _TaskRowFuturista({
    required this.task,
    required this.assigneeName,
    required this.isMine,
    required this.onTap,
    required this.onLongPress,
  });

  final Task task;
  final String assigneeName;
  final bool isMine;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  // Fallback glyph cuando el task no tiene visualKind/visualValue. Se deriva
  // de la recurrencia (consistente con today / detail) en vez del hash del
  // id, que daba glifos aleatorios sin significado.
  TaskGlyphKind get _fallbackGlyph {
    final r = task.recurrenceRule;
    if (r is HourlyRule) return TaskGlyphKind.arcs;
    if (r is DailyRule) return TaskGlyphKind.ring;
    if (r is WeeklyRule) return TaskGlyphKind.hex;
    if (r is MonthlyFixedRule || r is MonthlyNthRule) {
      return TaskGlyphKind.diamond;
    }
    if (r is YearlyFixedRule || r is YearlyNthRule) {
      return TaskGlyphKind.star4;
    }
    return TaskGlyphKind.dot;
  }

  String _recurrenceLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = task.recurrenceRule;
    return switch (r) {
      // Sufijos cortos para que la pill mono no rompa la fila. Se localizan
      // los textos pero los formatos compactos `'${e}h'` y `'${e}d'` se
      // mantienen — son neutros respecto al idioma.
      OneTimeRule() => l10n.recurrence_one_time,
      HourlyRule(every: final e) => '${e}h',
      DailyRule(every: final e) =>
        e == 1 ? l10n.recurrence_pill_daily : '${e}d',
      WeeklyRule() => l10n.recurrence_pill_weekly,
      MonthlyFixedRule() || MonthlyNthRule() => l10n.recurrence_pill_monthly,
      YearlyFixedRule() || YearlyNthRule() => l10n.recurrence_pill_yearly,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final glyphColor = isMine ? cs.primary : cs.onSurfaceVariant;
    final isFrozen = task.status == TaskStatus.frozen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMine
                  ? cs.primary.withValues(alpha: 0.22)
                  : theme.dividerColor,
            ),
          ),
          child: Row(
            children: [
              TaskVisualFuturista(
                visualKind: task.visualKind,
                visualValue: task.visualValue,
                color: glyphColor,
                size: 20,
                slotSize: 38,
                slotRadius: 10,
                fallbackGlyph: _fallbackGlyph,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (isFrozen) ...[
                const SizedBox(width: 6),
                Icon(Icons.ac_unit, size: 14, color: cs.onSurfaceVariant),
              ],
              const SizedBox(width: 8),
              Text(
                _recurrenceLabel(context),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'JetBrainsMono',
                  letterSpacing: 0.2,
                  color: cs.onSurface.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(width: 10),
              TockaAvatar(
                name: assigneeName,
                color: cs.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
