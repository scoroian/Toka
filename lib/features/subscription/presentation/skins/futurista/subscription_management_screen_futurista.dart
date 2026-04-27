// lib/features/subscription/presentation/skins/futurista/subscription_management_screen_futurista.dart
//
// Pantalla "Gestión de suscripción" en skin Futurista. Consume el mismo
// `subscriptionManagementViewModelProvider` que la variante v2: stream
// `subscriptionDashboardProvider` + `paywallProvider` para refresh en vivo.
//
// CONCERNS — props del VM no expuestas → placeholders documentados:
//   - price        → no hay precio canónico en `SubscriptionDashboard`. Se
//                    muestra el `plan` (annual / monthly) como label en el hero.
//   - payerName    → el VM expone sólo `currentPayerUid`; resolvemos a
//                    "Tú" si coincide con el usuario autenticado o "Pagador"
//                    como placeholder neutro.
//   - charge history → el VM no expone historial; la card "HISTORIAL DE
//                    COBROS" se omite. Si en el futuro se añade, encajaría
//                    con la última card propuesta en el spec.
//
// Paridad funcional con v2:
//   - free / purged       → CTA "Actualizar a Premium" → push paywall.
//   - active              → row "Gestionar facturación" + "Cancelar
//                           renovación" (Play Store).
//   - cancelledPendingEnd → row "Reactivar renovación" + "Cambiar plan".
//   - rescue              → row "Renovar" (rescue) + "Planear downgrade".
//   - expiredFree         → row "Reactivar Premium".
//   - restorable          → row "Restaurar Premium" → vm.restorePremium().
//
// Layout (lenguaje futurista — bg surfaceContainerHighest cards, mono labels
// uppercase letterSpacing 1.4-1.6, hero gradient gold, TockaBtn / TockaPill /
// TockaAvatar):
//   1. Header: chevron back 38x38 + título centrado.
//   2. Plan card hero: gradient gold→surface + plan label + pill estado +
//      detalle de renovación (si aplica) en mono.
//   3. Pagador card surfaceContainerHighest + TockaAvatar + pill rol.
//   4. Acciones list surfaceContainerHighest con rows divididas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/theme/futurista/futurista_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../../homes/domain/home.dart';
import '../../../application/paywall_provider.dart';
import '../../../application/subscription_management_view_model.dart';
import '../../../domain/subscription_dashboard.dart';

const String _kMono = 'JetBrainsMono';
const Color _gold = FuturistaColors.premium;

