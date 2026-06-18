import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

const _kBannerUnit = 'ca-app-pub-3940256099942544/6300978111';

/// Construye un dashboard mínimo con los flags de premium/ads indicados.
HomeDashboard _dashboard({
  required bool showAds,
  required bool showBanner,
  String bannerUnit = _kBannerUnit,
}) {
  return HomeDashboard.fromFirestore({
    'premiumFlags': {'isPremium': !showAds, 'showAds': showAds},
    'adFlags': {'showBanner': showBanner, 'bannerUnit': bannerUnit},
  });
}

Future<AdBannerConfig> _resolve(HomeDashboard? dashboard) async {
  final container = ProviderContainer(
    overrides: [
      dashboardProvider.overrideWith((_) => Stream.value(dashboard)),
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
  });
}
