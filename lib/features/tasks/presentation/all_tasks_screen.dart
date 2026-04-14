// lib/features/tasks/presentation/all_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/all_tasks_view_model.dart';
import '../domain/task_status.dart';
import 'widgets/task_card.dart';

class AllTasksScreen extends ConsumerWidget {
  const AllTasksScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tasks_delete_confirm_title),
        content: Text(l10n.tasks_delete_confirm_body),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(allTasksViewModelProvider);

    return vm.viewData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.tasks_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.tasks_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.tasks_title)),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tasks_title),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _FilterBar(
                current: data.filter.status,
                onChanged: vm.setStatusFilter,
              ),
            ),
          ),
          body: data.tasks.isEmpty
              ? Center(
                  key: const Key('tasks_empty_state'),
                  child: Text(l10n.tasks_empty_title))
              : ListView.builder(
                  key: const Key('tasks_list'),
                  itemCount: data.tasks.length,
                  itemBuilder: (_, i) {
                    final task = data.tasks[i];
                    return Dismissible(
                      key: Key('dismissible_${task.id}'),
                      background: _FreezeBackground(l10n: l10n),
                      secondaryBackground: _DeleteBackground(l10n: l10n),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await vm.toggleFreeze(task);
                          return false;
                        } else {
                          return _confirmDelete(context, l10n);
                        }
                      },
                      onDismissed: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          await vm.deleteTask(task);
                        }
                      },
                      child: TaskCard(
                        task: task,
                        onTap: () => context.go('/task/${task.id}'),
                      ),
                    );
                  },
                ),
          floatingActionButton: data.canManage
              ? FloatingActionButton(
                  key: const Key('create_task_fab'),
                  tooltip: l10n.tasks_create_title,
                  onPressed: () => context.go(AppRoutes.createTask),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});
  final TaskStatus current;
  final void Function(TaskStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          key: const Key('filter_active'),
          label: Text(l10n.tasks_section_active),
          selected: current == TaskStatus.active,
          onSelected: (_) => onChanged(TaskStatus.active),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          key: const Key('filter_frozen'),
          label: Text(l10n.tasks_section_frozen),
          selected: current == TaskStatus.frozen,
          onSelected: (_) => onChanged(TaskStatus.frozen),
        ),
      ],
    );
  }
}

class _FreezeBackground extends StatelessWidget {
  const _FreezeBackground({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.blue.shade100,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Row(children: [
          const Icon(Icons.pause_circle_outline),
          const SizedBox(width: 8),
          Text(l10n.tasks_action_freeze),
        ]),
      );
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.red.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Row(children: [
          const Spacer(),
          const Icon(Icons.delete_outline),
          const SizedBox(width: 8),
          Text(l10n.delete),
        ]),
      );
}
