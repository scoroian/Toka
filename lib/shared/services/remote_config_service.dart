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
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig.setDefaults(_defaults);
      await _remoteConfig.fetchAndActivate();
    } catch (e, st) {
      AppLogger.error('RemoteConfig init failed — using defaults', e, st);
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
