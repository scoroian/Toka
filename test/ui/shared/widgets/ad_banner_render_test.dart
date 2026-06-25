import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

Widget _app({required AdBannerConfig config}) => ProviderScope(
      overrides: [
        adBannerConfigProvider.overrideWith((ref) => config),
      ],
      child: const MaterialApp(home: Scaffold(body: AdBanner())),
    );

void main() {
  testWidgets('show=false → no reserva espacio (shrink)', (t) async {
    await t.pumpWidget(_app(config: const AdBannerConfig(show: false, unitId: '')));
    await t.pump();
    final box = t.widget<SizedBox>(find.descendant(
      of: find.byType(AdBanner),
      matching: find.byType(SizedBox),
    ));
    expect(box.height ?? 0, 0);
  });

  testWidgets(
      'show=true con unitId vacío (hogar Premium en dev) → reserva el slot del '
      'banner (resuelve test ID, no se oculta por unit vacío)', (t) async {
    await t.pumpWidget(_app(config: const AdBannerConfig(show: true, unitId: '')));
    await t.pump();
    final reserved = find.descendant(
      of: find.byType(AdBanner),
      matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == AdBanner.kBannerHeight),
    );
    expect(reserved, findsOneWidget);

    // Desmontar para cancelar el Timer.periodic de refresco (60s) que el banner
    // programa al intentar cargar, y no dejar timers pendientes en el test.
    await t.pumpWidget(const SizedBox());
  });
}
