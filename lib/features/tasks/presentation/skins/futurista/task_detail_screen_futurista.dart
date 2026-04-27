// lib/features/tasks/presentation/skins/futurista/task_detail_screen_futurista.dart
//
// Ficha de tarea en skin Futurista. Consume el mismo `taskDetailViewModelProvider`
// que `TaskDetailScreenV2` y reutiliza los dialogs `CompleteTaskDialog` y
// `PassTurnDialog`. Layout según canvas `skin_futurista/screens-tareas.jsx`:
//
//   1. Header row con 3 botones 38x38 (back / edit / more).
//   2. Hero card con glyph grande, título y row de pills (recurrencia, peso, modo).
//   3. Card "Próximo turno" con minutos destacados + botones Hecha / Pasar.
//   4. Card "Rotación" (solo si hay assignmentOrder) con avatars y connectors.
//   5. Sección "Historial" con lista de próximas ocurrencias.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/free_limits.dart';
import '../../../../../core/constants/routes.dart';
import '../../../../../core/utils/toka_dates.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/task_glyph.dart';
import '../../../../../shared/widgets/futurista/task_visual_futurista.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../../homes/application/dashboard_provider.dart';
import '../../../application/task_detail_view_model.dart';
import '../../../application/task_completion_provider.dart';
import '../../../application/task_pass_provider.dart';
import '../../../domain/home_dashboard.dart';
import '../../../domain/recurrence_rule.dart';
import '../../../domain/task.dart';
import '../../../domain/task_status.dart';
import '../../widgets/complete_task_dialog.dart';
import '../../widgets/pass_turn_dialog.dart';
import '../../widgets/unfreeze_blocked_dialog.dart';

