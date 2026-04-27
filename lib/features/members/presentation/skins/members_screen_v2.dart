import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/no_home_empty_state.dart';
import '../../../../shared/widgets/premium_upgrade_banner.dart';
import '../../../../shared/widgets/skins/main_shell_v2.dart';
import '../../../profile/application/profile_provider.dart';
import '../../../profile/domain/user_profile.dart';
import '../../application/members_view_model.dart';
import '../../domain/member.dart';
import '../widgets/invite_member_sheet.dart';
import '../widgets/member_card.dart';

class MembersScreenV2 extends ConsumerWidget {
  const MembersScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(membersViewModelProvider);

    return vm.viewData.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.members_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.members_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.members_title)),
            body: NoHomeEmptyState(
              title: l10n.members_no_home_title,
              body: l10n.members_no_home_body,
            ),
          );
        }

        // Para miembros cuyo documento homes/{homeId}/members/{uid} no tiene
        // nickname/photoUrl (cuando el CF no los denormalizó), hacemos fallback
        // al perfil del usuario en users/{uid}.
        final allMembers = [
          ...data.activeMembers,
          ...data.frozenMembers,
        ];
        final profileFallback = <String, UserProfile>{};
        for (final m in allMembers) {
          if (m.nickname.isEmpty || m.photoUrl == null) {
            final profile = ref.watch(userProfileProvider(m.uid)).valueOrNull;
            if (profile != null) profileFallback[m.uid] = profile;
          }
        }

        Member enrich(Member m) {
          final profile = profileFallback[m.uid];
          if (profile == null) return m;
          return m.copyWith(
            nickname: m.nickname.isEmpty && profile.nickname.isNotEmpty
                ? profile.nickname
                : m.nickname,
            photoUrl: m.photoUrl ?? profile.photoUrl,
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.members_title)),
          floatingActionButton: data.canInvite
              ? Padding(
                  padding: EdgeInsets.only(
                    bottom: MainShellV2.fabBottomPadding(context, ref),
                  ),
                  child: FloatingActionButton.extended(
                    key: const Key('fab_invite'),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => InviteMemberSheet(homeId: data.homeId),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: Text(l10n.members_invite_fab),
                  ),
                )
              : null,
          body: ListView(
                  key: const Key('members_list'),
                  padding: EdgeInsets.only(
                    bottom: adAwareBottomPadding(context, ref, extra: 16),
                  ),
                  children: [
                    if (data.freeLimitReached)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: PremiumUpgradeBanner(
                          key: const Key('members_free_limit_banner'),
                          message: l10n.free_limit_members_reached,
                          highlight: l10n.free_members_counter(
                            data.activeMembersCount,
                            data.maxMembersFree,
                          ),
                          cta: l10n.free_go_premium_cta,
                          ctaKey: const Key('members_free_limit_banner_cta'),
                          onCta: () => context.push(AppRoutes.paywall),
                        ),
                      ),
                    if (data.activeMembers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _BalanceCardV2(
                          activeMembers: data.activeMembers,
                          l10n: l10n,
                        ),
                      ),
                    if (data.activeMembers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          l10n.members_section_active,
                          key: const Key('section_active'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      ...data.activeMembers.map((m) => MemberCard(
                            member: enrich(m),
                            onTap: () => context.push(
                              AppRoutes.memberProfile.replaceFirst(':uid', m.uid),
                              extra: {'homeId': data.homeId},
                            ),
                          )),
                    ],
                    if (data.frozenMembers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          l10n.members_section_frozen,
                          key: const Key('section_frozen'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      ...data.frozenMembers.map((m) => MemberCard(
                            member: enrich(m),
                            onTap: () => context.push(
                              AppRoutes.memberProfile.replaceFirst(':uid', m.uid),
                              extra: {'homeId': data.homeId},
                            ),
                          )),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// Tarjeta "Equilibrio del hogar" (paridad con `_BalanceHero` futurista).
///
/// Muestra el promedio de `complianceRate` de miembros activos como un
/// porcentaje con barra. Si la diferencia entre el miembro con más tareas
/// hechas y el resto es relevante (≥2), se indica nominal — útil para
/// detectar reparto desigual.
class _BalanceCardV2 extends StatelessWidget {
  const _BalanceCardV2({required this.activeMembers, required this.l10n});

  final List<Member> activeMembers;
  final AppLocalizations l10n;

  double get _balance {
    if (activeMembers.isEmpty) return 0;
    final sum = activeMembers.fold<double>(
      0,
      (acc, m) => acc + m.complianceRate.clamp(0, 1),
    );
    return (sum / activeMembers.length).clamp(0.0, 1.0);
  }

  String _topDelta() {
    if (activeMembers.length < 2) return l10n.members_section_active;
    final sorted = [...activeMembers]
      ..sort((a, b) => b.tasksCompleted.compareTo(a.tasksCompleted));
    final top = sorted.first;
    final rest = sorted.sublist(1);
    final avgRest =
        rest.fold<int>(0, (a, m) => a + m.tasksCompleted) / rest.length;
    final diff = (top.tasksCompleted - avgRest).round();
    if (diff <= 1) return l10n.members_section_active;
    return '${top.nickname} +$diff';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final value = _balance;
    final percent = (value * 100).round();
    final isBalanced = percent >= 75;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBalanced ? Icons.balance : Icons.scale_outlined,
                size: 20,
                color: isBalanced ? cs.primary : cs.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.members_balance_title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isBalanced ? cs.primary : cs.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: cs.surface,
              valueColor: AlwaysStoppedAnimation(
                isBalanced ? cs.primary : cs.tertiary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isBalanced
                ? l10n.members_balance_well_distributed
                : l10n.members_balance_unbalanced(_topDelta()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
