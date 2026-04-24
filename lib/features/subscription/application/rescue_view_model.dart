// lib/features/subscription/application/rescue_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import 'days_left.dart';
import 'paywall_provider.dart';
import 'subscription_provider.dart';

part 'rescue_view_model.g.dart';

abstract class RescueViewModel {
  int get daysLeft;
  int get hoursLeft;
  DateTime? get endsAt;
  String? get lastBillingError;
  bool get isLoading;
  String get homeId;
  Future<void> startPurchase(String productId);
}

class _RescueViewModelImpl implements RescueViewModel {
  const _RescueViewModelImpl({
    required this.daysLeft,
    required this.hoursLeft,
    required this.endsAt,
    required this.lastBillingError,
    required this.isLoading,
    required this.homeId,
    required this.ref,
  });
  @override
  final int daysLeft;
  @override
  final int hoursLeft;
  @override
  final DateTime? endsAt;
  @override
  final String? lastBillingError;
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
  final endsAt = subState.whenOrNull(rescue: (_, e, __) => e);
  // Cliente prefiere calcular sobre endsAt (real-time, ceil). Si falta
  // fallback al daysLeft del dashboard (backup/analítica).
  final stateDaysLeft =
      subState.whenOrNull(rescue: (_, __, d) => d) ?? 0;
  final daysLeft = endsAt != null ? daysLeftFrom(endsAt) : stateDaysLeft;
  final hoursLeft = endsAt != null ? hoursLeftFrom(endsAt) : 0;
  final home = ref.watch(currentHomeProvider).valueOrNull;
  final homeId = home?.id ?? '';
  final lastBillingError = home?.lastBillingError;
  final isLoading = ref.watch(paywallProvider).isLoading;

  return _RescueViewModelImpl(
    daysLeft: daysLeft,
    hoursLeft: hoursLeft,
    endsAt: endsAt,
    lastBillingError: lastBillingError,
    isLoading: isLoading,
    homeId: homeId,
    ref: ref,
  );
}
