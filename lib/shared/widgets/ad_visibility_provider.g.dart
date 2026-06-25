// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_visibility_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adVisibilityHash() => r'77748b656eac0d10fc705f9f81536c3a9827a509';

/// Visibilidad de anuncios para el usuario y hogar actuales.
///
/// Inputs **leídos de Firestore** (nunca hardcode):
/// - Premium del hogar ← `dashboardProvider.premiumFlags.isPremium`
///   (calculado por el backend; cubre cualquier tier).
/// - Pagador ← `currentHomeProvider.currentPayerUid == uid` (`authProvider`).
/// - Toka Plus ← `plusActiveProvider`.
///
/// **Fail-safe**: si el dashboard o el hogar todavía no se conocen (cargando o
/// error → `valueOrNull == null`) devuelve [AdVisibility.hidden] (ocultar ambos),
/// para no parpadear un anuncio a un usuario de pago. Reactivo: se recalcula en
/// caliente cuando cambia el premium del hogar, el pagador o el estado de Plus.
///
/// Copied from [adVisibility].
@ProviderFor(adVisibility)
final adVisibilityProvider = Provider<AdVisibility>.internal(
  adVisibility,
  name: r'adVisibilityProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adVisibilityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdVisibilityRef = ProviderRef<AdVisibility>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
