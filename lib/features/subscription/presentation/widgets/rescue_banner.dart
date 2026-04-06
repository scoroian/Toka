import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/application/auth_provider.dart';
import '../../../../features/homes/application/current_home_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/subscription_provider.dart';

/// Banner que aparece si premiumStatus == 'rescue'.
/// Solo visible para owner y pagador actual.
class RescueBanner extends ConsumerWidget {
  const RescueBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionStateProvider);
    final daysLeft = subState.whenOrNull(
      rescue: (_, __, daysLeft) => daysLeft,
    );
    if (daysLeft == null) return const SizedBox.shrink();

    final homeAsync = ref.watch(currentHomeProvider);
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
    final home = homeAsync.valueOrNull;
    if (home == null) return const SizedBox.shrink();

    final isOwnerOrPayer = home.ownerUid == uid || home.currentPayerUid == uid;
    if (!isOwnerOrPayer) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.rescue_banner_text(daysLeft),
                key: const Key('rescue_banner_text'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              key: const Key('rescue_banner_renew_btn'),
              onPressed: () => context.push('/subscription/rescue'),
              child: Text(
                l10n.rescue_banner_renew,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
