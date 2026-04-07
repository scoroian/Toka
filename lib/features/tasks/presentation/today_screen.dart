import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../application/task_completion_provider.dart';
import '../application/task_pass_provider.dart';
import '../domain/home_dashboard.dart';
import '../domain/recurrence_order.dart';
import 'widgets/complete_task_dialog.dart';
import 'widgets/pass_turn_dialog.dart';
import 'widgets/today_empty_state.dart';
import 'widgets/today_header_counters.dart';
import 'widgets/today_skeleton_loader.dart';
import 'widgets/today_task_section.dart';

typedef RecurrenceGroup = ({
  List<TaskPreview> todos,
  List<DoneTaskPreview> dones,
});

@visibleForTesting
Map<String, RecurrenceGroup> groupByRecurrence(
  List<TaskPreview> activeTasks,
  List<DoneTaskPreview> doneTasks,
) {
  final result = <String, RecurrenceGroup>{};

  for (final task in activeTasks) {
    final key = task.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: [...(existing?.todos ?? []), task],
      dones: existing?.dones ?? [],
    );
  }

  for (final done in doneTasks) {
    final key = done.recurrenceType;
    final existing = result[key];
    result[key] = (
      todos: existing?.todos ?? [],
      dones: [...(existing?.dones ?? []), done],
    );
  }

  // Sort todos within each group
  for (final key in result.keys) {
    final group = result[key]!;
    final sorted = <TaskPreview>[...group.todos];
    sorted.sort((a, b) {
      // 1. Overdue first
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      // 2. By nextDueAt ascending
      final dateCmp = a.nextDueAt.compareTo(b.nextDueAt);
      if (dateCmp != 0) return dateCmp;
      // 3. Alphabetically
      return a.title.compareTo(b.title);
    });
    result[key] = (todos: sorted, dones: group.dones);
  }

  return result;
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _onDone(
    BuildContext context,
    WidgetRef ref,
    TaskPreview task,
    String homeId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CompleteTaskDialog(
        task: task,
        onConfirm: () {},
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(taskCompletionProvider.notifier)
          .completeTask(homeId, task.taskId);
    }
  }

  Future<void> _onPass(
    BuildContext context,
    WidgetRef ref,
    TaskPreview task,
    String homeId,
    String? currentUid,
  ) async {
    if (currentUid == null) return;

    // Leer stats del miembro para mostrar impacto en compliance
    double complianceBefore = 1.0;
    double estimatedAfter = 1.0;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(currentUid)
          .get();
      final data = snap.data() ?? {};
      final completed = (data['completedCount'] as int?) ?? 0;
      final passed = (data['passedCount'] as int?) ?? 0;
      complianceBefore = (data['complianceRate'] as double?) ??
          completed / (completed + passed).clamp(1, double.maxFinite);
      estimatedAfter = PassTurnDialog.calcEstimatedCompliance(
        completedCount: completed,
        passedCount: passed,
      );
    } catch (_) {
      // Si falla la lectura, usar defaults conservadores
    }

    if (!context.mounted) return;

    String? capturedReason;
    bool confirmed = false;

    await showDialog<void>(
      context: context,
      builder: (_) => PassTurnDialog(
        task: task,
        currentComplianceRate: complianceBefore,
        estimatedComplianceAfter: estimatedAfter,
        nextAssigneeName: null, // assignmentOrder no está en el dashboard
        onConfirm: (reason) {
          confirmed = true;
          capturedReason = reason;
        },
      ),
    );

    if (confirmed && context.mounted) {
      await ref.read(taskPassProvider.notifier).passTurn(
            homeId,
            task.taskId,
            reason: capturedReason,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dashboardAsync = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider);
    final currentUid = auth.whenOrNull(authenticated: (u) => u.uid);
    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.today_screen_title),
      ),
      body: dashboardAsync.when(
        loading: () => const TodaySkeletonLoader(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.error_generic),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null) return const TodayEmptyState();

          final grouped = groupByRecurrence(
            data.activeTasksPreview,
            data.doneTasksPreview,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TodayHeaderCounters(counters: data.counters),
              ),
              for (final recurrenceType in RecurrenceOrder.all)
                if (grouped[recurrenceType] != null) ...[
                  TodayTaskSection(
                    recurrenceType: recurrenceType,
                    todos: grouped[recurrenceType]!.todos,
                    dones: grouped[recurrenceType]!.dones,
                    currentUid: currentUid,
                    onDone: homeId != null
                        ? (task) => _onDone(context, ref, task, homeId)
                        : null,
                    onPass: homeId != null
                        ? (task) =>
                            _onPass(context, ref, task, homeId, currentUid)
                        : null,
                  ),
                ],
              if (data.adFlags.showBanner)
                const SliverToBoxAdapter(
                  child: _AdBannerPlaceholder(
                    key: Key('ad_banner'),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}

class _AdBannerPlaceholder extends StatelessWidget {
  const _AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Ad')),
    );
  }
}
