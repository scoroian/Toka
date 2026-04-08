// lib/features/subscription/application/rescue_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import 'paywall_provider.dart';
import 'subscription_provider.dart';

part 'rescue_view_model.g.dart';

abstract class RescueViewModel {
  int get daysLeft;
  bool get isLoading;
  String get homeId;
  Future<void> startPurchase(String productId);
}

class _RescueViewModelImpl implements RescueViewModel {
  const _RescueViewModelImpl({
    required this.daysLeft,
    required this.isLoading,
    required this.homeId,
    required this.ref,
  });
  @override
  final int daysLeft;
  @override
  final bool isLoading;
  @override
  final String homeId;
  final Ref ref;

  @override
  Future<void> startPurchase(String productId) =>
      ref.read(paywallProvider.notifier).startPurchase(
            homeId: homeId,
            productId: productId,
          );
}

@riverpod
RescueViewModel rescueViewModel(RescueViewModelRef ref) {
  final subState = ref.watch(subscriptionStateProvider);
  final daysLeft =
      subState.whenOrNull(rescue: (_, __, d) => d) ?? 0;
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
  final isLoading = ref.watch(paywallProvider).isLoading;

  return _RescueViewModelImpl(
    daysLeft: daysLeft,
    isLoading: isLoading,
    homeId: homeId,
    ref: ref,
  );
}
