// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tier_pricing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inAppPurchaseHash() => r'ccfc4be2a14f0d7ca9b3ec8d26b0a2b2aa28f189';

/// Instancia de [InAppPurchase] inyectable (seam de DI). Por defecto el
/// singleton; override en tests con `overrideWithValue`.
///
/// Copied from [inAppPurchase].
@ProviderFor(inAppPurchase)
final inAppPurchaseProvider = Provider<InAppPurchase>.internal(
  inAppPurchase,
  name: r'inAppPurchaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inAppPurchaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InAppPurchaseRef = ProviderRef<InAppPurchase>;
String _$tierPricingHash() => r'03c33ee95368520fc9c7a70a75aefe62da0f5e7f';

/// Precios localizados (y trials) de los 6 SKUs de tier, consultados a la store.
///
/// Devuelve un mapa `productId → [TierProductInfo]` que SOLO contiene los SKUs
/// que la store resolvió. El consumidor (paywall) hace fallback a los precios de
/// referencia (ARB) para los SKUs ausentes. Nunca lanza: ante store no
/// disponible o error, devuelve un mapa vacío (todo fallback).
///
/// Copied from [tierPricing].
@ProviderFor(tierPricing)
final tierPricingProvider =
    AutoDisposeFutureProvider<Map<String, TierProductInfo>>.internal(
  tierPricing,
  name: r'tierPricingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tierPricingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TierPricingRef
    = AutoDisposeFutureProviderRef<Map<String, TierProductInfo>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
