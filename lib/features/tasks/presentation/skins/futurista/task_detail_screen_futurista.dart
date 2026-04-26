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

import '../../../../../core/constants/routes.dart';
import '../../../../../core/utils/toka_dates.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/task_glyph.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../application/task_detail_view_model.dart';
import '../../../application/task_completion_provider.dart';
import '../../../application/task_pass_provider.dart';
import '../../../domain/home_dashboard.dart';
import '../../../domain/recurrence_rule.dart';
import '../../../domain/task.dart';
import '../../widgets/complete_task_dialog.dart';
import '../../widgets/pass_turn_dialog.dart';

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

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        adAwareBottomPadding(context, ref, extra: 16),
      ),
      children: [
        _HeaderRow(
          canManage: data.canManage,
          onBack: () => context.pop(),
          onEdit: data.canManage
              ? () =>
                  context.push(AppRoutes.editTask.replaceAll(':id', task.id))
              : null,
        ),
        const SizedBox(height: 16),
        _HeroCard(
          title: task.title,
          subtitle: _subtitle(l10n, task),
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
          onDone: () => _onDone(context, ref, task),
          onPass: data.currentAssigneeName != null
              ? () => _onPass(context, ref, task)
              : null,
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
          child: const Text('Reparto inteligente'),
        ),
      if (d.difficultyWeight != 1.0)
        TockaPill(
          child: Text('× ${d.difficultyWeight.toStringAsFixed(1)}'),
        ),
    ];
    return pills;
  }

  String _recurrenceLabel(BuildContext context, RecurrenceRule rule) =>
      switch (rule) {
        OneTimeRule _ => 'Una vez',
        HourlyRule r => 'Cada ${r.every}h',
        DailyRule r =>
          r.every == 1 ? 'Cada día' : 'Cada ${r.every} días',
        WeeklyRule _ => 'Semanal',
        MonthlyFixedRule _ || MonthlyNthRule _ => 'Mensual',
        YearlyFixedRule _ || YearlyNthRule _ => 'Anual',
      };

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
    required this.onBack,
    required this.onEdit,
  });

  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

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
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
        ],
        const _IconSlot(
          key: Key('fut_btn_more'),
          icon: Icons.more_vert,
          onTap: null, // placeholder; el menú vive en futuras iteraciones
        ),
      ],
    );
  }
}

class _IconSlot extends StatelessWidget {
  const _IconSlot({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
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
  }
}

// -----------------------------------------------------------------------------
// Hero card
// -----------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.pills,
  });

  final String title;
  final String subtitle;
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
            child: TaskGlyph(kind: glyph, color: cs.primary, size: 40),
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
                      'MIN',
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
                      'PRÓXIMO TURNO',
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
            'ROTACIÓN',
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

    final label = isCurrent ? 'AHORA' : (isNext ? 'SIG.' : '');
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
