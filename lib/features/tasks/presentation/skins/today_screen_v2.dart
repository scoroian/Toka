// lib/features/tasks/presentation/skins/today_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../subscription/presentation/widgets/premium_state_banner.dart';
import '../../application/today_view_model.dart';
import '../../domain/home_dashboard.dart';
import '../widgets/complete_task_dialog.dart';
import '../../../../features/homes/presentation/home_selector_widget.dart';
import '../widgets/pass_turn_dialog.dart';
import '../widgets/today_empty_state.dart';
import 'widgets/today_header_counters_v2.dart';
import 'widgets/today_skeleton_v2.dart';
import 'widgets/today_task_section_v2.dart';

class TodayScreenV2 extends ConsumerWidget {
  const TodayScreenV2({super.key});

  Future<void> _onDone(BuildContext ctx, TodayViewModel vm, TaskPreview task) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => CompleteTaskDialog(task: task, onConfirm: () {}),
    );
    if (confirmed == true && ctx.mounted) await vm.completeTask(task.taskId);
  }

  Future<void> _onPass(BuildContext ctx, TodayViewModel vm, TaskPreview task, String? uid) async {
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
        onConfirm: (r) { confirmed = true; reason = r; },
      ),
    );
    if (confirmed && ctx.mounted) await vm.passTurn(task.taskId, reason: reason);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final TodayViewModel vm = ref.watch(todayViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const HomeSelectorWidget(),
      ),
      body: vm.viewData.when(
        loading: () => const TodaySkeletonV2(),
        error: (_, __) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.error_generic),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: vm.retry, child: Text(l10n.retry)),
          ],
        )),
        data: (data) {
          if (data == null && vm.homes.isEmpty) return _NoHomeEmptyState(widgetRef: ref);
          if (data == null) return const TodayEmptyState();
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: PremiumStateBanner()),
              SliverToBoxAdapter(
                child: TodayHeaderCountersV2(counters: data.counters)),
              for (final recType in data.recurrenceOrder)
                if (data.grouped[recType] != null)
                  TodayTaskSectionV2(
                    recurrenceType: recType,
                    todos: data.grouped[recType]!.todos,
                    dones: data.grouped[recType]!.dones,
                    currentUid: data.currentUid,
                    onDone: data.homeId.isNotEmpty
                        ? (t) => _onDone(context, vm, t) : null,
                    onPass: data.homeId.isNotEmpty
                        ? (t) => _onPass(context, vm, t, data.currentUid) : null,
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
    );
  }
}

class _NoHomeEmptyState extends StatelessWidget {
  const _NoHomeEmptyState({required this.widgetRef});

  final WidgetRef widgetRef;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.today_no_home_title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.today_no_home_body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              key: const Key('no_home_create_button'),
              onPressed: () => showCreateHomeSheet(context, widgetRef, 0),
              icon: const Icon(Icons.add),
              label: Text(l10n.onboarding_create_home_button),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('no_home_join_button'),
              onPressed: () => showJoinHomeSheet(context, widgetRef, 0),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.onboarding_join_home),
            ),
          ],
        ),
      ),
    );
  }
}
