import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
import 'package:toka/shared/widgets/ad_flags_provider.dart';
import 'package:toka/shared/widgets/ad_visibility_provider.dart';

const _kBannerUnit = 'ca-app-pub-3940256099942544/6300978111';

/// Construye un dashboard mínimo con los flags de premium/ads indicados.
HomeDashboard _dashboard({
  required bool showAds,
  required bool showBanner,
  String bannerUnit = _kBannerUnit,
  String? bannerUnitAndroid,
  String? bannerUnitIos,
}) {
  final adFlags = <String, dynamic>{
    'showBanner': showBanner,
    'bannerUnit': bannerUnit,
    if (bannerUnitAndroid != null) 'bannerUnitAndroid': bannerUnitAndroid,
    if (bannerUnitIos != null) 'bannerUnitIos': bannerUnitIos,
  };
  return HomeDashboard.fromFirestore({
    'premiumFlags': {'isPremium': !showAds, 'showAds': showAds},
    'adFlags': adFlags,
  });
}

Future<AdBannerConfig> _resolve(
  HomeDashboard? dashboard, {
  BannerAdUnits? rcUnits,
}) async {
  final container = ProviderContainer(
    overrides: [
      dashboardProvider.overrideWith((_) => Stream.value(dashboard)),
      if (rcUnits != null)
        remoteBannerAdUnitsProvider.overrideWithValue(rcUnits),
    ],
  );
  addTearDown(container.dispose);
  // Resuelve el primer evento del stream antes de leer el config derivado.
  await container.read(dashboardProvider.future);
  return container.read(adBannerConfigProvider);
}