class TaskDetailScreenFuturista extends ConsumerWidget {
  const TaskDetailScreenFuturista({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final TaskDetailViewModel vm =
        ref.watch(taskDetailViewModelProvider(taskId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: vm.viewData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.error_generic)),
          data: (data) {
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _Content(data: data, vm: vm);
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Contenido principal
// -----------------------------------------------------------------------------

class _Content extends ConsumerWidget {
  const _Content({required this.data, required this.vm});

  final TaskDetailViewData data;
  final TaskDetailViewModel vm;

  static const _mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final task = data.task;

    final isFrozen = task.status == TaskStatus.frozen;
    // Sólo el assignee actual puede marcar la tarea como hecha o pasar
    // turno. El detalle SE VE para todo el mundo (información), pero los
    // botones de acción no aparecen si no es tu turno: Cloud Function
    // rechazaría la operación de todos modos por seguridad.
    final myUid = ref
        .watch(authProvider)
        .whenOrNull(authenticated: (u) => u.uid);
    final isMine = task.currentAssigneeUid != null &&
        task.currentAssigneeUid == myUid;

    return Column(
      children: [
        // Header fijo arriba: back/editar/freeze/delete quedan anclados
        // mientras el detalle scrollea por debajo. Paridad con v2.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _HeaderRow(
            canManage: data.canManage,
            isFrozen: isFrozen,
            freezeTooltip: isFrozen
                ? l10n.tasks_action_unfreeze
                : l10n.tasks_action_freeze,
            onBack: () => context.pop(),
            onEdit: data.canManage
                ? () =>
                    context.push(AppRoutes.editTask.replaceAll(':id', task.id))
                : null,
            onToggleFreeze: data.canManage
                ? () => _onToggleFreeze(context, ref, task)
                : null,
            onDelete: data.canManage
                ? () => _onDelete(context, ref, task)
                : null,
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              adAwareBottomPadding(context, ref, extra: 16),
            ),
            children: [
        _HeroCard(
          title: task.title,
          subtitle: _subtitle(l10n, task),
          // Pasamos el visual del task tal cual lo eligió el usuario; el
          // _glyphFor(task) sigue ahí como fallback cuando no hay visual.
          visualKind: task.visualKind,
          visualValue: task.visualValue,
          glyph: _glyphFor(task),
          pills: _pills(context, task, data),
        ),
        const SizedBox(height: 14),
        _NextTurnCard(
          assigneeName: data.currentAssigneeName ?? '—',
          minutesLabel: _minutesUntil(task.nextDueAt),
          whenLabel: _whenLabel(context, task.nextDueAt),
          doneLabel: l10n.today_btn_done,
          passLabel: l10n.pass_turn_confirm_btn,
          // Sólo se muestran si es el turno del usuario actual; en otro
          // caso el card sigue siendo informativo pero sin acciones
          // (consistente con la pantalla Hoy, donde sólo aparecen
          // Hecho/Pasar en las tareas de tu fila).
          onDone: isMine ? () => _onDone(context, ref, task) : null,
          onPass: isMine ? () => _onPass(context, ref, task) : null,
        ),
        if (task.assignmentOrder.length >= 2) ...[
          const SizedBox(height: 14),
          _RotationCard(
            order: task.assignmentOrder,
            currentUid: task.currentAssigneeUid,
            currentName: data.currentAssigneeName,
          ),
        ],
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            l10n.task_detail_upcoming.toUpperCase(),
            style: _mono.copyWith(
              color: cs.onSurface.withValues(alpha: 0.42),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (data.upcomingOccurrences.isEmpty)
          _emptyHistory(context)
        else
          ...data.upcomingOccurrences
              .map((o) => _HistoryRow(occurrence: o)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyHistory(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        '—',
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _onDone(
      BuildContext ctx, WidgetRef ref, Task task) async {
    final preview = _asPreview(task, data);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => CompleteTaskDialog(task: preview, onConfirm: () {}),
    );
    if (confirmed == true) {
      await ref
          .read(taskCompletionProvider.notifier)
          .completeTask(task.homeId, task.id);
    }
  }

  Future<void> _onPass(
      BuildContext ctx, WidgetRef ref, Task task) async {
    final preview = _asPreview(task, data);
    final stats = await _fetchPassStats(task.homeId, task.currentAssigneeUid);
    if (!ctx.mounted) return;
    String? reason;
    bool confirmed = false;
    await showDialog<void>(
      context: ctx,
      builder: (_) => PassTurnDialog(
        task: preview,
        currentComplianceRate: stats.complianceBefore,
        estimatedComplianceAfter: stats.estimatedAfter,
        nextAssigneeName: null,
        onConfirm: (r) {
          confirmed = true;
          reason = r;
        },
      ),
    );
    if (confirmed) {
      await ref
          .read(taskPassProvider.notifier)
          .passTurn(task.homeId, task.id, reason: reason);
    }
  }

  Future<void> _onToggleFreeze(
      BuildContext ctx, WidgetRef ref, Task task) async {
    final dashboard = ref.read(dashboardProvider).valueOrNull;
    final isPremium = dashboard?.premiumFlags.isPremium ?? true;
    final planCounters = dashboard?.planCounters;
    final isUnfreezing = task.status == TaskStatus.frozen;
    if (isUnfreezing &&
        !isPremium &&
        planCounters != null &&
        planCounters.activeTasks >= FreeLimits.maxActiveTasks) {
      await showUnfreezeBlockedDialog(
        ctx,
        current: planCounters.activeTasks,
        limit: FreeLimits.maxActiveTasks,
      );
      return;
    }
    await vm.toggleFreeze(task);
  }

  Future<void> _onDelete(BuildContext ctx, WidgetRef ref, Task task) async {
    final l10n = AppLocalizations.of(ctx);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(l10n.tasks_delete_confirm_title),
        content: Text(l10n.tasks_delete_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('btn_delete_confirm'),
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;

    // Navegar ANTES del callable (paridad con BUG-08 fix de v2): si no, el
    // stream emite null cuando Firestore borra el documento y la pantalla se
    // queda colgada con un CircularProgressIndicator eterno.
    final messenger = ScaffoldMessenger.of(ctx);
    final errorText = l10n.error_generic;
    ctx.pop();

    try {
      await vm.deleteTask(task);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
    }
  }

  Future<({double complianceBefore, double estimatedAfter})> _fetchPassStats(
      String homeId, String? currentUid) async {
    if (currentUid == null || currentUid.isEmpty) {
      return (complianceBefore: 1.0, estimatedAfter: 1.0);
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(currentUid)
          .get();
      final map = snap.data() ?? {};
      final completed = (map['completedCount'] as int?) ?? 0;
      final passed = (map['passedCount'] as int?) ?? 0;
      final before = (map['complianceRate'] as double?) ??
          completed / (completed + passed).clamp(1, double.maxFinite);
      final after = PassTurnDialog.calcEstimatedCompliance(
        completedCount: completed,
        passedCount: passed,
      );
      return (complianceBefore: before, estimatedAfter: after);
    } catch (_) {
      return (complianceBefore: 1.0, estimatedAfter: 1.0);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers de presentación
  // ---------------------------------------------------------------------------

  TaskPreview _asPreview(Task task, TaskDetailViewData d) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return TaskPreview(
      taskId: task.id,
      title: task.title,
      visualKind: task.visualKind,
      visualValue: task.visualValue,
      recurrenceType: _recurrenceType(task.recurrenceRule),
      currentAssigneeUid: task.currentAssigneeUid,
      currentAssigneeName: d.currentAssigneeName,
      currentAssigneePhoto: null,
      nextDueAt: task.nextDueAt,
      isOverdue: task.nextDueAt.isBefore(todayStart),
      status: task.status.name,
    );
  }

  String _recurrenceType(RecurrenceRule rule) => switch (rule) {
        OneTimeRule _ => 'oneTime',
        HourlyRule _ => 'hourly',
        DailyRule _ => 'daily',
        WeeklyRule _ => 'weekly',
        MonthlyFixedRule _ || MonthlyNthRule _ => 'monthly',
        YearlyFixedRule _ || YearlyNthRule _ => 'yearly',
      };

  String _subtitle(AppLocalizations l10n, Task task) {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return TokaDates.dateMediumWithWeekday(task.nextDueAt.toLocal(), locale);
  }

  TaskGlyphKind _glyphFor(Task task) => switch (task.recurrenceRule) {
        OneTimeRule _ => TaskGlyphKind.dot,
        HourlyRule _ => TaskGlyphKind.arcs,
        DailyRule _ => TaskGlyphKind.ring,
        WeeklyRule _ => TaskGlyphKind.hex,
        MonthlyFixedRule _ || MonthlyNthRule _ => TaskGlyphKind.diamond,
        YearlyFixedRule _ || YearlyNthRule _ => TaskGlyphKind.star4,
      };

  List<Widget> _pills(
      BuildContext context, Task task, TaskDetailViewData d) {
    final cs = Theme.of(context).colorScheme;
    final pills = <Widget>[
      TockaPill(
        color: cs.primary,
        child: Text(_recurrenceLabel(context, task.recurrenceRule)),
      ),
      if (task.assignmentMode == 'smartDistribution')
        TockaPill(
          color: cs.secondary,
          child: Text(AppLocalizations.of(context).assignment_smart),
        ),
      if (d.difficultyWeight != 1.0)
        TockaPill(
          child: Text('× ${d.difficultyWeight.toStringAsFixed(1)}'),
        ),
    ];
    return pills;
  }

  String _recurrenceLabel(BuildContext context, RecurrenceRule rule) {
    final l10n = AppLocalizations.of(context);
    return switch (rule) {
      OneTimeRule _ => l10n.recurrence_pill_one_time,
      HourlyRule r => l10n.recurrence_pill_hourly(r.every),
      DailyRule r => r.every == 1
          ? l10n.recurrence_pill_daily
          : l10n.recurrence_pill_daily_n(r.every),
      WeeklyRule _ => l10n.recurrence_pill_weekly,
      MonthlyFixedRule _ || MonthlyNthRule _ => l10n.recurrence_pill_monthly,
      YearlyFixedRule _ || YearlyNthRule _ => l10n.recurrence_pill_yearly,
    };
  }

  String _minutesUntil(DateTime due) {
    final diff = due.difference(DateTime.now()).inMinutes;
    if (diff <= 0) return '0';
    if (diff < 60) return diff.toString();
    final hours = (diff / 60).floor();
    if (hours < 24) return '${hours}h';
    return '${(hours / 24).floor()}d';
  }

  String _whenLabel(BuildContext context, DateTime due) {
    final locale = Localizations.localeOf(context);
    return TokaDates.timeShort(due.toLocal(), locale);
  }
}

// -----------------------------------------------------------------------------
// Header: botones 38x38 (back / edit / more)
// -----------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.canManage,
    required this.isFrozen,
    required this.freezeTooltip,
    required this.onBack,
    required this.onEdit,
    required this.onToggleFreeze,
    required this.onDelete,
  });

  final bool canManage;
  final bool isFrozen;
  final String freezeTooltip;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFreeze;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconSlot(
          key: const Key('fut_btn_back'),
          icon: Icons.chevron_left,
          onTap: onBack,
        ),
        const Spacer(),
        if (canManage) ...[
          _IconSlot(
            key: const Key('fut_btn_edit'),
            icon: Icons.edit_outlined,
            tooltip: freezeTooltip == '' ? null : null,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _IconSlot(
            key: const Key('fut_btn_freeze'),
            icon: isFrozen
                ? Icons.play_circle_outline
                : Icons.pause_circle_outline,
            tooltip: freezeTooltip,
            onTap: onToggleFreeze,
          ),
          const SizedBox(width: 8),
          _IconSlot(
            key: const Key('fut_btn_delete'),
            icon: Icons.delete_outline,
            onTap: onDelete,
          ),
        ],
      ],
    );
  }
}

class _IconSlot extends StatelessWidget {
  const _IconSlot({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slot = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: slot) : slot;
  }
}

// -----------------------------------------------------------------------------
// Hero card
// -----------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.visualKind,
    required this.visualValue,
    required this.glyph,
    required this.pills,
  });

  final String title;
  final String subtitle;
  final String visualKind;
  final String visualValue;
  // Fallback cuando no hay visual del usuario.
  final TaskGlyphKind glyph;
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [
            cs.primary.withValues(alpha: 0.13),
            cs.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withValues(alpha: 0.19)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.22),
                  blurRadius: 28,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: TaskVisualFuturista(
              visualKind: visualKind,
              visualValue: visualValue,
              color: cs.primary,
              size: 40,
              fallbackGlyph: glyph,
              // El wrapper ya pinta el slot grande; aquí solo el icono.
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.64),
            ),
          ),
          if (pills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: pills,
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Next turn card
// -----------------------------------------------------------------------------

class _NextTurnCard extends StatelessWidget {
  const _NextTurnCard({
    required this.assigneeName,
    required this.minutesLabel,
    required this.whenLabel,
    required this.doneLabel,
    required this.passLabel,
    required this.onDone,
    required this.onPass,
  });

  final String assigneeName;
  final String minutesLabel;
  final String whenLabel;
  final String doneLabel;
  final String passLabel;
  final VoidCallback? onDone;
  final VoidCallback? onPass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      minutesLabel,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).task_due_at_min_short,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 8,
                        letterSpacing: 1.5,
                        color: cs.onSurface.withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).task_detail_next_turn,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: cs.onSurface.withValues(alpha: 0.42),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        TockaAvatar(
                          name: assigneeName,
                          color: cs.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            assigneeName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· $whenLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.64),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Sólo pintamos la fila de acciones si al menos una está
          // disponible (es decir, es el turno del usuario actual). Para
          // observadores externos, el card se queda informativo.
          if (onDone != null || onPass != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TockaBtn(
                  key: const Key('fut_btn_done'),
                  variant: TockaBtnVariant.glow,
                  size: TockaBtnSize.md,
                  fullWidth: true,
                  icon: const Icon(Icons.check),
                  onPressed: onDone,
                  child: Text(doneLabel),
                ),
              ),
              const SizedBox(width: 8),
              TockaBtn(
                key: const Key('fut_btn_pass'),
                variant: TockaBtnVariant.ghost,
                size: TockaBtnSize.md,
                icon: const Icon(Icons.skip_next),
                onPressed: onPass,
                child: Text(passLabel),
              ),
            ],
          ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Rotation card
