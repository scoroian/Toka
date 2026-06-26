// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_banner_notice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adBannerNoticeEligibleHash() =>
    r'cb27f97feed0f1505364ba03466d6326f5f73d79';

/// Elegibilidad cableada a Firestore (mismos inputs que `adVisibilityProvider`).
/// Fail-safe `false` mientras dashboard/home no se conocen (cargando o error).
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
    r'128cdca1eeac3b7988709f33fd605b42510e7cba';

/// Visible ⇔ elegible ∧ hay homeId ∧ no descartada para ese hogar.
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
String _$adBannerNoticeDismissalHash() =>
    r'42a59728b66899803ceffd32767eba9da36900c3';

/// Conjunto de homeIds para los que el usuario descartó la caption en ESTA
/// sesión (in-memory: reaparece tras reiniciar la app, comportamiento suave y
/// sin estado persistido).
///
/// Copied from [AdBannerNoticeDismissal].
@ProviderFor(AdBannerNoticeDismissal)
final adBannerNoticeDismissalProvider =
    NotifierProvider<AdBannerNoticeDismissal, Set<String>>.internal(
  AdBannerNoticeDismissal.new,
  name: r'adBannerNoticeDismissalProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adBannerNoticeDismissalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdBannerNoticeDismissal = Notifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
