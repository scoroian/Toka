// UI test del NUEVO flujo de completar (Hallazgo #20): tocar "Hecho" ya NO abre
// un diálogo de confirmación; completa de forma optimista y ofrece "Deshacer"
// en un SnackBar durante la ventana (patrón Gmail). Si no se deshace, el commit
// real al backend se confirma al expirar; si se deshace, el backend nunca se
// toca.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/profile/application/profile_provider.dart';
import 'package:toka/features/profile/domain/user_profile.dart';
import 'package:toka/features/tasks/application/pending_completions_provider.dart';
import 'package:toka/features/tasks/application/task_completion_provider.dart';
import 'package:toka/features/tasks/application/today_view_model.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/skins/today_screen_v2.dart';
import 'package:toka/features/tasks/presentation/widgets/complete_task_dialog.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockTodayViewModel extends Mock implements TodayViewModel {}

// Auth/CurrentHome reales arrancan timers (refresco periódico) que quedarían
// pendientes al cerrar el test; los falseamos para aislar la pantalla.
class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

/// Registra las completaciones reales en una lista externa (sin Firebase).
class _FakeTaskCompletion extends TaskCompletion {
  _FakeTaskCompletion(this.calls);
  final List<(String homeId, String taskId)> calls;
  @override
  AsyncValue<void> build() => const AsyncValue<void>.data(null);
  @override
  Future<void> completeTask(String homeId, String taskId,
      {String? completionId}) async {
    calls.add((homeId, taskId));
  }
}

TodayViewData _dataWithOneOwnTask() {
  final task = TaskPreview(
    taskId: 't1',
    title: 'Barrer',
    visualKind: 'emoji',
    visualValue: '🧹',
    recurrenceType: 'daily',
    currentAssigneeUid: 'uid1', // == currentUid → muestra botones Hecho/Pasar
    currentAssigneeName: 'Yo',
    currentAssigneePhoto: null,
    nextDueAt: DateTime(2020, 1, 1), // vencida → siempre actionable
    isOverdue: true,
    isDueToday: false,
    status: 'active',
  );
  return TodayViewData(
    grouped: <String, RecurrenceGroup>{
      'daily': (
        todos: [task],
        upcoming: const <TaskPreview>[],
        dones: const <DoneTaskPreview>[]
      ),
    },
    counters: const DashboardCounters(
      totalActiveTasks: 1,
      totalMembers: 1,
      tasksDueToday: 1,
      tasksDoneToday: 0,
    ),
    showAdBanner: false,
    adBannerUnit: '',
    currentUid: 'uid1',
    homeId: 'home1',
    recurrenceOrder: const ['daily'],
  );
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: child,
    );

void main() {
  late _MockTodayViewModel vm;
  late List<(String, String)> calls;
  late ProviderContainer container;

  setUp(() {
    vm = _MockTodayViewModel();
    calls = [];
    when(() => vm.homes).thenReturn(const []);
    when(() => vm.viewData)
        .thenReturn(AsyncValue.data(_dataWithOneOwnTask()));
    container = ProviderContainer(overrides: [
      todayViewModelProvider.overrideWith((_) => vm),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      taskCompletionProvider.overrideWith(() => _FakeTaskCompletion(calls)),
      userProfileProvider('uid1')
          .overrideWith((ref) => const Stream<UserProfile>.empty()),
    ]);
    addTearDown(container.dispose);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(const TodayScreenV2()),
      ),
    );
    await tester.pump();
  }

  Future<void> tapDone(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('btn_done')));
    // El primer frame fija la línea base del ticker; el segundo (con duración)
    // avanza la animación de "check" (350ms) hasta completarla → dispara onDone.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(); // construir el SnackBar
  }

  // Drena los timers en vuelo (ventana de 10s + SnackBar) para cerrar limpio.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
  }

  testWidgets('tocar Hecho NO abre diálogo y muestra SnackBar con Deshacer',
      (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(const Key('btn_done')), findsOneWidget);

    await tapDone(tester);

    expect(find.byType(CompleteTaskDialog), findsNothing,
        reason: 'el diálogo de confirmación se eliminó');
    expect(find.text('Tarea completada'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);
    expect(container.read(pendingCompletionsProvider).pending, contains('t1'),
        reason: 'completación optimista pendiente');
    expect(calls, isEmpty, reason: 'el commit real está diferido');

    await drain(tester);
  });

  testWidgets('el SnackBar se auto-cierra al expirar la ventana (no persiste)',
      (tester) async {
    // Regresión: un SnackBar con acción tiene persist=true por defecto
    // (Flutter 3.44) → el timer de duración NO lo cierra y se queda fijo. Debe
    // llevar persist:false para desaparecer a los 10s.
    await pumpScreen(tester);
    await tapDone(tester);
    expect(find.text('Tarea completada'), findsOneWidget);

    // Superar kUndoWindow (10s) con margen (la animación de la tarjeta retrasa
    // el arranque del SnackBar) + drenar la animación de salida.
    await tester.pump(const Duration(seconds: 13));
    await tester.pumpAndSettle();

    expect(find.text('Tarea completada'), findsNothing,
        reason: 'el SnackBar debe auto-cerrarse, no quedarse fijo');
  });

  testWidgets('Deshacer cancela el commit: el backend nunca se llama',
      (tester) async {
    await pumpScreen(tester);
    await tapDone(tester);

    // Esperar a que el SnackBar termine de entrar (deja de ser IgnorePointer)
    // para que su acción sea pulsable, sin llegar al fin de la ventana (10s).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Deshacer'));
    await tester.pump();

    expect(container.read(pendingCompletionsProvider).pending, isNot(contains('t1')));

    await tester.pump(const Duration(seconds: 11));
    expect(calls, isEmpty, reason: 'deshacer = sin escritura en backend');
    await tester.pumpAndSettle();
  });

  testWidgets('sin Deshacer, al expirar la ventana se confirma el commit real',
      (tester) async {
    await pumpScreen(tester);
    await tapDone(tester);

    await tester.pump(const Duration(seconds: 11)); // supera kUndoWindow (10s)

    expect(calls, [('home1', 't1')]);
    expect(container.read(pendingCompletionsProvider).pending, isNot(contains('t1')));
    await tester.pumpAndSettle();
  });
}
