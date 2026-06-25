// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_packs_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$memberPacksEnabledHash() =>
    r'cf6f8c844dcc85cf3dcc6248732c5380ce773985';

/// Si el eje de **packs de miembro** está activo en la UI.
///
/// Lee `member_packs_enabled` de Remote Config (vía [RemoteConfigService]).
/// Default OFF: con el flag apagado la UI no ofrece packs (sección oculta en el
/// paywall, sin gestión de packs) y el tope máximo mostrado es el del tier.
/// Espeja `member_packs_enabled` del backend
/// (`functions/src/shared/feature_flags.ts`).
///
/// Fail-safe a OFF si Remote Config no está disponible (p. ej. tests sin
/// Firebase). Se recomputa en tiempo real al publicar un cambio en la consola.
/// Override en tests con `overrideWithValue`.
///
/// Copied from [memberPacksEnabled].
@ProviderFor(memberPacksEnabled)
final memberPacksEnabledProvider = Provider<bool>.internal(
  memberPacksEnabled,
  name: r'memberPacksEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$memberPacksEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MemberPacksEnabledRef = ProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
