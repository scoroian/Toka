// lib/features/subscription/presentation/downgrade_planner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../homes/application/current_home_provider.dart';
import '../../../homes/application/dashboard_provider.dart';
import '../../../members/application/members_provider.dart';
import '../../../members/domain/member.dart';
import '../../../homes/domain/home_membership.dart';
import '../../application/downgrade_planner_view_model.dart';

class DowngradePlannerScreenV2 extends ConsumerWidget {
  const DowngradePlannerScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(downgradePlannerViewModelProvider);
    final homeAsync = ref.watch(currentHomeProvider);
    final home = homeAsync.valueOrNull;

    if (home == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final membersAsync = ref.watch(homeMembersProvider(home.id));
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downgrade_planner_title)),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.downgrade_planner_members_section,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(l10n.downgrade_planner_max_members_hint,
                      style: Theme.of(context).textTheme.bodySmall),
                  membersAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text(l10n.error_generic),
                    data: (members) => _MembersList(
                      members: members
                          .where((m) => m.status == MemberStatus.active)
                          .toList(),
                      selected: vm.selectedMemberIds,
                      ownerId: home.ownerUid,
                      onToggle: (uid, checked) =>
                          ref.read(downgradePlannerViewModelNotifierProvider.notifier)
                              .toggleMember(uid, checked),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.downgrade_planner_tasks_section,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(l10n.downgrade_planner_max_tasks_hint,
                      style: Theme.of(context).textTheme.bodySmall),
                  dashAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text(l10n.error_generic),
                    data: (dash) => dash == null
                        ? const SizedBox.shrink()
                        : _TasksList(
                            tasks: dash.activeTasksPreview
                                .map((t) => (t.taskId, t.title))
                                .toList(),
                            selected: vm.selectedTaskIds,
                            onToggle: (id, checked) =>
                                ref.read(downgradePlannerViewModelNotifierProvider.notifier)
                                    .toggleTask(id, checked),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.downgrade_planner_auto_note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('btn_save_plan'),
                      onPressed: () async {
                        await vm.savePlan();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.downgrade_planner_saved)),
                          );
                          context.pop();
                        }
                      },
                      child: Text(l10n.downgrade_planner_save),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({
    required this.members,
    required this.selected,
    required this.ownerId,
    required this.onToggle,
  });

  final List<Member> members;
  final Set<String> selected;
  final String ownerId;
  final void Function(String uid, bool checked) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: members.map((m) {
        final isOwner = m.uid == ownerId;
        final isChecked = selected.contains(m.uid);
        return CheckboxListTile(
          key: Key('member_check_${m.uid}'),
          title: Text(m.nickname),
          subtitle: isOwner ? Text(AppLocalizations.of(context).members_role_badge_owner) : null,
          value: isChecked,
          onChanged: isOwner ? null : (val) => onToggle(m.uid, val ?? false),
        );
      }).toList(),
    );
  }
}

class _TasksList extends StatelessWidget {
  const _TasksList({
    required this.tasks,
    required this.selected,
    required this.onToggle,
  });

  final List<(String id, String title)> tasks;
  final Set<String> selected;
  final void Function(String id, bool checked) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks.map((t) {
        final isChecked = selected.contains(t.$1);
        return CheckboxListTile(
          key: Key('task_check_${t.$1}'),
          title: Text(t.$2),
          value: isChecked,
          onChanged: (val) => onToggle(t.$1, val ?? false),
        );
      }).toList(),
    );
  }
}
