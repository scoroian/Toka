import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/premium_upgrade_banner.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PremiumUpgradeBanner', () {
    testWidgets('con cta y onCta renderiza el botón y dispara el callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(PremiumUpgradeBanner(
        message: 'Has alcanzado el tope',
        cta: 'Subir de plan',
        ctaKey: const Key('banner_cta'),
        onCta: () => tapped = true,
      )));

      expect(find.text('Subir de plan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('banner_cta')));
      expect(tapped, isTrue);
    });

    testWidgets('sin cta (máximo alcanzado) muestra el mensaje sin botón',
        (tester) async {
      await tester.pumpWidget(_wrap(const PremiumUpgradeBanner(
        message: 'Has alcanzado el máximo de tu plan',
      )));

      expect(find.text('Has alcanzado el máximo de tu plan'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
