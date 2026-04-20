import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper de [Scaffold] para pantallas push.
///
/// Históricamente instanciaba un [AdBanner] propio, pero eso provocaba que,
/// al entrar en create/edit task, task detail o member detail, Google cargara
/// una impresión nueva — una penalización potencial por parte de AdMob.
///
/// La única instancia del banner vive en `MainShellV2`. Estas pantallas, al
/// estar dentro del ShellRoute, heredan ese banner. `AdAwareScaffold` queda
/// como pasarela a [Scaffold] para no romper call sites; el método estático
/// `bottomPaddingOf` se mantiene por compatibilidad pero devuelve solo
/// `safeBottom` porque el shell ya reserva el espacio del banner via su
/// propio Scaffold.
class AdAwareScaffold extends ConsumerWidget {
  const AdAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  /// Padding inferior que los scrollables del `body` deben aplicar para que
  /// el último ítem no quede tapado por el safe area del sistema.
  /// El espacio del banner ya lo reserva el shell padre.
  static double bottomPaddingOf(BuildContext ctx, WidgetRef ref) {
    return MediaQuery.of(ctx).padding.bottom;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
