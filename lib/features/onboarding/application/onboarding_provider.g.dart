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
    r'9e036bcaeb3b844e67299e02c20568ccadf38cfb';

/// True if the user has already completed the onboarding flow on this device.
/// Used by the router to distinguish "new user" from "user with no active homes".
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
    r'5eb07ed07903c951de66cdf2c52fb07ea2664e03';

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
