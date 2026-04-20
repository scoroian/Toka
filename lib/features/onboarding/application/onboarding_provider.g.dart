// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingRepositoryHash() =>
    r'1b495243982cbb532417167923c98b6844e54b71';

/// See also [onboardingRepository].
@ProviderFor(onboardingRepository)
final onboardingRepositoryProvider = Provider<OnboardingRepository>.internal(
  onboardingRepository,
  name: r'onboardingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OnboardingRepositoryRef = ProviderRef<OnboardingRepository>;
String _$onboardingCompletedHash() =>
    r'1cabb9a13cec4b3216ed26cee355300f7e1a60ae';

/// True if the user has already completed the onboarding flow.
/// Checks SharedPreferences first (fast path), then Firestore as fallback so
/// the flag survives app reinstalls and works across devices (Bug #onboarding-reinstall).
///
/// Copied from [onboardingCompleted].
@ProviderFor(onboardingCompleted)
final onboardingCompletedProvider = FutureProvider<bool>.internal(
  onboardingCompleted,
  name: r'onboardingCompletedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingCompletedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OnboardingCompletedRef = FutureProviderRef<bool>;
String _$onboardingNotifierHash() =>
    r'8d1fde9468e7d63b254500790564c1d38e90576e';

/// See also [OnboardingNotifier].
@ProviderFor(OnboardingNotifier)
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>.internal(
  OnboardingNotifier.new,
  name: r'onboardingNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OnboardingNotifier = Notifier<OnboardingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
