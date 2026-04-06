// lib/features/subscription/presentation/downgrade_planner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../../homes/application/dashboard_provider.dart';
import '../application/paywall_provider.dart';

class DowngradePlannerScreen extends ConsumerStatefulWidget {
  const DowngradePlannerScreen({super.key});

  @override
  ConsumerState<DowngradePlannerScreen> createState() => _DowngradePlannerScreenState();
}

class _DowngradePlannerScreenState extends ConsumerState<DowngradePlannerScreen> {
  Set<String> _selectedMemberIds = {};
  Set<String> _selectedTaskIds = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeAsync = ref.watch(currentHomeProvider);
    final home = homeAsync.valueOrNull;
    if (home == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final membersAsync = ref.watch(homeMembersProvider(home.id));
    final dashAsync = ref.watch(dashboardProvider);
    final paywallState = ref.watch(paywallProvider);

    // Initialize selection on first data
    if (!_initialized) {
      membersAsync.whenData((members) {
        dashAsync.whenData((dash) {
          if (dash != null && mounted) {
            setState(() {
              _selectedMemberIds = members
                  .where((m) => m.status == MemberStatus.active)
                  .map((m) => m.uid)
                  .toSet();
              _selectedTaskIds = dash.activeTasksPreview
                  .map((t) => t.taskId)
                  .toSet();
              _initialized = true;
            });
          }
        });
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downgrade_planner_title)),
      body: paywallState.isLoading
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
                      selected: _selectedMemberIds,
                      ownerId: home.ownerUid,
                      onToggle: (uid, checked) {
                        final newSelected = Set<String>.from(_selectedMemberIds);
                        if (checked) {
                          if (newSelected.length < 3) newSelected.add(uid);
                        } else {
                          newSelected.remove(uid);
                        }
                        setState(() => _selectedMemberIds = newSelected);
                      },
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
                            selected: _selectedTaskIds,
                            onToggle: (id, checked) {
                              final newSelected = Set<String>.from(_selectedTaskIds);
                              if (checked) {
                                if (newSelected.length < 4) newSelected.add(id);
                              } else {
                                newSelected.remove(id);
                              }
                              setState(() => _selectedTaskIds = newSelected);
                            },
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
                        await ref.read(paywallProvider.notifier).saveDowngradePlan(
                              homeId: home.id,
                              memberIds: _selectedMemberIds.toList(),
                              taskIds: _selectedTaskIds.toList(),
                            );
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
          subtitle: isOwner ? const Text('Owner') : null,
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
