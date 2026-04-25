// lib/features/homes/presentation/skins/my_homes_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../application/my_homes_view_model.dart';
import '../../domain/home_membership.dart';

class MyHomesScreenV2 extends ConsumerWidget {
  const MyHomesScreenV2({super.key});

  String _roleLabel(MemberRole role, AppLocalizations l10n) {
    switch (role) {
      case MemberRole.owner:
        return l10n.homes_role_owner;
      case MemberRole.admin:
        return l10n.homes_role_admin;
      case MemberRole.member:
      case MemberRole.frozen:
        return l10n.homes_role_member;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(myHomesViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homes_my_homes)),
      body: vm.memberships.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (memberships) => ListView.builder(
          key: const Key('my_homes_list'),
          itemCount: memberships.length,
          itemBuilder: (context, index) {
            final m = memberships[index];
            final isActive = m.homeId == vm.currentHomeId;
            return ListTile(
              key: Key('home_list_tile_${m.homeId}'),
              title: Text(m.homeNameSnapshot),
              subtitle: Text(_roleLabel(m.role, l10n)),
              trailing: isActive
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                vm.switchHome(m.homeId);
                context.pop();
              },
            );
          },
        ),
      ),
    );
  }
}
