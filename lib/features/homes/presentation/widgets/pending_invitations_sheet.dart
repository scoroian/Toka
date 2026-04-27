// lib/features/homes/presentation/widgets/pending_invitations_sheet.dart
//
// Sheet con la lista de invitaciones pendientes (no usadas y no expiradas).
// Permite revocar cualquiera con un tap. La fuente es el stream
// `pendingInvitationsProvider(homeId)` que apunta a la colección
// `homes/{homeId}/invitations` filtrada por `used==false` y descarta las
// expiradas en cliente.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../../members/application/member_actions_provider.dart';
import '../../../members/application/members_provider.dart';
import '../../domain/invitation.dart';

Future<void> showPendingInvitationsSheet(
  BuildContext context, {
  required String homeId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PendingInvitationsSheet(homeId: homeId),
  );
}

class _PendingInvitationsSheet extends ConsumerWidget {
  const _PendingInvitationsSheet({required this.homeId});

  final String homeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final invsAsync = ref.watch(pendingInvitationsProvider(homeId));
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
            l10n.homes_invitations_sheet_title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: invsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.error_generic,
                    style: TextStyle(color: cs.error)),
              ),
              data: (invs) {
                if (invs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.homes_invitations_empty,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: invs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _InvitationRow(
                    key: Key('invitation_row_${invs[i].id}'),
                    invitation: invs[i],
                    homeId: homeId,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationRow extends ConsumerWidget {
  const _InvitationRow({
    super.key,
    required this.invitation,
    required this.homeId,
  });

  final Invitation invitation;
  final String homeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final remaining = _humanizeDuration(
      invitation.expiresAt.difference(DateTime.now()),
    );
    final isExpiringSoon =
        invitation.expiresAt.difference(DateTime.now()).inHours < 24;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.primary.withValues(alpha: 0.30)),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.qr_code, size: 20),
      ),
      title: Text(
        invitation.code,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
      subtitle: Text(
        l10n.homes_invitations_expires_in(remaining),
        style: TextStyle(
          color: isExpiringSoon ? cs.error : cs.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: TextButton.icon(
        key: Key('revoke_${invitation.id}'),
        style: TextButton.styleFrom(foregroundColor: cs.error),
        onPressed: () => _revoke(context, ref),
        icon: const Icon(Icons.close, size: 16),
        label: Text(l10n.homes_invitations_revoke),
      ),
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(memberActionsProvider.notifier)
          .revokeInvitation(homeId, invitation.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.homes_invitations_revoked)),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.error_generic)));
    }
  }

  /// Devuelve "5d 3h", "12h", "45 min" — útil como subtítulo compacto. La
  /// granularidad se ajusta automáticamente al tamaño restante.
  String _humanizeDuration(Duration d) {
    if (d.isNegative) return '0 min';
    final days = d.inDays;
    final hoursTotal = d.inHours;
    final hours = hoursTotal - days * 24;
    if (days >= 1) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    if (hoursTotal >= 1) return '${hoursTotal}h';
    return '${d.inMinutes} min';
  }
}
