import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/rescue_view_model.dart';
import '../widgets/plan_comparison_card.dart';

class RescueScreenV2 extends ConsumerWidget {
  const RescueScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(rescueViewModelProvider);

    // Si quedan <24h mostramos el countdown en horas (precisión alta);
    // a partir de 24h (1 día) pasamos a días. daysLeft usa ceil, así
    // que para 7h daysLeft=1 pero queremos "Quedan 7 horas".
    final countdownLabel = vm.hoursLeft < 24
        ? l10n.rescue_banner_hours_left(vm.hoursLeft)
        : l10n.rescue_banner_text(vm.daysLeft);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rescue_screen_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.rescue_screen_body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              countdownLabel,
              key: const Key('rescue_countdown'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (vm.lastBillingError != null) ...[
              const SizedBox(height: 16),
              _LastBillingErrorTile(message: vm.lastBillingError!),
            ],
            const SizedBox(height: 24),
            const PlanComparisonCard(),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('btn_renew_annual'),
              onPressed: vm.isLoading
                  ? null
                  : () => vm.startPurchase('toka_premium_annual'),
              child: Text(l10n.paywall_cta_annual),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('btn_renew_monthly'),
              onPressed: vm.isLoading
                  ? null
                  : () => vm.startPurchase('toka_premium_monthly'),
              child: Text(l10n.paywall_cta_monthly),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('btn_plan_downgrade'),
              onPressed: () => context.push(AppRoutes.downgradePlanner),
              child: Text(l10n.subscription_plan_downgrade),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastBillingErrorTile extends StatelessWidget {
  const _LastBillingErrorTile({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const Key('rescue_last_billing_error'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rescue_last_billing_error_title,
                  style: TextStyle(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
