// lib/features/members/presentation/skins/futurista/members_screen_futurista.dart
//
// Pantalla "Miembros" en skin Futurista. Consume el mismo
// `membersViewModelProvider` que `MembersScreenV2` y reutiliza
// `InviteMemberSheet`. Layout según canvas `skin_futurista/screens-people.jsx`:
//
//   1. TockaTopBar.
//   2. Row "Hogar" + TockaBtn "Invitar".
//   3. Hero "Equilibrio del hogar" con TockaRing y mensaje derivado.
//   4. Lista de members: avatar + display name + handle/role + stats + ring %.
//   5. Padding inferior compatible con NavBar/banner via `AdAwareBottomPadding`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/futurista/futurista_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/tocka_avatar.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../../../shared/widgets/futurista/tocka_ring.dart';
import '../../../../../shared/widgets/futurista/tocka_top_bar.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../../homes/application/current_home_provider.dart';
import '../../../../homes/domain/home_membership.dart';
import '../../../application/members_view_model.dart';
import '../../../domain/member.dart';
import '../../widgets/invite_member_sheet.dart';

class MembersScreenFuturista extends ConsumerWidget {
  const MembersScreenFuturista({super.key});

  static const _mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = ref.watch(membersViewModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: vm.viewData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.error_generic)),
          data: (data) {
            final homeAsync = ref.watch(currentHomeProvider);
            final home = homeAsync.valueOrNull;
            final homeName = home?.name ?? l10n.members_title;

            if (data == null) {
              return Column(
                children: [
                  TockaTopBar(homeName: homeName, members: const []),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.members_no_home_body,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final auth = ref.watch(authProvider);
            final myUid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

            final all = [
              ...data.activeMembers,
              ...data.frozenMembers,
            ];
            final topBarMembers = all
                .take(3)
                .map<MemberAvatar>((m) =>
                    (name: m.nickname, color: _colorForUid(m.uid)))
                .toList();

            final balance = _balanceFromMembers(data.activeMembers);
            final balanceMessage = _balanceMessage(l10n, data, balance);

            return ListView(
              key: const Key('members_list'),
              padding: EdgeInsets.only(
                bottom: adAwareBottomPadding(context, ref, extra: 80),
              ),
              children: [
                TockaTopBar(homeName: homeName, members: topBarMembers),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          home?.name ?? l10n.members_title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      if (data.canInvite)
                        TockaBtn(
                          key: const Key('fab_invite'),
                          variant: TockaBtnVariant.soft,
                          size: TockaBtnSize.sm,
                          icon: const Icon(Icons.person_add),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                InviteMemberSheet(homeId: data.homeId),
                          ),
                          child: Text(l10n.members_invite_fab),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _BalanceHero(
                    value: balance,
                    label: balanceMessage,
                  ),
                ),
                if (data.activeMembers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                    child: Text(
                      l10n.members_section_active.toUpperCase(),
                      key: const Key('section_active'),
                      style: _mono.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.42),
                      ),
                    ),
                  ),
                  ...data.activeMembers.map(
                    (m) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _MemberRowFuturista(
                        member: m,
                        isMine: m.uid == myUid,
                        onTap: () => context.push(
                          AppRoutes.memberProfile.replaceFirst(':uid', m.uid),
                          extra: {'homeId': data.homeId},
                        ),
                      ),
                    ),
                  ),
                ],
                if (data.frozenMembers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                    child: Text(
                      l10n.members_section_frozen.toUpperCase(),
                      key: const Key('section_frozen'),
                      style: _mono.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.42),
                      ),
                    ),
                  ),
                  ...data.frozenMembers.map(
                    (m) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _MemberRowFuturista(
                        member: m,
                        isMine: m.uid == myUid,
                        onTap: () => context.push(
                          AppRoutes.memberProfile.replaceFirst(':uid', m.uid),
                          extra: {'homeId': data.homeId},
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers de presentación
  // ---------------------------------------------------------------------------

  /// Equilibrio derivado del promedio de complianceRate de los miembros activos.
  /// CONCERN: el VM aún no expone un campo `householdBalance`; usamos el
  /// promedio del cumplimiento como proxy estable y derivado del propio dato.
  double _balanceFromMembers(List<Member> activeMembers) {
    if (activeMembers.isEmpty) return 0.82; // placeholder canvas
    final sum = activeMembers.fold<double>(
      0,
      (acc, m) => acc + m.complianceRate.clamp(0, 1),
    );
    return (sum / activeMembers.length).clamp(0.0, 1.0);
  }

  /// Mensaje contextual: si todos los activos tienen compliance similar
  /// devolvemos "Bien repartido"; si hay diferencia significativa, mencionamos
  /// al miembro con más tareas hechas.
  String _balanceMessage(
    AppLocalizations l10n,
    MembersViewData data,
    double balance,
  ) {
    final actives = data.activeMembers;
    if (actives.length < 2) return l10n.members_section_active;
    final sorted = [...actives]
      ..sort((a, b) => b.tasksCompleted.compareTo(a.tasksCompleted));
    final top = sorted.first;
    final rest = sorted.sublist(1);
    final avgRest = rest.fold<int>(0, (a, m) => a + m.tasksCompleted) /
        rest.length;
    final diff = (top.tasksCompleted - avgRest).round();
    if (diff <= 1) return l10n.members_section_active;
    return '${top.nickname} +$diff';
  }
}

// -----------------------------------------------------------------------------
// Hero "Equilibrio del hogar"
// -----------------------------------------------------------------------------

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final percent = (value * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          TockaRing(
            value: value,
            size: 52,
            stroke: 5,
            color: cs.primary,
            child: Text(
              '$percent%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EQUILIBRIO DEL HOGAR',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                  ).copyWith(color: cs.onSurface.withValues(alpha: 0.42)),
                ),
                const SizedBox(height: 4),
                Text(
                  percent >= 75 ? 'Bien repartido' : 'Desequilibrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Card de miembro futurista
// -----------------------------------------------------------------------------

class _MemberRowFuturista extends StatelessWidget {
  const _MemberRowFuturista({
    required this.member,
    required this.isMine,
    required this.onTap,
  });

  final Member member;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final frozen = member.status == MemberStatus.frozen;
    final color = _colorForUid(member.uid);
    final compl = member.complianceRate.clamp(0.0, 1.0);
    final complPercent = (compl * 100).round();
    final isOwner = member.role == MemberRole.owner;

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMine
              ? cs.primary.withValues(alpha: 0.25)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          TockaAvatar(
            name: member.nickname.isNotEmpty ? member.nickname : '?',
            color: color,
            size: 44,
            ring: isMine && !frozen ? cs.primary : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.nickname.isNotEmpty ? member.nickname : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.workspace_premium,
                        size: 14,
                        color: FuturistaColors.premium,
                      ),
                    ],
                    if (frozen) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.ac_unit,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '@${_handle(member.nickname)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TockaPill(
                      color: isOwner ? cs.primary : null,
                      child: Text(_roleLabel(member.role)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${member.tasksCompleted} hechas',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${member.passedCount} pases',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '· $complPercent%',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: FuturistaColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!frozen) ...[
            const SizedBox(width: 8),
            TockaRing(
              value: compl,
              size: 36,
              stroke: 3,
              color: cs.primary,
            ),
          ],
        ],
      ),
    );

    final wrapped = Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('member_card_${member.uid}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );

    if (frozen) return Opacity(opacity: 0.55, child: wrapped);
    return wrapped;
  }

  String _handle(String nickname) {
    final n = nickname.trim().toLowerCase();
    if (n.isEmpty) return 'user';
    return n.replaceAll(RegExp(r'\s+'), '_');
  }

  String _roleLabel(MemberRole role) => switch (role) {
        MemberRole.owner => 'Owner',
        MemberRole.admin => 'Admin',
        MemberRole.member => 'Member',
        MemberRole.frozen => 'Frozen',
      };
}

// -----------------------------------------------------------------------------
// Helpers compartidos
// -----------------------------------------------------------------------------

Color _colorForUid(String uid) {
  if (uid.isEmpty) return FuturistaColors.primary;
  const palette = <Color>[
    FuturistaColors.primary,
    FuturistaColors.primaryAlt,
    FuturistaColors.success,
    FuturistaColors.warning,
    FuturistaColors.error,
  ];
  final idx = uid.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
  return palette[idx];
}

