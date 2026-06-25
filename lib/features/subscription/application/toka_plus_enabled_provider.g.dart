// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toka_plus_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tokaPlusEnabledHash() => r'331b239e50253115f50221da0f0180182641164c';

/// Si el eje de entitlement individual "Toka Plus" está activo en la UI.
///
/// Lee `toka_plus_enabled` de Remote Config (vía [RemoteConfigService]). Default
/// OFF: con el flag apagado NADIE ve features Plus (skins Plus ocultas, entradas
/// ocultas) ni nada se desbloquea, aunque exista el doc de entitlement. Espeja
/// `TOKA_PLUS_FLAG` del backend.
///
/// Fail-safe a OFF si Remote Config no está disponible (p. ej. tests sin
/// Firebase). Se recomputa en tiempo real al publicar un cambio en la consola.
/// Override en tests con `overrideWithValue`.
///
/// Copied from [tokaPlusEnabled].
@ProviderFor(tokaPlusEnabled)
final tokaPlusEnabledProvider = Provider<bool>.internal(
  tokaPlusEnabled,
  name: r'tokaPlusEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tokaPlusEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TokaPlusEnabledRef = ProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
