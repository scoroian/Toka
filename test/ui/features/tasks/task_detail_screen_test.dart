// test/ui/features/tasks/task_detail_screen_test.dart
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
import 'package:toka/shared/widgets/loading_widget.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _LoadingViewModel implements TaskDetailViewModel {
  @override
  AsyncValue<TaskDetailViewData?> get viewData => const AsyncLoading();
  @override
  Future<void> toggleFreeze(Task task) async {}
  @override
  Future<void> deleteTask(Task task) async {}
}

class _DataViewModel implements TaskDetailViewModel {
  _DataViewModel(this._data);
  final TaskDetailViewData? _data;

  @override
  AsyncValue<TaskDetailViewData?> get viewData => AsyncData(_data);
  @override
  Future<void> toggleFreeze(Task task) async {}
  @override
  Future<void> deleteTask(Task task) async {}
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
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra el título de la tarea cuando los datos están disponibles',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [],
      difficultyWeight: 1.0,
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('Limpiar cocina'), findsWidgets);
  });

  testWidgets('muestra el emoji de la tarea cuando los datos están disponibles',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [],
      difficultyWeight: 1.0,
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('🧹'), findsOneWidget);
  });

  testWidgets('muestra el botón de edición cuando canManage es true',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: true,
      currentAssigneeName: null,
      upcomingOccurrences: [],
      difficultyWeight: 1.0,
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_task_button')), findsOneWidget);
  });

  testWidgets('NO muestra el botón de edición cuando canManage es false',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [],
      difficultyWeight: 1.0,
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit_task_button')), findsNothing);
  });

  testWidgets(
      'muestra el nombre del asignado cuando currentAssigneeName no es null',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: 'Ana García',
      upcomingOccurrences: [],
      difficultyWeight: 1.0,
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('Ana García'), findsOneWidget);
  });

  testWidgets(
      'muestra guión cuando currentAssigneeName es null — nunca el UID',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [],
      difficultyWeight: 1.0,
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(find.text('uid1'), findsNothing);
  });

  testWidgets('muestra LoadingWidget cuando viewData es null',
      (tester) async {
    final vm = _DataViewModel(null);
    await tester.pumpWidget(_wrap(vm));
    await tester.pump();

    expect(find.byType(LoadingWidget), findsOneWidget);
  });

  testWidgets('próxima ocurrencia muestra el nombre del asignado',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [
        UpcomingOccurrence(date: DateTime(2025, 7, 1, 20, 0), assigneeName: 'Paco'),
      ],
      difficultyWeight: 1.0,
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('occurrence_tile_0')),
    );
    expect(tile.trailing, isA<Text>());
    expect((tile.trailing as Text).data, 'Paco');
  });

  testWidgets('próxima ocurrencia sin asignado no muestra texto trailing',
      (tester) async {
    final occDate = DateTime(2025, 7, 1, 20, 0);
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [
        UpcomingOccurrence(date: occDate, assigneeName: null),
      ],
      difficultyWeight: 1.0,
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.byKey(const Key('occurrence_tile_0')),
    );
    expect(tile.trailing, isNull);
  });
}
