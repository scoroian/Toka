// lib/features/subscription/application/subscription_management_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../domain/subscription_state.dart';
import 'paywall_provider.dart';
import 'subscription_provider.dart';

part 'subscription_management_view_model.g.dart';

abstract class SubscriptionManagementViewModel {
  SubscriptionState get subscriptionState;
  bool get isLoading;
  String get homeId;
  Future<void> restorePremium();
}

class _SubscriptionManagementViewModelImpl
    implements SubscriptionManagementViewModel {
  const _SubscriptionManagementViewModelImpl({
    required this.subscriptionState,
    required this.isLoading,
    required this.homeId,
    required this.ref,
  });
  @override
  final SubscriptionState subscriptionState;
  @override
  final bool isLoading;
  @override
  final String homeId;
  final Ref ref;

  @override
  Future<void> restorePremium() =>
      ref.read(paywallProvider.notifier).restorePremium(homeId: homeId);
}

@riverpod
SubscriptionManagementViewModel subscriptionManagementViewModel(
    SubscriptionManagementViewModelRef ref) {
  final subState = ref.watch(subscriptionStateProvider);
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
  final isLoading = ref.watch(paywallProvider).isLoading;

  return _SubscriptionManagementViewModelImpl(
    subscriptionState: subState,
    isLoading: isLoading,
    homeId: homeId,
    ref: ref,
  );
}
