// lib/features/homes/presentation/widgets/admins_sheet.dart
//
// Sheet de gestión de administradores. Lista los miembros del hogar y
// permite al owner promocionar/degradar roles. Llama a las callables
// `promoteToAdmin` / `demoteFromAdmin` ya implementadas vía
// `MemberActionsProvider`.
//
// Reglas de negocio (validadas también server-side):
//   - Solo el owner puede promocionar/degradar (la pantalla esconde el
//     tile si !isOwner).
//   - El owner aparece marcado pero no es manipulable (no se puede
//     "degradar" un owner; eso es transferir propiedad, otro flujo).
//   - Free plan: la promoción a admin está bloqueada. Mostramos el botón
//     deshabilitado con tooltip explicativo en vez de dejar que el
//     usuario espere a que la callable falle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../../homes/application/dashboard_provider.dart';
import '../../../homes/domain/home_membership.dart';
import '../../../members/application/member_actions_provider.dart';
import '../../../members/application/members_provider.dart';
import '../../../members/domain/member.dart';
import '../../../members/presentation/widgets/member_role_badge.dart';

Future<void> showAdminsSheet(
  BuildContext context, {
  required String homeId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AdminsSheet(homeId: homeId),
  );
}

class _AdminsSheet extends ConsumerWidget {
  const _AdminsSheet({required this.homeId});

  final String homeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final membersAsync = ref.watch(homeMembersProvider(homeId));
    final dashboard = ref.watch(dashboardProvider).valueOrNull;
    final isPremium = dashboard?.premiumFlags.isPremium ?? false;
    final bottomPad = bottomSheetSafeBottom(context, ref, hasNavBar: true);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPad + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homes_admins_sheet_title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homes_admins_sheet_body,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: membersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.error_generic,
                    style: TextStyle(color: cs.error)),
              ),
              data: (members) {
                final actives = members
                    .where((m) => m.status != MemberStatus.frozen)
                    .toList()
                  ..sort((a, b) {
                    // Owner primero, luego admins, luego members. Útil para
                    // que el owner siempre se vea arriba y el siguiente
                    // candidato a promover quede a un scroll de distancia.
                    int rank(MemberRole r) => switch (r) {
                          MemberRole.owner => 0,
                          MemberRole.admin => 1,
                          MemberRole.member => 2,
                          MemberRole.frozen => 3,
                        };
                    return rank(a.role).compareTo(rank(b.role));
                  });
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: actives.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final m = actives[i];
                    return _AdminRow(
                      key: Key('admin_row_${m.uid}'),
                      member: m,
                      homeId: homeId,
                      isPremium: isPremium,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminRow extends ConsumerWidget {
  const _AdminRow({
    super.key,
    required this.member,
    required this.homeId,
    required this.isPremium,
  });

  final Member member;
  final String homeId;
  final bool isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final canPromote = member.role == MemberRole.member && isPremium;
    final canDemote = member.role == MemberRole.admin;

    Widget? trailing;
    if (member.role == MemberRole.member) {
      trailing = Tooltip(
        message: isPremium ? '' : l10n.homes_admins_promote_blocked_free,
        child: TextButton.icon(
          key: Key('promote_${member.uid}'),
          onPressed: canPromote
              ? () => _act(context, ref,
                  () => ref
                      .read(memberActionsProvider.notifier)
                      .promoteToAdmin(homeId, member.uid))
              : null,
          icon: const Icon(Icons.arrow_upward, size: 16),
          label: Text(l10n.homes_admins_promote),
        ),
      );
    } else if (canDemote) {
      trailing = TextButton.icon(
        key: Key('demote_${member.uid}'),
        style: TextButton.styleFrom(foregroundColor: cs.error),
        onPressed: () => _act(
          context,
          ref,
          () => ref
              .read(memberActionsProvider.notifier)
              .demoteFromAdmin(homeId, member.uid),
        ),
        icon: const Icon(Icons.arrow_downward, size: 16),
        label: Text(l10n.homes_admins_demote),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
        child: member.photoUrl == null
            ? Text(member.nickname.isNotEmpty
                ? member.nickname[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Text(
        member.nickname.isNotEmpty ? member.nickname : '—',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [MemberRoleBadge(role: member.role)],
      ),
      trailing: trailing,
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on Exception catch (e) {
      // free_limit_admins viene como FirebaseFunctionsException con
      // code='failed-precondition' y message contiene 'free_limit_admins'.
      // Mantenemos esta detección por mensaje porque el repo Dart aún
      // no convierte códigos de error a tipos del dominio.
      final msg = e.toString();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            msg.contains('free_limit_admins')
                ? l10n.homes_admins_promote_blocked_free
                : l10n.error_generic,
          ),
        ),
      );
    }
  }
}
