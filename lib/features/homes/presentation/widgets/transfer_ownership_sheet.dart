// lib/features/homes/presentation/widgets/transfer_ownership_sheet.dart
//
// Sheet para transferir la propiedad del hogar. Llamada desde
// `home_settings_screen_v2` y `home_settings_screen_futurista`. Usa el
// `MemberActionsProvider.transferOwnership` (callable `transferOwnership`)
// que ya existe.
//
// Reglas de negocio aplicables (validadas por la Cloud Function):
//   - Solo el owner actual puede transferir (la pantalla ya esconde el tile
//     si !isOwner).
//   - El nuevo dueño debe ser miembro del hogar (cualquier estado).
//   - **Payer lock**: si el caller es `currentPayerUid` y el hogar tiene
//     Premium activo / cancelado pendiente / rescue, la CF rechaza con
//     `payer-cannot-transfer-ownership-while-premium-active`. Capturamos
//     el error y mostramos un SnackBar específico.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../../members/application/member_actions_provider.dart';
import '../../../members/application/members_provider.dart';
import '../../../members/domain/member.dart';
import '../../../members/presentation/widgets/member_role_badge.dart';
import '../../domain/home_membership.dart';

Future<void> showTransferOwnershipSheet(
  BuildContext context, {
  required String homeId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TransferOwnershipSheet(homeId: homeId),
  );
}

class _TransferOwnershipSheet extends ConsumerWidget {
  const _TransferOwnershipSheet({required this.homeId});

  final String homeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final membersAsync = ref.watch(homeMembersProvider(homeId));
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
            l10n.homes_transfer_ownership_title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homes_transfer_ownership_body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: membersAsync.when(
              loading: () =>
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.error_generic,
                    style: TextStyle(color: cs.error)),
              ),
              data: (members) {
                // Excluir owner (no se transfiere a uno mismo) y miembros
                // congelados (no pueden ser dueños activos).
                final candidates = members
                    .where((m) =>
                        m.role != MemberRole.owner &&
                        m.status != MemberStatus.frozen)
                    .toList();
                if (candidates.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.homes_transfer_no_candidates,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final m = candidates[i];
                    return ListTile(
                      key: Key('transfer_candidate_${m.uid}'),
                      leading: CircleAvatar(
                        backgroundImage: m.photoUrl != null
                            ? NetworkImage(m.photoUrl!)
                            : null,
                        child: m.photoUrl == null
                            ? Text(m.nickname.isNotEmpty
                                ? m.nickname[0].toUpperCase()
                                : '?')
                            : null,
                      ),
                      title: Text(
                        m.nickname.isNotEmpty ? m.nickname : '—',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MemberRoleBadge(role: m.role),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _confirmAndTransfer(context, ref, m),
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

  Future<void> _confirmAndTransfer(
    BuildContext context,
    WidgetRef ref,
    Member newOwner,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_transfer_confirm_title),
        content: Text(
          l10n.homes_transfer_confirm_body(
            newOwner.nickname.isNotEmpty ? newOwner.nickname : '—',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('btn_transfer_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.homes_transfer_btn),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Capturamos messengers ANTES de los awaits para no usar context
    // tras un await (regla de Flutter — el context puede haberse
    // desmontado).
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(memberActionsProvider.notifier)
          .transferOwnership(homeId, newOwner.uid);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.homes_transfer_success(
              newOwner.nickname.isNotEmpty ? newOwner.nickname : '—',
            ),
          ),
        ),
      );
      navigator.maybePop();
    } on Exception catch (e) {
      // `payer-cannot-transfer-ownership-while-premium-active` viene
      // como FirebaseFunctionsException con code='failed-precondition'.
      // Mostramos mensaje específico para que el usuario sepa que tiene
      // que cancelar la suscripción / esperar al fin del periodo.
      final errMsg = e.toString();
      final isPayerLock = errMsg.contains('payer-cannot-transfer-ownership');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isPayerLock
                ? l10n.homes_transfer_error_payer_locked
                : l10n.error_generic,
          ),
        ),
      );
    }
  }
}
