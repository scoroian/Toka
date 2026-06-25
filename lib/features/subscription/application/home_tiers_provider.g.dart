// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_tiers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeTiersEnabledHash() => r'3346b3c01e074a6117b00dc58c2549bd76db9162';

/// Si el modelo de tiers por tamaño de hogar está activo en la UI.
///
/// Lee `home_tiers_enabled` de Remote Config (vía [RemoteConfigService]). Con el
/// flag OFF la UI vuelve al comportamiento binario (paywall Premium único). El
/// backend ya gobierna los TOPES por su cuenta con el mismo flag, así que los
/// límites de miembros son correctos en ambos estados; este provider solo decide
/// qué paywall y qué copy de tier se pintan.
///
/// Fail-safe a OFF si Remote Config no está disponible (p. ej. tests sin
/// Firebase). Se recomputa en tiempo real al publicar un cambio en la consola.
/// Override en tests con `overrideWithValue`.
///
/// Copied from [homeTiersEnabled].
@ProviderFor(homeTiersEnabled)
final homeTiersEnabledProvider = Provider<bool>.internal(
  homeTiersEnabled,
  name: r'homeTiersEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeTiersEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeTiersEnabledRef = ProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
