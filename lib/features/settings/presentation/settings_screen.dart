// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../application/settings_view_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(settingsViewModelProvider);
    final isPremium = vm.viewData.isPremium;
    final homeId = vm.viewData.homeId;
    final uid = vm.viewData.uid;
    final appVersion = vm.viewData.appVersion;

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
            onTap: () {
              if (homeId.isNotEmpty && uid.isNotEmpty) {
                context.push(AppRoutes.notificationSettings, extra: {
                  'homeId': homeId,
                  'uid': uid,
                });
              }
            },
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
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settings_app_version),
            subtitle: Text(appVersion ?? '—'),
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
          // ── Cerrar sesión ─────────────────────────────────────────────
          const Divider(),
          ListTile(
            key: const Key('settings_sign_out'),
            leading: const Icon(Icons.logout),
            title: Text(l10n.settings_sign_out),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: Text(l10n.settings_sign_out_confirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: Text(l10n.settings_sign_out),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(authProvider.notifier).signOut();
              }
            },
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
