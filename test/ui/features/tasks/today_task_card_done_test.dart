import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/today_task_card_done.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  testWidgets('golden: card Hecha', (tester) async {
    final task = DoneTaskPreview(
      taskId: 'd1',
      title: 'Fregar platos',
      visualKind: 'emoji',
      visualValue: '🍽️',
      recurrenceType: 'daily',
      completedByUid: 'uid1',
      completedByName: 'Carlos',
      completedByPhoto: null,
      completedAt: DateTime(2026, 4, 6, 9, 30),
    );

    await tester.pumpWidget(_wrap(TodayTaskCardDone(task: task)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_done.png'),
    );
  });

  testWidgets('muestra nombre del completado y la hora', (tester) async {
    final task = DoneTaskPreview(
      taskId: 'd2',
      title: 'Sacar basura',
      visualKind: 'emoji',
      visualValue: '🗑️',
      recurrenceType: 'weekly',
      completedByUid: 'uid2',
      completedByName: 'María',
      completedByPhoto: null,
      completedAt: DateTime(2026, 4, 6, 14, 45),
    );

    await tester.pumpWidget(_wrap(TodayTaskCardDone(task: task)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('done_by_label')), findsOneWidget);
    expect(find.textContaining('María'), findsOneWidget);
    expect(find.textContaining('14:45'), findsOneWidget);
  });
}
