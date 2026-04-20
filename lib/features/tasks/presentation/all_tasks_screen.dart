// lib/features/tasks/presentation/all_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/all_tasks_view_model.dart';
import '../domain/task_status.dart';
import 'widgets/task_card.dart';

class AllTasksScreen extends ConsumerStatefulWidget {
  const AllTasksScreen({super.key});

  @override
  ConsumerState<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends ConsumerState<AllTasksScreen> {
  Future<bool> _confirmBulkDelete(
      BuildContext context, AppLocalizations l10n, int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tasks_bulk_delete_confirm_title(count)),
        content: Text(l10n.tasks_bulk_delete_confirm_body),
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

  Future<bool> _confirmSingleDelete(
      BuildContext context, AppLocalizations l10n) async {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final AllTasksViewModel vm = ref.watch(allTasksViewModelProvider);
    final isSelectionMode = vm.isSelectionMode;
    final selectedIds = vm.selectedIds;

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
            body: const LoadingWidget(),
          );
        }

        final appBar = isSelectionMode
            ? AppBar(
                leading: IconButton(
                  key: const Key('exit_selection_button'),
                  icon: const Icon(Icons.close),
                  onPressed: vm.clearSelection,
                ),
                title: Text(
                  key: const Key('selection_count_text'),
                  l10n.tasks_selection_count(selectedIds.length),
                ),
                actions: [
                  if (data.canManage) ...[
                    IconButton(
                      key: const Key('bulk_freeze_button'),
                      icon: const Icon(Icons.pause_circle_outline),
                      tooltip: l10n.tasks_bulk_freeze,
                      onPressed: () async => vm.bulkFreeze(),
                    ),
                    IconButton(
                      key: const Key('bulk_delete_button'),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.tasks_bulk_delete,
                      onPressed: () async {
                        final ok = await _confirmBulkDelete(
                            context, l10n, selectedIds.length);
                        if (ok && context.mounted) await vm.bulkDelete();
                      },
                    ),
                  ],
                ],
              )
            : AppBar(
                title: Text(l10n.tasks_title),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: _FilterBar(
                    current: data.filter.status,
                    onChanged: vm.setStatusFilter,
                  ),
                ),
              );

        return Scaffold(
          appBar: appBar,
          body: Column(
            children: [
              Expanded(
                child: data.tasks.isEmpty
                    ? Center(
                        key: const Key('tasks_empty_state'),
                        child: Text(l10n.tasks_empty_title))
                    : ListView.builder(
                        key: const Key('tasks_list'),
                        itemCount: data.tasks.length,
                        itemBuilder: (_, i) {
                          final task = data.tasks[i];
                          final isSelected = selectedIds.contains(task.id);

                          if (isSelectionMode) {
                            return CheckboxListTile(
                              key: Key('selectable_task_${task.id}'),
                              value: isSelected,
                              onChanged: (_) => vm.toggleSelection(task.id),
                              title: Text(task.title),
                              secondary: task.visualKind == 'emoji'
                                  ? Text(task.visualValue,
                                      style: const TextStyle(fontSize: 24))
                                  : const Icon(Icons.task_alt),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                            );
                          }

                          return Dismissible(
                            key: Key('dismissible_${task.id}'),
                            background: _FreezeBackground(l10n: l10n),
                            secondaryBackground: _DeleteBackground(l10n: l10n),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                await vm.toggleFreeze(task);
                                return false;
                              } else {
                                return _confirmSingleDelete(context, l10n);
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
                              onLongPress: () => vm.toggleSelection(task.id),
                            ),
                          );
                        },
                      ),
              ),
              const AdBanner(key: Key('ad_banner')),
            ],
          ),
          floatingActionButton: (!isSelectionMode && data.canManage)
              ? FloatingActionButton(
                  key: const Key('create_task_fab'),
                  tooltip: l10n.tasks_create_title,
                  onPressed: () => context.push(AppRoutes.createTask),
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
