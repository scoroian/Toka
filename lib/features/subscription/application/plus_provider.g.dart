// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$plusRepositoryHash() => r'c05d9d0733f01080dac98338322e1964035a2f56';

/// Repositorio de SOLO LECTURA del entitlement Plus. Override en tests con un
/// fake vía `overrideWithValue`.
///
/// Copied from [plusRepository].
@ProviderFor(plusRepository)
final plusRepositoryProvider = Provider<PlusRepository>.internal(
  plusRepository,
  name: r'plusRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$plusRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlusRepositoryRef = ProviderRef<PlusRepository>;
String _$plusEntitlementHash() => r'd775cd3f44d43b7733681ba9ea982beb437cec9e';

/// Stream del entitlement Plus del USUARIO ACTUAL.
///
/// Se reabre automáticamente cuando cambia el uid autenticado (no mezcla el
/// estado de un usuario con el de otro). Emite `null` si no hay sesión o el doc
/// no existe (sin Plus).
///
/// Copied from [plusEntitlement].
@ProviderFor(plusEntitlement)
final plusEntitlementProvider =
    AutoDisposeStreamProvider<PlusEntitlement?>.internal(
  plusEntitlement,
  name: r'plusEntitlementProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$plusEntitlementHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlusEntitlementRef = AutoDisposeStreamProviderRef<PlusEntitlement?>;
String _$plusActiveHash() => r'32a7ba2e447f5f6509f1144337d6eb179653c8a8';

/// Activación EFECTIVA de Toka Plus para el usuario actual. ÚNICO punto de
/// gating de la UI y CONTRATO para la Fase 5 (cálculo de ads).
///
/// `true` solo si: el flag `toka_plus_enabled` está ON, el doc tiene
/// `active == true`, y no está vencido (`endsAt == null || endsAt > now`).
/// Fail-safe a `false` mientras carga, en error, o sin sesión. Espejo de
/// `isPlusEffectivelyActive` del backend.
///
/// Copied from [plusActive].
@ProviderFor(plusActive)
final plusActiveProvider = AutoDisposeProvider<bool>.internal(
  plusActive,
  name: r'plusActiveProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$plusActiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlusActiveRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
