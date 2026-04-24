// lib/features/homes/presentation/home_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../subscription/presentation/widgets/premium_state_banner.dart';
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
