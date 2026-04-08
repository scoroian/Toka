import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../application/paywall_provider.dart';
import '../application/subscription_management_view_model.dart';
import '../domain/subscription_state.dart';

class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(subscriptionManagementViewModelProvider);

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
      appBar: AppBar(title: Text(l10n.subscription_management_title)),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusTile(subState: vm.subscriptionState),
                  const SizedBox(height: 24),
                  _ActionButtons(
                    subState: vm.subscriptionState,
                    homeId: vm.homeId,
                    vm: vm,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.subState});
  final SubscriptionState subState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMd();

    final statusText = subState.when(
      free: () => l10n.subscription_status_free,
      active: (_, __, ___) => l10n.subscription_status_active,
      cancelledPendingEnd: (_, endsAt) =>
          l10n.subscription_status_cancelled(dateFormat.format(endsAt)),
      rescue: (_, __, daysLeft) => l10n.subscription_status_rescue(daysLeft),
      expiredFree: () => l10n.subscription_status_free,
      restorable: (restoreUntil) =>
          l10n.subscription_status_restorable(dateFormat.format(restoreUntil)),
      purged: () => l10n.subscription_status_free,
    );

    return ListTile(
      key: const Key('subscription_status_tile'),
      leading: const Icon(Icons.star),
      title: Text(statusText),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.subState,
    required this.homeId,
    required this.vm,
  });
  final SubscriptionState subState;
  final String homeId;
  final SubscriptionManagementViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (subState is SubscriptionFree ||
            subState is SubscriptionExpiredFree ||
            subState is SubscriptionPurged)
          FilledButton(
            key: const Key('btn_go_premium'),
            onPressed: () => context.push(AppRoutes.paywall),
            child: Text(l10n.premium_gate_upgrade),
          ),
        if (subState is SubscriptionRestorable) ...[
          FilledButton(
            key: const Key('btn_restore_premium'),
            onPressed: () => vm.restorePremium(),
            child: Text(l10n.subscription_restore_btn),
          ),
          const SizedBox(height: 8),
        ],
        if (subState is SubscriptionRescue) ...[
          FilledButton(
            key: const Key('btn_renew'),
            onPressed: () => context.push(AppRoutes.rescueScreen),
            child: Text(l10n.rescue_banner_renew),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('btn_plan_downgrade'),
            onPressed: () => context.push(AppRoutes.downgradePlanner),
            child: Text(l10n.subscription_plan_downgrade),
          ),
        ],
      ],
    );
  }
}
