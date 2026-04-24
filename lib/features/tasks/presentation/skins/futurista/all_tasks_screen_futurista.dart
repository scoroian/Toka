// lib/features/tasks/presentation/skins/futurista/all_tasks_screen_futurista.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/futurista/task_glyph.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_chip.dart';
import '../../../../../shared/widgets/futurista/tocka_top_bar.dart';
import '../../../../homes/application/current_home_provider.dart';
import '../../../../members/application/members_provider.dart';
import '../../../../members/domain/member.dart';
import '../../../application/all_tasks_view_model.dart';
import '../../../domain/recurrence_rule.dart';
import '../../../domain/task.dart';

/// Filtros visuales de la pantalla de tareas futurista. No afectan al VM;
/// solo re-filtran la lista en cliente. La search box es mockup visual.
enum _TaskListFilter { all, mine, dueSoon, weekly, monthly }

/// State provider local de pantalla para el filtro activo de chips.
final _taskListFilterProvider =
    StateProvider<_TaskListFilter>((_) => _TaskListFilter.all);

class AllTasksScreenFuturista extends ConsumerWidget {
  const AllTasksScreenFuturista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = ref.watch(allTasksViewModelProvider);
    final currentFilter = ref.watch(_taskListFilterProvider);

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
            TockaTopBar(homeName: homeName, members: topBarMembers),
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
                  TockaBtn(
                    variant: TockaBtnVariant.soft,
                    size: TockaBtnSize.sm,
                    icon: const Icon(Icons.add),
                    onPressed: () => context.push(AppRoutes.createTask),
                    child: Text(l10n.tasks_create_title),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _SearchMock(cs: cs, dividerColor: theme.dividerColor),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip(
                    context, ref, _TaskListFilter.all, currentFilter, 'Todas'),
                  const SizedBox(width: 8),
                  _filterChip(
                    context, ref, _TaskListFilter.mine, currentFilter, 'Mías'),
                  const SizedBox(width: 8),
                  _filterChip(context, ref, _TaskListFilter.dueSoon,
                      currentFilter, 'Por vencer'),
                  const SizedBox(width: 8),
                  _filterChip(context, ref, _TaskListFilter.weekly,
                      currentFilter, 'Semanales'),
                  const SizedBox(width: 8),
                  _filterChip(context, ref, _TaskListFilter.monthly,
                      currentFilter, 'Mensuales'),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final task = tasks[i];
                      final assigneeName = _nicknameFor(
                          members, task.currentAssigneeUid);
                      return _TaskRowFuturista(
                        task: task,
                        assigneeName: assigneeName,
                        isMine: task.currentAssigneeUid == myUid,
                        onTap: () => context.push(
                          AppRoutes.taskDetail.replaceAll(':id', task.id),
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
    BuildContext context,
    WidgetRef ref,
    _TaskListFilter filter,
    _TaskListFilter current,
    String label,
  ) {
    return TockaChip(
      active: filter == current,
      onTap: () =>
          ref.read(_taskListFilterProvider.notifier).state = filter,
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
        return tasks
            .where((t) => t.nextDueAt.isBefore(horizon))
            .toList();
      case _TaskListFilter.weekly:
        return tasks
            .where((t) => t.recurrenceRule is WeeklyRule)
            .toList();
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

class _SearchMock extends StatelessWidget {
  const _SearchMock({required this.cs, required this.dividerColor});
  final ColorScheme cs;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'Buscar tareas...',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              letterSpacing: -0.1,
            ),
          ),
        ],
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
  });

  final Task task;
  final String assigneeName;
  final bool isMine;
  final VoidCallback onTap;

  TaskGlyphKind get _glyph {
    // Selección determinista basada en el hash del id.
    const kinds = TaskGlyphKind.values;
    return kinds[task.id.hashCode.abs() % kinds.length];
  }

  String get _recurrenceLabel {
    final r = task.recurrenceRule;
    return switch (r) {
      OneTimeRule() => 'Puntual',
      HourlyRule(every: final e) => '${e}h',
      DailyRule(every: final e) => e == 1 ? 'Diaria' : '${e}d',
      WeeklyRule() => 'Semanal',
      MonthlyFixedRule() || MonthlyNthRule() => 'Mensual',
      YearlyFixedRule() || YearlyNthRule() => 'Anual',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final glyphColor = isMine ? cs.primary : cs.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: glyphColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: glyphColor.withValues(alpha: 0.19),
                  ),
                ),
                child: Center(
                  child: TaskGlyph(kind: _glyph, color: glyphColor, size: 20),
                ),
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
              const SizedBox(width: 8),
              Text(
                _recurrenceLabel,
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
