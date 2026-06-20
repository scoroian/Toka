import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/skins/task_detail_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockTaskDetailViewModel extends Mock implements TaskDetailViewModel {}

Task _task({String? description}) => Task(
      id: 't1',
      homeId: 'home1',
      title: 'Barrer',
      description: description,
      visualKind: 'emoji',
      visualValue: '🧹',
      status: TaskStatus.active,
      recurrenceRule: const RecurrenceRule.daily(
        every: 1,
        time: '10:00',
        timezone: 'Europe/Madrid',
      ),
      assignmentMode: 'basicRotation',
      assignmentOrder: const ['u1'],
      currentAssigneeUid: 'u1',
      nextDueAt: DateTime(2026, 4, 14),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: 'u1',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

TaskDetailViewData _data({String? description}) => TaskDetailViewData(
      task: _task(description: description),
      canManage: true,
      currentAssigneeName: 'Ana',
      upcomingOccurrences: const [],
      difficultyWeight: 1.0,
    );

Widget _wrap(Widget child, TaskDetailViewModel vm) => ProviderScope(
      overrides: [
        taskDetailViewModelProvider('t1').overrideWith((_) => vm),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: child,
      ),
    );

void main() {
  late _MockTaskDetailViewModel vm;

  setUp(() {
    vm = _MockTaskDetailViewModel();
  });

  testWidgets('muestra loading spinner', (tester) async {
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
    await tester.pumpWidget(_wrap(const TaskDetailScreenV2(taskId: 't1'), vm));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('usa tipo abstracto TaskDetailViewModel', (tester) async {
    expect(vm, isA<TaskDetailViewModel>());
  });

  testWidgets('muestra la descripción de la tarea cuando existe', (tester) async {
    when(() => vm.viewData)
        .thenReturn(AsyncValue.data(_data(description: 'Mi descripción QA')));
    await tester.pumpWidget(_wrap(const TaskDetailScreenV2(taskId: 't1'), vm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_description')), findsOneWidget);
    expect(find.text('Mi descripción QA'), findsOneWidget);
  });

  testWidgets('no muestra bloque de descripción cuando está vacía',
      (tester) async {
    when(() => vm.viewData).thenReturn(AsyncValue.data(_data(description: null)));
    await tester.pumpWidget(_wrap(const TaskDetailScreenV2(taskId: 't1'), vm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_description')), findsNothing);
  });
}
