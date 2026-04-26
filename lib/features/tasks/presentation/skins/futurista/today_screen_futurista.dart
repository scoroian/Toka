// lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/futurista/futurista_colors.dart';
import '../../../../../core/utils/toka_dates.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/block_header.dart';
import '../../../../../shared/widgets/futurista/task_card_futurista.dart';
import '../../../../../shared/widgets/futurista/task_glyph.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../../../shared/widgets/futurista/tocka_top_bar.dart';
import '../../../../homes/application/current_home_provider.dart';
import '../../../../homes/domain/home.dart';
import '../../../../members/application/members_provider.dart';
import '../../../../members/domain/member.dart';
import '../../../application/today_view_model.dart';
import '../../../domain/home_dashboard.dart';
import '../../../domain/recurrence_order.dart';
import '../../widgets/complete_task_dialog.dart';
import '../../widgets/pass_turn_dialog.dart';
import '../../widgets/today_empty_state.dart';

/// Pantalla "Hoy" en el skin futurista (variante A — Pulso).
///
/// Consume el mismo `todayViewModelProvider` que `TodayScreenV2` y reutiliza
/// los dialogs `CompleteTaskDialog` y `PassTurnDialog`. Layout:
///
/// 1. `TockaTopBar` con nombre de hogar y avatars de miembros.
/// 2. Hero "Te toca ahora" cuando hay tarea asignada al usuario actual.
/// 3. Bloques por recurrencia (HORA, DÍA, SEMANA, MES, AÑO) con
///    `BlockHeader` + `TaskCardFuturista`.
/// 4. Bloque `HECHAS · HOY` con las tareas completadas del día.
/// El banner publicitario lo pinta el shell (`MainShellFuturista`), no esta
/// pantalla — paridad con `TodayScreenV2`.
class TodayScreenFuturista extends ConsumerWidget {
  const TodayScreenFuturista({super.key});

