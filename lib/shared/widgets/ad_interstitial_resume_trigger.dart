import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_flags_provider.dart';
import 'ad_interstitial_controller.dart';
import 'ad_interstitial_decision.dart';

/// Observa el ciclo de vida de la app y, cuando vuelve a primer plano tras haber
/// estado en segundo plano al menos `ad_interstitial_resume_min_background_seconds`,
/// le pide al [AdInterstitialController] que evalúe mostrar un intersticial.
///
/// Hallazgo #10: el intersticial **ya no** se dispara con el cambio de pestaña
/// (navegación core). El nuevo momento es un cierre natural — el usuario se fue
/// de la app y volvió — que nunca interrumpe una acción en curso. El cold-start
/// (sin background previo) **no** dispara: abrir la app para usarla nunca queda
/// gateado por un anuncio.
///
/// Toda la política de frecuencia (gracia del primer disparo, cap por sesión,
/// intervalo mínimo) y la elegibilidad per-usuario (Premium/Plus vía
/// [adVisibilityProvider]) siguen viviendo en [AdInterstitialController.maybeShow];
/// este widget solo decide el *momento*. Es de tamaño cero, pensado para montarse
/// dentro del shell.
class AdInterstitialResumeTrigger extends ConsumerStatefulWidget {
  const AdInterstitialResumeTrigger({super.key, this.child});

  final Widget? child;

  @override
  ConsumerState<AdInterstitialResumeTrigger> createState() =>
      _AdInterstitialResumeTriggerState();
}

class _AdInterstitialResumeTriggerState
    extends ConsumerState<AdInterstitialResumeTrigger>
    with WidgetsBindingObserver {
  /// Marca de cuándo la app pasó a segundo plano. `null` mientras está en primer
  /// plano (o tras un cold-start sin background previo).
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // `paused` es el estado canónico de "app en segundo plano" en móvil
        // (home, bloqueo, cambio de app). Anotamos el instante para medir
        // cuánto estuvo fuera. NO estampamos en `hidden`/`inactive`: son
        // transiciones efímeras que ocurren tanto al irse COMO al volver, y
        // re-estamparían el timestamp borrando el background real. `detached`
        // se ignora (cold-start/teardown), de modo que abrir la app nunca
        // queda gateado por un anuncio.
        _backgroundedAt = ref.read(nowProvider)();
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null; // el periodo de background se consume al volver.
        final cfg = ref.read(interstitialRemoteConfigProvider);
        final shouldEvaluate = shouldShowInterstitialOnResume(
          backgroundedAt: backgroundedAt,
          now: ref.read(nowProvider)(),
          minBackgroundSeconds: cfg.resumeMinBackgroundSeconds,
        );
        if (shouldEvaluate) {
          // No await: el controlador decide y muestra de forma asíncrona sin
          // bloquear el regreso a la app.
          ref.read(adInterstitialControllerProvider.notifier).maybeShow();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.child ?? const SizedBox.shrink();
}
