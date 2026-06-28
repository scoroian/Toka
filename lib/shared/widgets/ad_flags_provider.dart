import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/remote_config_service.dart';

part 'ad_flags_provider.g.dart';

/// Flag MAESTRO de la publicidad diferenciada per-usuario (`ad_differentiated_enabled`).
///
/// OFF (default): el banner vuelve al comportamiento de hogar actual y el
/// intersticial queda desactivado. ON: el banner se decide per-usuario
/// ([adVisibilityProvider]) y se habilita el subsistema de intersticial.
///
/// Fail-safe a OFF si Remote Config no está disponible (p. ej. tests sin
/// Firebase). Se recomputa en tiempo real al publicar un cambio en la consola.
/// Override en tests con `overrideWithValue`.
@Riverpod(keepAlive: true)
bool adDifferentiatedEnabled(AdDifferentiatedEnabledRef ref) {
  try {
    final rc = RemoteConfigService(FirebaseRemoteConfig.instance);
    final sub = rc.onConfigUpdated.listen((_) async {
      await rc.activate();
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);
    return rc.adDifferentiatedEnabled;
  } catch (_) {
    return false;
  }
}

/// Parámetros de Remote Config del intersticial, agrupados para que el
/// controlador los lea de una sola vez.
class InterstitialRemoteConfig {
  const InterstitialRemoteConfig({
    required this.enabled,
    required this.minIntervalSeconds,
    required this.maxPerSession,
    required this.resumeMinBackgroundSeconds,
    required this.unitAndroid,
    required this.unitIos,
  });

  /// `ad_interstitial_enabled` crudo (sin combinar todavía con el maestro).
  final bool enabled;
  final int minIntervalSeconds;
  final int maxPerSession;

  /// Tiempo mínimo en segundo plano para que un "app resume" sea momento
  /// elegible de intersticial (Hallazgo #10). Lo consume el trigger, no el
  /// controlador.
  final int resumeMinBackgroundSeconds;
  final String unitAndroid;
  final String unitIos;

  /// Unit ID del intersticial para la plataforma actual.
  String unitFor({required bool isIos}) => isIos ? unitIos : unitAndroid;

  static const InterstitialRemoteConfig disabled = InterstitialRemoteConfig(
    enabled: false,
    minIntervalSeconds: 210,
    maxPerSession: 3,
    resumeMinBackgroundSeconds: 240,
    unitAndroid: '',
    unitIos: '',
  );
}

/// Lee los parámetros del intersticial de Remote Config. Fail-safe a
/// [InterstitialRemoteConfig.disabled] si Firebase no está disponible. Se
/// recomputa en tiempo real. Override en tests con `overrideWithValue`.
@Riverpod(keepAlive: true)
InterstitialRemoteConfig interstitialRemoteConfig(
    InterstitialRemoteConfigRef ref) {
  try {
    final rc = RemoteConfigService(FirebaseRemoteConfig.instance);
    final sub = rc.onConfigUpdated.listen((_) async {
      await rc.activate();
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);
    return InterstitialRemoteConfig(
      enabled: rc.adInterstitialEnabled,
      minIntervalSeconds: rc.adInterstitialMinIntervalSeconds,
      maxPerSession: rc.adInterstitialMaxPerSession,
      resumeMinBackgroundSeconds: rc.adInterstitialResumeMinBackgroundSeconds,
      unitAndroid: rc.adInterstitialUnitAndroid,
      unitIos: rc.adInterstitialUnitIos,
    );
  } catch (_) {
    return InterstitialRemoteConfig.disabled;
  }
}
