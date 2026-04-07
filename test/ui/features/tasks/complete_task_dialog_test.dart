import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/complete_task_dialog.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

TaskPreview _task() => TaskPreview(
      taskId: 't1',
      title: 'Barrer',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: 'uid1',
      currentAssigneeName: 'Ana',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 6, 18, 0),
      isOverdue: false,
      status: 'active',
    );

void main() {
  testWidgets('muestra nombre e icono de la tarea', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => CompleteTaskDialog(task: _task(), onConfirm: () {}),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('🧹 Barrer'), findsOneWidget);
    expect(find.text('¿Confirmas que has completado esta tarea?'), findsOneWidget);
  });

  testWidgets('botón Cancelar cierra el diálogo', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => CompleteTaskDialog(task: _task(), onConfirm: () {}),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_cancel_complete')));
    await tester.pumpAndSettle();

    expect(find.byType(CompleteTaskDialog), findsNothing);
  });

  testWidgets('botón Sí hecha dispara onConfirm', (tester) async {
    bool confirmed = false;
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => CompleteTaskDialog(
            task: _task(),
            onConfirm: () => confirmed = true,
          ),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_confirm_complete')));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('golden: diálogo completar tarea', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => CompleteTaskDialog(task: _task(), onConfirm: () {}),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/complete_task_dialog.png'),
    );
  });
}
