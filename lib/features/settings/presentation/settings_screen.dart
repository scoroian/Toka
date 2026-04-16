// lib/features/settings/presentation/settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../i18n/presentation/language_selector_widget.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../../homes/domain/home_membership.dart';
import '../../members/presentation/widgets/invite_member_sheet.dart';
import '../application/settings_view_model.dart';
import '../../../core/theme/theme_mode_provider.dart';

/// Caso B/D — transfiere ownership y luego abandona el hogar.
Future<void> _transferAndLeave(
  BuildContext context,
  WidgetRef ref,
  String homeId,
  String uid,
  String newOwnerUid,
) async {
  try {
    await ref
        .read(membersRepositoryProvider)
        .transferOwnership(homeId, newOwnerUid);
    await ref
        .read(homesRepositoryProvider)
        .leaveHome(homeId, uid: uid);
    ref.invalidate(currentHomeProvider);
    if (context.mounted) context.go(AppRoutes.home);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ha ocurrido un error. Inténtalo de nuevo.')),
      );
    }
  }
}

/// Caso C — muestra el diálogo de eliminar y cierra el hogar si confirma.
Future<void> _confirmAndDeleteHome(
  BuildContext context,
  WidgetRef ref,
  String homeId,
  AppLocalizations l10n,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.homes_delete_home_title),
      content: Text(l10n.homes_delete_home_body_sole),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('delete_home_confirm_btn'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.homes_delete_btn),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(homesRepositoryProvider).closeHome(homeId);
    ref.invalidate(currentHomeProvider);
    if (context.mounted) context.go(AppRoutes.home);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ha ocurrido un error. Inténtalo de nuevo.')),
      );
    }
  }
}

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
            onTap: () async {
              final authState = ref.read(authProvider);
              final email = authState.whenOrNull(authenticated: (u) => u.email);
              if (email == null) return;
              await ref.read(authProvider.notifier).sendPasswordReset(email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.auth_reset_sent)),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.settings_delete_account),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.settings_delete_account_confirm_title),
                  content: Text(l10n.settings_delete_account_confirm_body),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.error,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (context.mounted) {
                  await ref.read(authProvider.notifier).signOut();
                  context.go(AppRoutes.login);
                }
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;
                final msg = e.code == 'requires-recent-login'
                    ? l10n.settings_delete_requires_reauth
                    : l10n.error_generic;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            },
          ),
          const Divider(),

          // ── Idioma ───────────────────────────────────────────────────
          ListTile(
            key: const Key('settings_language'),
            leading: const Icon(Icons.language),
            title: Text(l10n.settings_section_language),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: LanguageSelectorWidget(
                    onSelected: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ),
          ),
          const Divider(),

          // ── Apariencia ───────────────────────────────────────────────
          const _SectionHeader(key: Key('settings_section_appearance'), title: 'Apariencia'),
          const _ThemeModeSelector(key: Key('settings_theme_mode')),
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
            onTap: () => context.push(AppRoutes.editProfile),
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
            onTap: () {
              if (homeId.isNotEmpty) {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => InviteMemberSheet(homeId: homeId),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red), // TODO: move to AppColors
            title: Text(l10n.settings_leave_home,
                style: const TextStyle(color: Colors.red)), // TODO: move to AppColors
            onTap: () async {
              if (homeId.isEmpty || uid.isEmpty) return;
              final l10n = AppLocalizations.of(context);

              // Lectura one-shot de miembros para clasificar el caso
              final members = await ref
                  .read(membersRepositoryProvider)
                  .watchHomeMembers(homeId)
                  .first;
              if (!context.mounted) return;

              final isOwner = members.any(
                (m) => m.uid == uid && m.role == MemberRole.owner,
              );
              final activeOthers = members
                  .where((m) => m.uid != uid && m.status == MemberStatus.active)
                  .toList();
              final frozenOthers = members
                  .where((m) => m.uid != uid && m.status == MemberStatus.frozen)
                  .toList();

              // ── Caso A: no es owner ───────────────────────────────────────────
              if (!isOwner) {
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
                if (confirmed != true || !context.mounted) return;
                await ref.read(homesRepositoryProvider).leaveHome(homeId, uid: uid);
                ref.invalidate(currentHomeProvider);
                if (context.mounted) context.go(AppRoutes.home);
                return;
              }

              // ── Caso B: owner con miembros activos ────────────────────────────
              if (activeOthers.isNotEmpty) {
                final selectedUid = await showDialog<String>(
                  context: context,
                  builder: (_) => _TransferOwnershipDialog(members: activeOthers),
                );
                if (selectedUid == null || !context.mounted) return;
                await _transferAndLeave(context, ref, homeId, uid, selectedUid);
                return;
              }

              // ── Caso C: owner único, sin otros miembros ───────────────────────
              if (frozenOthers.isEmpty) {
                await _confirmAndDeleteHome(context, ref, homeId, l10n);
                return;
              }

              // ── Caso D: owner con solo miembros congelados ────────────────────
              final result = await showDialog<(String, String?)>(
                context: context,
                builder: (_) => _FrozenTransferDialog(members: frozenOthers),
              );
              if (result == null || !context.mounted) return;
              final (action, selectedUid) = result;
              if (action == 'transfer' && selectedUid != null) {
                await _transferAndLeave(context, ref, homeId, uid, selectedUid);
              } else if (action == 'delete') {
                await _confirmAndDeleteHome(context, ref, homeId, l10n);
              }
            },
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
            onTap: () => launchUrl(Uri.parse('https://toka.app/terms')),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settings_privacy_policy),
            onTap: () => launchUrl(Uri.parse('https://toka.app/privacy')),
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

