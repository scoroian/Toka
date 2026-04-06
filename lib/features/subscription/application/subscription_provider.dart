import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../../homes/domain/home.dart';
import '../data/subscription_repository_impl.dart';
import '../domain/subscription_repository.dart';
import '../domain/subscription_state.dart';

part 'subscription_provider.g.dart';

@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(SubscriptionRepositoryRef ref) {
  return SubscriptionRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instance,
    inAppPurchase: InAppPurchase.instance,
  );
}

/// Deriva el SubscriptionState directamente del Home actual.
@riverpod
SubscriptionState subscriptionState(SubscriptionStateRef ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  return homeAsync.when(
    loading: () => const SubscriptionState.free(),
    error: (_, __) => const SubscriptionState.free(),
    data: (home) => home == null ? const SubscriptionState.free() : _fromHome(home),
  );
}

SubscriptionState _fromHome(Home home) {
  switch (home.premiumStatus) {
    case HomePremiumStatus.free:
      return const SubscriptionState.free();
    case HomePremiumStatus.active:
      return SubscriptionState.active(
        plan: home.premiumPlan ?? 'monthly',
        endsAt: home.premiumEndsAt ?? DateTime.now(),
        autoRenew: home.autoRenewEnabled,
      );
    case HomePremiumStatus.cancelledPendingEnd:
      return SubscriptionState.cancelledPendingEnd(
        plan: home.premiumPlan ?? 'monthly',
        endsAt: home.premiumEndsAt ?? DateTime.now(),
      );
    case HomePremiumStatus.rescue:
      final daysLeft = home.premiumEndsAt != null
          ? home.premiumEndsAt!.difference(DateTime.now()).inDays.clamp(0, 3)
          : 0;
      return SubscriptionState.rescue(
        plan: home.premiumPlan ?? 'monthly',
        endsAt: home.premiumEndsAt,
        daysLeft: daysLeft,
      );
    case HomePremiumStatus.expiredFree:
      return const SubscriptionState.expiredFree();
    case HomePremiumStatus.restorable:
      return SubscriptionState.restorable(
        restoreUntil: home.restoreUntil ?? DateTime.now(),
      );
    case HomePremiumStatus.purged:
      return const SubscriptionState.purged();
  }
}
