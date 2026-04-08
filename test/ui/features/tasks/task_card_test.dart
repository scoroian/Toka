import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/widgets/task_card.dart';
import 'package:toka/l10n/app_localizations.dart';

Task _makeTask({
  String id = 't1',
  String title = 'Fregar platos',
  String visualKind = 'emoji',
  String visualValue = '🧹',
  TaskStatus status = TaskStatus.active,
}) =>
    Task(
      id: id,
      homeId: 'h1',
      title: title,
      visualKind: visualKind,
      visualValue: visualValue,
      status: status,
      recurrenceRule: const RecurrenceRule.daily(
        every: 1,
        time: '20:00',
        timezone: 'Europe/Madrid',
      ),
      assignmentMode: 'basicRotation',
      assignmentOrder: const ['uid1'],
      currentAssigneeUid: 'uid1',
      nextDueAt: DateTime(2025, 6, 15, 20, 0),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: 'uid1',
      createdAt: DateTime(2025, 6, 1),
      updatedAt: DateTime(2025, 6, 1),
    );

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  testWidgets('muestra el título de la tarea', (tester) async {
    await tester.pumpWidget(_wrap(
      TaskCard(task: _makeTask(), onTap: () {}),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Fregar platos'), findsOneWidget);
  });

  testWidgets('muestra el emoji de la tarea', (tester) async {
    await tester.pumpWidget(_wrap(
      TaskCard(task: _makeTask(), onTap: () {}),
    ));
    await tester.pumpAndSettle();

    expect(find.text('🧹'), findsOneWidget);
  });

  testWidgets('tarea congelada muestra lineThrough en el título', (tester) async {
    await tester.pumpWidget(_wrap(
      TaskCard(task: _makeTask(status: TaskStatus.frozen), onTap: () {}),
    ));
    await tester.pumpAndSettle();

    final titleWidget = tester.widget<Text>(find.text('Fregar platos'));
    expect(titleWidget.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('tarea activa NO muestra lineThrough en el título', (tester) async {
    await tester.pumpWidget(_wrap(
      TaskCard(task: _makeTask(status: TaskStatus.active), onTap: () {}),
    ));
    await tester.pumpAndSettle();

    final titleWidget = tester.widget<Text>(find.text('Fregar platos'));
    expect(titleWidget.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('el callback onTap se invoca al pulsar', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      TaskCard(task: _makeTask(), onTap: () => tapped = true),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
