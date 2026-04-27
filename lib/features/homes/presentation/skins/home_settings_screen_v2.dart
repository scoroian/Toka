// lib/features/homes/presentation/skins/home_settings_screen_v2.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../members/application/members_provider.dart';
import '../../../members/domain/member.dart';
import '../../../subscription/presentation/widgets/premium_state_banner.dart';
import '../../domain/home_membership.dart';
import '../../application/home_settings_view_model.dart';
import '../../domain/homes_repository.dart';
import '../widgets/admins_sheet.dart';
import '../widgets/home_avatar_sheet.dart';
import '../widgets/pending_invitations_sheet.dart';
import '../widgets/transfer_ownership_sheet.dart';

class HomeSettingsScreenV2 extends ConsumerStatefulWidget {
  const HomeSettingsScreenV2({super.key});

  @override
  ConsumerState<HomeSettingsScreenV2> createState() => _HomeSettingsScreenV2State();
}

class _HomeSettingsScreenV2State extends ConsumerState<HomeSettingsScreenV2> {
  late TextEditingController _nameController;
  bool _nameInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmLeave(
    BuildContext context,
    AppLocalizations l10n,
    HomeSettingsViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_leave_confirm_title),
        content: Text(l10n.homes_leave_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    // BUG-26: navegamos ANTES de esperar al callable. Si esperamos a que
    // resuelva, el rebuild deja currentHomeProvider == null mientras la
    // pantalla aún está montada → Scaffold zombie con error genérico
    // durante 1-2 frames antes del redirect.
    final messenger = ScaffoldMessenger.of(context);
    context.go(AppRoutes.home);
    try {
      await vm.leaveHome();
    } on CannotLeaveAsOwnerException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.homes_error_cannot_leave_as_owner)),
      );
    } on PayerLockedException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.members_error_payer_locked)),
      );
    }
  }

  Future<void> _confirmClose(
    BuildContext context,
    AppLocalizations l10n,
    HomeSettingsViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_close_confirm_title),
        content: Text(l10n.homes_close_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await vm.closeHome();
    if (context.mounted) Navigator.of(context).pop();
  }

  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  Future<void> _showDebugPremiumSheet(
    BuildContext context,
    HomeSettingsViewModel vm,
    String currentStatus,
  ) async {
    const statuses = <String>[
      'free',
      'active',
      'cancelledPendingEnd',
      'rescue',
      'expiredFree',
      'restorable',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '🧪 Debug: cambiar estado premium',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: currentStatus,
                  onChanged: (v) => Navigator.of(ctx).pop(v),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: statuses
                        .map((s) => RadioListTile<String>(
                              key: Key('debug_premium_option_$s'),
                              value: s,
                              title: Text(s),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == currentStatus) return;

    try {
      await vm.debugSetPremiumStatus(selected);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado premium: $selected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  // END DEBUG PREMIUM

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(homeSettingsViewModelProvider(l10n));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homes_settings_title)),
      body: vm.viewData.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (data) {
          if (data == null) return Center(child: Text(l10n.error_generic));

          if (!_nameInitialized) {
            _nameController.text = data.homeName;
            _nameInitialized = true;
          }

          return ListView(
            children: [
              const PremiumStateBanner(),
              // Avatar grande del hogar — tap abre el sheet (solo
              // admin/owner pueden editarlo, las rules backuppen).
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      key: const Key('home_avatar_tile'),
                      onTap: data.canEdit
                          ? () => showHomeAvatarSheet(context)
                          : null,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: data.photoUrl != null
                            ? NetworkImage(data.photoUrl!)
                            : null,
                        child: data.photoUrl == null
                            ? Text(
                                data.homeName.isNotEmpty
                                    ? data.homeName[0].toUpperCase()
                                    : '?',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              )
                            : null,
                      ),
                    ),
                    if (data.canEdit) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        key: const Key('home_avatar_change_btn'),
                        onPressed: () => showHomeAvatarSheet(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.homes_avatar_sheet_title),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: data.canEdit
                    ? TextField(
                        key: const Key('home_name_field'),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.homes_name_label,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (v) => vm.updateHomeName(v),
                      )
                    : ListTile(
                        title: Text(l10n.homes_name_label),
                        subtitle: Text(data.homeName),
                      ),
              ),
              const Divider(),
              ListTile(
                key: const Key('home_plan_tile'),
                title: Text(data.planLabel),
              ),
              if (data.isPayer)
                ListTile(
                  key: const Key('payer_info_tile'),
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.homes_payer_info_body),
                  subtitle: Text(l10n.homes_payer_info_action),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.subscription),
                ),
              // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
              if (data.showDebugPremiumToggle)
                ListTile(
                  key: const Key('debug_premium_toggle_tile'),
                  leading: const Icon(Icons.science, color: Colors.amber),
                  title: const Text('🧪 DEBUG: Estado premium'),
                  subtitle: Text('Actual: ${data.premiumStatusCode}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDebugPremiumSheet(
                    context,
                    vm,
                    data.premiumStatusCode,
                  ),
                ),
              // END DEBUG PREMIUM
              const Divider(),
              ListTile(
                key: const Key('manage_members_tile'),
                leading: const Icon(Icons.people_outline),
                title: Text(l10n.homes_manage_members),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.members),
              ),
              // Administradores: contador real + sheet de gestión.
              Consumer(builder: (ctx, ref, _) {
                final members = ref
                        .watch(homeMembersProvider(data.homeId))
                        .valueOrNull ??
                    const <Member>[];
                final adminCount = members
                    .where((m) =>
                        m.role == MemberRole.owner ||
                        m.role == MemberRole.admin)
                    .length;
                return ListTile(
                  key: const Key('admins_tile'),
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l10n.homes_admins_sheet_title),
                  subtitle: Text(l10n.homes_admins_count(adminCount)),
                  trailing: data.isOwner
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: data.isOwner
                      ? () => showAdminsSheet(ctx, homeId: data.homeId)
                      : null,
                );
              }),
              // Invitaciones pendientes: contador reactivo + sheet con
              // listado revocable. Solo visible para admin/owner (las
              // reglas Firestore protegen la lectura igualmente).
              if (data.isOwner)
                Consumer(builder: (ctx, ref, _) {
                  final invs = ref
                          .watch(pendingInvitationsProvider(data.homeId))
                          .valueOrNull ??
                      const [];
                  return ListTile(
                    key: const Key('pending_invitations_tile'),
                    leading: const Icon(Icons.mail_outline),
                    title: Text(l10n.homes_invitations_sheet_title),
                    subtitle: Text(l10n.homes_invitations_count(invs.length)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showPendingInvitationsSheet(
                      ctx,
                      homeId: data.homeId,
                    ),
                  );
                }),
              if (data.isOwner)
                ListTile(
                  key: const Key('transfer_ownership_tile'),
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(l10n.homes_transfer_ownership),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showTransferOwnershipSheet(
                    context,
                    homeId: data.homeId,
                  ),
                ),
              if (data.isPayer)
                ListTile(
                  key: const Key('cancel_renewal_tile'),
                  leading: Icon(
                    Icons.cancel_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    l10n.homes_cancel_renewal,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.subscription),
                ),
              const Divider(),
              ListTile(
                key: const Key('leave_home_tile'),
                title: Text(
                  l10n.homes_leave_home,
                  style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                ),
                onTap: () => _confirmLeave(context, l10n, vm),
              ),
              if (data.isOwner)
                ListTile(
                  key: const Key('close_home_tile'),
                  title: Text(
                    l10n.homes_close_home,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () => _confirmClose(context, l10n, vm),
                ),
            ],
          );
        },
      ),
    );
  }
}
