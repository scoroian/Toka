import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/dashboard_provider.dart';
import '../domain/home_dashboard.dart';
import '../domain/recurrence_order.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dashboardAsync = ref.watch(dashboardProvider);
    final auth = ref.watch(authProvider);
    final currentUid = auth.whenOrNull(authenticated: (u) => u.uid);

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
