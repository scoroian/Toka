import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/members/application/vacation_provider.dart';
import 'package:toka/features/members/presentation/vacation_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap() => ProviderScope(
      overrides: [
        memberVacationProvider(homeId: 'h1', uid: 'u1')
            .overrideWith((_) => Stream.value(null)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const VacationScreen(homeId: 'h1', uid: 'u1'),
      ),
    );

void main() {
  testWidgets('VacationScreen muestra toggle de vacaciones', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('Toggle activo muestra selectores de fecha', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    // Tap the switch to activate vacation mode
    await tester.tap(find.byKey(const Key('vacation_toggle')));
    await tester.pump();

    expect(find.byKey(const Key('vacation_date_pickers')), findsOneWidget);
  });
}
