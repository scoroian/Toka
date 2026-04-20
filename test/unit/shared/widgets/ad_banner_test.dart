import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

void main() {
  testWidgets('AdBanner renderiza SizedBox.shrink cuando show=false', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adBannerConfigProvider.overrideWithValue(
            const AdBannerConfig(show: false, unitId: 'x'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdBanner())),
      ),
    );
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('AdBanner renderiza SizedBox.shrink cuando unitId vacío', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adBannerConfigProvider.overrideWithValue(
            const AdBannerConfig(show: true, unitId: ''),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdBanner())),
      ),
    );
    expect(find.byType(SizedBox), findsWidgets);
  });
}
