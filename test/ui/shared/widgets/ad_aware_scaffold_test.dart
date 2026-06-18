import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_aware_scaffold.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

Widget _pump({required bool bannerVisible, Widget? fab}) {
  return ProviderScope(
    overrides: [
      adBannerConfigProvider.overrideWith(
        (ref) => AdBannerConfig(
          show: bannerVisible,
          unitId: bannerVisible ? 'ca-app-pub-3940256099942544/6300978111' : '',
        ),
      ),
    ],
    child: MaterialApp(
      home: AdAwareScaffold(
        appBar: AppBar(title: const Text('T')),
        body: const SizedBox.expand(),
        floatingActionButton: fab,
      ),
    ),
  );
}

void main() {
  group('AdAwareScaffold', () {
    testWidgets('no instancia un AdBanner propio (lo aporta el shell)',
        (t) async {
      // Tras el refactor, el único AdBanner vive en MainShellV2 para no
      // duplicar impresiones de AdMob. AdAwareScaffold ya no pinta uno propio
      // ni siquiera con la config de banner activa.
      await t.pumpWidget(_pump(bannerVisible: true));
      expect(find.byKey(const Key('ad_banner')), findsNothing);
    });

    testWidgets('no renderiza AdBanner cuando bannerVisible=false', (t) async {
      await t.pumpWidget(_pump(bannerVisible: false));
      expect(find.byKey(const Key('ad_banner')), findsNothing);
    });

    testWidgets(
        'bottomPaddingOf devuelve solo safeBottom incluso con banner activo '
        '(el shell ya reserva el espacio del banner)', (t) async {
      double? captured;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: true, unitId: 'x'),
            ),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
              child: Consumer(
                builder: (ctx, ref, _) {
                  captured = AdAwareScaffold.bottomPaddingOf(ctx, ref);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      expect(captured, 24);
    });

    testWidgets('bottomPaddingOf devuelve solo safeBottom cuando no hay banner',
        (t) async {
      double? captured;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: false, unitId: ''),
            ),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
              child: Consumer(
                builder: (ctx, ref, _) {
                  captured = AdAwareScaffold.bottomPaddingOf(ctx, ref);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      expect(captured, 24);
    });
  });
}