void main() {
  group('adBannerConfigProvider', () {
    test('hogar gratis con banner activo: muestra banner', () async {
      final cfg = await _resolve(_dashboard(showAds: true, showBanner: true));
      expect(cfg.show, isTrue);
      expect(cfg.unitId, _kBannerUnit);
    });

    test(
        'hogar premium con adFlags STALE (showAds=false pero showBanner=true): '
        'NO muestra banner — regresión del bug de "Crear tarea"', () async {
      final cfg = await _resolve(_dashboard(showAds: false, showBanner: true));
      expect(cfg.show, isFalse);
    });

    test('hogar premium coherente (showAds=false, showBanner=false): oculto',
        () async {
      final cfg = await _resolve(_dashboard(showAds: false, showBanner: false));
      expect(cfg.show, isFalse);
    });

    test('hogar gratis sin banner configurado: oculto', () async {
      final cfg = await _resolve(_dashboard(showAds: true, showBanner: false));
      expect(cfg.show, isFalse);
    });

    test('sin dashboard (aún cargando): oculto y sin unitId', () async {
      final cfg = await _resolve(null);
      expect(cfg.show, isFalse);
      expect(cfg.unitId, isEmpty);
    });

    group('unit por plataforma (toma el del dashboard)', () {
      const androidUnit = 'ca-app-pub-9999/android-real';
      const iosUnit = 'ca-app-pub-9999/ios-real';

      tearDown(() => debugDefaultTargetPlatformOverride = null);

      test('Android → toma adFlags.bannerUnitAndroid del dashboard', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final cfg = await _resolve(_dashboard(
          showAds: true,
          showBanner: true,
          bannerUnit: androidUnit,
          bannerUnitAndroid: androidUnit,
          bannerUnitIos: iosUnit,
        ));
        expect(cfg.show, isTrue);
        expect(cfg.unitId, androidUnit);
      });

      test('iOS → toma adFlags.bannerUnitIos del dashboard', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final cfg = await _resolve(_dashboard(
          showAds: true,
          showBanner: true,
          bannerUnit: androidUnit,
          bannerUnitAndroid: androidUnit,
          bannerUnitIos: iosUnit,
        ));
        expect(cfg.show, isTrue);
        expect(cfg.unitId, iosUnit);
      });

      test('back-compat: dashboard viejo con solo bannerUnit → ambas plataformas '
          'usan bannerUnit', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final cfg = await _resolve(_dashboard(
          showAds: true,
          showBanner: true,
          bannerUnit: androidUnit,
        ));
        expect(cfg.unitId, androidUnit);
      });
    });

    group('Remote Config gana sobre el dashboard (cambiable sin redeploy)', () {
      const rcAndroid = 'ca-app-pub-7777/rc-android';
      const rcIos = 'ca-app-pub-7777/rc-ios';
      const dashAndroid = 'ca-app-pub-8888/dash-android';
      const dashIos = 'ca-app-pub-8888/dash-ios';

      tearDown(() => debugDefaultTargetPlatformOverride = null);

      test('Android: usa el unit de Remote Config aunque el dashboard traiga otro',
          () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final cfg = await _resolve(
          _dashboard(
            showAds: true,
            showBanner: true,
            bannerUnitAndroid: dashAndroid,
            bannerUnitIos: dashIos,
          ),
          rcUnits: const BannerAdUnits(android: rcAndroid, ios: rcIos),
        );
        expect(cfg.unitId, rcAndroid);
      });

      test('iOS: usa el unit de Remote Config aunque el dashboard traiga otro',
          () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final cfg = await _resolve(
          _dashboard(
            showAds: true,
            showBanner: true,
            bannerUnitAndroid: dashAndroid,
            bannerUnitIos: dashIos,
          ),
          rcUnits: const BannerAdUnits(android: rcAndroid, ios: rcIos),
        );
        expect(cfg.unitId, rcIos);
      });

      test('Remote Config vacío → cae al unit del dashboard (fallback)', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final cfg = await _resolve(
          _dashboard(
            showAds: true,
            showBanner: true,
            bannerUnitAndroid: dashAndroid,
            bannerUnitIos: dashIos,
          ),
          rcUnits: const BannerAdUnits(android: '', ios: ''),
        );
        expect(cfg.unitId, dashAndroid);
      });
    });

    group('flag maestro OFF → comportamiento de hogar actual (legacy)', () {
      test('por defecto el maestro está OFF (RC no disponible en tests)',
          () async {
        // Sin override de adDifferentiatedEnabledProvider: el provider real cae a
        // false (Firebase no disponible) → camino legacy. Hogar gratis con banner
        // activo muestra banner; premium lo oculta.
        final libre =
            await _resolve(_dashboard(showAds: true, showBanner: true));
        expect(libre.show, isTrue);
        final premium =
            await _resolve(_dashboard(showAds: false, showBanner: false));
        expect(premium.show, isFalse);
      });
    });

    group('flag maestro ON → banner per-usuario (adVisibilityProvider)', () {
      Future<AdBannerConfig> _resolveDiff(
        HomeDashboard? dashboard, {
        required bool bannerVisible,
        BannerAdUnits? rcUnits,
      }) async {
        final container = ProviderContainer(overrides: [
          dashboardProvider.overrideWith((_) => Stream.value(dashboard)),
          adDifferentiatedEnabledProvider.overrideWithValue(true),
          adVisibilityProvider.overrideWithValue(
            AdVisibility(banner: bannerVisible, interstitial: false),
          ),
          if (rcUnits != null)
            remoteBannerAdUnitsProvider.overrideWithValue(rcUnits),
        ]);
        addTearDown(container.dispose);
        await container.read(dashboardProvider.future);
        return container.read(adBannerConfigProvider);
      }

      test('show sigue adVisibility.banner=true aunque el dashboard sea premium '
          '(showBanner=false): el flag de hogar ya no manda', () async {
        final cfg = await _resolveDiff(
          _dashboard(showAds: false, showBanner: false),
          bannerVisible: true,
        );
        expect(cfg.show, isTrue);
      });

      test('show sigue adVisibility.banner=false aunque el hogar sea gratis con '
          'banner activo (pagador/Plus quita banner individual)', () async {
        final cfg = await _resolveDiff(
          _dashboard(showAds: true, showBanner: true),
          bannerVisible: false,
        );
        expect(cfg.show, isFalse);
      });

      test('unitId se resuelve igual (Remote Config gana) en el camino per-usuario',
          () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final cfg = await _resolveDiff(
          _dashboard(showAds: false, showBanner: false),
          bannerVisible: true,
          rcUnits: const BannerAdUnits(android: 'rc-android', ios: 'rc-ios'),
        );
        expect(cfg.show, isTrue);
        expect(cfg.unitId, 'rc-android');
      });
    });
  });
}
