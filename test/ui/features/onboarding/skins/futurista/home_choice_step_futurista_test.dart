import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/futurista/home_choice_step_futurista.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/home_choice_step.dart';
import 'package:toka/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget harness(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: HomeChoiceStep(
            isLoading: false,
            error: null,
            onCreateHome: (_, __) async {},
            onJoinHome: (_) async {},
            onPrev: () {},
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(c));
    await tester.pumpAndSettle();
    expect(find.byType(HomeChoiceStepV2), findsOneWidget);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tocka.skin': 'futurista'});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(c));
    await tester.pumpAndSettle();
    expect(find.byType(HomeChoiceStepFuturista), findsOneWidget);
  });
}
