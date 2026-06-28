import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../homes/application/current_home_provider.dart';
import '../../../homes/application/dashboard_provider.dart';
import '../../../homes/domain/home.dart';
import '../../../tasks/domain/home_dashboard.dart';
import '../../application/days_left.dart';
import '../../application/home_tiers_provider.dart';
import '../../application/intro_offer_provider.dart';
import '../../application/member_packs_enabled_provider.dart';
import '../../application/member_packs_pricing_provider.dart';
import '../../application/paywall_view_model.dart';
import '../../application/tier_pricing_provider.dart';
import '../../application/tiered_paywall_controller.dart';
import '../../domain/intro_offer.dart';
import '../../domain/member_pack_catalog.dart';
import '../../domain/subscription_products.dart';
import '../../domain/tier_catalog.dart';
import '../pack_display.dart';
import '../paywall_entry_context.dart';
import '../tier_display.dart';
import '../widgets/plan_comparison_card.dart';
import '../widgets/toka_business_dialog.dart';

class PaywallScreenV2 extends ConsumerWidget {
  const PaywallScreenV2({
    super.key,
    this.entryContext = PaywallEntryContext.fromFree,
  });

  final PaywallEntryContext entryContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(paywallViewModelProvider);
    final home = ref.watch(currentHomeProvider).valueOrNull;
    // Flag de Remote Config: con OFF, la UI vuelve al paywall Premium único.
    final tiersEnabled = ref.watch(homeTiersEnabledProvider);

    ref.listen<PaywallViewModel>(paywallViewModelProvider, (_, next) {
      if (next.purchasedSuccessfully) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscription_restore_success)),
        );
        ref.read(paywallViewModelNotifierProvider.notifier).clearPurchaseResult();
        context.pop();
      } else if (next.purchaseError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.purchaseError!)),
        );
        ref.read(paywallViewModelNotifierProvider.notifier).clearPurchaseResult();
      }
    });

    final header = _headerFor(entryContext, l10n, home);

    return Scaffold(
      appBar: AppBar(
        title: Text(header.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (tiersEnabled
              ? _TieredPaywallBody(header: header)
              : _BinaryPaywallBody(header: header)),
    );
  }
}

/// Paywall Premium único (comportamiento binario / flag de tiers OFF).
class _BinaryPaywallBody extends ConsumerWidget {
  const _BinaryPaywallBody({required this.header});

  final _PaywallHeader header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(paywallViewModelProvider);
    final annualOffer =
        ref.watch(annualIntroOfferProvider).valueOrNull ?? IntroOffer.none;
    final hasTrial = annualOffer.hasFreeTrial;

