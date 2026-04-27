// lib/features/homes/presentation/skins/futurista/home_settings_screen_futurista.dart
//
// Pantalla "Ajustes del hogar" en skin Futurista. Consume el mismo
// `homeSettingsViewModelProvider` que `HomeSettingsScreenV2`. Layout adaptado
// del canvas `skin_futurista/screens-meta.jsx > AjustesHogarScreen`:
//
//   1. Header: chevron back 38x38 + título "Ajustes del hogar" centrado.
//   2. Hero hogar: gradient primary→surface, slot avatar+initial, name,
//      mono "CODE · {homeId}" y pills (Premium / plan).
//   3. Secciones (GENERAL, MIEMBROS Y ROLES, SUSCRIPCIÓN, ZONA DE PELIGRO),
//      cada una con header mono uppercase + Container surfaceContainerHighest
//      con rows separadas por Divider.
//
// CONCERNS — props del VM no expuestas → placeholders documentados:
//   - homeCode  → se usa `homeId` (no hay un código corto en el VM).
//   - timezone  → "—" placeholder.
//   - invitaciones pendientes / admins / total → "—".
//   - payerName / nextRenewal → "—" / placeholder vacío. El `planLabel` del VM
//     ya incluye la fecha de fin si está disponible.
//   - Acciones "Transferir propiedad", "Cancelar renovación", "Congelar
//     miembro", "Avatar del hogar", "Zona horaria" no tienen handler en el VM
//     y se dejan inertes (placeholders) — el VM solo expone updateHomeName,
//     leaveHome, closeHome y debugSetPremiumStatus.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/futurista/futurista_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../members/application/members_provider.dart';
import '../../../../members/domain/member.dart';
import '../../../application/home_settings_view_model.dart';
import '../../../domain/home_membership.dart';
import '../../../domain/homes_repository.dart';
import '../../widgets/admins_sheet.dart';
import '../../widgets/home_avatar_sheet.dart';
import '../../widgets/pending_invitations_sheet.dart';
import '../../widgets/transfer_ownership_sheet.dart';

const String _kMono = 'JetBrainsMono';

class HomeSettingsScreenFuturista extends ConsumerStatefulWidget {
  const HomeSettingsScreenFuturista({super.key});

  @override
  ConsumerState<HomeSettingsScreenFuturista> createState() =>
      _HomeSettingsScreenFuturistaState();
}

