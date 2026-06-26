import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/paywall_provider.dart';
import '../../application/plus_paywall_view_model.dart';
import '../../application/plus_pricing_provider.dart';
import '../../application/plus_provider.dart';
import '../../application/tier_pricing_provider.dart';
import '../../domain/subscription_products.dart';
import '../../domain/tier_catalog.dart';

/// Paywall del producto INDIVIDUAL Toka Plus (mensual/anual). Separado del
/// paywall de hogar: aquí no hay tiers, downgrade ni pagador.
class PlusPaywallScreenV2 extends ConsumerWidget {
  const PlusPaywallScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Observamos el provider de ESTADO (cambia al seleccionar ciclo / resolver
    // compra) y `paywallProvider` (loading) para que la UI se reconstruya; el
    // provider-VM solo devuelve la instancia estable del notifier.
    ref.watch(plusPaywallViewModelNotifierProvider);
    ref.watch(paywallProvider);
    final vm = ref.read(plusPaywallViewModelNotifierProvider.notifier);
    final hasPlus = ref.watch(plusActiveProvider);
    final pricing = ref.watch(plusPricingProvider).valueOrNull ?? const {};

    ref.listen(plusPaywallViewModelNotifierProvider, (_, __) {
      final v = ref.read(plusPaywallViewModelNotifierProvider.notifier);
      if (v.purchasedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.plusPurchaseSuccess)),
        );
        v.clearPurchaseResult();
        if (context.canPop()) context.pop();
      } else if (v.purchaseError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(v.purchaseError!)),
        );
        v.clearPurchaseResult();
      }
    });

    final Widget body;
    if (hasPlus) {
      body = const _AlreadyActiveBody();
    } else if (vm.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = _PlansBody(pricing: pricing);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plusPaywallTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: body,
    );
  }
}

class _AlreadyActiveBody extends StatelessWidget {
  const _AlreadyActiveBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      key: const Key('plus_already_active'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.plusAlreadyActiveTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.plusAlreadyActiveBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlansBody extends ConsumerWidget {
  const _PlansBody({required this.pricing});

  final Map<String, TierProductInfo> pricing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(plusPaywallViewModelNotifierProvider);
    ref.watch(paywallProvider);
    final vm = ref.read(plusPaywallViewModelNotifierProvider.notifier);

    final annualInfo = pricing[kPlusAnnualProductId];
    final hasTrial = annualInfo?.introOffer.hasFreeTrial ?? false;
    final trialDays = annualInfo?.introOffer.freeTrialDays ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              l10n.plusPaywallSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          _Benefit(
            icon: Icons.block,
            title: l10n.plusBenefitNoAdsTitle,
            description: l10n.plusBenefitNoAdsDesc,
          ),
          _Benefit(
            icon: Icons.palette_outlined,
            title: l10n.plusBenefitSkinsTitle,
            description: l10n.plusBenefitSkinsDesc,
          ),
          _Benefit(
            icon: Icons.insights_outlined,
            title: l10n.plusBenefitMetricsTitle,
            description: l10n.plusBenefitMetricsDesc,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: _PlanCard(
              key: const Key('plus_plan_annual'),
              label: l10n.plusPlanAnnualLabel,
              price: annualInfo?.price ?? l10n.plusPriceAnnualFallback,
              suffix: l10n.plusPriceAnnualSuffix,
              badge: hasTrial
                  ? l10n.paywall_trial_badge(trialDays)
                  : l10n.plusAnnualSavingsBadge,
              selected: vm.cycle == BillingCycle.annual,
              onTap: () => vm.selectCycle(BillingCycle.annual),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: _PlanCard(
              key: const Key('plus_plan_monthly'),
              label: l10n.plusPlanMonthlyLabel,
              price: pricing[kPlusMonthlyProductId]?.price ??
                  l10n.plusPriceMonthlyFallback,
              suffix: l10n.plusPriceMonthlySuffix,
              selected: vm.cycle == BillingCycle.monthly,
              onTap: () => vm.selectCycle(BillingCycle.monthly),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton(
              key: const Key('plus_cta'),
              onPressed: vm.isLoading ? null : () => vm.startPurchase(),
              child: Text(
                hasTrial && vm.cycle == BillingCycle.annual
                    ? l10n.paywall_cta_start_trial(trialDays)
                    : l10n.plusCtaSubscribe,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              key: const Key('plus_restore'),
              onPressed: () => vm.restore(),
              child: Text(l10n.plusRestore),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(description,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
    required this.label,
    required this.price,
    required this.suffix,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String price;
  final String suffix;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selected ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(suffix, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
