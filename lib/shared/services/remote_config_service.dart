// lib/shared/services/remote_config_service.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../core/utils/logger.dart';

class RemoteConfigService {
  RemoteConfigService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  static const _defaults = {
    'ad_banner_enabled': true,
    'ad_banner_unit_android': '',
    'ad_banner_unit_ios': '',
    'paywall_default_plan': 'monthly',
    'paywall_show_annual_savings': true,
    'rescue_notification_days': 3,
    'max_review_note_chars': 300,
    // Activa el modelo de tiers por tamaño de hogar en la UI (paywall de 3
    // tiers, display de tier en gestión). Default OFF → paywall Premium único
    // (comportamiento binario). Debe coincidir con `HOME_TIERS_FLAG` del backend
    // (`functions/src/shared/feature_flags.ts`).
    'home_tiers_enabled': false,
    // Activa el eje de entitlement INDIVIDUAL "Toka Plus". Default OFF → ningún
    // usuario tiene Plus activo aunque exista el doc (el gating se aplica al
    // consumir junto con users/{uid}/entitlements/plus.active). Debe coincidir
    // con `TOKA_PLUS_FLAG` del backend (`functions/src/shared/feature_flags.ts`).
    'toka_plus_enabled': false,
    // Activa el eje ADITIVO de "packs de miembro" (sobre el tier Grupo) en la
    // UI: sección de packs en el paywall, gestión y tope dinámico hasta 25.
    // Default OFF → la UI no ofrece packs y el tope máximo mostrado es el del
    // tier. Debe coincidir con `member_packs_enabled` del backend
    // (`functions/src/shared/feature_flags.ts`).
    'member_packs_enabled': false,
    // ── Publicidad diferenciada (banner per-usuario) + intersticial ──────
    // Flag MAESTRO de la diferenciación de anuncios. OFF (default) → el banner
    // vuelve al comportamiento de hogar actual (`premiumFlags.showAds &&
    // adFlags.showBanner`) y el intersticial queda desactivado. ON → el banner
    // se decide per-usuario (`adVisibilityProvider`) y se habilita el subsistema
    // de intersticial (sujeto además a `ad_interstitial_enabled`).
    'ad_differentiated_enabled': false,
    // On/off del intersticial. Requiere además el maestro ON.
    'ad_interstitial_enabled': false,
    // Cap de frecuencia del intersticial: intervalo mínimo entre impresiones y
    // tope por sesión. ~3,5 min por defecto para no ser intrusivo.
    'ad_interstitial_min_interval_seconds': 210,
    'ad_interstitial_max_per_session': 3,
    // Unit IDs del intersticial por plataforma (prod). En dev quedan vacíos y el
    // controlador cae a los TEST IDs oficiales de AdMob.
    'ad_interstitial_unit_android': '',
    'ad_interstitial_unit_ios': '',
  };

  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Intervalo bajo para que un cambio en la consola se recoja casi al
        // instante en el próximo fetch/arranque. Los cambios EN VIVO (app
        // abierta) llegan por [onConfigUpdated] (Remote Config en tiempo real),
        // que no depende de este intervalo.
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      await _remoteConfig.setDefaults(_defaults);
      await _remoteConfig.fetchAndActivate();
    } catch (e, st) {
      AppLogger.error('RemoteConfig init failed — using defaults', e, st);
    }
  }

  /// Stream de actualizaciones en tiempo real de Remote Config: emite cuando se
  /// publica un cambio en la consola y la app está en primer plano. Tras un
  /// evento hay que llamar a [activate] para que los nuevos valores estén vivos.
  Stream<RemoteConfigUpdate> get onConfigUpdated => _remoteConfig.onConfigUpdated;

  /// Activa los últimos valores fetchados (incl. los traídos por el listener en
  /// tiempo real). Best-effort: devuelve false si Firebase falla.
  Future<bool> activate() async {
    try {
      return await _remoteConfig.activate();
    } catch (e, st) {
      AppLogger.error('RemoteConfig activate failed', e, st);
      return false;
    }
  }

  bool get adBannerEnabled {
    try { return _remoteConfig.getBool('ad_banner_enabled'); } catch (_) { return true; }
  }

  String get adBannerUnitAndroid {
    try { return _remoteConfig.getString('ad_banner_unit_android'); } catch (_) { return ''; }
  }

  String get adBannerUnitIos {
    try { return _remoteConfig.getString('ad_banner_unit_ios'); } catch (_) { return ''; }
  }

  String get paywallDefaultPlan {
    try { return _remoteConfig.getString('paywall_default_plan'); } catch (_) { return 'monthly'; }
  }

  bool get paywallShowAnnualSavings {
    try { return _remoteConfig.getBool('paywall_show_annual_savings'); } catch (_) { return true; }
  }

  int get rescueNotificationDays {
    try { return _remoteConfig.getInt('rescue_notification_days'); } catch (_) { return 3; }
  }

  int get maxReviewNoteChars {
    try { return _remoteConfig.getInt('max_review_note_chars'); } catch (_) { return 300; }
  }

  /// Modelo de tiers por tamaño de hogar activo. Default OFF (fallback seguro al
  /// paywall Premium único). Espeja `home_tiers_enabled` del backend.
  bool get homeTiersEnabled {
    try { return _remoteConfig.getBool('home_tiers_enabled'); } catch (_) { return false; }
  }

  /// Eje de entitlement individual "Toka Plus" activo. Default OFF (fallback
  /// seguro: ningún usuario tiene Plus aunque exista el doc). El provider de la
  /// Fase 4 combina este flag con `users/{uid}/entitlements/plus.active` para
  /// decidir la activación efectiva. Espeja `toka_plus_enabled` del backend.
  bool get tokaPlusEnabled {
    try { return _remoteConfig.getBool('toka_plus_enabled'); } catch (_) { return false; }
  }

  /// Eje aditivo de "packs de miembro" activo en la UI. Default OFF (fallback
  /// seguro: sin packs, el tope mostrado es el del tier). Espeja
  /// `member_packs_enabled` del backend.
  bool get memberPacksEnabled {
    try { return _remoteConfig.getBool('member_packs_enabled'); } catch (_) { return false; }
  }

  /// Flag MAESTRO de la publicidad diferenciada per-usuario. Default OFF
  /// (fallback seguro: banner con el comportamiento de hogar actual e
  /// intersticial desactivado).
  bool get adDifferentiatedEnabled {
    try { return _remoteConfig.getBool('ad_differentiated_enabled'); } catch (_) { return false; }
  }

  /// On/off del intersticial. Requiere además [adDifferentiatedEnabled]. Default
  /// OFF.
  bool get adInterstitialEnabled {
    try { return _remoteConfig.getBool('ad_interstitial_enabled'); } catch (_) { return false; }
  }

  /// Intervalo mínimo (segundos) entre dos intersticiales. Default 210 (~3,5 min).
  int get adInterstitialMinIntervalSeconds {
    try { return _remoteConfig.getInt('ad_interstitial_min_interval_seconds'); } catch (_) { return 210; }
  }

  /// Tope de intersticiales por sesión. Default 3.
  int get adInterstitialMaxPerSession {
    try { return _remoteConfig.getInt('ad_interstitial_max_per_session'); } catch (_) { return 3; }
  }

  /// Unit ID del intersticial en Android (prod). Vacío → el controlador usa el
  /// TEST ID oficial de AdMob (dev).
  String get adInterstitialUnitAndroid {
    try { return _remoteConfig.getString('ad_interstitial_unit_android'); } catch (_) { return ''; }
  }

  /// Unit ID del intersticial en iOS (prod). Vacío → TEST ID oficial (dev).
  String get adInterstitialUnitIos {
    try { return _remoteConfig.getString('ad_interstitial_unit_ios'); } catch (_) { return ''; }
  }
}
