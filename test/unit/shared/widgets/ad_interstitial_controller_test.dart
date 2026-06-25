import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toka/shared/widgets/ad_flags_provider.dart';
import 'package:toka/shared/widgets/ad_interstitial_controller.dart';
import 'package:toka/shared/widgets/ad_visibility_provider.dart';

/// Presentación falsa: cuenta cuántas veces se mostró.
class _FakePresentation implements InterstitialPresentation {
  int shows = 0;
  @override
  Future<void> show() async => shows++;
}

/// Gateway falso: registra las cargas y entrega presentaciones (o null si se
/// configura para fallar).
class _FakeGateway implements InterstitialAdGateway {
  _FakeGateway({this.fail = false});
  bool fail;
  int loads = 0;
  final List<_FakePresentation> presentations = [];

  @override
  Future<InterstitialPresentation?> load(String unitId) async {
    loads++;
    if (fail) return null;
    final p = _FakePresentation();
    presentations.add(p);
    return p;
  }

  int get totalShows => presentations.fold(0, (a, p) => a + p.shows);
}

class _Clock {
  _Clock(this.value);
  DateTime value;
  DateTime call() => value;
}

const _visOn = AdVisibility(banner: true, interstitial: true);
const _visBannerOnly = AdVisibility(banner: true, interstitial: false);

ProviderContainer _container({
  required _FakeGateway gateway,
  required _Clock clock,
  bool master = true,
  bool interstitialEnabled = true,
  AdVisibility visibility = _visOn,
  int minInterval = 210,
  int maxPerSession = 3,
}) {
  return ProviderContainer(overrides: [
    adDifferentiatedEnabledProvider.overrideWithValue(master),
    interstitialRemoteConfigProvider.overrideWithValue(InterstitialRemoteConfig(
      enabled: interstitialEnabled,
      minIntervalSeconds: minInterval,
      maxPerSession: maxPerSession,
      unitAndroid: '',
      unitIos: '',
    )),
    adVisibilityProvider.overrideWithValue(visibility),
    nowProvider.overrideWithValue(clock.call),
    interstitialAdGatewayProvider.overrideWithValue(gateway),
  ]);
}

