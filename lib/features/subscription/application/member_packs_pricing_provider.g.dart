// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_packs_pricing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memberPacksPricingHash() =>
    r'98ed43dbcd806108ef347876242e457584c12d15';

/// Precios localizados de los 4 SKUs de pack de miembro, consultados a la store.
/// Reutiliza [inAppPurchaseProvider]. Los packs no tienen oferta introductoria
/// (trial), así que basta el precio (`productId → precio localizado`).
///
/// Devuelve SOLO los SKUs que la store resolvió; el paywall hace fallback a los
/// precios de referencia (ARB) para los ausentes. Nunca lanza: ante store no
/// disponible o error, mapa vacío (todo fallback).
///
/// Copied from [memberPacksPricing].
@ProviderFor(memberPacksPricing)
final memberPacksPricingProvider =
    AutoDisposeFutureProvider<Map<String, String>>.internal(
  memberPacksPricing,
  name: r'memberPacksPricingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$memberPacksPricingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MemberPacksPricingRef
    = AutoDisposeFutureProviderRef<Map<String, String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
