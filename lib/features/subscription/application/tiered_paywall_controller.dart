import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/application/dashboard_provider.dart';
import '../domain/tier_catalog.dart';

part 'tiered_paywall_controller.g.dart';

/// Selección actual en el paywall de tiers: qué tier y qué ciclo de facturación.
class TieredPaywallSelection {
  const TieredPaywallSelection({required this.tier, required this.cycle});

  final HomeTier tier;
  final BillingCycle cycle;

  TieredPaywallSelection copyWith({HomeTier? tier, BillingCycle? cycle}) =>
      TieredPaywallSelection(
        tier: tier ?? this.tier,
        cycle: cycle ?? this.cycle,
      );
}

/// Estado del selector del paywall de tiers.
///
/// Preselección inteligente (solo seed inicial; no se rebuildea al cambiar el
/// dashboard para no pisar la elección del usuario): el tier actual si el hogar
/// ya es premium, o el menor tier cuyo tope cabe los miembros activos. Ciclo por
/// defecto: anual (donde vive el trial/ahorro).
@riverpod
class TieredPaywallController extends _$TieredPaywallController {
  @override
  TieredPaywallSelection build() {
    final dash = ref.read(dashboardProvider).valueOrNull;
    final currentTier = homeTierFromString(dash?.premiumFlags.tier);
    final activeMembers = dash?.planCounters.activeMembers ?? 0;
    final tier = currentTier ??
        smallestTierForMembers(activeMembers < 1 ? 1 : activeMembers);
    return TieredPaywallSelection(tier: tier, cycle: BillingCycle.annual);
  }

  void selectTier(HomeTier tier) => state = state.copyWith(tier: tier);

  void selectCycle(BillingCycle cycle) => state = state.copyWith(cycle: cycle);
}
