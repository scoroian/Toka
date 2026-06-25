import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_interstitial_controller.dart';

// Test unit IDs oficiales de Google para intersticial. Nunca generan revenue y
// son seguros en dev. En producción se sobreescriben por el unit de Remote
// Config (`ad_interstitial_unit_*`). Única fuente de los test IDs del intersticial.
const String _kTestInterstitialAndroid =
    'ca-app-pub-3940256099942544/1033173712';
const String _kTestInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

/// Implementación AdMob del [InterstitialAdGateway]. Aislada del controlador para
/// que la lógica de frecuencia se pueda testear sin tocar código nativo.
class AdMobInterstitialGateway implements InterstitialAdGateway {
  @override
  Future<InterstitialPresentation?> load(String unitId) {
    final completer = Completer<InterstitialPresentation?>();
    InterstitialAd.load(
      adUnitId: _effectiveUnitId(unitId),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(_AdMobInterstitialPresentation(ad));
          }
        },
        onAdFailedToLoad: (err) {
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future;
  }

  /// En dev (debug) o sin unit configurado → test ID oficial; en prod con unit
  /// configurado → el real. Mismo guardrail que el banner.
  String _effectiveUnitId(String fromServer) {
    if (kDebugMode || fromServer.isEmpty) {
      return Platform.isIOS ? _kTestInterstitialIos : _kTestInterstitialAndroid;
    }
    return fromServer;
  }
}

class _AdMobInterstitialPresentation implements InterstitialPresentation {
  _AdMobInterstitialPresentation(this._ad);
  final InterstitialAd _ad;

  @override
  Future<void> show() async {
    // Liberar el anuncio al cerrarse para no fugar memoria.
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
    );
    await _ad.show();
  }
}
