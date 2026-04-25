// lib/features/subscription/presentation/skins/futurista/paywall_screen_futurista.dart
//
// Pantalla "Paywall" en skin futurista. Consume el mismo
// `paywallViewModelProvider` que la variante v2 y respeta los `productId`
// `toka_premium_monthly` / `toka_premium_annual` definidos en v2.
//
// Layout (canvas `skin_futurista/screens-meta.jsx`, función `PaywallScreen`):
//   1. Header row: botón cerrar (X) + Spacer + TextButton "Restaurar".
//   2. Hero centrado: caja gold 88x88 con icono crown + display
//      "Tocka Premium" (con `Premium` en gold) + subtítulo.
//   3. Card de features (6 filas con icono gold + check success).
//   4. Row de planes: Mensual neutra + Anual destacada con gradient gold.
//   5. CTA `TockaBtn(variant: gold, size: lg, fullWidth: true)` + footer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../homes/application/current_home_provider.dart';
import '../../../../homes/domain/home.dart';
import '../../../application/days_left.dart';
import '../../../application/paywall_view_model.dart';
import '../../paywall_entry_context.dart';

const _kMonthlyId = 'toka_premium_monthly';
const _kAnnualId = 'toka_premium_annual';

const _gold = Color(0xFFF5B544);
const _goldDark = Color(0xFFD97706);
const _goldOn = Color(0xFF1A1000);

class PaywallScreenFuturista extends ConsumerWidget {
  const PaywallScreenFuturista({
    super.key,
    this.entryContext = PaywallEntryContext.fromFree,
  });

  final PaywallEntryContext entryContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = ref.watch(paywallViewModelProvider);
    final home = ref.watch(currentHomeProvider).valueOrNull;

    ref.listen<PaywallViewModel>(paywallViewModelProvider, (_, next) {
      if (next.purchasedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscription_restore_success)),
        );
        ref
            .read(paywallViewModelNotifierProvider.notifier)
            .clearPurchaseResult();
        if (context.mounted) context.pop();
      } else if (next.purchaseError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.purchaseError!)),
        );
        ref
            .read(paywallViewModelNotifierProvider.notifier)
            .clearPurchaseResult();
      }
    });

    final header = _headerFor(entryContext, l10n, home);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          _CloseButton(onTap: () => context.pop()),
                          const Spacer(),
                          TextButton(
                            key: const Key('btn_restore'),
                            onPressed: () => vm.restorePremium(),
                            style: TextButton.styleFrom(
                              foregroundColor: cs.onSurfaceVariant,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: Text(l10n.paywall_restore),
                          ),
                        ],
                      ),
                    ),

                    // 2. Hero
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [_gold, _goldDark],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.5),
                                  blurRadius: 60,
                                  offset: const Offset(0, 20),
                                  spreadRadius: -10,
                                ),
                              ],
                            ),
                            child: const SizedBox(
                              width: 88,
                              height: 88,
                              child: Center(
                                child: Icon(
                                  Icons.workspace_premium,
                                  size: 40,
                                  color: _goldOn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Tocka ',
                                  style: TextStyle(color: cs.onSurface),
                                ),
                                const TextSpan(
                                  text: 'Premium',
                                  style: TextStyle(color: _gold),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            header.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Features card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: _FeaturesCard(),
                    ),

                    // 4. Plans
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _PlanMonthly(
                              price: l10n.subscription_price_monthly,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PlanAnnual(
                              price: l10n.subscription_price_annual,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 5. CTA
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: TockaBtn(
                        key: const Key('btn_cta_annual'),
                        variant: TockaBtnVariant.gold,
                        size: TockaBtnSize.lg,
                        fullWidth: true,
                        onPressed: vm.isLoading
                            ? null
                            : () => vm.startPurchase(_kAnnualId),
                        child: Text(header.ctaPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // CTA secundaria mensual (manteniendo paridad funcional con v2).
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TockaBtn(
                        key: const Key('btn_cta_monthly'),
                        variant: TockaBtnVariant.ghost,
                        size: TockaBtnSize.md,
                        fullWidth: true,
                        onPressed: vm.isLoading
                            ? null
                            : () => vm.startPurchase(_kMonthlyId),
                        child: Text(l10n.paywall_cta_monthly),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Cancela cuando quieras · Cada cobro suma 1 plaza',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(
            Icons.close,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  static const _features = <(IconData, String)>[
    (Icons.group, '10 miembros · 4 admins'),
    (Icons.auto_awesome, 'Reparto inteligente'),
    (Icons.notifications_outlined, 'Recordatorios avanzados'),
    (Icons.radar, 'Radar de puntos fuertes'),
    (Icons.history, 'Historial 90 días'),
    (Icons.shield_outlined, 'Sin publicidad · todos'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _features.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.19),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: _gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _features[i].$2,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  // Icono real del feature a la izquierda del label.
                  Icon(
                    _features[i].$1,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.tertiary == cs.tertiary
                        ? const Color(0xFF34D399)
                        : const Color(0xFF34D399),
                  ),
                ],
              ),
            ),
            if (i < _features.length - 1)
              Container(height: 1, color: theme.dividerColor),
          ],
        ],
      ),
    );
  }
}

class _PlanMonthly extends StatelessWidget {
  const _PlanMonthly({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MENSUAL',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: cs.onSurface,
            ),
          ),
          Text(
            'al mes · hogar',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PlanAnnual extends StatelessWidget {
  const _PlanAnnual({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.34, -1),
              end: const Alignment(0.34, 1),
              colors: [
                _gold.withValues(alpha: 0.19),
                cs.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _gold.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.5),
                blurRadius: 60,
                offset: const Offset(0, 20),
                spreadRadius: -20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ANUAL',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: _gold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                price,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'al año · 2,50€/mes',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Positioned(
          top: -10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '-37%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _goldOn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaywallHeaderData {
  const _PaywallHeaderData({
    required this.title,
    required this.subtitle,
    required this.ctaPrimary,
  });
  final String title;
  final String subtitle;
  final String ctaPrimary;
}

_PaywallHeaderData _headerFor(
  PaywallEntryContext ctx,
  AppLocalizations l10n,
  Home? home,
) {
  switch (ctx) {
    case PaywallEntryContext.fromFree:
      return _PaywallHeaderData(
        title: l10n.paywall_title,
        subtitle: 'Un pago, todo el hogar\nbeneficia. Para siempre.',
        ctaPrimary: 'Activar Premium → 29,99€/año',
      );
    case PaywallEntryContext.fromExpired:
      final expiredDate = _formatDate(home?.premiumEndsAt) ?? '';
      return _PaywallHeaderData(
        title: l10n.paywall_title_from_expired,
        subtitle: l10n.paywall_subtitle_from_expired(expiredDate),
        ctaPrimary: l10n.paywall_cta_reactivate,
      );
    case PaywallEntryContext.fromRescue:
      final endsAt = home?.premiumEndsAt;
      final days = endsAt != null ? daysLeftFrom(endsAt) : 0;
      return _PaywallHeaderData(
        title: l10n.paywall_title_from_rescue,
        subtitle: l10n.paywall_subtitle_from_rescue(days),
        ctaPrimary: l10n.paywall_cta_reactivate,
      );
    case PaywallEntryContext.fromRestorable:
      final until = home?.restoreUntil;
      final days = until != null ? daysLeftFrom(until) : 0;
      return _PaywallHeaderData(
        title: l10n.paywall_title_from_restorable,
        subtitle: l10n.paywall_subtitle_from_restorable(days),
        ctaPrimary: l10n.paywall_cta_reactivate,
      );
  }
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}
