// Widget test del manejo de FALLOS del commit diferido (Hallazgo #02).
//
// Al expirar la ventana de Deshacer se confirma el commit. Si falla:
//   - transient (red): SnackBar de error con "Reintentar" + la tarjeta vuelve a
//     ser visible con marca persistente "No se guardó" (no en silencio).
//   - conflict (carrera de turno): SnackBar informativo SIN "Reintentar".
// El caso de éxito NO muestra ningún aviso de error.
import 'package:cloud_functions/cloud_functions.dart';
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
import 'package:toka/l10n/app_localizations.dart';

class _MockTodayViewModel extends Mock implements TodayViewModel {}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

/// Fake del notifier de completación: registra cada `taskId` y lanza el error
/// devuelto por [errorFor] (índice de llamada 0-based) o tiene éxito si null.
class _FakeTaskCompletion extends TaskCompletion {
  _FakeTaskCompletion(this.calls, {this.errorFor});
  final List<String> calls;
  final Object? Function(int callIndex)? errorFor;
  @override
  AsyncValue<void> build() => const AsyncValue<void>.data(null);
  @override
  Future<void> completeTask(String homeId, String taskId,
      {String? completionId}) async {
    final idx = calls.length;
    calls.add(taskId);
    final err = errorFor?.call(idx);
    if (err != null) throw err;
  }
}

FirebaseFunctionsException _ffx(String code) =>
    FirebaseFunctionsException(message: code, code: code);

TodayViewData _dataWithOneOwnTask() {
  final task = TaskPreview(
    taskId: 't1',
    title: 'Barrer',
    visualKind: 'emoji',
    visualValue: '🧹',
    recurrenceType: 'daily',
    currentAssigneeUid: 'uid1',
    currentAssigneeName: 'Yo',
    currentAssigneePhoto: null,
    nextDueAt: DateTime(2020, 1, 1),
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
  late List<String> calls;

  ProviderContainer makeContainer({Object? Function(int)? errorFor}) {
    calls = [];
    final c = ProviderContainer(overrides: [
      todayViewModelProvider.overrideWith((_) => vm),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      taskCompletionProvider
          .overrideWith(() => _FakeTaskCompletion(calls, errorFor: errorFor)),
      userProfileProvider('uid1')
          .overrideWith((ref) => const Stream<UserProfile>.empty()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    vm = _MockTodayViewModel();
    when(() => vm.homes).thenReturn(const []);
    when(() => vm.viewData).thenReturn(AsyncValue.data(_dataWithOneOwnTask()));
  });

  Future<void> pumpScreen(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: _app(const TodayScreenV2()),
    ));
    await tester.pump();
  }

  Future<void> tapDone(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('btn_done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  // Avanza más allá de la ventana (10s) y deja resolver el commit asíncrono.
  Future<void> expireWindow(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 11));
    await tester.pump(); // resolver el Future del commit
    await tester.pump(); // construir el SnackBar de error
  }

  testWidgets('fallo transitorio → SnackBar de error con Reintentar + marca en la tarjeta',
      (tester) async {
    final c = makeContainer(errorFor: (_) => _ffx('unavailable'));
    await pumpScreen(tester, c);

    await tapDone(tester);
    await expireWindow(tester);

    expect(find.textContaining('No se pudo completar'), findsOneWidget);
    // El SnackBar ofrece Reintentar (la tarjeta también tiene su botón, de ahí
    // que acotemos al SnackBar).
    expect(
      find.descendant(
          of: find.byType(SnackBar), matching: find.text('Reintentar')),
      findsOneWidget,
    );
    expect(c.read(pendingCompletionsProvider).failed.containsKey('t1'), isTrue);

    // Marca persistente en la tarjeta (la tarea vuelve a ser visible).
    expect(find.byKey(const Key('btn_retry_completion')), findsOneWidget);
    expect(find.text('No se guardó'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('fallo por conflicto → SnackBar informativo SIN Reintentar',
      (tester) async {
    final c = makeContainer(errorFor: (_) => _ffx('permission-denied'));
    await pumpScreen(tester, c);

    await tapDone(tester);
    await expireWindow(tester);

    expect(find.textContaining('ya fue completada o actualizada'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing,
        reason: 'reintentar un conflicto no sirve');

    await tester.pumpAndSettle();
  });

  testWidgets('éxito NO muestra ningún aviso de error', (tester) async {
    final c = makeContainer(); // sin error
    await pumpScreen(tester, c);

    await tapDone(tester);
    await expireWindow(tester);

    expect(find.textContaining('No se pudo completar'), findsNothing);
    expect(find.byKey(const Key('btn_retry_completion')), findsNothing);
    expect(calls, ['t1']);

    await tester.pumpAndSettle();
  });

  testWidgets('el SnackBar de error es persist:false y desaparece', (tester) async {
    final c = makeContainer(errorFor: (_) => _ffx('unavailable'));
    await pumpScreen(tester, c);

    await tapDone(tester);
    await expireWindow(tester);
    expect(find.textContaining('No se pudo completar'), findsOneWidget);

    // Superar la duración del SnackBar y drenar la animación de salida.
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo completar'), findsNothing,
        reason: 'el SnackBar de error debe auto-cerrarse (bug Flutter 3.44)');
  });

  testWidgets('Reintentar desde la tarjeta vuelve a llamar al backend',
      (tester) async {
    // Falla la 1.ª vez (idx 0), éxito la 2.ª (idx 1).
    final c = makeContainer(errorFor: (i) => i == 0 ? _ffx('unavailable') : null);
    await pumpScreen(tester, c);

    await tapDone(tester);
    await expireWindow(tester);
    expect(find.byKey(const Key('btn_retry_completion')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_retry_completion')));
    await tester.pump();
    await tester.pump();

    expect(calls, ['t1', 't1'], reason: 'se reintentó el commit');
    expect(c.read(pendingCompletionsProvider).failed, isEmpty);

    await tester.pumpAndSettle();
  });
}
