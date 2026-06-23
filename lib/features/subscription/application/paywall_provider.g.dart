// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paywall_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paywallHash() => r'9a492ed3a6bdcf84ca0e5c55a0753c403cb8836e';

/// See also [Paywall].
@ProviderFor(Paywall)
final paywallProvider =
    AutoDisposeNotifierProvider<Paywall, AsyncValue<PurchaseResult?>>.internal(
  Paywall.new,
  name: r'paywallProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$paywallHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Paywall = AutoDisposeNotifier<AsyncValue<PurchaseResult?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
