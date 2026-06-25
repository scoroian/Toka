// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tiered_paywall_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tieredPaywallControllerHash() =>
    r'0e60c2ee025d9da03e18adee444110cd85f6c63a';

/// Estado del selector del paywall de tiers.
///
/// Preselección inteligente (solo seed inicial; no se rebuildea al cambiar el
/// dashboard para no pisar la elección del usuario): el tier actual si el hogar
/// ya es premium, o el menor tier cuyo tope cabe los miembros activos. Ciclo por
/// defecto: anual (donde vive el trial/ahorro).
///
/// Copied from [TieredPaywallController].
@ProviderFor(TieredPaywallController)
final tieredPaywallControllerProvider = AutoDisposeNotifierProvider<
    TieredPaywallController, TieredPaywallSelection>.internal(
  TieredPaywallController.new,
  name: r'tieredPaywallControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tieredPaywallControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TieredPaywallController = AutoDisposeNotifier<TieredPaywallSelection>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
