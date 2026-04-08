import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../application/rescue_view_model.dart';
import 'widgets/plan_comparison_card.dart';

class RescueScreen extends ConsumerWidget {
  const RescueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(rescueViewModelProvider);

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
              l10n.rescue_banner_text(vm.daysLeft),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
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
