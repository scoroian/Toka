// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscription/application/subscription_provider.dart';
import '../../subscription/domain/subscription_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  bool _isPremium(SubscriptionState state) {
    return state.map(
      free: (_) => false,
      active: (_) => true,
      cancelledPendingEnd: (_) => true,
      rescue: (_) => true,
      expiredFree: (_) => false,
      restorable: (_) => false,
      purged: (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPremium = _isPremium(ref.watch(subscriptionStateProvider));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings_title)),
      body: ListView(
        children: [
          // ── Cuenta ──────────────────────────────────────────────────
          _SectionHeader(key: const Key('settings_section_account'), title: l10n.settings_section_account),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settings_edit_profile),
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.settings_change_password),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.settings_delete_account),
            onTap: () {},
          ),
          const Divider(),

          // ── Idioma ───────────────────────────────────────────────────
          ListTile(
            key: const Key('settings_language'),
            leading: const Icon(Icons.language),
            title: Text(l10n.settings_section_language),
            onTap: () {},
          ),
          const Divider(),

          // ── Notificaciones ───────────────────────────────────────────
          ListTile(
            key: const Key('settings_notifications'),
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settings_section_notifications),
            onTap: () {},
          ),
          const Divider(),

          // ── Privacidad ────────────────────────────────────────────────
          _SectionHeader(key: const Key('settings_section_privacy'), title: l10n.settings_section_privacy),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text(l10n.settings_phone_visibility),
            onTap: () {},
          ),
          const Divider(),

          // ── Suscripción ───────────────────────────────────────────────
          _SectionHeader(key: const Key('settings_section_subscription'), title: l10n.settings_section_subscription),
          ListTile(
            key: const Key('subscription_status_label'),
            leading: Icon(
              isPremium ? Icons.star : Icons.star_border,
              color: isPremium ? Colors.amber : null, // TODO: move to AppColors
            ),
            title: Text(isPremium ? l10n.settings_plan_premium : l10n.settings_plan_free),
            onTap: () => context.push(AppRoutes.subscription),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l10n.settings_restore_purchases),
            onTap: () => context.push(AppRoutes.subscription),
          ),
          const Divider(),

          // ── Hogar ─────────────────────────────────────────────────────
          _SectionHeader(key: const Key('settings_section_home'), title: l10n.settings_section_home),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.settings_home_settings),
            onTap: () => context.push(AppRoutes.homeSettings),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: Text(l10n.settings_invite_code),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red), // TODO: move to AppColors
            title: Text(l10n.settings_leave_home,
                style: const TextStyle(color: Colors.red)), // TODO: move to AppColors
            onTap: () {},
          ),
          const Divider(),

          // ── Acerca de ─────────────────────────────────────────────────
          _SectionHeader(key: const Key('settings_section_about'), title: l10n.settings_section_about),
          FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (ctx, snap) {
              final version = snap.data?.version ?? '—';
              final build = snap.data?.buildNumber ?? '';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settings_app_version),
                subtitle: Text('$version ($build)'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settings_terms),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settings_privacy_policy),
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
