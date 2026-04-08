import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/task_detail_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fake TaskDetailViewModel implementations
// ---------------------------------------------------------------------------

class _LoadingViewModel implements TaskDetailViewModel {
  @override
  AsyncValue<TaskDetailViewData?> get viewData => const AsyncLoading();
}

class _DataViewModel implements TaskDetailViewModel {
  _DataViewModel(this._data);
  final TaskDetailViewData? _data;

  @override
  AsyncValue<TaskDetailViewData?> get viewData => AsyncData(_data);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kTaskId = 'task-1';

Task _makeTask({
  String title = 'Limpiar cocina',
  String visualKind = 'emoji',
  String visualValue = '🧹',
}) =>
    Task(
      id: _kTaskId,
      homeId: 'h1',
      title: title,
      visualKind: visualKind,
      visualValue: visualValue,
      status: TaskStatus.active,
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

Widget _wrap(TaskDetailViewModel fakeVm) {
  return ProviderScope(
    overrides: [
      taskDetailViewModelProvider(_kTaskId).overrideWith((_) => fakeVm),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es')],
      home: TaskDetailScreen(taskId: _kTaskId),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('muestra CircularProgressIndicator cuando viewData está cargando',
      (tester) async {
    await tester.pumpWidget(_wrap(_LoadingViewModel()));
    // No pumpAndSettle — loading state should be visible immediately
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra el título de la tarea cuando los datos están disponibles',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: false,
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('Limpiar cocina'), findsWidgets);
  });

  testWidgets('muestra el emoji de la tarea cuando los datos están disponibles',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: false,
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('🧹'), findsOneWidget);
  });

  testWidgets('muestra el botón de edición cuando canEdit es true',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: true,
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_task_button')), findsOneWidget);
  });

  testWidgets('NO muestra el botón de edición cuando canEdit es false',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canEdit: false,
      upcomingOccurrences: [],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_task_button')), findsNothing);
  });

  testWidgets('no falla cuando viewData es null', (tester) async {
    final vm = _DataViewModel(null);
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    // Should show some error/empty Text widgets without crashing
    expect(find.byType(Text), findsWidgets);
  });
}
