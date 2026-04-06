import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/today_task_card_todo.dart';
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

TaskPreview _makeTask({
  String uid = 'uid1',
  bool isOverdue = false,
}) =>
    TaskPreview(
      taskId: 't1',
      title: 'Barrer la cocina',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: uid,
      currentAssigneeName: 'Ana',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 6, 18, 0),
      isOverdue: isOverdue,
      status: 'active',
    );

void main() {
  testWidgets('golden: card Por hacer con botones visibles', (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(uid: 'uid1'),
        currentUid: 'uid1',
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_with_buttons.png'),
    );
  });

  testWidgets('golden: card Por hacer sin botones (otro responsable)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(uid: 'uid2'),
        currentUid: 'uid1',
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_no_buttons.png'),
    );
  });

  testWidgets('golden: card vencida', (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(isOverdue: true),
        currentUid: null,
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_overdue.png'),
    );
  });
}
