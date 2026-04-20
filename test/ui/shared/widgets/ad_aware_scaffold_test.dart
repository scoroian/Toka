import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_aware_scaffold.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
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
    testWidgets('renderiza AdBanner cuando bannerVisible=true', (t) async {
      await t.pumpWidget(_pump(bannerVisible: true));
      expect(find.byKey(const Key('ad_banner')), findsOneWidget);
    });

    testWidgets('no renderiza AdBanner cuando bannerVisible=false', (t) async {
      await t.pumpWidget(_pump(bannerVisible: false));
      expect(find.byKey(const Key('ad_banner')), findsNothing);
    });

    testWidgets('bottomPaddingOf suma safeBottom + bannerSlot cuando hay banner',
        (t) async {
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
      expect(
        captured,
        24 + AdBanner.kBannerHeight + AdBanner.kBannerGap,
      );
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
