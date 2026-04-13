// lib/features/tasks/presentation/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/task_detail_view_model.dart';
import '../domain/task_status.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    TaskDetailViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tasks_delete_confirm_title),
        content: Text(l10n.tasks_delete_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.deleteTask();
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(taskDetailViewModelProvider(taskId));

    return vm.viewData.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (data) {
        if (data == null) {
          return const Scaffold(body: Center(child: LoadingWidget()));
        }

        final task = data.task;

        return Scaffold(
          appBar: AppBar(
            title: Text(task.title),
            actions: [
              if (data.canManage) ...[
                IconButton(
                  key: const Key('freeze_task_button'),
                  icon: Icon(data.isFrozen
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline),
                  tooltip: data.isFrozen
                      ? l10n.tasks_action_unfreeze
                      : l10n.tasks_action_freeze,
                  onPressed: () => vm.toggleFreeze(),
                ),
                IconButton(
                  key: const Key('delete_task_button'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () => _confirmDelete(context, l10n, vm),
                ),
                IconButton(
                  key: const Key('edit_task_button'),
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/task/$taskId/edit'),
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  if (task.visualKind == 'emoji')
                    Text(task.visualValue,
                        style: const TextStyle(fontSize: 48))
                  else
                    const Icon(Icons.task_alt, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title,
                            style: Theme.of(context).textTheme.headlineSmall),
                        if (task.description != null)
                          Text(task.description!),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              if (task.status == TaskStatus.frozen)
                Chip(
                  key: const Key('frozen_chip'),
                  label: Text(l10n.tasks_status_frozen),
                  avatar: const Icon(Icons.pause_circle_outline),
                ),
              ListTile(
                key: const Key('current_assignee_tile'),
                leading: const Icon(Icons.person),
                title: Text(l10n.tasks_detail_assignment_order),
                subtitle: Text(data.currentAssigneeName ?? '—'),
              ),
              ListTile(
                key: const Key('next_due_tile'),
                leading: const Icon(Icons.schedule),
                title: Text(l10n.tasks_detail_next_occurrences),
                subtitle: Text(
                  DateFormat.yMMMd()
                      .add_Hm()
                      .format(task.nextDueAt.toLocal()),
                ),
              ),
              ListTile(
                key: const Key('difficulty_tile'),
                leading: const Icon(Icons.fitness_center),
                title: Text(l10n.tasks_field_difficulty),
                subtitle: Text(task.difficultyWeight.toStringAsFixed(1)),
              ),
              const Divider(height: 32),
              Text(l10n.tasks_detail_next_occurrences,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...data.upcomingOccurrences.asMap().entries.map(
                (entry) => ListTile(
                  key: Key('occurrence_tile_${entry.key}'),
                  dense: true,
                  title: Text(
                    DateFormat.yMMMd()
                        .add_Hm()
                        .format(entry.value.date.toLocal()),
                  ),
                  trailing: entry.value.assigneeName != null
                      ? Text(
                          entry.value.assigneeName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
