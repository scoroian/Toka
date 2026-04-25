import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/futurista/welcome_step_futurista.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/welcome_step.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/welcome_step_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget harness({
  required ProviderContainer container,
  required VoidCallback onStart,
}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: WelcomeStep(onStart: onStart)),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(container: c, onStart: () {}));
    await tester.pump();
    expect(find.byType(WelcomeStepV2), findsOneWidget);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tocka.skin': 'futurista'});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(container: c, onStart: () {}));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.byType(WelcomeStepFuturista), findsOneWidget);
  });
}
