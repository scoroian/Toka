import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_skin.dart';
import 'skin_provider.dart';

/// Elige qué widget renderizar según la skin activa y aplica una transición
/// suave al cambiar.
///
/// Uso típico:
/// ```dart
/// SkinSwitch(
///   v2:        (c) => const TodayScreenV2(),
///   futurista: (c) => const TodayScreenFuturista(),
/// );
/// ```
///
/// Ambos builders reciben el mismo [BuildContext] y deben consumir los mismos
/// providers/ViewModels. El widget es únicamente presentación.
class SkinSwitch extends ConsumerWidget {
  const SkinSwitch({
    super.key,
    required this.v2,
    required this.futurista,
  });

  final WidgetBuilder v2;
  final WidgetBuilder futurista;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinModeProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: KeyedSubtree(
        key: ValueKey<AppSkin>(skin),
        child: switch (skin) {
          AppSkin.v2 => v2(context),
          AppSkin.futurista => futurista(context),
        },
      ),
    );
  }
}
