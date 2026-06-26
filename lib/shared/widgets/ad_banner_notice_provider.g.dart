// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_banner_notice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adBannerNoticeEligibleHash() =>
    r'6916b9bac01b6eef035f5c802b5149db129427da';

/// Elegibilidad cableada reusando [adVisibilityProvider] como fuente de verdad.
///
/// Equivalencia (probada): `banner ∧ isPremium ⇔ premium ∧ ¬pagador ∧ ¬Plus`.
/// Como `banner = ¬Plus ∧ ¬(premium ∧ pagador)`, al conjugarlo con `premium`
/// queda `premium ∧ ¬Plus ∧ ¬pagador` — exactamente [computeBannerNoticeEligible].
///
/// Reusar [adVisibilityProvider] (en vez de releer auth/currentHome/plus) evita
/// duplicar el cómputo y NO acopla el camino de padding del shell al timer de
/// `authProvider`: donde adVisibility ya está resuelto/mockeado, esto lo sigue.
/// Fail-safe `false` mientras el dashboard no se conoce (cargando o error).
///
/// Copied from [adBannerNoticeEligible].
@ProviderFor(adBannerNoticeEligible)
final adBannerNoticeEligibleProvider = Provider<bool>.internal(
  adBannerNoticeEligible,
  name: r'adBannerNoticeEligibleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adBannerNoticeEligibleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdBannerNoticeEligibleRef = ProviderRef<bool>;
String _$adBannerNoticeVisibleHash() =>
    r'1dfa9979d829f79ed8e0f4b6625e02dac1bf3979';

/// Visible ⇔ elegible ∧ no descartada en esta sesión.
///
/// Route/teclado-agnóstico a propósito: cada consumidor (shell, helpers de
/// padding) lo combina con su propio `bannerVisible` para no reservar altura
/// cuando el banner no se muestra (ruta suprimida, teclado abierto, etc.).
///
/// Copied from [adBannerNoticeVisible].
@ProviderFor(adBannerNoticeVisible)
final adBannerNoticeVisibleProvider = Provider<bool>.internal(
  adBannerNoticeVisible,
  name: r'adBannerNoticeVisibleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adBannerNoticeVisibleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdBannerNoticeVisibleRef = ProviderRef<bool>;
String _$adBannerNoticeDismissedHash() =>
    r'ad5d89425e09e386173678c66944573d0d0d025b';

/// Descarte de la caption para ESTA sesión (in-memory, ámbito global: reaparece
/// tras reiniciar la app, comportamiento suave y sin estado persistido).
///
/// Global (no por hogar) a propósito: ligar el descarte a un hogar concreto
/// exigiría leer `currentHomeProvider` en el camino de padding del shell, que
/// arrastra el timer de `authProvider`. Global es además "menos nag".
///
/// Copied from [AdBannerNoticeDismissed].
@ProviderFor(AdBannerNoticeDismissed)
final adBannerNoticeDismissedProvider =
    NotifierProvider<AdBannerNoticeDismissed, bool>.internal(
  AdBannerNoticeDismissed.new,
  name: r'adBannerNoticeDismissedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adBannerNoticeDismissedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdBannerNoticeDismissed = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
