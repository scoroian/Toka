import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/application/auth_provider.dart';
import '../application/current_home_provider.dart';
import '../application/homes_provider.dart';
import '../domain/home.dart';
import '../domain/home_membership.dart';
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

  String _planLabel(Home home, AppLocalizations l10n) {
    if (home.premiumStatus == HomePremiumStatus.free ||
        home.premiumStatus == HomePremiumStatus.expiredFree) {
      return l10n.homes_plan_free;
    }
    final endsAt = home.premiumEndsAt;
    if (endsAt != null) {
      final formatted = DateFormat.yMd().format(endsAt);
      return '${l10n.homes_plan_premium} · ${l10n.homes_plan_ends(formatted)}';
    }
    return l10n.homes_plan_premium;
  }

  Future<void> _confirmLeave(
    BuildContext context,
    AppLocalizations l10n,
    String homeId,
    String uid,
    HomesRepository repo,
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
      await repo.leaveHome(homeId, uid: uid);
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
    String homeId,
    HomesRepository repo,
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
    await repo.closeHome(homeId);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentHomeAsync = ref.watch(currentHomeProvider);
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homes_settings_title)),
      body: currentHomeAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (home) {
          if (home == null) {
            return Center(child: Text(l10n.error_generic));
          }

          // Initialize name controller once we have data
          if (!_nameInitialized) {
            _nameController.text = home.name;
            _nameInitialized = true;
          }

          final membershipsAsync = uid.isNotEmpty
              ? ref.watch(userMembershipsProvider(uid))
              : null;
          final memberships = membershipsAsync?.valueOrNull ?? [];
          final myMembership = memberships.isEmpty
              ? null
              : memberships
                  .where((m) => m.homeId == home.id)
                  .cast<HomeMembership?>()
                  .firstOrNull;

          final myRole = myMembership?.role;
          final isOwner = myRole == MemberRole.owner;
          final canEdit = isOwner || myRole == MemberRole.admin;
          final isCurrentPayer = myMembership?.billingState ==
              BillingState.currentPayer;
          final canManageSubscription = isOwner || isCurrentPayer;

          final repo = ref.read(homesRepositoryProvider);

          return ListView(
            children: [
              // 1. Name field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: canEdit
                    ? TextField(
                        key: const Key('home_name_field'),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.homes_name_label,
                          border: const OutlineInputBorder(),
                        ),
                      )
                    : ListTile(
                        title: Text(l10n.homes_name_label),
                        subtitle: Text(home.name),
                      ),
              ),

              const Divider(),

              // 2. Plan
              ListTile(
                key: const Key('home_plan_tile'),
                title: Text(_planLabel(home, l10n)),
              ),

              // 3. Manage subscription (owner or currentPayer only)
              if (canManageSubscription)
                ListTile(
                  key: const Key('manage_subscription_tile'),
                  title: Text(l10n.homes_manage_subscription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: navigate to subscription screen
                  },
                ),

              const Divider(),

              // 4. Members
              ListTile(
                key: const Key('members_tile'),
                title: Text(l10n.homes_members),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: navigate to members screen
                },
              ),

              // 5. Invite code
              ListTile(
                key: const Key('invite_code_tile'),
                title: Text(l10n.homes_invite_code),
                trailing: TextButton(
                  key: const Key('generate_code_button'),
                  onPressed: () {
                    // TODO: generate code
                  },
                  child: Text(l10n.homes_generate_code),
                ),
              ),

              const Divider(),

              // 6. Leave home
              ListTile(
                key: const Key('leave_home_tile'),
                title: Text(
                  l10n.homes_leave_home,
                  style: const TextStyle(color: Colors.orange),
                ),
                onTap: () => _confirmLeave(
                  context,
                  l10n,
                  home.id,
                  uid,
                  repo,
                ),
              ),

              // 7. Close home (owner only)
              if (isOwner)
                ListTile(
                  key: const Key('close_home_tile'),
                  title: Text(
                    l10n.homes_close_home,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () => _confirmClose(context, l10n, home.id, repo),
                ),
            ],
          );
        },
      ),
    );
  }
}
