import 'package:flutter/widgets.dart';

/// `InheritedWidget` que marca la presencia de un shell de skin
/// (`MainShellV2` o `MainShellFuturista`) como ancestro.
///
/// Permite a widgets descendientes (especialmente `adAwareBottomPadding`)
/// saber si están renderizándose bajo un shell con NavBar y AdBanner
/// flotantes, o si están en una ruta push sin shell (paywall, profile,
/// vacation, etc.).
///
/// Uso típico:
/// ```dart
/// final inShell = ShellPresenceMarker.of(context);
/// if (!inShell) return safeArea + extra;  // sin nav ni banner
/// // ...resto del cálculo con banner+navBar
/// ```
///
/// `updateShouldNotify` siempre devuelve `false`: la presencia/ausencia
/// del marker es estable durante el lifetime del shell — nunca cambia,
/// nunca dispara rebuild.
class ShellPresenceMarker extends InheritedWidget {
  const ShellPresenceMarker({super.key, required super.child});

  /// Devuelve `true` si algún ancestro es un `ShellPresenceMarker`,
  /// `false` en caso contrario.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellPresenceMarker>() != null;

  @override
  bool updateShouldNotify(ShellPresenceMarker oldWidget) => false;
}
