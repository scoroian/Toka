import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../application/recurrence_provider.dart';
import '../application/tasks_provider.dart';
import '../domain/task_status.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final homeAsync = ref.watch(currentHomeProvider);
    final authState = ref.watch(authProvider);
    final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

    return homeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (home) {
        if (home == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        final tasksAsync = ref.watch(homeTasksProvider(home.id));
        final membershipsAsync = uid.isNotEmpty
            ? ref.watch(userMembershipsProvider(uid))
            : null;
        final memberships = membershipsAsync?.valueOrNull ?? [];
        final myMembership = memberships
            .where((m) => m.homeId == home.id)
            .cast<HomeMembership?>()
            .firstOrNull;
        final myRole = myMembership?.role;
        final canEdit =
            myRole == MemberRole.owner || myRole == MemberRole.admin;

        return tasksAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(),
            body: const LoadingWidget(),
          ),
          error: (_, __) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.error_generic)),
          ),
          data: (tasks) {
            final task =
                tasks.where((t) => t.id == taskId).cast<dynamic>().firstOrNull;
            if (task == null) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(child: Text(l10n.error_generic)),
              );
            }

            final upcoming =
                ref.watch(upcomingOccurrencesProvider(task.recurrenceRule));

            return Scaffold(
              appBar: AppBar(
                title: Text(task.title),
                actions: [
                  if (canEdit)
                    IconButton(
                      key: const Key('edit_task_button'),
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SizedBox.shrink(), // replaced by router
                        ),
                      ),
                    ),
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
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            if (task.description != null)
                              Text(task.description!),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  if (task.status == TaskStatus.frozen)
                    const Chip(
                      key: Key('frozen_chip'),
                      label: Text('Congelada'),
                      avatar: Icon(Icons.pause_circle_outline),
                    ),

                  ListTile(
                    key: const Key('current_assignee_tile'),
                    leading: const Icon(Icons.person),
                    title: Text(l10n.tasks_detail_assignment_order),
                    subtitle: Text(task.currentAssigneeUid ?? '—'),
                  ),

                  ListTile(
                    key: const Key('next_due_tile'),
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n.tasks_detail_next_occurrences),
                    subtitle: Text(
                      DateFormat.yMMMd().add_Hm().format(
                            task.nextDueAt.toLocal(),
                          ),
                    ),
                  ),

                  ListTile(
                    key: const Key('difficulty_tile'),
                    leading: const Icon(Icons.fitness_center),
                    title: Text(l10n.tasks_field_difficulty),
                    subtitle:
                        Text(task.difficultyWeight.toStringAsFixed(1)),
                  ),

                  const Divider(height: 32),

                  Text(l10n.tasks_detail_next_occurrences,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...upcoming.take(3).map((d) => ListTile(
                        dense: true,
                        title: Text(
                          DateFormat.yMMMd().add_Hm().format(d.toLocal()),
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
