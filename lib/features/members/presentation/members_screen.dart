import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/members_view_model.dart';
import 'widgets/invite_member_sheet.dart';
import 'widgets/member_card.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

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
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(l10n.members_title)),
          floatingActionButton: data.canInvite
              ? FloatingActionButton.extended(
                  key: const Key('fab_invite'),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => InviteMemberSheet(homeId: data.homeId),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.members_invite_fab),
                )
              : null,
          body: ListView(
            key: const Key('members_list'),
            children: [
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
                      member: m,
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
                      member: m,
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
