import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/today_task_card_todo.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(body: child),
      ),
    );

TaskPreview _makeTask({
  String? currentAssigneeUid,
  bool isOverdue = false,
  DateTime? nextDueAt,
}) =>
    TaskPreview(
      taskId: 't1',
      title: 'Barrer',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: currentAssigneeUid,
      currentAssigneeName: currentAssigneeUid != null ? 'Ana' : null,
      currentAssigneePhoto: null,
      nextDueAt: nextDueAt ?? DateTime(2026, 4, 6, 20, 0),
      isOverdue: isOverdue,
      status: 'active',
    );

void main() {
  group('TodayTaskCardTodo — botones de acción', () {
    testWidgets('muestra botones si currentAssigneeUid == currentUid',
        (tester) async {
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(currentAssigneeUid: 'uid1'),
          currentUid: 'uid1',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsOneWidget);
      expect(find.byKey(const Key('btn_pass')), findsOneWidget);
    });

    testWidgets('no muestra botones si currentAssigneeUid != currentUid',
        (tester) async {
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(currentAssigneeUid: 'uid2'),
          currentUid: 'uid1',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsNothing);
      expect(find.byKey(const Key('btn_pass')), findsNothing);
    });

    testWidgets('no muestra botones si currentUid es null', (tester) async {
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(currentAssigneeUid: 'uid1'),
          currentUid: null,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_done')), findsNothing);
      expect(find.byKey(const Key('btn_pass')), findsNothing);
    });

    testWidgets('chip muestra "Vencida" si isOverdue == true', (tester) async {
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(isOverdue: true),
          currentUid: null,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vencida'), findsOneWidget);
    });

    testWidgets('chip muestra "Hoy HH:mm" si vence hoy', (tester) async {
      final today = DateTime(2026, 4, 6, 20, 0);
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(nextDueAt: today),
          currentUid: null,
          now: DateTime(2026, 4, 6, 10, 0),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hoy 20:00'), findsOneWidget);
    });

    testWidgets('chip muestra hora si vence otra fecha', (tester) async {
      final nextWeek = DateTime(2026, 4, 7, 15, 30);
      await tester.pumpWidget(
        _wrap(TodayTaskCardTodo(
          task: _makeTask(nextDueAt: nextWeek),
          currentUid: null,
          now: DateTime(2026, 4, 6, 10, 0),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('15:30'), findsOneWidget);
    });
  });
}
