import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'skins/main_shell_v2.dart';

/// Wrapper de [Scaffold] para pantallas push.
///
/// Históricamente instanciaba un [AdBanner] propio, pero eso provocaba que,
/// al entrar en create/edit task, task detail o member detail, Google cargara
/// una impresión nueva — una penalización potencial por parte de AdMob.
///
/// La única instancia del banner vive en `MainShellV2`. Estas pantallas, al
/// estar dentro del ShellRoute (sub-rutas de `/tasks` y `/members`, sin
/// `parentNavigatorKey`), heredan ese banner flotante. `AdAwareScaffold` queda
/// como pasarela a [Scaffold] para no romper call sites.
///
/// El Scaffold anidado de esta pasarela NO propaga al `body` el espacio que el
/// shell reservó en su `MediaQuery.padding.bottom`, así que un scrollable que
/// solo aplicara `MediaQuery.padding.bottom` quedaría tapado por el banner y la
/// NavBar flotante (Hallazgo #4: el banner solapaba la última opción del form
/// de crear tarea). Por eso `bottomPaddingOf` delega en
/// `MainShellV2.bottomContentPadding`, que reserva `safeBottom + navBar +
/// banner` igual que las pantallas tab.
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

  /// Padding inferior que los scrollables del `body` deben aplicar para que su
  /// último ítem quede por encima del banner y la NavBar flotante del shell.
  ///
  /// Debe llamarse desde un `build`/`Consumer.builder`: hace `ref.watch`.
  static double bottomPaddingOf(BuildContext ctx, WidgetRef ref) {
    return MainShellV2.bottomContentPadding(ctx, ref);
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
