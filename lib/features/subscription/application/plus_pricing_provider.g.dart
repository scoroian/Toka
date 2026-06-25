// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plus_pricing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$plusPricingHash() => r'd210399ff713612691a82d30fcb65c0e73a6ad9e';

/// Precios localizados (y trial) de los 2 SKUs de Toka Plus, consultados a la
/// store. Reutiliza [inAppPurchaseProvider] y el DTO [TierProductInfo].
///
/// Devuelve `productId → TierProductInfo` SOLO con los SKUs que la store
/// resolvió. El paywall hace fallback a los precios de referencia (ARB) para
/// los ausentes. Nunca lanza: ante store no disponible o error, mapa vacío.
///
/// Copied from [plusPricing].
@ProviderFor(plusPricing)
final plusPricingProvider =
    AutoDisposeFutureProvider<Map<String, TierProductInfo>>.internal(
  plusPricing,
  name: r'plusPricingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$plusPricingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlusPricingRef
    = AutoDisposeFutureProviderRef<Map<String, TierProductInfo>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