  Future<void> _onDone(
    BuildContext ctx,
    TodayViewModel vm,
    TaskPreview task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => CompleteTaskDialog(task: task, onConfirm: () {}),
    );
    if (confirmed == true && ctx.mounted) {
      await vm.completeTask(task.taskId);
    }
  }

  Future<void> _onPass(
    BuildContext ctx,
    TodayViewModel vm,
    TaskPreview task,
    String? uid,
  ) async {
    if (uid == null) return;
    final stats = await vm.fetchPassStats(uid);
    if (!ctx.mounted) return;
    String? reason;
    bool confirmed = false;
    await showDialog<void>(
      context: ctx,
      builder: (_) => PassTurnDialog(
        task: task,
        currentComplianceRate: stats.complianceBefore,
        estimatedComplianceAfter: stats.estimatedAfter,
        nextAssigneeName: null,
        onConfirm: (r) {
          confirmed = true;
          reason = r;
        },
      ),
    );
    if (confirmed && ctx.mounted) {
      await vm.passTurn(task.taskId, reason: reason);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final TodayViewModel vm = ref.watch(todayViewModelProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: vm.viewData.when(
          loading: () => const _FuturistaLoading(),
          error: (_, __) => _FuturistaError(
            message: l10n.error_generic,
            onRetry: vm.retry,
            retryLabel: l10n.retry,
          ),
          data: (data) {
            if (data == null) {
              return Column(
                children: [
                  _TopBarFromState(ref: ref),
                  const Expanded(child: TodayEmptyState()),
                ],
              );
            }

            final currentUid = data.currentUid;
            final heroTask = _pickHeroTask(data, currentUid);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _TopBarFromState(ref: ref)),
                if (heroTask != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _HeroTurn(
                        task: heroTask,
                        label: l10n.today_btn_done,
                        onDone: data.homeId.isNotEmpty
                            ? () => _onDone(context, vm, heroTask)
                            : null,
                        onPass: data.homeId.isNotEmpty
                            ? () => _onPass(
                                context, vm, heroTask, currentUid)
                            : null,
                      ),
                    ),
                  ),
                // Bloques por recurrencia (excluyendo hero, evitando duplicar).
                for (final recType in data.recurrenceOrder)
                  if ((data.grouped[recType]?.todos ?? const <TaskPreview>[])
                      .where((t) => t.taskId != heroTask?.taskId)
                      .isNotEmpty)
                    _recurrenceBlock(
                      context: context,
                      recType: recType,
                      todos: data.grouped[recType]!.todos
                          .where((t) => t.taskId != heroTask?.taskId)
                          .toList(),
                      currentUid: currentUid,
                      onDone: data.homeId.isNotEmpty
                          ? (t) => _onDone(context, vm, t)
                          : null,
                      onPass: data.homeId.isNotEmpty
                          ? (t) => _onPass(context, vm, t, currentUid)
                          : null,
                    ),
                // Bloque HECHAS · HOY: agrupar todas las done de todos los recs.
                if (_allDones(data).isNotEmpty)
                  _donesBlock(
                    context: context,
                    dones: _allDones(data),
                    l10n: l10n,
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: adAwareBottomPadding(context, ref, extra: 16),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------

  /// Escoge la primera tarea pendiente del usuario actual para el hero.
  TaskPreview? _pickHeroTask(TodayViewData data, String? currentUid) {
    if (currentUid == null) return null;
    for (final recType in data.recurrenceOrder) {
      final todos = data.grouped[recType]?.todos ?? const <TaskPreview>[];
      for (final t in todos) {
        if (t.currentAssigneeUid == currentUid) return t;
      }
    }
    return null;
  }

  List<DoneTaskPreview> _allDones(TodayViewData data) {
    final result = <DoneTaskPreview>[];
    for (final entry in data.grouped.values) {
      result.addAll(entry.dones);
    }
    return result;
  }

  Widget _recurrenceBlock({
    required BuildContext context,
    required String recType,
    required List<TaskPreview> todos,
    required String? currentUid,
    required void Function(TaskPreview)? onDone,
    required void Function(TaskPreview)? onPass,
  }) {
    final title = RecurrenceOrder.localizedTitle(context, recType);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: BlockHeader(label: title, count: todos.length),
          ),
        ),
        SliverList.separated(
          itemCount: todos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final t = todos[i];
            final isMine = t.currentAssigneeUid != null &&
                t.currentAssigneeUid == currentUid;
            final l10n = AppLocalizations.of(ctx);
            final actionable = _isActionable(t);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TaskCardFuturista(
                key: Key('task_card_fut_${t.taskId}'),
                title: t.title,
                assignee: t.currentAssigneeName ?? '—',
                assigneeColor: _colorFromUid(t.currentAssigneeUid),
                when: _whenLabel(ctx, t),
                glyph: _glyphForRecurrence(recType),
                mine: isMine,
                overdue: t.isOverdue,
                urgent: t.isOverdue,
                actionable: actionable,
                doneLabel: l10n.today_btn_done,
                onTap: () => ctx.push(
                  AppRoutes.taskDetail.replaceAll(':id', t.taskId),
                ),
                onComplete: onDone == null ? null : () => onDone(t),
                onPass: onPass == null ? null : () => onPass(t),
                onActionableHint: () => _snackNotYet(ctx, l10n, t),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _donesBlock({
    required BuildContext context,
    required List<DoneTaskPreview> dones,
    required AppLocalizations l10n,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: BlockHeader(
              label: '${l10n.today_section_done} · ${l10n.today_screen_title}',
              count: dones.length,
            ),
          ),
        ),
        SliverList.separated(
          itemCount: dones.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final d = dones[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TaskCardFuturista(
                key: Key('task_card_done_fut_${d.taskId}'),
                title: d.title,
                assignee: d.completedByName,
                assigneeColor: _colorFromUid(d.completedByUid),
                glyph: _glyphForRecurrence(d.recurrenceType),
                done: true,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Mapea tipo de recurrencia a un glyph estable y reconocible.
  TaskGlyphKind _glyphForRecurrence(String recType) {
    switch (recType) {
      case 'hourly':
        return TaskGlyphKind.arcs;
      case 'daily':
        return TaskGlyphKind.ring;
      case 'weekly':
        return TaskGlyphKind.hex;
      case 'monthly':
        return TaskGlyphKind.diamond;
      case 'yearly':
        return TaskGlyphKind.star4;
      case 'oneTime':
        return TaskGlyphKind.dot;
      default:
        return TaskGlyphKind.ring;
    }
  }

  /// Color estable por uid (fallback al primary). Evita depender de un provider
  /// adicional para el color de asignado; en el futuro se puede mapear desde
  /// `memberPreview`.
  Color _colorFromUid(String? uid) {
    if (uid == null || uid.isEmpty) return FuturistaColors.primary;
    final palette = <Color>[
      FuturistaColors.primary,
      FuturistaColors.primaryAlt,
      FuturistaColors.success,
      FuturistaColors.warning,
      FuturistaColors.error,
    ];
    final idx = uid.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    return palette[idx];
  }

  /// Etiqueta mono "HH:MM" / "Vencida" para la esquina derecha de la card.
  String? _whenLabel(BuildContext context, TaskPreview t) {
    final l10n = AppLocalizations.of(context);
    if (t.isOverdue) return l10n.today_overdue;
    final due = t.nextDueAt.toLocal();
    final hh = due.hour.toString().padLeft(2, '0');
    final mm = due.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Determina si la tarea puede completarse ahora según su tipo de
  /// recurrencia. Lógica idéntica a `_TodayTaskCardTodoV2State._isActionable`
  /// para mantener paridad con la skin v2.
  bool _isActionable(TaskPreview t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final due = t.nextDueAt;
    if (due.isBefore(n)) return true;
    switch (t.recurrenceType) {
      case 'hourly':
        final hourEnd = DateTime(n.year, n.month, n.day, n.hour + 1);
        return due.isBefore(hourEnd);
      case 'daily':
        final dayEnd = DateTime(n.year, n.month, n.day + 1);
        return due.isBefore(dayEnd);
      case 'weekly':
        final daysFromMonday = n.weekday - 1;
        final weekStart = DateTime(n.year, n.month, n.day - daysFromMonday);
        final weekEnd = weekStart.add(const Duration(days: 7));
        return due.isBefore(weekEnd);
      case 'monthly':
        final monthEnd = DateTime(n.year, n.month + 1, 1);
        return due.isBefore(monthEnd);
      case 'yearly':
        final yearEnd = DateTime(n.year + 1, 1, 1);
        return due.isBefore(yearEnd);
      default:
        final dayEnd = DateTime(n.year, n.month, n.day + 1);
        return due.isBefore(dayEnd);
    }
  }

  /// Formato del mensaje "aún no es momento — vence el {date}" según el tipo
  /// de recurrencia. Mismas reglas que `_TodayTaskCardTodoV2State._formatDueForMessage`.
  String _formatDueForMessage(BuildContext context, TaskPreview t) {
    final locale = Localizations.localeOf(context);
    final due = t.nextDueAt.toLocal();
    switch (t.recurrenceType) {
      case 'hourly':
        return TokaDates.timeShort(due, locale);
      case 'daily':
        return '${TokaDates.dateMediumWithWeekday(due, locale)} · '
            '${TokaDates.timeShort(due, locale)}';
      case 'weekly':
        return TokaDates.dateMediumWithWeekday(due, locale);
      case 'monthly':
        return TokaDates.dateLongDayMonth(due, locale);
      case 'yearly':
        return TokaDates.monthYearLong(due, locale);
      default:
        return '${TokaDates.dateMediumWithWeekday(due, locale)} · '
            '${TokaDates.timeShort(due, locale)}';
    }
  }

  void _snackNotYet(BuildContext ctx, AppLocalizations l10n, TaskPreview t) {
    final dateStr = _formatDueForMessage(ctx, t);
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(l10n.today_hecho_not_yet(dateStr)),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
  }
}

// -----------------------------------------------------------------------------
// Widgets auxiliares privados
// -----------------------------------------------------------------------------

class _TopBarFromState extends ConsumerWidget {
  const _TopBarFromState({required this.ref});

  // ignore: unused_field
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final AsyncValue<Home?> homeAsync = ref.watch(currentHomeProvider);
    final home = homeAsync.valueOrNull;
    final homeName = home?.name ?? l10n.today_no_home_title;

    List<MemberAvatar> members = const [];
    if (home != null) {
      final membersAsync = ref.watch(homeMembersProvider(home.id));
      final list = membersAsync.valueOrNull ?? const <Member>[];
      members = list
          .take(3)
          .map((m) => (name: m.nickname, color: _colorFor(m.uid)))
          .toList();
    }

    return TockaTopBar(homeName: homeName, members: members);
  }

  static Color _colorFor(String uid) {
    final palette = <Color>[
      FuturistaColors.primary,
      FuturistaColors.primaryAlt,
      FuturistaColors.success,
      FuturistaColors.warning,
      FuturistaColors.error,
    ];
    final idx = uid.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    return palette[idx];
  }
}

class _HeroTurn extends StatelessWidget {
  const _HeroTurn({
    required this.task,
    required this.label,
    this.onDone,
    this.onPass,
  });

  final TaskPreview task;
  final String label;
  final VoidCallback? onDone;
  final VoidCallback? onPass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TockaPill(
                color: cs.primary,
                glow: true,
                child: const Text('TE TOCA'),
              ),
              const Spacer(),
              TockaAvatar(
                name: task.currentAssigneeName ?? '?',
                color: cs.primary,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            task.currentAssigneeName ?? '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TockaBtn(
                  key: const Key('hero_btn_done'),
                  variant: TockaBtnVariant.glow,
                  size: TockaBtnSize.lg,
                  fullWidth: true,
                  icon: const Icon(Icons.check),
                  onPressed: onDone,
                  child: Text(label),
                ),
              ),
              const SizedBox(width: 8),
              TockaBtn(
                key: const Key('hero_btn_pass'),
                variant: TockaBtnVariant.ghost,
                size: TockaBtnSize.lg,
                onPressed: onPass,
                child: const Icon(Icons.swap_horiz),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FuturistaLoading extends StatelessWidget {
  const _FuturistaLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _FuturistaError extends StatelessWidget {
  const _FuturistaError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TockaBtn(
              variant: TockaBtnVariant.primary,
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