    // Modo binario: el SKU legacy (toka_premium_*) es el que se COMPRA. Mostramos
    // su precio de store con fallback ARB de Grupo (legacy = Grupo en el backend),
    // así lo mostrado coincide con lo cobrado.
    final pricing = ref.watch(binaryPricingProvider).valueOrNull ?? const {};
    final monthlyPrice = pricing[kMonthlyProductId]?.price ??
        tierFallbackPrice(l10n, HomeTier.grupo, BillingCycle.monthly);
    final annualPrice = pricing[kAnnualProductId]?.price ??
        tierFallbackPrice(l10n, HomeTier.grupo, BillingCycle.annual);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              header.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          PlanComparisonCard(premiumMemberLimit: HomeTier.grupo.maxMembers),
          const SizedBox(height: 24),
          _PriceChip(
            key: const Key('chip_annual'),
            label: l10n.subscription_annual,
            price: annualPrice,
            badge: hasTrial
                ? l10n.paywall_trial_badge(annualOffer.freeTrialDays)
                : l10n.subscription_annual_saving,
          ),
          const SizedBox(height: 8),
          _PriceChip(
            key: const Key('chip_monthly'),
            label: l10n.subscription_monthly,
            price: monthlyPrice,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton(
              key: const Key('btn_cta_annual'),
              onPressed: vm.isLoading
                  ? null
                  : () => vm.startPurchase(kAnnualProductId),
              child: Text(hasTrial
                  ? l10n.paywall_cta_start_trial(annualOffer.freeTrialDays)
                  : header.ctaPrimary),
            ),
          ),
          if (hasTrial) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.paywall_trial_note,
                key: const Key('paywall_trial_note'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton(
              key: const Key('btn_cta_monthly'),
              onPressed: vm.isLoading
                  ? null
                  : () => vm.startPurchase(kMonthlyProductId),
              child: Text(l10n.paywall_cta_monthly),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              key: const Key('btn_restore'),
              onPressed: () => vm.restorePremium(),
              child: Text(l10n.paywall_restore),
            ),
          ),
          Center(
            child: TextButton(
              key: const Key('btn_terms'),
              onPressed: () {/* open URL in future */},
              child: Text(
                l10n.paywall_terms,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paywall con selector de 3 tiers por tamaño de hogar + toggle mensual/anual.
class _TieredPaywallBody extends ConsumerWidget {
  const _TieredPaywallBody({required this.header});

  final _PaywallHeader header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(paywallViewModelProvider);
    final selection = ref.watch(tieredPaywallControllerProvider);
    final controller = ref.read(tieredPaywallControllerProvider.notifier);
    final pricing = ref.watch(tierPricingProvider).valueOrNull ?? const {};

    final selectedProductId = productIdFor(selection.tier, selection.cycle);
    final selectedInfo = pricing[selectedProductId];
    final hasTrial = selection.cycle == BillingCycle.annual &&
        (selectedInfo?.introOffer.hasFreeTrial ?? false);
    final trialDays = selectedInfo?.introOffer.freeTrialDays ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Copy clave: mismas funciones en los 3 planes; cambia el tope.
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              l10n.paywall_tiers_same_features,
              key: const Key('paywall_tiers_copy'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          // Toggle mensual / anual.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: SegmentedButton<BillingCycle>(
                key: const Key('paywall_cycle_toggle'),
                segments: [
                  ButtonSegment(
                    value: BillingCycle.monthly,
                    label: Text(l10n.paywall_cycle_monthly),
                  ),
                  ButtonSegment(
                    value: BillingCycle.annual,
                    label: Text(l10n.paywall_cycle_annual),
                  ),
                ],
                selected: {selection.cycle},
                onSelectionChanged: (s) => controller.selectCycle(s.first),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tarjetas de tier.
          for (final tier in HomeTier.values)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: _TierCard(
                tier: tier,
                cycle: selection.cycle,
                selected: selection.tier == tier,
                price: pricing[productIdFor(tier, selection.cycle)]?.price ??
                    tierFallbackPrice(l10n, tier, selection.cycle),
                onTap: () => controller.selectTier(tier),
              ),
            ),
          const SizedBox(height: 12),
          // CTA principal.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton(
              key: const Key('btn_tier_cta'),
              onPressed: vm.isLoading
                  ? null
                  : () => vm.startPurchase(selectedProductId),
              child: Text(hasTrial
                  ? l10n.paywall_cta_start_trial(trialDays)
                  : l10n.paywall_tier_continue_cta),
            ),
          ),
          if (hasTrial) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.paywall_trial_note,
                key: const Key('paywall_trial_note'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          // Packs de miembro (eje aditivo sobre Grupo). Se autogestiona el
          // gating: nada con el flag OFF, CTA a Grupo si el hogar no es Grupo.
          const _PacksSection(),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              key: const Key('btn_restore'),
              onPressed: () => vm.restorePremium(),
              child: Text(l10n.paywall_restore),
            ),
          ),
          Center(
            child: TextButton(
              key: const Key('btn_terms'),
              onPressed: () {/* open URL in future */},
              child: Text(
                l10n.paywall_terms,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta seleccionable de un tier en el paywall.
class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.cycle,
    required this.selected,
    required this.price,
    required this.onTap,
  });

  final HomeTier tier;
  final BillingCycle cycle;
  final bool selected;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final suffix = cycle == BillingCycle.monthly
        ? l10n.paywall_price_monthly_suffix
        : l10n.paywall_price_annual_suffix;

    return InkWell(
      key: Key('paywall_tier_card_${tier.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tierDisplayName(l10n, tier),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.paywall_tier_members(tier.maxMembers),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(suffix,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección de **packs de miembro** del paywall (eje aditivo sobre Grupo).
///
/// Autogestiona el gating leyendo `memberPacksEnabledProvider` y el tier
/// efectivo del hogar (`dashboardProvider.premiumFlags`):
///  - Flag OFF → no renderiza nada.
///  - Hogar no Grupo → tarjeta bloqueada con CTA para subir a Grupo.
///  - Hogar Grupo → tarjetas de Pack +5 / +10 (precio + tope resultante) y, si
///    ya están ambos activos (tope 25), un tile informativo de Toka Business.
class _PacksSection extends ConsumerWidget {
  const _PacksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(memberPacksEnabledProvider)) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final flags = ref.watch(dashboardProvider).valueOrNull?.premiumFlags;
    final controller = ref.read(tieredPaywallControllerProvider.notifier);

    if (flags?.tier != 'grupo') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: _LockedPacksCard(
          onUpgrade: () => controller.selectTier(HomeTier.grupo),
        ),
      );
    }

    final cycle = ref.watch(tieredPaywallControllerProvider).cycle;
    final packs = flags?.memberPacks ?? MemberPacks.empty;
    final currentMax = flags?.maxMembers ?? HomeTier.grupo.maxMembers;
    final pricing =
        ref.watch(memberPacksPricingProvider).valueOrNull ?? const {};
    final vm = ref.watch(paywallViewModelProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        key: const Key('paywall_packs_section'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            l10n.paywall_packs_title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(l10n.paywall_packs_subtitle,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final pack in MemberPack.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PackCard(
                pack: pack,
                active: switch (pack) {
                  MemberPack.plus5 => packs.plus5,
                  MemberPack.plus10 => packs.plus10,
                },
                resultingCap: resultingCap(currentMax: currentMax, pack: pack),
                cycle: cycle,
                price: packDisplayPrice(l10n, pack, cycle, pricing),
                onBuy: vm.isLoading
                    ? null
                    : () => vm.startPurchase(packProductIdFor(pack, cycle)),
              ),
            ),
          if (packs.isMaxed)
            _BusinessTile(onTap: () => showTokaBusinessDialog(context)),
        ],
      ),
    );
  }
}

