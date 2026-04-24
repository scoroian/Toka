import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'keyboard_visible_provider.g.dart';

/// Propaga si el teclado del sistema está visible. Alimentado desde
/// [lib/app.dart] por un `KeyboardVisibilityBuilder` global que envuelve
/// el `MaterialApp.router`. El banner publicitario y la utilidad
/// `adAwareBottomPadding` reaccionan a este provider.
///
/// Política AdMob: ocultar el banner mientras el usuario está escribiendo
/// para evitar clicks accidentales (ver spec 2026-04-21).
@Riverpod(keepAlive: true)
class KeyboardVisible extends _$KeyboardVisible {
  @override
  bool build() => false;

  void setVisible(bool value) {
    if (state != value) state = value;
  }
}
