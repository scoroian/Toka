import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_skin.dart';
import 'effective_skin_provider.dart';

/// Elige qué widget renderizar según la skin activa y aplica una transición
/// suave al cambiar.
///
/// Uso típico:
/// ```dart
/// SkinSwitch(
///   v2: (c) => const TodayScreenV2(),
/// );
/// ```
///
/// Por ahora solo existe la skin `v2`, pero el `switch (skin)` se mantiene como
/// punto de extensión: al añadir un valor a [AppSkin] habrá que sumar aquí su
/// builder (p. ej. un nuevo named param) y la rama correspondiente.
///
/// El builder recibe el [BuildContext] y debe consumir los mismos
/// providers/ViewModels que las demás skins. El widget es únicamente
/// presentación.
class SkinSwitch extends ConsumerWidget {
  const SkinSwitch({
    super.key,
    required this.v2,
  });

  final WidgetBuilder v2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(effectiveSkinProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: KeyedSubtree(
        key: ValueKey<AppSkin>(skin),
        child: switch (skin) {
          // Las skins cosméticas (p. ej. Océano) reutilizan las pantallas v2:
          // solo cambian el ThemeData (ver app.dart), no el árbol de widgets.
          AppSkin.v2 => v2(context),
          AppSkin.oceano => v2(context),
        },
      ),
    );
  }
}
