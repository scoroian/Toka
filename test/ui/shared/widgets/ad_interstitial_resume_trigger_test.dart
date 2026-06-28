import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toka/shared/widgets/ad_flags_provider.dart';
import 'package:toka/shared/widgets/ad_interstitial_controller.dart';
import 'package:toka/shared/widgets/ad_interstitial_resume_trigger.dart';

/// Notifier espía: cuenta las llamadas a maybeShow sin tocar AdMob.
class _SpyController extends AdInterstitialController {
  int calls = 0;
  @override
  void build() {}
  @override
  Future<void> maybeShow() async => calls++;
}

/// Reloj mutable inyectable.
class _Clock {
  _Clock(this.value);
  DateTime value;
  DateTime call() => value;
}

InterstitialRemoteConfig _cfg({int resumeMinBackgroundSeconds = 240}) =>
    InterstitialRemoteConfig(
      enabled: true,
      minIntervalSeconds: 210,
      maxPerSession: 3,
      resumeMinBackgroundSeconds: resumeMinBackgroundSeconds,
      unitAndroid: '',
      unitIos: '',
    );

void main() {
  late _SpyController spy;

  Future<void> pumpTrigger(
    WidgetTester tester, {
    required _Clock clock,
    int resumeMinBackgroundSeconds = 240,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adInterstitialControllerProvider.overrideWith(() {
            spy = _SpyController();
            return spy;
          }),
          nowProvider.overrideWithValue(clock.call),
          interstitialRemoteConfigProvider.overrideWithValue(
            _cfg(resumeMinBackgroundSeconds: resumeMinBackgroundSeconds),
          ),
        ],
        child: const MaterialApp(home: AdInterstitialResumeTrigger()),
      ),
    );
    // Fuerza la creación del notifier espía (el montaje no lo construye).
    final container = ProviderScope.containerOf(
        tester.element(find.byType(AdInterstitialResumeTrigger)));
    container.read(adInterstitialControllerProvider.notifier);
    await tester.pump();
  }

  Future<void> setState(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }

  testWidgets('resume tras background >= umbral dispara maybeShow una vez',
      (tester) async {
    final clock = _Clock(DateTime(2026, 6, 28, 12));
    await pumpTrigger(tester, clock: clock);
    expect(spy.calls, 0, reason: 'el montaje inicial no dispara');

    await setState(tester, AppLifecycleState.paused);
    clock.value = clock.value.add(const Duration(seconds: 300)); // > 240
    await setState(tester, AppLifecycleState.resumed);

    expect(spy.calls, 1);
  });

  testWidgets('resume tras background < umbral NO dispara', (tester) async {
    final clock = _Clock(DateTime(2026, 6, 28, 12));
    await pumpTrigger(tester, clock: clock);

    await setState(tester, AppLifecycleState.paused);
    clock.value = clock.value.add(const Duration(seconds: 60)); // < 240
    await setState(tester, AppLifecycleState.resumed);

    expect(spy.calls, 0, reason: 'vistazo corto: no dispara');
  });

  testWidgets('resume sin background previo (cold-start) NO dispara',
      (tester) async {
    final clock = _Clock(DateTime(2026, 6, 28, 12));
    await pumpTrigger(tester, clock: clock);

    // Un resumed sin un paused anterior (arranque) no debe disparar.
    await setState(tester, AppLifecycleState.resumed);

    expect(spy.calls, 0, reason: 'abrir la app nunca queda gateado por un ad');
  });

  testWidgets('dos ciclos background->resume, ambos >= umbral → 2 disparos',
      (tester) async {
    final clock = _Clock(DateTime(2026, 6, 28, 12));
    await pumpTrigger(tester, clock: clock);

    await setState(tester, AppLifecycleState.paused);
    clock.value = clock.value.add(const Duration(seconds: 300));
    await setState(tester, AppLifecycleState.resumed);
    expect(spy.calls, 1);

    await setState(tester, AppLifecycleState.paused);
    clock.value = clock.value.add(const Duration(seconds: 300));
    await setState(tester, AppLifecycleState.resumed);
    expect(spy.calls, 2);
  });

  testWidgets('el periodo de background se consume: un 2º resume seguido no dispara',
      (tester) async {
    final clock = _Clock(DateTime(2026, 6, 28, 12));
    await pumpTrigger(tester, clock: clock);

    await setState(tester, AppLifecycleState.paused);
    clock.value = clock.value.add(const Duration(seconds: 300));
    await setState(tester, AppLifecycleState.resumed);
    expect(spy.calls, 1);

    // Otro resumed sin pasar por paused: ya no hay background pendiente.
    clock.value = clock.value.add(const Duration(seconds: 300));
    await setState(tester, AppLifecycleState.resumed);
    expect(spy.calls, 1, reason: 'sin un nuevo background no se reevalúa');
  });

  testWidgets(
      'transiciones efímeras (inactive/hidden) no estampan ni disparan; '
      'reconstrucción sin ciclo de vida tampoco (regresión: navegación no dispara)',
      (tester) async {
    final clock = _Clock(DateTime(2026, 6, 28, 12));
    await pumpTrigger(tester, clock: clock);

    // Simula salir y volver pasando por las transiciones efímeras, pero SIN un
    // paused real (p. ej. abrir el control center): no debe disparar.
    await setState(tester, AppLifecycleState.inactive);
    clock.value = clock.value.add(const Duration(seconds: 300));
    await setState(tester, AppLifecycleState.hidden);
    await setState(tester, AppLifecycleState.inactive);
    await setState(tester, AppLifecycleState.resumed);
    expect(spy.calls, 0, reason: 'sin un paused real no hay background medible');

    // Una simple reconstrucción del árbol (lo que haría una navegación) no
    // dispara: el trigger ni siquiera conoce las pestañas.
    await tester.pump();
    expect(spy.calls, 0);
  });
}