class SubscriptionManagementScreenFuturista extends ConsumerWidget {
  const SubscriptionManagementScreenFuturista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = ref.watch(subscriptionManagementViewModelProvider);
    final currentUid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);

    ref.listen<AsyncValue<dynamic>>(paywallProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.subscription_restore_success)),
          );
        },
        error: (err, _) {
          final msg = err.toString().contains('restore_window_expired')
              ? l10n.subscription_restore_expired_error
              : l10n.error_generic;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header fijo arriba: el botón back queda anclado.
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _Header(title: l10n.subscription_management_title),
            ),
            Expanded(
              child: vm.dashboard.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.error_generic),
                  ),
                ),
                data: (data) => ListView(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    14,
                    0,
                    adAwareBottomPadding(context, ref, extra: 16),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PlanHeroCard(data: data),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PayerCard(
                        data: data,
                        currentUserUid: currentUid,
                        l10n: l10n,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ActionsCard(
                        data: data,
                        vm: vm,
                        l10n: l10n,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Material(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: const Key('subscription_mgmt_back'),
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
                child: Icon(
                  Icons.chevron_left,
                  size: 22,
                  color: cs.onSurface,
                ),
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
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Plan hero card
// -----------------------------------------------------------------------------

class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({required this.data});

  final SubscriptionDashboard data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final info = _PlanHeroInfo.from(data, AppLocalizations.of(context));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _gold.withValues(alpha: 0.14),
            cs.surface.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  info.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              info.statusPill,
            ],
          ),
          if (info.detail != null) ...[
            const SizedBox(height: 12),
            Text(
              info.detail!,
              style: TextStyle(
                fontFamily: _kMono,
                fontSize: 11.5,
                letterSpacing: 0.3,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanHeroInfo {
  const _PlanHeroInfo({
    required this.title,
    required this.statusPill,
    required this.detail,
  });

  final String title;
  final Widget statusPill;
  final String? detail;

  factory _PlanHeroInfo.from(
    SubscriptionDashboard data,
    AppLocalizations l10n,
  ) {
    // 'Tocka Premium' / 'Tocka Free' son nombres de marca y NO se localizan.
    // Sí se localizan los sufijos de plan (Mensual/Anual) y todos los
    // detalles del pill (renovación, vencimiento, etc.).
    String planSuffix() {
      if (data.plan == 'annual') return ' · ${l10n.subscription_annual}';
      if (data.plan == 'monthly') return ' · ${l10n.subscription_monthly}';
      return '';
    }

    String? renewalDetail() {
      final endsAt = data.endsAt;
      if (endsAt == null) return null;
      return l10n.subscription_renewal_detail(_formatDate(endsAt));
    }

    String? expiredDetail() {
      final endsAt = data.endsAt;
      if (endsAt == null) return null;
      return l10n.subscription_expired_detail(_formatDate(endsAt));
    }

    String? restoreDetail() {
      final until = data.restoreUntil;
      if (until == null) return null;
      return l10n.subscription_restore_detail(_formatDate(until));
    }

    switch (data.status) {
      case HomePremiumStatus.active:
        return _PlanHeroInfo(
          title: 'Tocka Premium${planSuffix()}',
          statusPill: _StatusPill(
            label: l10n.subscription_status_pill_active,
            color: FuturistaColors.success,
          ),
          detail: renewalDetail(),
        );
      case HomePremiumStatus.cancelledPendingEnd:
        return _PlanHeroInfo(
          title: 'Tocka Premium${planSuffix()}',
          statusPill: _StatusPill(
            label: l10n.subscription_status_pill_cancelled,
            color: FuturistaColors.warning,
          ),
          detail: data.endsAt != null
              ? l10n.subscription_expires_on_detail(_formatDate(data.endsAt!))
              : null,
        );
      case HomePremiumStatus.rescue:
        return _PlanHeroInfo(
          title: 'Tocka Premium${planSuffix()}',
          statusPill: _StatusPill(
            label: l10n.subscription_status_pill_rescue,
            color: FuturistaColors.warning,
          ),
          detail: data.endsAt != null
              ? l10n.subscription_expires_in_days(data.daysLeft)
              : null,
        );
      case HomePremiumStatus.expiredFree:
        return _PlanHeroInfo(
          title: 'Tocka Free',
          statusPill: _StatusPill(
            label: l10n.subscription_status_pill_expired,
            color: FuturistaColors.error,
          ),
          detail: expiredDetail(),
        );
      case HomePremiumStatus.restorable:
        return _PlanHeroInfo(
          title: 'Tocka Free',
          statusPill: _StatusPill(
            label: l10n.subscription_status_pill_restorable,
            color: FuturistaColors.primary,
          ),
          detail: restoreDetail(),
        );
      case HomePremiumStatus.free:
      case HomePremiumStatus.purged:
        return _PlanHeroInfo(
          title: 'Tocka Free',
          statusPill: _StatusPill(
            label: l10n.homes_plan_free,
            color: null,
          ),
          detail: null,
        );
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color;
    final bg = c != null
        ? c.withValues(alpha: 0.13)
        : theme.colorScheme.surfaceContainerHighest;
    final border = c != null
        ? c.withValues(alpha: 0.3)
        : theme.dividerColor;
    final fg = c ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pagador card
// -----------------------------------------------------------------------------

class _PayerCard extends StatelessWidget {
  const _PayerCard({
    required this.data,
    required this.currentUserUid,
    required this.l10n,
  });

  final SubscriptionDashboard data;
  final String? currentUserUid;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasPayer = data.currentPayerUid != null;
    final isSelf =
        hasPayer && currentUserUid != null && currentUserUid == data.currentPayerUid;
    final name = !hasPayer
        ? '—'
        : (isSelf ? l10n.subscription_payer_you : l10n.subscription_payer_other);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _PayerAvatar(name: name, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PAGADOR',
                  style: TextStyle(
                    fontFamily: _kMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(
            label: isSelf ? 'Tú' : 'Hogar',
            color: isSelf ? FuturistaColors.primary : null,
          ),
        ],
      ),
    );
  }
}

class _PayerAvatar extends StatelessWidget {
  const _PayerAvatar({required this.name, required this.color});

  final String name;
  final Color color;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == '—') return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.67)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Actions card
// -----------------------------------------------------------------------------

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.data,
    required this.vm,
    required this.l10n,
  });

  final SubscriptionDashboard data;
  final SubscriptionManagementViewModel vm;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLoading = vm.isLoading;

    final rows = _rowsFor(context);

    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(Divider(height: 1, color: theme.dividerColor));
      }
    }

    return Opacity(
      opacity: isLoading ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(children: children),
      ),
    );
  }

  List<Widget> _rowsFor(BuildContext context) {
    final isLoading = vm.isLoading;
    switch (data.status) {
      case HomePremiumStatus.free:
      case HomePremiumStatus.purged:
        return [
          _ActionRow(
            rowKey: const Key('btn_go_premium'),
            label: l10n.premium_gate_upgrade,
            icon: Icons.workspace_premium,
            tone: _RowTone.accent,
            onTap: isLoading ? null : () => context.push(AppRoutes.paywall),
          ),
        ];
      case HomePremiumStatus.active:
        return [
          _ActionRow(
            rowKey: const Key('btn_manage_billing'),
            label: l10n.subscription_manage_billing,
            icon: Icons.credit_card,
            tone: _RowTone.accent,
            onTap: isLoading ? null : _openPlayStoreSubscriptions,
          ),
          _ActionRow(
            rowKey: const Key('btn_cancel_renewal'),
            label: l10n.subscription_cancel_renewal,
            icon: Icons.cancel_outlined,
            tone: _RowTone.danger,
            onTap: isLoading ? null : _openPlayStoreSubscriptions,
          ),
        ];
      case HomePremiumStatus.cancelledPendingEnd:
        return [
          _ActionRow(
            rowKey: const Key('btn_reactivate_renewal'),
            label: l10n.subscription_reactivate_renewal,
            icon: Icons.refresh,
            tone: _RowTone.accent,
            onTap: isLoading ? null : () => context.push(AppRoutes.paywall),
          ),
          _ActionRow(
            rowKey: const Key('btn_change_plan'),
            label: l10n.subscription_change_plan,
            icon: Icons.swap_horiz,
            tone: _RowTone.neutral,
            onTap: isLoading ? null : () => context.push(AppRoutes.paywall),
          ),
        ];
      case HomePremiumStatus.rescue:
        return [
          _ActionRow(
            rowKey: const Key('btn_renew'),
            label: l10n.rescue_banner_renew,
            icon: Icons.refresh,
            tone: _RowTone.accent,
            onTap: isLoading
                ? null
                : () => context.push(AppRoutes.rescueScreen),
          ),
          _ActionRow(
            rowKey: const Key('btn_plan_downgrade'),
            label: l10n.subscription_plan_downgrade,
            icon: Icons.trending_down,
            tone: _RowTone.neutral,
            onTap: isLoading
                ? null
                : () => context.push(AppRoutes.downgradePlanner),
          ),
        ];
      case HomePremiumStatus.expiredFree:
        return [
          _ActionRow(
            rowKey: const Key('btn_reactivate_premium'),
            label: l10n.subscription_reactivate_premium,
            icon: Icons.workspace_premium,
            tone: _RowTone.accent,
            onTap: isLoading ? null : () => context.push(AppRoutes.paywall),
          ),
        ];
      case HomePremiumStatus.restorable:
        return [
          _ActionRow(
            rowKey: const Key('btn_restore_premium'),
            label: l10n.subscription_restore_btn,
            icon: Icons.restore,
            tone: _RowTone.accent,
            onTap: isLoading ? null : () => vm.restorePremium(),
          ),
        ];
    }
  }

  Future<void> _openPlayStoreSubscriptions() async {
    final uri =
        Uri.parse('https://play.google.com/store/account/subscriptions');
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

enum _RowTone { neutral, accent, danger }

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.rowKey,
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final Key rowKey;
  final String label;
  final IconData icon;
  final _RowTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final danger = cs.error;

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
        slotBg = _gold.withValues(alpha: 0.09);
        slotBorder = _gold.withValues(alpha: 0.19);
        slotIcon = _gold;
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
        key: rowKey,
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
                child: Icon(icon, size: 13, color: slotIcon),
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

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}
