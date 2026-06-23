import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/shared/services/remote_config_service.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void main() {
  late MockFirebaseRemoteConfig mockRemoteConfig;
  late RemoteConfigService service;

  setUpAll(() {
    registerFallbackValue(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero,
    ));
    registerFallbackValue(<String, dynamic>{});
  });

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

  group('RemoteConfigService tiempo real', () {
    test('init configura minimumFetchInterval bajo (refresco casi al instante)',
        () async {
      when(() => mockRemoteConfig.setConfigSettings(any())).thenAnswer((_) async {});
      when(() => mockRemoteConfig.setDefaults(any())).thenAnswer((_) async {});
      when(() => mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);

      await service.init();

      final captured =
          verify(() => mockRemoteConfig.setConfigSettings(captureAny()))
              .captured
              .single as RemoteConfigSettings;
      expect(captured.minimumFetchInterval, const Duration(minutes: 1));
    });

    test('onConfigUpdated reenvía los updates del SDK (tiempo real)', () async {
      final controller = StreamController<RemoteConfigUpdate>.broadcast();
      addTearDown(controller.close);
      when(() => mockRemoteConfig.onConfigUpdated)
          .thenAnswer((_) => controller.stream);

      final received = <RemoteConfigUpdate>[];
      final sub = service.onConfigUpdated.listen(received.add);
      addTearDown(sub.cancel);

      final update = RemoteConfigUpdate({'ad_banner_unit_android'});
      controller.add(update);
      await Future<void>.delayed(Duration.zero);

      expect(received, [update]);
    });

    test('activate delega a Firebase y devuelve el resultado', () async {
      when(() => mockRemoteConfig.activate()).thenAnswer((_) async => true);
      expect(await service.activate(), true);
    });

    test('activate devuelve false (best-effort) si Firebase lanza', () async {
      when(() => mockRemoteConfig.activate()).thenThrow(Exception());
      expect(await service.activate(), false);
    });
  });
}
