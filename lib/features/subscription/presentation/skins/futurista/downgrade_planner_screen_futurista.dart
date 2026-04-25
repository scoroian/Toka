// lib/features/subscription/presentation/skins/futurista/downgrade_planner_screen_futurista.dart
//
// Pantalla "DowngradePlanner" en skin futurista. Consume el mismo VM que
// la variante v2 (`downgradePlannerViewModelProvider` +
// `downgradePlannerViewModelNotifierProvider.notifier`).
//
// Layout (lenguaje futurista, sin canvas):
//   - AppBar igual al v2.
//   - Display "Decide qué conservar" (24/800).
//   - Subtitle 13 muted.
//   - Card miembros (surfaceContainerHighest, radius 16): header mono uppercase
//     + hint l10n.downgrade_planner_max_members_hint + lista con avatares y
//     Switch (deshabilitado para owner).
//   - Card tareas (surfaceContainerHighest, radius 16): header mono uppercase
//     + hint l10n.downgrade_planner_max_tasks_hint + Wrap de chips toggle.
//   - Nota auto + CTA primary lg fullWidth "Guardar plan".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../homes/application/current_home_provider.dart';
import '../../../../homes/application/dashboard_provider.dart';
import '../../../../homes/domain/home_membership.dart';
import '../../../../members/application/members_provider.dart';
import '../../../../members/domain/member.dart';
import '../../../application/downgrade_planner_view_model.dart';

class DowngradePlannerScreenFuturista extends ConsumerWidget {
  const DowngradePlannerScreenFuturista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurfaceVariant;

    final vm = ref.watch(downgradePlannerViewModelProvider);
    final state = ref.watch(downgradePlannerViewModelNotifierProvider);
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
                  const SizedBox(height: 8),
                  Text(
                    'Decide qué conservar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.15,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Elige los miembros y tareas que seguirán activos en Free.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Card miembros
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.downgrade_planner_members_section
                                  .toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: muted,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${state.selectedMemberIds.length}/3',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.downgrade_planner_max_members_hint,
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 12),
                        membersAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => Text(l10n.error_generic),
                          data: (members) {
                            final active = members
                                .where((m) =>
                                    m.status == MemberStatus.active)
                                .toList();
                            return _MembersList(
                              members: active,
                              ownerUid: home.ownerUid,
                              selected: state.selectedMemberIds,
                              onToggle: (uid, checked) => ref
                                  .read(downgradePlannerViewModelNotifierProvider
                                      .notifier)
                                  .toggleMember(uid, checked),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card tareas
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.downgrade_planner_tasks_section
                                  .toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: muted,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${state.selectedTaskIds.length}/4',
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.downgrade_planner_max_tasks_hint,
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => Text(l10n.error_generic),
                          data: (dash) {
                            if (dash == null) return const SizedBox.shrink();
                            final tasks = dash.activeTasksPreview;
                            if (tasks.isEmpty) return const SizedBox.shrink();
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tasks.map((t) {
                                final isOn =
                                    state.selectedTaskIds.contains(t.taskId);
                                return InkWell(
                                  key: Key('task_check_${t.taskId}'),
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => ref
                                      .read(downgradePlannerViewModelNotifierProvider
                                          .notifier)
                                      .toggleTask(t.taskId, !isOn),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isOn
                                          ? cs.primary.withValues(alpha: 0.14)
                                          : theme.scaffoldBackgroundColor,
                                      border: Border.all(
                                        color: isOn
                                            ? cs.primary
                                                .withValues(alpha: 0.55)
                                            : theme.dividerColor,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isOn)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 6),
                                            child: Icon(
                                              Icons.check,
                                              size: 14,
                                              color: cs.primary,
                                            ),
                                          ),
                                        Text(
                                          t.title,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            decoration: isOn
                                                ? null
                                                : TextDecoration.lineThrough,
                                            color: isOn
                                                ? cs.onSurface
                                                : cs.onSurface
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.downgrade_planner_auto_note,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TockaBtn(
                      key: const Key('btn_save_plan'),
                      variant: TockaBtnVariant.primary,
                      size: TockaBtnSize.lg,
                      fullWidth: true,
                      onPressed: () async {
                        await vm.savePlan();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.downgrade_planner_saved),
                            ),
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
    required this.ownerUid,
    required this.selected,
    required this.onToggle,
  });

  final List<Member> members;
  final String ownerUid;
  final Set<String> selected;
  final void Function(String uid, bool checked) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final muted = cs.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        for (var i = 0; i < members.length; i++) ...[
          if (i > 0)
            Container(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _MemberRow(
              key: Key('member_check_${members[i].uid}'),
              member: members[i],
              isOwner: members[i].uid == ownerUid,
              isChecked: selected.contains(members[i].uid),
              onToggle: onToggle,
              cs: cs,
              muted: muted,
              ownerLabel: l10n.members_role_badge_owner,
            ),
          ),
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    super.key,
    required this.member,
    required this.isOwner,
    required this.isChecked,
    required this.onToggle,
    required this.cs,
    required this.muted,
    required this.ownerLabel,
  });

  final Member member;
  final bool isOwner;
  final bool isChecked;
  final void Function(String uid, bool checked) onToggle;
  final ColorScheme cs;
  final Color muted;
  final String ownerLabel;

  @override
  Widget build(BuildContext context) {
    final initial = member.nickname.isNotEmpty
        ? member.nickname[0].toUpperCase()
        : '?';
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                cs.primary.withValues(alpha: 0.67),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.nickname,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              if (isOwner)
                Text(
                  ownerLabel,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: isChecked,
          onChanged:
              isOwner ? null : (v) => onToggle(member.uid, v),
        ),
      ],
    );
  }
}
