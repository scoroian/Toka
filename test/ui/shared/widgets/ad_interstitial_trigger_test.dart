import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toka/shared/widgets/ad_interstitial_controller.dart';
import 'package:toka/shared/widgets/ad_interstitial_trigger.dart';

/// Notifier espía: cuenta las llamadas a maybeShow sin tocar AdMob.
class _SpyController extends AdInterstitialController {
  int calls = 0;
  @override
  void build() {}
  @override
  Future<void> maybeShow() async => calls++;
}

void main() {
  testWidgets(
      'cambio de pestaña dispara maybeShow; montaje inicial y misma pestaña no',
      (tester) async {
    late _SpyController spy;
    var tabIndex = 0;
    late StateSetter setOuter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adInterstitialControllerProvider.overrideWith(() {
            spy = _SpyController();
            return spy;
          }),
        ],
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return AdInterstitialTrigger(
                tabIndex: tabIndex,
                child: const SizedBox(),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    // Forzar la creación del notifier para poder leer el espía: el montaje
    // inicial no lo construye porque no llama a maybeShow.
    final container = ProviderScope.containerOf(
        tester.element(find.byType(AdInterstitialTrigger)));
    container.read(adInterstitialControllerProvider.notifier);
    expect(spy.calls, 0, reason: 'el montaje inicial no dispara');

    // Cambio de pestaña 0 → 1
    setOuter(() => tabIndex = 1);
    await tester.pump();
    expect(spy.calls, 1);

    // Cambio de pestaña 1 → 2
    setOuter(() => tabIndex = 2);
    await tester.pump();
    expect(spy.calls, 2);

    // Rebuild SIN cambiar de pestaña (misma index) → no dispara
    setOuter(() {});
    await tester.pump();
    expect(spy.calls, 2, reason: 'misma pestaña no dispara');
  });
}
