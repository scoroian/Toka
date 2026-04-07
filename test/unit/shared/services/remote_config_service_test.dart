import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/shared/services/remote_config_service.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  late MockFirebaseRemoteConfig mockRemoteConfig;
  late RemoteConfigService service;

  setUp(() {
    mockRemoteConfig = MockFirebaseRemoteConfig();
    service = RemoteConfigService(mockRemoteConfig);
  });

  group('RemoteConfigService defaults', () {
    test('adBannerEnabled devuelve true por defecto si Firebase no responde', () {
      when(() => mockRemoteConfig.getBool('ad_banner_enabled')).thenThrow(Exception('no internet'));
      expect(service.adBannerEnabled, true);
    });

    test('rescueNotificationDays devuelve 3 por defecto', () {
      when(() => mockRemoteConfig.getInt('rescue_notification_days')).thenThrow(Exception());
      expect(service.rescueNotificationDays, 3);
    });

    test('maxReviewNoteChars devuelve 300 por defecto', () {
      when(() => mockRemoteConfig.getInt('max_review_note_chars')).thenThrow(Exception());
      expect(service.maxReviewNoteChars, 300);
    });

    test('paywallDefaultPlan devuelve "monthly" por defecto', () {
      when(() => mockRemoteConfig.getString('paywall_default_plan')).thenThrow(Exception());
      expect(service.paywallDefaultPlan, 'monthly');
    });

    test('adBannerEnabled delega a Firebase cuando funciona', () {
      when(() => mockRemoteConfig.getBool('ad_banner_enabled')).thenReturn(false);
      expect(service.adBannerEnabled, false);
    });
  });
}
