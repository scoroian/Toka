import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
import 'package:toka/shared/widgets/futurista/ad_banner_futurista.dart';

Widget harness({required AdBannerConfig config}) => ProviderScope(
      overrides: [
        adBannerConfigProvider.overrideWith((ref) => config),
      ],
      child: const MaterialApp(home: Scaffold(body: AdBannerFuturista())),
    );

void main() {
  testWidgets('show=false renders SizedBox.shrink', (tester) async {
    await tester.pumpWidget(harness(
      config: const AdBannerConfig(show: false, unitId: ''),
    ));
    expect(find.text('Anuncio · AdMob'), findsNothing);
    expect(find.text('Instalar'), findsNothing);
  });

  testWidgets('show=true renders banner mock', (tester) async {
    await tester.pumpWidget(harness(
      config: const AdBannerConfig(show: true, unitId: 'test'),
    ));
    expect(find.text('Anuncio · AdMob'), findsOneWidget);
    expect(find.text('Instalar'), findsOneWidget);
    expect(find.text('AD'), findsOneWidget);
  });
}
