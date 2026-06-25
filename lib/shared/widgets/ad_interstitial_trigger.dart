import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_interstitial_controller.dart';

/// Observa el índice de la pestaña principal y, cuando CAMBIA, le pide al
/// [AdInterstitialController] que evalúe mostrar un intersticial.
///
/// El montaje inicial (llegar a una pestaña) no dispara nada; solo el cambio de
/// una pestaña a otra. El cap de frecuencia (intervalo + tope por sesión) vive en
/// el controlador, así que cambiar de pestaña varias veces seguidas no provoca
/// más de un intersticial dentro de la ventana configurada. Es un widget de
/// tamaño cero pensado para montarse dentro del shell.
class AdInterstitialTrigger extends ConsumerStatefulWidget {
  const AdInterstitialTrigger({
    super.key,
    required this.tabIndex,
    this.child,
  });

  final int tabIndex;
  final Widget? child;

  @override
  ConsumerState<AdInterstitialTrigger> createState() =>
      _AdInterstitialTriggerState();
}

class _AdInterstitialTriggerState extends ConsumerState<AdInterstitialTrigger> {
  @override
  void didUpdateWidget(AdInterstitialTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) {
      // No await: el controlador decide y muestra de forma asíncrona sin
      // bloquear la navegación.
      ref.read(adInterstitialControllerProvider.notifier).maybeShow();
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.child ?? const SizedBox.shrink();
}
