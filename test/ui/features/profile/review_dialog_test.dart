// test/ui/features/profile/review_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/presentation/widgets/review_dialog.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('ReviewDialog muestra slider 1-10', (tester) async {
    await tester.pumpWidget(_wrap(
      ReviewDialog(
        homeId: 'h1',
        taskEventId: 'e1',
        taskTitle: 'Fregar',
        performerName: 'Ana',
        isPremium: true,
        currentUid: 'u1',
        performerUid: 'u2',
        onSubmitted: () {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 1);
    expect(slider.max, 10);
  });

  testWidgets('ReviewDialog no aparece para el propio ejecutor', (tester) async {
    await tester.pumpWidget(_wrap(
      ReviewDialog(
        homeId: 'h1',
        taskEventId: 'e1',
        taskTitle: 'Fregar',
        performerName: 'Yo',
        isPremium: true,
        currentUid: 'u1',
        performerUid: 'u1',
        onSubmitted: () {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('btn_submit_review')), findsNothing);
    expect(find.byKey(const Key('self_review_message')), findsOneWidget);
  });

  testWidgets('En plan Free muestra mensaje de upgrade', (tester) async {
    await tester.pumpWidget(_wrap(
      ReviewDialog(
        homeId: 'h1',
        taskEventId: 'e1',
        taskTitle: 'Fregar',
        performerName: 'Ana',
        isPremium: false,
        currentUid: 'u1',
        performerUid: 'u2',
        onSubmitted: () {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('premium_gate_overlay')), findsOneWidget);
  });

  testWidgets('golden: ReviewDialog con slider', (tester) async {
    await tester.pumpWidget(_wrap(
      ReviewDialog(
        homeId: 'h1',
        taskEventId: 'e1',
        taskTitle: 'Fregar',
        performerName: 'Ana',
        isPremium: true,
        currentUid: 'u1',
        performerUid: 'u2',
        onSubmitted: () {},
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ReviewDialog),
      matchesGoldenFile('goldens/review_dialog.png'),
    );
  });
}