class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeNotifierProvider);
    final notifier = ref.read(themeModeNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<ThemeMode>(
        key: const Key('theme_mode_segmented'),
        segments: const [
          ButtonSegment(value: ThemeMode.light,  label: Text('Claro'),  icon: Icon(Icons.wb_sunny_outlined)),
          ButtonSegment(value: ThemeMode.dark,   label: Text('Oscuro'), icon: Icon(Icons.nightlight_outlined)),
          ButtonSegment(value: ThemeMode.system, label: Text('Sistema'),icon: Icon(Icons.phone_android_outlined)),
        ],
        selected: {current},
        onSelectionChanged: (set) => notifier.setMode(set.first),
      ),
    );
  }
}

/// Diálogo Caso B: el owner selecciona un miembro activo como nuevo propietario.
class _TransferOwnershipDialog extends StatefulWidget {
  const _TransferOwnershipDialog({required this.members});

  final List<Member> members;

  @override
  State<_TransferOwnershipDialog> createState() =>
      _TransferOwnershipDialogState();
}

class _TransferOwnershipDialogState extends State<_TransferOwnershipDialog> {
  String? _selectedUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.homes_transfer_ownership_title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homes_transfer_ownership_body),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.members.length,
                itemBuilder: (_, i) {
                  final m = widget.members[i];
                  return RadioListTile<String>(
                    key: Key('transfer_member_${m.uid}'),
                    value: m.uid,
                    groupValue: _selectedUid,
                    onChanged: (v) => setState(() => _selectedUid = v),
                    title: Text(m.nickname),
                    secondary: CircleAvatar(
                      backgroundImage: m.photoUrl != null
                          ? NetworkImage(m.photoUrl!)
                          : null,
                      child: m.photoUrl == null
                          ? Text(m.nickname.isNotEmpty
                              ? m.nickname[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('transfer_confirm_btn'),
          onPressed: _selectedUid == null
              ? null
              : () => Navigator.of(context).pop(_selectedUid),
          child: Text(l10n.homes_transfer_btn),
        ),
      ],
    );
  }
}

/// Diálogo Caso D: el owner puede transferir a un miembro congelado o eliminar el hogar.
/// Retorna ('transfer', uid) o ('delete', null).
class _FrozenTransferDialog extends StatefulWidget {
  const _FrozenTransferDialog({required this.members});

  final List<Member> members;

  @override
  State<_FrozenTransferDialog> createState() => _FrozenTransferDialogState();
}

class _FrozenTransferDialogState extends State<_FrozenTransferDialog> {
  String? _selectedUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.homes_frozen_only_title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homes_frozen_only_body),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.members.length,
                itemBuilder: (_, i) {
                  final m = widget.members[i];
                  return RadioListTile<String>(
                    key: Key('frozen_member_${m.uid}'),
                    value: m.uid,
                    groupValue: _selectedUid,
                    onChanged: (v) => setState(() => _selectedUid = v),
                    title: Text(m.nickname),
                    secondary: CircleAvatar(
                      backgroundImage: m.photoUrl != null
                          ? NetworkImage(m.photoUrl!)
                          : null,
                      child: m.photoUrl == null
                          ? Text(m.nickname.isNotEmpty
                              ? m.nickname[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('frozen_delete_btn'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(('delete', null)),
          child: Text(l10n.homes_delete_btn),
        ),
        TextButton(
          key: const Key('frozen_transfer_btn'),
          onPressed: _selectedUid == null
              ? null
              : () => Navigator.of(context).pop(('transfer', _selectedUid)),
          child: Text(l10n.homes_transfer_btn),
        ),
      ],
    );
  }
}
