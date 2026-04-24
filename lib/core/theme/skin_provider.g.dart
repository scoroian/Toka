// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$skinModeHash() => r'c113fbd548c4965067aff2d9648f9661b2b764b3';

/// Skin visual activo de la app.
///
/// Persiste la preferencia del usuario en SharedPreferences bajo la clave
/// `tocka.skin` (guarda el nombre del enum). `keepAlive` evita reinicios al
/// navegar.
///
/// Consistente con `ThemeModeNotifier`: la carga async no bloquea el primer
/// frame; `build()` devuelve `AppSkin.v2` mientras se lee el storage y se
/// actualiza con `state = ...` cuando llega el valor persistido.
///
/// Copied from [SkinMode].
@ProviderFor(SkinMode)
final skinModeProvider = NotifierProvider<SkinMode, AppSkin>.internal(
  SkinMode.new,
  name: r'skinModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$skinModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SkinMode = Notifier<AppSkin>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
