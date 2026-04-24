// lib/features/tasks/presentation/skins/task_detail_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/free_limits.dart';
import '../../../../core/constants/routes.dart';
import '../../../../core/theme/app_colors_v2.dart';
import '../../../../core/utils/toka_dates.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ad_aware_scaffold.dart';
import '../../../homes/application/dashboard_provider.dart';
import '../../application/task_detail_view_model.dart';
import '../../domain/task.dart';
import '../../domain/task_status.dart';
import '../utils/task_visual_utils.dart';
import '../widgets/unfreeze_blocked_dialog.dart';

class TaskDetailScreenV2 extends ConsumerWidget {
  const TaskDetailScreenV2({super.key, required this.taskId});
  final String taskId;

  Future<void> _confirmDelete(BuildContext ctx, AppLocalizations l10n,
      TaskDetailViewModel vm, Task task) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(l10n.tasks_delete_confirm_title),
        content: Text(l10n.tasks_delete_confirm_body),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;

    // BUG-08: navegar ANTES de awaitear el callable. Si no, el stream del
    // detalle emite null cuando Firestore borra el documento y la pantalla
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

  Future<void> _handleToggleFreeze(BuildContext ctx, WidgetRef ref,
      TaskDetailViewModel vm, Task task) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final TaskDetailViewModel vm =
        ref.watch(taskDetailViewModelProvider(taskId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return vm.viewData.when(
      loading: () => AdAwareScaffold(
          appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
          body: const Center(child: CircularProgressIndicator())),
      error: (_, __) => AdAwareScaffold(
          appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
          body: Center(child: Text(l10n.error_generic))),
      data: (data) {
        if (data == null) {
          return AdAwareScaffold(
              appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
              body: const Center(child: CircularProgressIndicator()));
        }
        final task = data.task;
        final bg = isDark ? AppColorsV2.backgroundDark : AppColorsV2.backgroundLight;
        final surf = isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight;
        final bd = isDark ? AppColorsV2.borderDark : AppColorsV2.borderLight;

        return AdAwareScaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            leading: BackButton(onPressed: () => context.pop()),
            actions: [
              if (data.canManage) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editTask,
                  onPressed: () =>
                      context.push(AppRoutes.editTask.replaceAll(':id', task.id)),
                ),
                IconButton(
                  tooltip: task.status == TaskStatus.frozen
                      ? l10n.tasks_action_unfreeze
                      : l10n.tasks_action_freeze,
                  icon: Icon(task.status == TaskStatus.frozen
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline),
                  onPressed: () => _handleToggleFreeze(context, ref, vm, task),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, l10n, vm, task),
                ),
              ],
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              16, 8, 16,
              AdAwareScaffold.bottomPaddingOf(context, ref),
            ),
            children: [
              Row(children: [
                taskVisualWidget(task.visualKind, task.visualValue, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColorsV2.textPrimaryDark
                            : AppColorsV2.textPrimaryLight),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surf,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bd),
                ),
                child: Column(children: [
                  _InfoRow(
                    key: const Key('detail_assignee'),
                    label: l10n.task_detail_assignee,
                    value: data.currentAssigneeName ?? '—',
                    isDark: isDark,
                  ),
                  Divider(color: bd),
                  _InfoRow(
                    key: const Key('detail_next_due'),
                    label: l10n.task_detail_next_due,
                    value: TokaDates.dateMediumWithWeekday(
                        task.nextDueAt.toLocal(),
                        Localizations.localeOf(context)),
                    isDark: isDark,
                  ),
                  Divider(color: bd),
                  _InfoRow(
                    key: const Key('detail_difficulty'),
                    label: l10n.task_detail_difficulty,
                    value: '${data.difficultyWeight}',
                    isDark: isDark,
                  ),
                ]),
              ),
              if (data.upcomingOccurrences.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.task_detail_upcoming,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.15,
                      color: isDark
                          ? AppColorsV2.textSecondaryDark
                          : AppColorsV2.textSecondaryLight),
                ),
                const SizedBox(height: 8),
                ...data.upcomingOccurrences.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Text(
                          '${TokaDates.dateMediumWithWeekday(o.date, Localizations.localeOf(context))} '
                          '${TokaDates.timeShort(o.date, Localizations.localeOf(context))}',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          o.assigneeName ?? '—',
                          style: GoogleFonts.plusJakartaSans(
                              color: isDark
                                  ? AppColorsV2.textSecondaryDark
                                  : AppColorsV2.textSecondaryLight),
                        ),
                      ]),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {super.key,
      required this.label,
      required this.value,
      required this.isDark});
  final String label, value;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColorsV2.textSecondaryDark
                          : AppColorsV2.textSecondaryLight))),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColorsV2.textPrimaryDark
                      : AppColorsV2.textPrimaryLight)),
        ]),
      );
}
