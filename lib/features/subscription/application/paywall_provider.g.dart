// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paywall_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paywallHash() => r'17b4f3894add523b9236f88dcf9f6882b53fe6a7';

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
