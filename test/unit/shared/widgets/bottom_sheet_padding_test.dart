import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
import 'package:toka/shared/widgets/bottom_sheet_padding.dart';
import 'package:toka/shared/widgets/skins/main_shell_v2.dart';

/// Harness que devuelve el valor calculado por [bottomSheetSafeBottom]
/// dentro de un BuildContext con MediaQuery controlado.
Future<double> _harness(
  WidgetTester tester, {
  required MediaQueryData mq,
  required bool bannerVisible,
  required bool hasNavBar,
}) async {
  double? captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adBannerConfigProvider.overrideWith(
          (ref) => AdBannerConfig(
            show: bannerVisible,
            unitId: bannerVisible ? 'unit-test' : '',
          ),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: mq,
          child: Consumer(
            builder: (ctx, ref, _) {
              captured = bottomSheetSafeBottom(
                ctx,
                ref,
                hasNavBar: hasNavBar,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return captured!;
}

void main() {
  const kNav = MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom;
  const kBan = AdBanner.kBannerHeight + AdBanner.kBannerGap;

  group('bottomSheetSafeBottom', () {
    testWidgets('sin banner, sin navbar, sin teclado → solo viewPadding', (t) async {
      final mq = const MediaQueryData(
        padding: EdgeInsets.only(bottom: 24),
      );
      final r = await _harness(t, mq: mq, bannerVisible: false, hasNavBar: false);
      expect(r, 24);
    });

    testWidgets('sin banner, con navbar, sin teclado', (t) async {
      final mq = const MediaQueryData(padding: EdgeInsets.only(bottom: 24));
      final r = await _harness(t, mq: mq, bannerVisible: false, hasNavBar: true);
      expect(r, 24 + kNav);
    });

    testWidgets('con banner, sin navbar, sin teclado', (t) async {
      final mq = const MediaQueryData(padding: EdgeInsets.only(bottom: 24));
      final r = await _harness(t, mq: mq, bannerVisible: true, hasNavBar: false);
      expect(r, 24 + kBan);
    });

    testWidgets('con banner, con navbar, sin teclado', (t) async {
      final mq = const MediaQueryData(padding: EdgeInsets.only(bottom: 24));
      final r = await _harness(t, mq: mq, bannerVisible: true, hasNavBar: true);
      expect(r, 24 + kNav + kBan);
    });

    testWidgets('con banner, con navbar, con teclado', (t) async {
      final mq = const MediaQueryData(
        padding: EdgeInsets.only(bottom: 24),
        viewInsets: EdgeInsets.only(bottom: 300),
      );
      final r = await _harness(t, mq: mq, bannerVisible: true, hasNavBar: true);
      expect(r, 24 + 300 + kNav + kBan);
    });
  });
}
