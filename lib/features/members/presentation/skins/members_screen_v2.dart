import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/no_home_empty_state.dart';
import '../../../../shared/widgets/premium_upgrade_banner.dart';
import '../../../../shared/widgets/skins/main_shell_v2.dart';
import '../../../profile/application/profile_provider.dart';
import '../../../subscription/application/member_packs_enabled_provider.dart';
import '../../../subscription/presentation/widgets/toka_business_dialog.dart';
import '../../../profile/domain/user_profile.dart';
import '../../application/member_limit.dart';
import '../../application/members_provider.dart';
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
          ...data.leftMembers,
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
                    if (data.limitReached)
                      Builder(builder: (context) {
                        final packsEnabled =
                            ref.watch(memberPacksEnabledProvider);
                        final kind = memberLimitMessageFor(
                          tier: data.tier,
                          isPremium: data.isPremium,
                          packsEnabled: packsEnabled,
                          cap: data.effectiveMaxMembers,
                        );
                        final limit = data.effectiveMaxMembers ??
                            data.activeMembersCount;
                        final showsUpsell = memberLimitShowsUpsell(kind);
                        final showsBusiness = memberLimitShowsBusiness(kind);
                        String? ctaText;
                        Key? ctaKey;
                        VoidCallback? onCta;
                        if (showsUpsell) {
                          ctaText = switch (kind) {
                            MemberLimitMessage.free => l10n.free_go_premium_cta,
                            MemberLimitMessage.grupoPacks =>
                              l10n.member_limit_add_pack_cta,
                            _ => l10n.member_limit_upgrade_cta,
                          };
                          ctaKey = const Key('members_free_limit_banner_cta');
                          onCta = () => context.push(AppRoutes.paywall);
                        } else if (showsBusiness) {
                          ctaText = l10n.member_limit_business_cta;
                          ctaKey = const Key('members_business_cta');
                          onCta = () => showTokaBusinessDialog(context);
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: PremiumUpgradeBanner(
                            key: const Key('members_free_limit_banner'),
                            message: memberLimitMessageText(l10n, kind, limit),
                            highlight: l10n.member_limit_counter(
                              data.activeMembersCount,
                              limit,
                            ),
                            cta: ctaText,
                            ctaKey: ctaKey,
                            onCta: onCta,
                          ),
                        );
                      }),
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
                    // Antiguos miembros (status='left') — reincorporables por
                    // owner/admin. Fila simple con botón inline (no navega al
                    // perfil, que no carga miembros 'left').
                    if (data.canReinstate && data.leftMembers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          l10n.members_section_left,
                          key: const Key('section_left'),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      ...data.leftMembers.map((m) {
                        final em = enrich(m);
                        final name = em.nickname.isNotEmpty ? em.nickname : m.uid;
                        return ListTile(
                          key: Key('left_member_${m.uid}'),
                          leading: CircleAvatar(
                            child: Text(name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: OutlinedButton(
                            key: Key('reinstate_${m.uid}'),
                            onPressed: () => _reinstateMember(
                                context, ref, data.homeId, m.uid, name, l10n),
                            child: Text(l10n.members_reinstate),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// Resuelve el texto localizado del mensaje de límite de miembros para un
/// [MemberLimitMessage] y el tope [limit]. Mantiene `member_limit.dart` puro
/// (sin dependencia de l10n).
String memberLimitMessageText(
  AppLocalizations l10n,
  MemberLimitMessage kind,
  int limit,
) {
  switch (kind) {
    case MemberLimitMessage.free:
      return l10n.member_limit_free(limit);
    case MemberLimitMessage.pareja:
      return l10n.member_limit_pareja(limit);
    case MemberLimitMessage.familia:
      return l10n.member_limit_familia(limit);
    case MemberLimitMessage.grupo:
      return l10n.member_limit_grupo(limit);
    case MemberLimitMessage.grupoPacks:
      return l10n.member_limit_grupo_packs(limit);
    case MemberLimitMessage.business:
      return l10n.member_limit_business(limit);
    case MemberLimitMessage.premiumMax:
      return l10n.member_limit_premium_max(limit);
  }
}

/// Reincorpora a un miembro 'left' (owner/admin) con confirmación y feedback.
Future<void> _reinstateMember(
  BuildContext context,
  WidgetRef ref,
  String homeId,
  String uid,
  String name,
  AppLocalizations l10n,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(l10n.members_reinstate),
      content: Text(l10n.members_reinstate_confirm(name)),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(l10n.cancel)),
        FilledButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l10n.confirm)),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(membersRepositoryProvider).reinstateMember(homeId, uid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.members_reinstate_success(name))));
    }
  } on MaxMembersReachedException {
    if (context.mounted) {
      final data = ref.read(membersViewModelProvider).viewData.valueOrNull;
      final message = data == null
          ? l10n.free_limit_members_reached
          : memberLimitMessageText(
              l10n,
              memberLimitMessageFor(
                  tier: data.tier, isPremium: data.isPremium),
              data.effectiveMaxMembers ?? data.activeMembersCount,
            );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.error_generic)));
    }
  }
}

/// Tarjeta "Equilibrio del hogar".
///
/// Muestra el promedio de `complianceRate` de los miembros activos como un
/// porcentaje con barra. Habla del hogar en conjunto: si el reparto está
/// desigual (≥2 miembros activos y balance < 75 %) sugiere repartir, sin
/// señalar a nadie por nombre ni usar color de alarma.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final value = _balance;
    final percent = (value * 100).round();
    // Con un solo miembro activo no hay reparto que equilibrar.
    final isBalanced = activeMembers.length < 2 || percent >= 75;
    // Neutro/informativo en desequilibrio: nunca color de alarma.
    final neutral = cs.onSurfaceVariant;

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
                color: isBalanced ? cs.primary : neutral,
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
                  color: isBalanced ? cs.primary : neutral,
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
                isBalanced ? cs.primary : cs.secondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (isBalanced)
            Text(
              l10n.members_balance_well_distributed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else ...[
            Text(
              l10n.members_balance_uneven,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('btn_balance_share'),
                onPressed: () => context.go(AppRoutes.tasks),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: Text(l10n.members_balance_share_cta),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
