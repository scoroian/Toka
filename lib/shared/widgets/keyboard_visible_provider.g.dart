// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyboard_visible_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$keyboardVisibleHash() => r'5214294ee2e0a364656226c74bb2ae665ea5710d';

/// Propaga si el teclado del sistema está visible. Alimentado desde
/// [lib/app.dart] por un `KeyboardVisibilityBuilder` global que envuelve
/// el `MaterialApp.router`. El banner publicitario y la utilidad
/// `adAwareBottomPadding` reaccionan a este provider.
///
/// Política AdMob: ocultar el banner mientras el usuario está escribiendo
/// para evitar clicks accidentales (ver spec 2026-04-21).
///
/// Copied from [KeyboardVisible].
@ProviderFor(KeyboardVisible)
final keyboardVisibleProvider =
    NotifierProvider<KeyboardVisible, bool>.internal(
  KeyboardVisible.new,
  name: r'keyboardVisibleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$keyboardVisibleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$KeyboardVisible = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
