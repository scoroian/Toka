// lib/features/homes/presentation/home_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../members/application/member_actions_provider.dart';
import '../../members/application/members_provider.dart';
import '../../members/presentation/widgets/invite_member_sheet.dart';
import '../application/home_settings_view_model.dart';
import '../domain/homes_repository.dart';

class HomeSettingsScreen extends ConsumerStatefulWidget {
  const HomeSettingsScreen({super.key});

  @override
  ConsumerState<HomeSettingsScreen> createState() => _HomeSettingsScreenState();
}

class _HomeSettingsScreenState extends ConsumerState<HomeSettingsScreen> {
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
    try {
      await vm.leaveHome();
      if (context.mounted) Navigator.of(context).pop();
    } on CannotLeaveAsOwnerException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.homes_error_cannot_leave_as_owner)),
        );
      }
    } on PayerLockedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.members_error_payer_locked)),
        );
      }
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              if (data.canManageSubscription)
                ListTile(
                  key: const Key('manage_subscription_tile'),
                  title: Text(l10n.homes_manage_subscription),
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
                key: const Key('members_tile'),
                title: Text(l10n.homes_members),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.homeSettingsMembers),
              ),
              if (data.canGenerateCode) _InviteCodeTile(homeId: data.homeId),
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

/// Tile que muestra el código de invitación activo con fecha de expiración,
/// botón de copiar y botón de regenerar. Si no hay código activo muestra
/// un botón para generar uno nuevo que abre el InviteMemberSheet.
class _InviteCodeTile extends ConsumerStatefulWidget {
  const _InviteCodeTile({required this.homeId});

  final String homeId;

  @override
  ConsumerState<_InviteCodeTile> createState() => _InviteCodeTileState();
}

class _InviteCodeTileState extends ConsumerState<_InviteCodeTile> {
  bool _isRegenerating = false;

  bool _isExpiringSoon(DateTime expiresAt) =>
      expiresAt.difference(DateTime.now()).inHours < 24;

  Future<void> _regenerateCode() async {
    setState(() => _isRegenerating = true);
    try {
      await ref
          .read(memberActionsProvider.notifier)
          .generateInviteCode(widget.homeId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).error_generic)),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeCodeAsync = ref.watch(activeInviteCodeProvider(widget.homeId));

    return activeCodeAsync.when(
      loading: () => ListTile(
        key: const Key('invite_code_tile'),
        title: Text(l10n.homes_invite_code),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => ListTile(
        key: const Key('invite_code_tile'),
        title: Text(l10n.homes_invite_code),
        trailing: TextButton(
          key: const Key('generate_code_button'),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => InviteMemberSheet(homeId: widget.homeId),
          ),
          child: Text(l10n.homes_generate_code),
        ),
      ),
      data: (activeCode) {
        if (activeCode == null) {
          return ListTile(
            key: const Key('invite_code_tile'),
            title: Text(l10n.homes_invite_code),
            trailing: TextButton(
              key: const Key('generate_code_button'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => InviteMemberSheet(homeId: widget.homeId),
              ),
              child: Text(l10n.homes_generate_code),
            ),
          );
        }

        final expiresAt = activeCode.expiresAt;
        final formattedDate =
            DateFormat('dd MMM yyyy · HH:mm').format(expiresAt);
        final expiringSoon = _isExpiringSoon(expiresAt);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homes_invite_code,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeCode.code,
                          key: const Key('settings_invite_code_text'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(letterSpacing: 3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.invite_code_expires_at(formattedDate),
                          key: const Key('settings_invite_code_expiry'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: expiringSoon
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('copy_code_button'),
                    icon: const Icon(Icons.copy),
                    tooltip: l10n.invite_sheet_copy_code,
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: activeCode.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(l10n.invite_sheet_code_copied)),
                      );
                    },
                  ),
                  IconButton(
                    key: const Key('regenerate_code_button'),
                    icon: _isRegenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: l10n.invite_code_regenerate,
                    onPressed: _isRegenerating ? null : _regenerateCode,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
