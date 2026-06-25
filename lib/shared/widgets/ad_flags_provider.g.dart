// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_flags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adDifferentiatedEnabledHash() =>
    r'b4caf600e76eefe6cde77c2cf05c0123084a84eb';

/// Flag MAESTRO de la publicidad diferenciada per-usuario (`ad_differentiated_enabled`).
///
/// OFF (default): el banner vuelve al comportamiento de hogar actual y el
/// intersticial queda desactivado. ON: el banner se decide per-usuario
/// ([adVisibilityProvider]) y se habilita el subsistema de intersticial.
///
/// Fail-safe a OFF si Remote Config no está disponible (p. ej. tests sin
/// Firebase). Se recomputa en tiempo real al publicar un cambio en la consola.
/// Override en tests con `overrideWithValue`.
///
/// Copied from [adDifferentiatedEnabled].
@ProviderFor(adDifferentiatedEnabled)
final adDifferentiatedEnabledProvider = Provider<bool>.internal(
  adDifferentiatedEnabled,
  name: r'adDifferentiatedEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adDifferentiatedEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdDifferentiatedEnabledRef = ProviderRef<bool>;
String _$interstitialRemoteConfigHash() =>
    r'996751ceb70a861f10cd173425ad1ba21d724970';

/// Lee los parámetros del intersticial de Remote Config. Fail-safe a
/// [InterstitialRemoteConfig.disabled] si Firebase no está disponible. Se
/// recomputa en tiempo real. Override en tests con `overrideWithValue`.
///
/// Copied from [interstitialRemoteConfig].
@ProviderFor(interstitialRemoteConfig)
final interstitialRemoteConfigProvider =
    Provider<InterstitialRemoteConfig>.internal(
  interstitialRemoteConfig,
  name: r'interstitialRemoteConfigProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$interstitialRemoteConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InterstitialRemoteConfigRef = ProviderRef<InterstitialRemoteConfig>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
