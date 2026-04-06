import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Tarjeta comparativa Free vs Premium con tabla de features.
class PlanComparisonCard extends StatelessWidget {
  const PlanComparisonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final features = [
      (l10n.paywall_feature_members, false, true),
      (l10n.paywall_feature_smart, false, true),
      (l10n.paywall_feature_vacations, false, true),
      (l10n.paywall_feature_reviews, false, true),
      (l10n.paywall_feature_history, false, true),
      (l10n.paywall_feature_no_ads, false, true),
    ];

    return Card(
      key: const Key('plan_comparison_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  child: Text(
                    l10n.subscription_free,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.subscription_premium,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...features.map(
              (f) => _FeatureRow(
                label: f.$1,
                hasFree: f.$2,
                hasPremium: f.$3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.hasFree,
    required this.hasPremium,
  });

  final String label;
  final bool hasFree;
  final bool hasPremium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: Center(
              child: Icon(
                hasFree ? Icons.check_circle : Icons.cancel,
                color: hasFree ? Colors.green : Colors.grey.shade300,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                hasPremium ? Icons.check_circle : Icons.cancel,
                color: hasPremium
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
