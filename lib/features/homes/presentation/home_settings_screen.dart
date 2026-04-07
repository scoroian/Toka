// lib/features/homes/presentation/home_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
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
                  onTap: () {},
                ),
              const Divider(),
              ListTile(
                key: const Key('members_tile'),
                title: Text(l10n.homes_members),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.members),
              ),
              ListTile(
                key: const Key('invite_code_tile'),
                title: Text(l10n.homes_invite_code),
                trailing: TextButton(
                  key: const Key('generate_code_button'),
                  onPressed: () {},
                  child: Text(l10n.homes_generate_code),
                ),
              ),
              const Divider(),
              ListTile(
                key: const Key('leave_home_tile'),
                title: Text(
                  l10n.homes_leave_home,
                  style: const TextStyle(color: Colors.orange),
                ),
                onTap: () => _confirmLeave(context, l10n, vm),
              ),
              if (data.isOwner)
                ListTile(
                  key: const Key('close_home_tile'),
                  title: Text(
                    l10n.homes_close_home,
                    style: const TextStyle(color: Colors.red),
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
