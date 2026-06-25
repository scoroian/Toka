import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ad_flags_provider.dart';
import 'ad_interstitial_decision.dart';
import 'ad_interstitial_gateway.dart';
import 'ad_visibility_provider.dart';

part 'ad_interstitial_controller.g.dart';

/// Anuncio intersticial cargado y listo para mostrarse.
abstract class InterstitialPresentation {
  Future<void> show();
}

/// Abstracción inyectable de la carga del intersticial. La implementación real
/// ([AdMobInterstitialGateway]) habla con AdMob; en tests se sustituye por un
/// doble que no toca código nativo.
abstract class InterstitialAdGateway {
  /// Carga un intersticial para [unitId]; resuelve con una presentación
  /// mostrable, o `null` si la carga falla.
  Future<InterstitialPresentation?> load(String unitId);
}

/// Reloj inyectable (testeable). Por defecto el reloj del sistema.
final nowProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Gateway de intersticial. Por defecto la implementación AdMob real; los tests
/// lo sobreescriben con un doble.
final interstitialAdGatewayProvider =
    Provider<InterstitialAdGateway>((_) => AdMobInterstitialGateway());

/// Orquesta la carga/visualización del intersticial respetando el cap de
/// frecuencia (intervalo mínimo + tope por sesión) de Remote Config y la
/// visibilidad per-usuario ([adVisibilityProvider]).
///
/// El estado de frecuencia (`lastShownAt`, `sessionCount`) vive en la instancia
/// del notifier (keepAlive). La decisión de mostrar es la función pura
/// [shouldShowInterstitial]. Disparado por el cambio de pestaña principal
/// ([AdInterstitialTrigger]); nunca desde flujos críticos.
@Riverpod(keepAlive: true)
class AdInterstitialController extends _$AdInterstitialController {
  DateTime? _lastShownAt;
  int _sessionCount = 0;
  InterstitialPresentation? _ready;
  bool _loading = false;
  // Gracia de cortesía: el primer cambio de pestaña de la sesión nunca dispara
  // intersticial (evita interrumpir al usuario nada más entrar). Hallazgo #4-QA.
  bool _firstTabChangeSeen = false;

  @override
  void build() {}

  bool get _enabled =>
      ref.read(adDifferentiatedEnabledProvider) &&
      ref.read(interstitialRemoteConfigProvider).enabled;

  String _unitId() {
    final cfg = ref.read(interstitialRemoteConfigProvider);
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    return cfg.unitFor(isIos: isIos);
  }

  /// Pre-carga un intersticial si el subsistema está habilitado y no hay uno
  /// listo. Best-effort: un fallo deja `_ready == null` y se reintentará.
  Future<void> preload() async {
    if (_ready != null || _loading || !_enabled) return;
    _loading = true;
    try {
      _ready = await ref.read(interstitialAdGatewayProvider).load(_unitId());
    } finally {
      _loading = false;
    }
  }

  /// Punto de entrada del disparador (cambio de pestaña). Muestra un intersticial
  /// solo si la decisión pura lo permite; si no, no hace nada.
  Future<void> maybeShow() async {
    // Corto antes de tocar `adVisibility` (y su cadena dashboard/currentHome):
    // con el subsistema apagado no hay nada que evaluar ni que suscribir.
    if (!_enabled) return;
    // Gracia: el PRIMER cambio de pestaña de la sesión no muestra intersticial.
    // No consume cupo ni marca `_lastShownAt`; aprovechamos para precargar el
    // siguiente, de modo que la primera impresión real sea instantánea.
    if (!_firstTabChangeSeen) {
      _firstTabChangeSeen = true;
      unawaited(preload());
      return;
    }
    final cfg = ref.read(interstitialRemoteConfigProvider);
    final now = ref.read(nowProvider)();
    final ok = shouldShowInterstitial(
      enabled: true,
      visibility: ref.read(adVisibilityProvider),
      now: now,
      lastShownAt: _lastShownAt,
      sessionCount: _sessionCount,
      minIntervalSeconds: cfg.minIntervalSeconds,
      maxPerSession: cfg.maxPerSession,
    );
    if (!ok) return;

    if (_ready == null) await preload();
    final ad = _ready;
    if (ad == null) return; // la carga falló: no consumimos cupo.

    _ready = null;
    _lastShownAt = now;
    _sessionCount++;
    await ad.show();
    // Precarga el siguiente para que el próximo sea instantáneo.
    unawaited(preload());
  }
}
