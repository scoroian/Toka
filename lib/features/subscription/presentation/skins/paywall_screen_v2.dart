import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../homes/application/current_home_provider.dart';
import '../../../homes/domain/home.dart';
import '../../application/days_left.dart';
import '../../application/intro_offer_provider.dart';
import '../../application/paywall_view_model.dart';
import '../../domain/intro_offer.dart';
import '../../domain/subscription_products.dart';
import '../paywall_entry_context.dart';
import '../widgets/plan_comparison_card.dart';

class PaywallScreenV2 extends ConsumerWidget {
  const PaywallScreenV2({
    super.key,
    this.entryContext = PaywallEntryContext.fromFree,
  });

  final PaywallEntryContext entryContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(paywallViewModelProvider);
    final home = ref.watch(currentHomeProvider).valueOrNull;
    // Oferta introductoria del plan anual leída de la store (Hallazgo #14). Si
    // aún no ha cargado o la store no concede trial, asumimos "sin trial" para
    // no prometer una prueba inexistente.
    final annualOffer =
        ref.watch(annualIntroOfferProvider).valueOrNull ?? IntroOffer.none;
    final hasTrial = annualOffer.hasFreeTrial;

    ref.listen<PaywallViewModel>(paywallViewModelProvider, (_, next) {
      if (next.purchasedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscription_restore_success)),
        );
        ref.read(paywallViewModelNotifierProvider.notifier).clearPurchaseResult();
        context.pop();
      } else if (next.purchaseError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.purchaseError!)),
        );
        ref.read(paywallViewModelNotifierProvider.notifier).clearPurchaseResult();
      }
    });

    final header = _headerFor(entryContext, l10n, home);

    return Scaffold(
      appBar: AppBar(
        title: Text(header.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Text(
                      header.subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const PlanComparisonCard(),
                  const SizedBox(height: 24),
                  _PriceChip(
                    key: const Key('chip_annual'),
                    label: l10n.subscription_annual,
                    price: l10n.subscription_price_annual,
                    // Si hay prueba gratuita, el trial es el reclamo principal
                    // del chip anual; si no, el ahorro frente al mensual.
                    badge: hasTrial
                        ? l10n.paywall_trial_badge(annualOffer.freeTrialDays)
                        : l10n.subscription_annual_saving,
                  ),
                  const SizedBox(height: 8),
                  _PriceChip(
                    key: const Key('chip_monthly'),
                    label: l10n.subscription_monthly,
                    price: l10n.subscription_price_monthly,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FilledButton(
                      key: const Key('btn_cta_annual'),
                      onPressed: vm.isLoading
                          ? null
                          : () => vm.startPurchase(kAnnualProductId),
                      child: Text(hasTrial
                          ? l10n.paywall_cta_start_trial(annualOffer.freeTrialDays)
                          : header.ctaPrimary),
                    ),
                  ),
                  if (hasTrial) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        l10n.paywall_trial_note,
                        key: const Key('paywall_trial_note'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OutlinedButton(
                      key: const Key('btn_cta_monthly'),
                      onPressed: vm.isLoading
                          ? null
                          : () => vm.startPurchase(kMonthlyProductId),
                      child: Text(l10n.paywall_cta_monthly),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      key: const Key('btn_restore'),
                      onPressed: () => vm.restorePremium(),
                      child: Text(l10n.paywall_restore),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      key: const Key('btn_terms'),
                      onPressed: () {/* open URL in future */},
                      child: Text(
                        l10n.paywall_terms,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PaywallHeader {
  const _PaywallHeader({
    required this.title,
    required this.subtitle,
    required this.ctaPrimary,
  });
  final String title;
  final String subtitle;
  final String ctaPrimary;
}

_PaywallHeader _headerFor(
  PaywallEntryContext ctx,
  AppLocalizations l10n,
  Home? home,
) {
  switch (ctx) {
    case PaywallEntryContext.fromFree:
      return _PaywallHeader(
        title: l10n.paywall_title,
        subtitle: l10n.paywall_subtitle,
        ctaPrimary: l10n.paywall_cta_annual,
      );
    case PaywallEntryContext.fromExpired:
      final expiredDate = _formatDate(home?.premiumEndsAt) ?? '';
      return _PaywallHeader(
        title: l10n.paywall_title_from_expired,
        subtitle: l10n.paywall_subtitle_from_expired(expiredDate),
        ctaPrimary: l10n.paywall_cta_reactivate,
      );
    case PaywallEntryContext.fromRescue:
      final endsAt = home?.premiumEndsAt;
      final days = endsAt != null ? daysLeftFrom(endsAt) : 0;
      return _PaywallHeader(
        title: l10n.paywall_title_from_rescue,
        subtitle: l10n.paywall_subtitle_from_rescue(days),
        ctaPrimary: l10n.paywall_cta_reactivate,
      );
    case PaywallEntryContext.fromRestorable:
      final until = home?.restoreUntil;
      final days = until != null ? daysLeftFrom(until) : 0;
      return _PaywallHeader(
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

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    super.key,
    required this.label,
    required this.price,
    this.badge,
  });

  final String label;
  final String price;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
