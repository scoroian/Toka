import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../application/tasks_provider.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import 'widgets/task_card.dart';

class AllTasksScreen extends ConsumerStatefulWidget {
  const AllTasksScreen({super.key});

  @override
  ConsumerState<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends ConsumerState<AllTasksScreen> {
  TaskStatus _filter = TaskStatus.active;
  String? _assigneeFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeAsync = ref.watch(currentHomeProvider);
    final authState = ref.watch(authProvider);
    final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

    return homeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.tasks_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.tasks_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (home) {
        if (home == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.tasks_title)),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        final membershipsAsync = uid.isNotEmpty
            ? ref.watch(userMembershipsProvider(uid))
            : null;
        final memberships = membershipsAsync?.valueOrNull ?? [];
        final myMembership = memberships
            .where((m) => m.homeId == home.id)
            .cast<HomeMembership?>()
            .firstOrNull;
        final myRole = myMembership?.role;
        final canCreate =
            myRole == MemberRole.owner || myRole == MemberRole.admin;

        final tasksAsync = ref.watch(homeTasksProvider(home.id));

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tasks_title),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _FilterBar(
                current: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
            ),
          ),
          body: tasksAsync.when(
            loading: () => const LoadingWidget(),
            error: (_, __) => Center(child: Text(l10n.error_generic)),
            data: (allTasks) {
              var tasks = allTasks.where((t) => t.status == _filter).toList();
              if (_assigneeFilter != null) {
                tasks = tasks
                    .where((t) => t.currentAssigneeUid == _assigneeFilter)
                    .toList();
              }
              tasks.sort((a, b) => a.nextDueAt.compareTo(b.nextDueAt));

              if (tasks.isEmpty) {
                return Center(
                    key: const Key('tasks_empty_state'),
                    child: Text(l10n.tasks_empty_title));
              }

              return ListView.builder(
                key: const Key('tasks_list'),
                itemCount: tasks.length,
                itemBuilder: (_, i) {
                  final task = tasks[i];
                  return Dismissible(
                    key: Key('dismissible_${task.id}'),
                    background: _FreezeBackground(l10n: l10n),
                    secondaryBackground: _DeleteBackground(l10n: l10n),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        await _toggleFreeze(context, task, home.id);
                        return false;
                      } else {
                        return _confirmDelete(context, l10n);
                      }
                    },
                    onDismissed: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        await ref
                            .read(tasksRepositoryProvider)
                            .deleteTask(home.id, task.id, uid);
                      }
                    },
                    child: TaskCard(
                      task: task,
                      onTap: () =>
                          context.go('/task/${task.id}'),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: canCreate
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

  Future<void> _toggleFreeze(
      BuildContext context, Task task, String homeId) async {
    final repo = ref.read(tasksRepositoryProvider);
    if (task.status == TaskStatus.active) {
      await repo.freezeTask(homeId, task.id);
    } else {
      await repo.unfreezeTask(homeId, task.id);
    }
  }

  Future<bool> _confirmDelete(
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
  Widget build(BuildContext context) {
    return Container(
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
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
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
}
