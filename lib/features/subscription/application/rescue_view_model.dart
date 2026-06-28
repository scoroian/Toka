// lib/features/subscription/application/rescue_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/current_home_provider.dart';
import '../domain/renewal_product.dart';
import '../domain/tier_catalog.dart';
import 'current_tier_provider.dart';
import 'days_left.dart';
import 'home_tiers_provider.dart';
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

  /// SKU de renovación ANUAL resuelto según el modelo de tiers: con tiers ON
  /// renueva el tier actual del hogar; con OFF (o tier desconocido) el legacy.
  String get annualProductId;

  /// SKU de renovación MENSUAL resuelto (ver [annualProductId]).
  String get monthlyProductId;

  /// Tope de miembros del tier ACTUAL del hogar (Pareja 2 / Familia 5 / Grupo
  /// 10). Fallback a Grupo (10) si el tier es desconocido — coherente con
  /// `renewalProductId`, que cae al SKU legacy (=Grupo) en ese caso. Lo usa la
  /// pantalla de rescate para mostrar los miembros de "su tier", no "10" fijo.
  int get premiumMemberLimit;

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
    required this.annualProductId,
    required this.monthlyProductId,
    required this.premiumMemberLimit,
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
  @override
  final String annualProductId;
  @override
  final String monthlyProductId;
  @override
  final int premiumMemberLimit;
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

  // Renovar el TIER ACTUAL del hogar con el modelo de tiers ON; legacy con OFF.
  final tiersEnabled = ref.watch(homeTiersEnabledProvider);
  final tier = ref.watch(currentHomeTierProvider);

  return _RescueViewModelImpl(
    daysLeft: daysLeft,
    hoursLeft: hoursLeft,
    endsAt: endsAt,
    lastBillingError: lastBillingError,
    isLoading: isLoading,
    homeId: homeId,
    annualProductId: renewalProductId(
        tiersEnabled: tiersEnabled, tier: tier, cycle: BillingCycle.annual),
    monthlyProductId: renewalProductId(
        tiersEnabled: tiersEnabled, tier: tier, cycle: BillingCycle.monthly),
    premiumMemberLimit:
        (tiersEnabled && tier != null ? tier : HomeTier.grupo).maxMembers,
    ref: ref,
  );
}
