// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_interstitial_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adInterstitialControllerHash() =>
    r'6d099e58432f4792bb82967b5fb0490bc694a1f4';

/// Orquesta la carga/visualización del intersticial respetando el cap de
/// frecuencia (intervalo mínimo + tope por sesión) de Remote Config y la
/// visibilidad per-usuario ([adVisibilityProvider]).
///
/// El estado de frecuencia (`lastShownAt`, `sessionCount`) vive en la instancia
/// del notifier (keepAlive). La decisión de mostrar es la función pura
/// [shouldShowInterstitial]. Disparado por el cambio de pestaña principal
/// ([AdInterstitialTrigger]); nunca desde flujos críticos.
///
/// Copied from [AdInterstitialController].
@ProviderFor(AdInterstitialController)
final adInterstitialControllerProvider =
    NotifierProvider<AdInterstitialController, void>.internal(
  AdInterstitialController.new,
  name: r'adInterstitialControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adInterstitialControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdInterstitialController = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
