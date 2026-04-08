import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/today_view_model.dart';
import '../domain/home_dashboard.dart';
import 'widgets/complete_task_dialog.dart';
import 'widgets/pass_turn_dialog.dart';
import 'widgets/today_empty_state.dart';
import 'widgets/today_header_counters.dart';
import 'widgets/today_skeleton_loader.dart';
import 'widgets/today_task_section.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _onDone(
    BuildContext context,
    TodayViewModel vm,
    TaskPreview task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CompleteTaskDialog(
        task: task,
        onConfirm: () {},
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.completeTask(task.taskId);
    }
  }

  Future<void> _onPass(
    BuildContext context,
    TodayViewModel vm,
    TaskPreview task,
    String? currentUid,
  ) async {
    if (currentUid == null) return;

    final stats = await vm.fetchPassStats(currentUid);

    if (!context.mounted) return;

    String? capturedReason;
    bool confirmed = false;

    await showDialog<void>(
      context: context,
      builder: (_) => PassTurnDialog(
        task: task,
        currentComplianceRate: stats.complianceBefore,
        estimatedComplianceAfter: stats.estimatedAfter,
        nextAssigneeName: null,
        onConfirm: (reason) {
          confirmed = true;
          capturedReason = reason;
        },
      ),
    );

    if (confirmed && context.mounted) {
      await vm.passTurn(task.taskId, reason: capturedReason);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(todayViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.today_screen_title),
      ),
      body: vm.viewData.when(
        loading: () => const TodaySkeletonLoader(),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.error_generic),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: vm.retry,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data == null) return const TodayEmptyState();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TodayHeaderCounters(counters: data.counters),
              ),
              for (final recurrenceType in data.recurrenceOrder)
                if (data.grouped[recurrenceType] != null)
                  TodayTaskSection(
                    recurrenceType: recurrenceType,
                    todos: data.grouped[recurrenceType]!.todos,
                    dones: data.grouped[recurrenceType]!.dones,
                    currentUid: data.currentUid,
                    onDone: data.homeId.isNotEmpty
                        ? (task) => _onDone(context, vm, task)
                        : null,
                    onPass: data.homeId.isNotEmpty
                        ? (task) =>
                            _onPass(context, vm, task, data.currentUid)
                        : null,
                  ),
              if (data.showAdBanner)
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
