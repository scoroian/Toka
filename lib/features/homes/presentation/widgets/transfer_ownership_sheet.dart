// lib/features/homes/presentation/widgets/transfer_ownership_sheet.dart
//
// Sheet para transferir la propiedad del hogar. Llamada desde
// `home_settings_screen_v2`. Usa el
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
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../members/application/member_actions_provider.dart';
import '../../../members/application/members_provider.dart';
import '../../../members/domain/member.dart';
import '../../../members/presentation/widgets/member_role_badge.dart';
import '../../application/homes_provider.dart';
import '../../domain/home_membership.dart';

/// Sheet para elegir nuevo propietario.
///
/// [leaveAfter] = true encadena "Transferir y salir" (Hallazgo #12): tras
/// ceder la propiedad, el caller (ex-owner, ya degradado a admin) abandona el
/// hogar. Es la salida limpia del owner, que NO puede usar "Abandonar"
/// directamente.
Future<void> showTransferOwnershipSheet(
  BuildContext context, {
  required String homeId,
  bool leaveAfter = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _TransferOwnershipSheet(homeId: homeId, leaveAfter: leaveAfter),
  );
}

class _TransferOwnershipSheet extends ConsumerWidget {
  const _TransferOwnershipSheet({
    required this.homeId,
    this.leaveAfter = false,
  });

  final String homeId;
  final bool leaveAfter;

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
            leaveAfter
                ? l10n.homes_transfer_and_leave_title
                : l10n.homes_transfer_ownership_title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            leaveAfter
                ? l10n.homes_transfer_and_leave_body
                : l10n.homes_transfer_ownership_body,
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
    final displayName = newOwner.nickname.isNotEmpty ? newOwner.nickname : '—';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          leaveAfter
              ? l10n.homes_transfer_and_leave_confirm_title
              : l10n.homes_transfer_confirm_title,
        ),
        content: Text(
          leaveAfter
              ? l10n.homes_transfer_and_leave_confirm_body(displayName)
              : l10n.homes_transfer_confirm_body(displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('btn_transfer_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              leaveAfter ? l10n.homes_transfer_and_leave : l10n.homes_transfer_btn,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Capturamos messengers/navigator/router/uid ANTES de los awaits para no
    // usar context tras un await (regla de Flutter — el context puede haberse
    // desmontado).
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // GoRouter/authProvider solo son necesarios en el flujo "transferir y salir".
    // Los leemos condicionalmente para no exigir un GoRouter ancestro ni
    // inicializar authProvider en el flujo de transferencia simple.
    final router = leaveAfter ? GoRouter.of(context) : null;
    final myUid = leaveAfter
        ? (ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '')
        : '';
    // IMPORTANTE: cerramos el sheet (maybePop) ANTES de mostrar el SnackBar en
    // TODOS los caminos. El SnackBar del ScaffoldMessenger se pinta al fondo de
    // la pantalla; si el bottom sheet sigue abierto queda tapado por él y el
    // usuario no ve el mensaje (verificado en dispositivo: el aviso de
    // payer-lock era invisible porque el sheet permanecía encima).
    try {
      await ref
          .read(memberActionsProvider.notifier)
          .transferOwnership(homeId, newOwner.uid);
      if (leaveAfter) {
        // Transferir y salir: ya degradado a admin, ahora sí puede abandonar.
        // Si la transferencia pasó el payer-lock, leaveHome tampoco lo gatea
        // (el ex-owner ya no es el pagador con Premium vigente).
        await ref
            .read(homesRepositoryProvider)
            .leaveHome(homeId, uid: myUid);
        navigator.maybePop();
        router!.go(AppRoutes.home);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.homes_transfer_and_left)),
        );
        return;
      }
      navigator.maybePop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.homes_transfer_success(displayName)),
        ),
      );
    } on PayerLockedException {
      // El repo mapea `payer-cannot-transfer-ownership-while-premium-active`
      // (failed-precondition) a PayerLockedException. Mostramos el mensaje
      // específico para que el usuario sepa que debe cancelar la suscripción /
      // esperar al fin del periodo antes de transferir.
      navigator.maybePop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.homes_transfer_error_payer_locked)),
      );
    } catch (_) {
      navigator.maybePop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.error_generic)),
      );
    }
  }
}