// -----------------------------------------------------------------------------

class _RotationCard extends StatelessWidget {
  const _RotationCard({
    required this.order,
    required this.currentUid,
    required this.currentName,
  });

  final List<String> order;
  final String? currentUid;
  final String? currentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentIdx = currentUid != null ? order.indexOf(currentUid!) : -1;
    final nextIdx = currentIdx >= 0 && order.isNotEmpty
        ? (currentIdx + 1) % order.length
        : -1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).task_detail_rotation,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              letterSpacing: 1.8,
              color: cs.onSurface.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < order.length; i++) ...[
                _RotationSlot(
                  uid: order[i],
                  name: _displayName(i, order[i]),
                  isCurrent: i == currentIdx,
                  isNext: i == nextIdx,
                ),
                if (i < order.length - 1)
                  Expanded(
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: theme.dividerColor,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _displayName(int idx, String uid) {
    if (currentUid == uid && currentName != null && currentName!.isNotEmpty) {
      return currentName!;
    }
    // Fallback legible: primeros 2 chars del uid como iniciales.
    return uid.length >= 2 ? uid.substring(0, 2).toUpperCase() : uid;
  }
}

class _RotationSlot extends StatelessWidget {
  const _RotationSlot({
    required this.uid,
    required this.name,
    required this.isCurrent,
    required this.isNext,
  });

  final String uid;
  final String name;
  final bool isCurrent;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isCurrent
        ? cs.primary
        : (isNext ? cs.secondary : cs.onSurface.withValues(alpha: 0.32));

    Widget avatar = TockaAvatar(name: name, color: color, size: 32);
    if (isCurrent) {
      avatar = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [cs.primary, cs.primary.withValues(alpha: 0)],
          ),
        ),
        child: avatar,
      );
    }

    final l10n = AppLocalizations.of(context);
    final label =
        isCurrent ? l10n.rotation_now : (isNext ? l10n.rotation_next : '');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 4),
        SizedBox(
          height: 10,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 8.5,
              letterSpacing: 1.3,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// History row (upcoming occurrence)
// -----------------------------------------------------------------------------

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.occurrence});

  final UpcomingOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final locale = Localizations.localeOf(context);

    final dateLabel =
        TokaDates.dateMediumWithWeekday(occurrence.date.toLocal(), locale);
    final timeLabel = TokaDates.timeShort(occurrence.date.toLocal(), locale);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: cs.primary.withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.schedule, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occurrence.assigneeName ?? '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateLabel · $timeLabel',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10.5,
                      letterSpacing: 0.4,
                      color: cs.onSurface.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
