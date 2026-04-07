// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paywall_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paywallHash() => r'c087caac05e63b52a53ff7d0f70d816a6a7af2fb';

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
