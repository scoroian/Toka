import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/onboarding/presentation/skins/futurista/notification_rationale_screen_futurista.dart';
import 'package:toka/features/onboarding/presentation/skins/notification_rationale_screen.dart';
import 'package:toka/features/onboarding/presentation/skins/notification_rationale_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget harness(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      // ignore: prefer_const_constructors
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const NotificationRationaleScreen(),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(c));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.byType(NotificationRationaleScreenV2), findsOneWidget);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tocka.skin': 'futurista'});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(c));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.byType(NotificationRationaleScreenFuturista), findsOneWidget);
  });
}
