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

import '../../../../../core/theme/futurista/futurista_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../application/home_settings_view_model.dart';
import '../../../domain/homes_repository.dart';

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
        child: vm.viewData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.error_generic)),
          data: (data) {
            if (data == null) return Center(child: Text(l10n.error_generic));
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _Header(title: l10n.homes_settings_title),
                const SizedBox(height: 14),
                _Hero(
                  homeName: data.homeName,
                  homeIdShort: _shortenId(data.homeId),
                  isPremium: !data.planLabel
                      .toLowerCase()
                      .contains(l10n.homes_plan_free.toLowerCase()),
                  planLabel: data.planLabel,
                ),
                const _SectionHeader(title: 'GENERAL'),
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
                    const _SettingsRow(
                      label: 'Avatar del hogar',
                      value: '—',
                      iconLeft: Icons.image_outlined,
                      tone: _RowTone.neutral,
                      onTap: null,
                    ),
                    const _SettingsRow(
                      label: 'Zona horaria',
                      value: '—',
                      iconLeft: Icons.public,
                      tone: _RowTone.neutral,
                      onTap: null,
                    ),
                  ],
                ),
                const _SectionHeader(title: 'MIEMBROS Y ROLES'),
                _SectionCard(
                  rows: [
                    const _SettingsRow(
                      label: 'Invitaciones pendientes',
                      value: '—',
                      iconLeft: Icons.mail_outline,
                      tone: _RowTone.neutral,
                      onTap: null,
                    ),
                    const _SettingsRow(
                      label: 'Administradores',
                      value: '—',
                      iconLeft: Icons.shield_outlined,
                      tone: _RowTone.neutral,
                      onTap: null,
                    ),
                    _SettingsRow(
                      label: 'Transferir propiedad',
                      value: null,
                      iconLeft: Icons.swap_horiz,
                      tone: _RowTone.neutral,
                      onTap: data.isOwner ? () {} : null,
                    ),
                  ],
                ),
                const _SectionHeader(title: 'SUSCRIPCIÓN'),
                _SectionCard(
                  rows: [
                    _SettingsRow(
                      label: 'Plan actual',
                      value: data.planLabel,
                      iconLeft: Icons.workspace_premium,
                      tone: _RowTone.accent,
                      onTap: null,
                    ),
                    _SettingsRow(
                      label: 'Pagador',
                      value: data.isPayer ? l10n.homes_role_owner : '—',
                      iconLeft: Icons.person_outline,
                      tone: _RowTone.neutral,
                      onTap: null,
                    ),
                    const _SettingsRow(
                      label: 'Renovación',
                      value: '—',
                      iconLeft: Icons.calendar_today,
                      tone: _RowTone.neutral,
                      onTap: null,
                    ),
                    _SettingsRow(
                      label: 'Cancelar renovación',
                      value: null,
                      iconLeft: Icons.cancel_outlined,
                      tone: _RowTone.danger,
                      onTap: () {},
                    ),
                  ],
                ),
                const _SectionHeader(title: 'ZONA DE PELIGRO'),
                _SectionCard(
                  rows: [
                    _SettingsRow(
                      label: 'Congelar miembro',
                      value: null,
                      iconLeft: Icons.ac_unit,
                      tone: _RowTone.danger,
                      onTap: data.isOwner ? () {} : null,
                    ),
                    _SettingsRow(
                      label: l10n.homes_leave_home,
                      value: null,
                      iconLeft: Icons.logout,
                      tone: _RowTone.danger,
                      onTap: () => _confirmLeave(context, l10n, vm),
                    ),
                    if (data.isOwner)
                      _SettingsRow(
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
    required this.isPremium,
    required this.planLabel,
  });

  final String homeName;
  final String homeIdShort;
  final bool isPremium;
  final String planLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final initial =
        homeName.trim().isEmpty ? '?' : homeName.trim()[0].toUpperCase();

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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.secondary],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
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
                  'CODE · $homeIdShort',
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

    final labelColor = tone == _RowTone.danger ? danger : cs.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                size: 13,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
