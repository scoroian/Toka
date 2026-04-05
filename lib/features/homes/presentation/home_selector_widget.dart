import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../application/current_home_provider.dart';
import '../application/homes_provider.dart';
import '../domain/home_membership.dart';

@visibleForTesting
List<HomeMembership> sortMembershipsForSelector(
  List<HomeMembership> memberships, {
  required String currentHomeId,
}) {
  final result = [...memberships];
  result.sort((a, b) {
    if (a.homeId == currentHomeId) return -1;
    if (b.homeId == currentHomeId) return 1;
    return a.homeNameSnapshot.compareTo(b.homeNameSnapshot);
  });
  return result;
}

class HomeSelectorWidget extends ConsumerWidget {
  const HomeSelectorWidget({super.key});

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
    final currentHomeAsync = ref.watch(currentHomeProvider);
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid);

    final currentHome = currentHomeAsync.valueOrNull;
    final currentHomeId = currentHome?.id ?? '';

    final membershipsAsync =
        uid != null ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];

    final hasMultiple = memberships.length > 1;

    void openSelector() {
      if (!hasMultiple) return;
      final sorted = sortMembershipsForSelector(
        memberships,
        currentHomeId: currentHomeId,
      );
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.homes_selector_title,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    key: const Key('home_selector_list'),
                    shrinkWrap: true,
                    itemCount: sorted.length,
                    itemBuilder: (ctx, index) {
                      final membership = sorted[index];
                      final isActive = membership.homeId == currentHomeId;
                      return ListTile(
                        key: Key('home_tile_${membership.homeId}'),
                        title: Text(membership.homeNameSnapshot),
                        subtitle: Text(_roleLabel(membership.role, l10n)),
                        trailing: isActive
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ref
                              .read(currentHomeProvider.notifier)
                              .switchHome(membership.homeId);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return GestureDetector(
      key: const Key('home_selector'),
      onTap: hasMultiple ? openSelector : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentHome?.name ?? l10n.loading,
            style: Theme.of(context).appBarTheme.titleTextStyle ??
                Theme.of(context).textTheme.titleLarge,
          ),
          if (hasMultiple) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              key: Key('selector_arrow'),
            ),
          ],
        ],
      ),
    );
  }
}
