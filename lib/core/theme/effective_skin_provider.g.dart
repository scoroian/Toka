// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effective_skin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$effectiveSkinHash() => r'983e8ac9719b653c991e31b1148676098e5a8654';

/// Skin EFECTIVA a aplicar, combinando la preferencia del usuario
/// ([skinModeProvider]) con su entitlement Plus ([plusActiveProvider]).
///
/// Si la skin elegida es cosmética-Plus y el usuario NO tiene Plus efectivo
/// (sin Plus, expirado, o flag OFF), cae a [AppSkin.v2]. La PREFERENCIA se
/// conserva en SharedPreferences: al reactivar Plus la skin elegida vuelve a
/// aplicarse sola, sin que el usuario tenga que reseleccionarla.
///
/// `app.dart` (tema) y `SkinSwitch` (widgets) consumen ESTE provider, de modo
/// que activar/desactivar Plus re-tematiza la app EN VIVO.
///
/// Copied from [effectiveSkin].
@ProviderFor(effectiveSkin)
final effectiveSkinProvider = AutoDisposeProvider<AppSkin>.internal(
  effectiveSkin,
  name: r'effectiveSkinProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$effectiveSkinHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EffectiveSkinRef = AutoDisposeProviderRef<AppSkin>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
