// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro_offer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$annualIntroOfferHash() => r'dce9f4ab72f3445abade4141f5cfbe12c77abbdb';

/// Oferta introductoria (prueba gratuita) del plan ANUAL, leída de la store
/// (Hallazgo #14). El paywall la usa para mostrar el copy del trial solo cuando
/// la store realmente lo concede. Si la store no está disponible o no devuelve
/// el producto/oferta, resuelve a [IntroOffer.none] (sin trial), nunca lanza.
///
/// Copied from [annualIntroOffer].
@ProviderFor(annualIntroOffer)
final annualIntroOfferProvider = AutoDisposeFutureProvider<IntroOffer>.internal(
  annualIntroOffer,
  name: r'annualIntroOfferProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$annualIntroOfferHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnnualIntroOfferRef = AutoDisposeFutureProviderRef<IntroOffer>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
