import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../application/paywall_view_model.dart';
import 'widgets/plan_comparison_card.dart';

const _kMonthlyId = 'toka_premium_monthly';
const _kAnnualId = 'toka_premium_annual';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(paywallViewModelProvider);

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paywall_title),
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
                      l10n.paywall_subtitle,
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
                    badge: l10n.subscription_annual_saving,
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
                          : () => vm.startPurchase(_kAnnualId),
                      child: Text(l10n.paywall_cta_annual),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OutlinedButton(
                      key: const Key('btn_cta_monthly'),
                      onPressed: vm.isLoading
                          ? null
                          : () => vm.startPurchase(_kMonthlyId),
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