void main() {
  group('AdInterstitialController.maybeShow — gating', () {
    test('no muestra cuando visibility.interstitial=false', () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      final c = _container(gateway: gw, clock: clock, visibility: _visBannerOnly);
      addTearDown(c.dispose);

      await c.read(adInterstitialControllerProvider.notifier).maybeShow();
      expect(gw.totalShows, 0);
    });

    test('no muestra cuando el maestro está OFF', () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      final c = _container(gateway: gw, clock: clock, master: false);
      addTearDown(c.dispose);

      await c.read(adInterstitialControllerProvider.notifier).maybeShow();
      expect(gw.totalShows, 0);
    });

    test('no muestra cuando ad_interstitial_enabled está OFF', () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      final c = _container(gateway: gw, clock: clock, interstitialEnabled: false);
      addTearDown(c.dispose);

      await c.read(adInterstitialControllerProvider.notifier).maybeShow();
      expect(gw.totalShows, 0);
    });

    test('caso feliz: muestra una vez', () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      final c = _container(gateway: gw, clock: clock);
      addTearDown(c.dispose);
      final ctrl = c.read(adInterstitialControllerProvider.notifier);

      await ctrl.maybeShow(); // consume la gracia del primer cambio de pestaña
      await ctrl.maybeShow();
      expect(gw.totalShows, 1);
    });
  });

  group('AdInterstitialController.maybeShow — cap de frecuencia', () {
    test('respeta el intervalo mínimo: un 2º intento demasiado pronto no muestra',
        () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      final c = _container(gateway: gw, clock: clock, minInterval: 210);
      addTearDown(c.dispose);
      final ctrl = c.read(adInterstitialControllerProvider.notifier);

      await ctrl.maybeShow(); // consume la gracia (no avanza el reloj)
      await ctrl.maybeShow(); // t0 → muestra
      expect(gw.totalShows, 1);

      clock.value = clock.value.add(const Duration(seconds: 100)); // < 210s
      await ctrl.maybeShow();
      expect(gw.totalShows, 1, reason: 'demasiado pronto: no debe mostrar otro');

      clock.value = clock.value.add(const Duration(seconds: 150)); // total 250s
      await ctrl.maybeShow();
      expect(gw.totalShows, 2, reason: 'pasado el intervalo: muestra el 2º');
    });

    test('respeta el tope por sesión', () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      // minInterval 0 para aislar el tope de sesión.
      final c = _container(
          gateway: gw, clock: clock, minInterval: 0, maxPerSession: 2);
      addTearDown(c.dispose);
      final ctrl = c.read(adInterstitialControllerProvider.notifier);

      for (var i = 0; i < 5; i++) {
        clock.value = clock.value.add(const Duration(seconds: 1));
        await ctrl.maybeShow();
      }
      expect(gw.totalShows, 2, reason: 'no más de maxPerSession por sesión');
    });
  });

  group('AdInterstitialController.maybeShow — gracia primer cambio de pestaña',
      () {
    test('no muestra en el PRIMER cambio de pestaña; el segundo sí', () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      // minInterval 0 para aislar la gracia del cap de intervalo: si el 2º no
      // mostrara, sería por la gracia y no por el intervalo.
      final c = _container(gateway: gw, clock: clock, minInterval: 0);
      addTearDown(c.dispose);
      final ctrl = c.read(adInterstitialControllerProvider.notifier);

      await ctrl.maybeShow();
      expect(gw.totalShows, 0,
          reason: 'el primer cambio de pestaña de la sesión no muestra');

      clock.value = clock.value.add(const Duration(seconds: 1));
      await ctrl.maybeShow();
      expect(gw.totalShows, 1, reason: 'el segundo cambio sí muestra');
    });

    test('la gracia precarga para que el 2º sea instantáneo', () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      final c = _container(gateway: gw, clock: clock, minInterval: 0);
      addTearDown(c.dispose);
      final ctrl = c.read(adInterstitialControllerProvider.notifier);

      await ctrl.maybeShow(); // gracia → aprovecha para precargar
      expect(gw.loads, 1, reason: 'la gracia precarga el siguiente intersticial');
    });

    test('la gracia no consume cupo de sesión', () async {
      final gw = _FakeGateway();
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      final c = _container(
          gateway: gw, clock: clock, minInterval: 0, maxPerSession: 1);
      addTearDown(c.dispose);
      final ctrl = c.read(adInterstitialControllerProvider.notifier);

      await ctrl.maybeShow(); // gracia, no cuenta
      clock.value = clock.value.add(const Duration(seconds: 1));
      await ctrl.maybeShow(); // 1ª impresión real
      expect(gw.totalShows, 1,
          reason: 'tras la gracia aún queda el cupo completo de sesión');
    });
  });

  group('AdInterstitialController — robustez', () {
    test('si la carga falla, no cuenta impresión y reintenta después', () async {
      final gw = _FakeGateway(fail: true);
      final clock = _Clock(DateTime(2026, 6, 24, 12));
      final c = _container(gateway: gw, clock: clock, minInterval: 0);
      addTearDown(c.dispose);
      final ctrl = c.read(adInterstitialControllerProvider.notifier);

      await ctrl.maybeShow(); // consume la gracia del primer cambio de pestaña
      await ctrl.maybeShow(); // intento real con la carga fallando
      expect(gw.totalShows, 0);

      // La carga falló → no consumió cupo: al recuperar la red, sí muestra.
      gw.fail = false;
      clock.value = clock.value.add(const Duration(seconds: 1));
      await ctrl.maybeShow();
      expect(gw.totalShows, 1);
    });
  });
}
