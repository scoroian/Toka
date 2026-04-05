import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/application/auth_provider.dart';
import '../application/current_home_provider.dart';
import '../application/homes_provider.dart';
import '../domain/home_membership.dart';

class MyHomesScreen extends ConsumerWidget {
  const MyHomesScreen({super.key});

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
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid);

    final currentHomeAsync = ref.watch(currentHomeProvider);
    final currentHomeId = currentHomeAsync.valueOrNull?.id ?? '';

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.homes_my_homes)),
        body: const SizedBox.shrink(),
      );
    }

    final membershipsAsync = ref.watch(userMembershipsProvider(uid));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homes_my_homes)),
      body: membershipsAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (memberships) => ListView.builder(
          key: const Key('my_homes_list'),
          itemCount: memberships.length,
          itemBuilder: (context, index) {
            final m = memberships[index];
            final isActive = m.homeId == currentHomeId;
            return ListTile(
              key: Key('home_list_tile_${m.homeId}'),
              title: Text(m.homeNameSnapshot),
              subtitle: Text(_roleLabel(m.role, l10n)),
              trailing: isActive
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                ref.read(currentHomeProvider.notifier).switchHome(m.homeId);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}
