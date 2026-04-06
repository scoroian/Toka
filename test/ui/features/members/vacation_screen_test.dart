import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/members/application/vacation_provider.dart';
import 'package:toka/features/members/domain/vacation.dart';
import 'package:toka/features/members/presentation/vacation_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

void main() {
  testWidgets('VacationScreen muestra toggle de vacaciones', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberVacationProvider(homeId: 'h1', uid: 'u1')
              .overrideWith((_) => Stream.value(null)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VacationScreen(homeId: 'h1', uid: 'u1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('Toggle activo muestra selectores de fecha', (tester) async {
    final activeVacation = Vacation(
      uid: 'u1',
      homeId: 'h1',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberVacationProvider(homeId: 'h1', uid: 'u1')
              .overrideWith((_) => Stream.value(activeVacation)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VacationScreen(homeId: 'h1', uid: 'u1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vacation_date_pickers')), findsOneWidget);
  });
}
