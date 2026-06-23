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
}
