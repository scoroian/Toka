// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_banner_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$remoteBannerAdUnitsHash() =>
    r'9e6601afb61464492887e13881bd97919cb2c020';

/// Lee los banner unit IDs de Remote Config (claves `ad_banner_unit_android` /
/// `ad_banner_unit_ios`, vía [RemoteConfigService]). Si Remote Config no está
/// disponible (p. ej. en tests sin Firebase) devuelve cadenas vacías, de modo
/// que el consumidor cae al unit del dashboard y, en último término, a los test
/// IDs (ver `ad_banner.dart`). Override en tests con `overrideWithValue`.
///
/// Copied from [remoteBannerAdUnits].
@ProviderFor(remoteBannerAdUnits)
final remoteBannerAdUnitsProvider = Provider<BannerAdUnits>.internal(
  remoteBannerAdUnits,
  name: r'remoteBannerAdUnitsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$remoteBannerAdUnitsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RemoteBannerAdUnitsRef = ProviderRef<BannerAdUnits>;
String _$adBannerConfigHash() => r'8c4c47a404a053536593c0d504fd27f8c6b12f28';

/// See also [adBannerConfig].
@ProviderFor(adBannerConfig)
final adBannerConfigProvider = Provider<AdBannerConfig>.internal(
  adBannerConfig,
  name: r'adBannerConfigProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adBannerConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdBannerConfigRef = ProviderRef<AdBannerConfig>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