/// Tarjeta de un pack en el paywall: nombre, plazas, tope resultante y precio
/// con su botón de compra; si el pack ya está activo, muestra un badge "Activo".
class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.active,
    required this.resultingCap,
    required this.cycle,
    required this.price,
    required this.onBuy,
  });

  final MemberPack pack;
  final bool active;
  final int resultingCap;
  final BillingCycle cycle;
  final String price;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final suffix = cycle == BillingCycle.monthly
        ? l10n.paywall_price_monthly_suffix
        : l10n.paywall_price_annual_suffix;

    return Container(
      key: Key('paywall_pack_card_${pack.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packDisplayName(l10n, pack),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.pack_seats(pack.seats),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                if (!active)
                  Text(
                    l10n.pack_result_cap(resultingCap),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (active)
            Container(
              key: Key('paywall_pack_active_${pack.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.pack_active_badge,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(suffix, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                FilledButton(
                  key: Key('paywall_pack_buy_${pack.id}'),
                  onPressed: onBuy,
                  child: Text(l10n.pack_buy_cta),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Tarjeta bloqueada cuando el hogar no es Grupo: explica que los packs
/// requieren Grupo y ofrece un CTA para subir a Grupo (preselecciona ese tier).
class _LockedPacksCard extends StatelessWidget {
  const _LockedPacksCard({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('paywall_packs_locked'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.pack_requires_grupo_title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(l10n.pack_requires_grupo_body,
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const Key('paywall_packs_upgrade_cta'),
              onPressed: onUpgrade,
              child: Text(l10n.pack_requires_grupo_cta),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile informativo de Toka Business (cuando ya se tienen ambos packs y el tope
/// está en 25). Abre el diálogo informativo; no inicia ningún flujo de compra.
class _BusinessTile extends StatelessWidget {
  const _BusinessTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const Key('paywall_packs_business_tile'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.business_outlined, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.toka_business_title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.toka_business_body(kAbsoluteMaxMembers),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallHeader {
  const _PaywallHeader({
    required this.title,
    required this.subtitle,
    required this.ctaPrimary,
  });
  final String title;
  final String subtitle;
  final String ctaPrimary;
}

_PaywallHeader _headerFor(
  PaywallEntryContext ctx,
  AppLocalizations l10n,
  Home? home,
) {
  switch (ctx) {
    case PaywallEntryContext.fromFree:
      return _PaywallHeader(
        title: l10n.paywall_title,
        subtitle: l10n.paywall_subtitle,
        ctaPrimary: l10n.paywall_cta_annual,
      );
    case PaywallEntryContext.fromExpired:
      final expiredDate = _formatDate(home?.premiumEndsAt) ?? '';
      return _PaywallHeader(
        title: l10n.paywall_title_from_expired,
        subtitle: l10n.paywall_subtitle_from_expired(expiredDate),
        ctaPrimary: l10n.paywall_cta_reactivate,
      );
    case PaywallEntryContext.fromRescue:
      final endsAt = home?.premiumEndsAt;
      final days = endsAt != null ? daysLeftFrom(endsAt) : 0;
      return _PaywallHeader(
        title: l10n.paywall_title_from_rescue,
        subtitle: l10n.paywall_subtitle_from_rescue(days),
        ctaPrimary: l10n.paywall_cta_reactivate,
      );
    case PaywallEntryContext.fromRestorable:
      final until = home?.restoreUntil;
      final days = until != null ? daysLeftFrom(until) : 0;
      return _PaywallHeader(
        title: l10n.paywall_title_from_restorable,
        subtitle: l10n.paywall_subtitle_from_restorable(days),
        ctaPrimary: l10n.paywall_cta_reactivate,
      );
  }
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    super.key,
    required this.label,
    required this.price,
    this.badge,
  });

  final String label;
  final String price;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
