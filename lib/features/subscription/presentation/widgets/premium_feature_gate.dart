import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/subscription_provider.dart';

/// Wrapper que muestra el child si el hogar tiene Premium,
/// o un overlay de upgrade si requiresPremium es true y no hay Premium.
class PremiumFeatureGate extends ConsumerWidget {
  const PremiumFeatureGate({
    super.key,
    required this.child,
    required this.requiresPremium,
    required this.featureName,
  });

  final Widget child;
  final bool requiresPremium;
  final String featureName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!requiresPremium) return child;

    final subState = ref.watch(subscriptionStateProvider);
    final isPremium = subState.when(
      free: () => false,
      active: (_, __, ___) => true,
      cancelledPendingEnd: (_, __) => true,
      rescue: (_, __, ___) => true,
      expiredFree: () => false,
      restorable: (_) => false,
      purged: () => false,
    );

    if (isPremium) return child;

    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        IgnorePointer(child: Opacity(opacity: 0.4, child: child)),
        Positioned.fill(
          child: Container(
            key: const Key('premium_gate_overlay'),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  l10n.premium_gate_title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.premium_gate_body(featureName),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: const Key('btn_upgrade'),
                  onPressed: () => context.push(AppRoutes.paywall),
                  child: Text(l10n.premium_gate_upgrade),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
