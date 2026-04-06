import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/homes/application/current_home_provider.dart';
import '../../../features/homes/application/homes_provider.dart';
import '../../../features/homes/domain/home_membership.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/members_provider.dart';
import 'widgets/invite_member_sheet.dart';
import 'widgets/member_card.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentHomeAsync = ref.watch(currentHomeProvider);
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

    return currentHomeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.members_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.members_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (home) {
        if (home == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.members_title)),
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

        final canInvite = myMembership?.role == MemberRole.owner ||
            myMembership?.role == MemberRole.admin;

        final membersAsync = ref.watch(homeMembersProvider(home.id));

        return Scaffold(
          appBar: AppBar(title: Text(l10n.members_title)),
          floatingActionButton: canInvite
              ? FloatingActionButton.extended(
                  key: const Key('fab_invite'),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => InviteMemberSheet(homeId: home.id),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.members_invite_fab),
                )
              : null,
          body: membersAsync.when(
            loading: () => const LoadingWidget(),
            error: (_, __) => Center(child: Text(l10n.error_generic)),
            data: (members) {
              final active = members
                  .where((m) => m.status == MemberStatus.active)
                  .toList();
              final frozen = members
                  .where((m) => m.status == MemberStatus.frozen)
                  .toList();

              return ListView(
                key: const Key('members_list'),
                children: [
                  if (active.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.members_section_active,
                        key: const Key('section_active'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    ...active.map((m) => MemberCard(
                          member: m,
                          onTap: () => context.push(
                            AppRoutes.memberProfile
                                .replaceFirst(':uid', m.uid),
                            extra: {'homeId': home.id},
                          ),
                        )),
                  ],
                  if (frozen.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.members_section_frozen,
                        key: const Key('section_frozen'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    ...frozen.map((m) => MemberCard(
                          member: m,
                          onTap: () => context.push(
                            AppRoutes.memberProfile
                                .replaceFirst(':uid', m.uid),
                            extra: {'homeId': home.id},
                          ),
                        )),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