class _HomeSettingsScreenFuturistaState
    extends ConsumerState<HomeSettingsScreenFuturista> {
  Future<void> _editName(
    BuildContext context,
    AppLocalizations l10n,
    HomeSettingsViewModel vm,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_name_label),
        content: TextField(
          key: const Key('home_name_field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await vm.updateHomeName(result);
    }
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.leaveHome();
      if (context.mounted) Navigator.of(context).maybePop();
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

  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION RELEASE
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
    if (context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = ref.watch(homeSettingsViewModelProvider(l10n));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header fijo arriba: el chevron back queda anclado mientras
            // el contenido scrollea.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _Header(title: l10n.homes_settings_title),
            ),
            Expanded(
              child: vm.viewData.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.error_generic)),
                data: (data) {
                  if (data == null) {
                    return Center(child: Text(l10n.error_generic));
                  }
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      adAwareBottomPadding(context, ref, extra: 16),
                    ),
                    children: [
                _Hero(
                  homeName: data.homeName,
                  homeIdShort: _shortenId(data.homeId),
                  photoUrl: data.photoUrl,
                  isPremium: !data.planLabel
                      .toLowerCase()
                      .contains(l10n.homes_plan_free.toLowerCase()),
                  planLabel: data.planLabel,
                  onTapAvatar: data.canEdit
                      ? () => showHomeAvatarSheet(context)
                      : null,
                ),
                _SectionHeader(title: l10n.home_settings_section_general),
                _SectionCard(
                  rows: [
                    _SettingsRow(
                      label: l10n.homes_name_label,
                      value: data.homeName,
                      iconLeft: Icons.edit,
                      tone: _RowTone.accent,
                      onTap: data.canEdit
                          ? () => _editName(context, l10n, vm, data.homeName)
                          : null,
                    ),
                    // Avatar y zona horaria — no implementados aún en el VM.
                    // Mostrados en informativo (no tappables) para que el
                    // usuario sepa que existirán pero no parezcan rotos.
                    _SettingsRow(
                      key: const Key('home_avatar_tile'),
                      label: l10n.home_settings_avatar,
                      value: data.photoUrl != null ? '✓' : '—',
                      iconLeft: Icons.image_outlined,
                      tone: _RowTone.accent,
                      onTap: data.canEdit
                          ? () => showHomeAvatarSheet(context)
                          : null,
                    ),
                    _SettingsRow(
                      label: l10n.home_settings_timezone,
                      value: l10n.homes_coming_soon,
                      iconLeft: Icons.public,
                      tone: _RowTone.neutral,
                      onTap: null,
                    ),
                  ],
                ),
                _SectionHeader(title: l10n.home_settings_section_members),
                _SectionCard(
                  rows: [
                    // Tile principal de miembros — paridad con v2 (manage_members_tile).
                    _SettingsRow(
                      key: const Key('manage_members_tile'),
                      label: l10n.homes_manage_members,
                      value: null,
                      iconLeft: Icons.people_outline,
                      tone: _RowTone.accent,
                      onTap: () => context.push(AppRoutes.members),
                    ),
                    // Filas informativas: no tappeables, sin chevron (ver _SettingsRow).
                    // Invitaciones pendientes: contador reactivo + sheet.
                    Consumer(builder: (ctx, ref, _) {
                      final invs = ref
                              .watch(pendingInvitationsProvider(data.homeId))
                              .valueOrNull ??
                          const [];
                      return _SettingsRow(
                        key: const Key('pending_invitations_tile'),
                        label: l10n.home_settings_pending_invites,
                        value: l10n.homes_invitations_count(invs.length),
                        iconLeft: Icons.mail_outline,
                        tone: _RowTone.neutral,
                        onTap: data.isOwner
                            ? () => showPendingInvitationsSheet(
                                  ctx,
                                  homeId: data.homeId,
                                )
                            : null,
                      );
                    }),
                    // Administradores: contador real derivado de
                    // homeMembersProvider (owner cuenta como admin), tap
                    // abre sheet de gestión solo para owners.
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
                      return _SettingsRow(
                        key: const Key('admins_tile'),
                        label: l10n.home_settings_admins,
                        value: l10n.homes_admins_count(adminCount),
                        iconLeft: Icons.shield_outlined,
                        tone: _RowTone.neutral,
                        onTap: data.isOwner
                            ? () => showAdminsSheet(ctx, homeId: data.homeId)
                            : null,
                      );
                    }),
                    if (data.isOwner)
                      _SettingsRow(
                        key: const Key('transfer_ownership_tile'),
                        label: l10n.homes_transfer_ownership,
                        value: null,
                        iconLeft: Icons.swap_horiz,
                        tone: _RowTone.neutral,
                        onTap: () => showTransferOwnershipSheet(
                          context,
                          homeId: data.homeId,
                        ),
                      ),
                  ],
                ),
                _SectionHeader(title: l10n.home_settings_section_subscription),
                _SectionCard(
                  rows: [
                    _SettingsRow(
                      label: l10n.home_settings_plan_current,
                      value: data.planLabel,
                      iconLeft: Icons.workspace_premium,
                      tone: _RowTone.accent,
                      onTap: null,
                    ),
                    _SettingsRow(
                      label: l10n.subscription_payer_label,
                      value: data.isPayer ? l10n.homes_role_owner : '—',
                      iconLeft: Icons.person_outline,
                      tone: _RowTone.neutral,
                      onTap: null,
                    ),
                    // Tile "Gestionar suscripción": entry-point al detalle
                    // de la suscripción donde el pagador puede cancelar
                    // renovación, ver historial y reactivar (paridad con v2).
                    if (data.isPayer)
                      _SettingsRow(
                        key: const Key('manage_subscription_tile'),
                        label: l10n.homes_manage_subscription,
                        value: null,
                        iconLeft: Icons.tune,
                        tone: _RowTone.accent,
                        onTap: () => context.push(AppRoutes.subscription),
                      ),
                    if (data.isPayer)
                      _SettingsRow(
                        key: const Key('cancel_renewal_tile'),
                        label: l10n.homes_cancel_renewal,
                        value: null,
                        iconLeft: Icons.cancel_outlined,
                        tone: _RowTone.danger,
                        onTap: () => context.push(AppRoutes.subscription),
                      ),
                  ],
                ),
                // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
                if (data.showDebugPremiumToggle) ...[
                  _SectionHeader(title: l10n.home_settings_section_debug),
                  _SectionCard(
                    rows: [
                      _SettingsRow(
                        key: const Key('debug_premium_toggle_tile'),
                        // Etiqueta visible al equipo dev — el emoji es
                        // intencional para distinguir tiles de debug. NO
                        // se internacionaliza porque desaparecerá antes de
                        // producción (ver script `check-debug-premium.js`).
                        label: '🧪 Estado premium',
                        value: data.premiumStatusCode,
                        iconLeft: Icons.science,
                        tone: _RowTone.accent,
                        onTap: () => _showDebugPremiumSheet(
                          context,
                          vm,
                          data.premiumStatusCode,
                        ),
                      ),
                    ],
                  ),
                ],
                // END DEBUG PREMIUM
                _SectionHeader(title: l10n.home_settings_section_danger),
                _SectionCard(
                  rows: [
                    if (data.isOwner)
                      _SettingsRow(
                        key: const Key('freeze_member_tile'),
                        label: l10n.homes_freeze_member,
                        value: null,
                        iconLeft: Icons.ac_unit,
                        tone: _RowTone.danger,
                        onTap: () => context.push(AppRoutes.members),
                      ),
                    _SettingsRow(
                      key: const Key('leave_home_tile'),
                      label: l10n.homes_leave_home,
                      value: null,
                      iconLeft: Icons.logout,
                      tone: _RowTone.danger,
                      onTap: () => _confirmLeave(context, l10n, vm),
                    ),
                    if (data.isOwner)
                      _SettingsRow(
                        key: const Key('close_home_tile'),
                        label: l10n.homes_close_home,
                        value: null,
                        iconLeft: Icons.delete_outline,
                        tone: _RowTone.danger,
                        onTap: () => _confirmClose(context, l10n, vm),
                      ),
                  ],
                ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortenId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: const Key('home_settings_back'),
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Icon(Icons.chevron_left, size: 22, color: cs.onSurface),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 38),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Hero
// -----------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({
    required this.homeName,
    required this.homeIdShort,
    required this.photoUrl,
    required this.isPremium,
    required this.planLabel,
    required this.onTapAvatar,
  });

  final String homeName;
  final String homeIdShort;
  final String? photoUrl;
  final bool isPremium;
  final String planLabel;
  final VoidCallback? onTapAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final initial =
        homeName.trim().isEmpty ? '?' : homeName.trim()[0].toUpperCase();

    Widget avatarBox = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: photoUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.secondary],
              )
            : null,
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: photoUrl == null
          ? Text(
              initial,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            )
          : null,
    );
    if (onTapAvatar != null) {
      avatarBox = InkWell(
        key: const Key('home_avatar_hero'),
        onTap: onTapAvatar,
        borderRadius: BorderRadius.circular(14),
        child: avatarBox,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.14),
            cs.surface.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatarBox,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppLocalizations.of(context).home_settings_code_short} · $homeIdShort',
                  style: TextStyle(
                    fontFamily: _kMono,
                    fontSize: 11,
                    letterSpacing: 0.3,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                if (isPremium)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const _PremiumPill(),
                      _PlanPill(label: planLabel),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPill extends StatelessWidget {
  const _PremiumPill();

  @override
  Widget build(BuildContext context) {
    const gold = FuturistaColors.premium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: gold.withValues(alpha: 0.19)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 10, color: gold),
          SizedBox(width: 3),
          Text(
            'Premium',
            style: TextStyle(
              color: gold,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Section header + card
// -----------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: _kMono,
          fontSize: 10.5,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(Divider(height: 1, color: theme.dividerColor));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(children: children),
    );
  }
}

// -----------------------------------------------------------------------------
// Settings row
// -----------------------------------------------------------------------------

enum _RowTone { neutral, accent, danger }

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.label,
    required this.value,
    required this.iconLeft,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final String? value;
  final IconData iconLeft;
  final _RowTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final danger = cs.error;
    const gold = FuturistaColors.premium;

    final Color slotBg;
    final Color slotBorder;
    final Color slotIcon;
    switch (tone) {
      case _RowTone.danger:
        slotBg = danger.withValues(alpha: 0.09);
        slotBorder = danger.withValues(alpha: 0.19);
        slotIcon = danger;
        break;
      case _RowTone.accent:
        slotBg = gold.withValues(alpha: 0.09);
        slotBorder = gold.withValues(alpha: 0.19);
        slotIcon = gold;
        break;
      case _RowTone.neutral:
        slotBg = cs.surface;
        slotBorder = theme.dividerColor;
        slotIcon = cs.onSurfaceVariant;
        break;
    }

    final isInteractive = onTap != null;
    final labelColor = tone == _RowTone.danger ? danger : cs.onSurface;
    // Filas sin onTap son meramente informativas. No pintamos el chevron
    // ni el ripple del InkWell — así el usuario distingue de un vistazo
    // qué se puede tocar y qué es solo lectura.
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: slotBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: slotBorder),
            ),
            alignment: Alignment.center,
            child: Icon(iconLeft, size: 13, color: slotIcon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: _kMono,
                  fontSize: 12.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (isInteractive) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 13,
              color: cs.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    if (!isInteractive) {
      return Opacity(opacity: 0.72, child: body);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: body),
    );
  }
}
