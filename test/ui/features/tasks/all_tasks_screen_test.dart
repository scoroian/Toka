import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';
import 'package:toka/features/tasks/presentation/all_tasks_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockTasksRepository extends Mock implements TasksRepository {}

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  _FakeCurrentHome(this._home);
  final Home? _home;
  @override
  Future<Home?> build() async => _home;
  @override
  Future<void> switchHome(String homeId) async {}
}

const _uid = 'uid1';
const _fakeUser = AuthUser(
  uid: _uid,
  email: 'u@u.com',
  displayName: 'User',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

Home _makeHome() => Home(
      id: 'h1',
      name: 'Casa',
      ownerUid: _uid,
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: HomePremiumStatus.free,
      premiumPlan: null,
      premiumEndsAt: null,
      restoreUntil: null,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 5),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

Task _makeTask(String id, {TaskStatus status = TaskStatus.active}) => Task(
      id: id,
      homeId: 'h1',
      title: 'Tarea $id',
      visualKind: 'emoji',
      visualValue: '🧹',
      status: status,
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '20:00', timezone: 'Europe/Madrid'),
      assignmentMode: 'basicRotation',
      assignmentOrder: const [_uid],
      currentAssigneeUid: _uid,
      nextDueAt: DateTime(2025, 6, 15, 20, 0),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: _uid,
      updatedAt: DateTime(2025, 6, 1),
      createdAt: DateTime(2025, 6, 1),
    );

HomeMembership _makeMembership(MemberRole role) => HomeMembership(
      homeId: 'h1',
      homeNameSnapshot: 'Casa',
      role: role,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
    );

Widget _wrap({
  required List<Task> tasks,
  MemberRole role = MemberRole.member,
  _MockTasksRepository? mockRepo,
}) {
  final repo = mockRepo ?? _MockTasksRepository();
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuth(
            const AuthState.authenticated(_fakeUser),
          )),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(_makeHome())),
      tasksRepositoryProvider.overrideWithValue(repo),
      homeTasksProvider('h1').overrideWith((ref) => Stream.value(tasks)),
      userMembershipsProvider(_uid)
          .overrideWith((ref) => Stream.value([_makeMembership(role)])),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es')],
      home: AllTasksScreen(),
    ),
  );
}

void main() {
  testWidgets('lista de tareas renderiza nombre e icono/emoji', (tester) async {
    await tester.pumpWidget(_wrap(tasks: [_makeTask('t1'), _makeTask('t2')]));
    await tester.pumpAndSettle();

    expect(find.text('Tarea t1'), findsOneWidget);
    expect(find.text('Tarea t2'), findsOneWidget);
    expect(find.text('🧹'), findsNWidgets(2));
  });

  testWidgets('FAB visible para admin', (tester) async {
    await tester.pumpWidget(_wrap(tasks: [], role: MemberRole.admin));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_task_fab')), findsOneWidget);
  });

  testWidgets('FAB NO visible para member', (tester) async {
    await tester.pumpWidget(_wrap(tasks: [], role: MemberRole.member));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_task_fab')), findsNothing);
  });

  testWidgets('estado vacío muestra mensaje', (tester) async {
    await tester.pumpWidget(_wrap(tasks: []));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tasks_empty_state')), findsOneWidget);
  });

  testWidgets('filtro por estado activo/congelado', (tester) async {
    final frozen = _makeTask('frozen', status: TaskStatus.frozen);
    final active = _makeTask('active');
    await tester.pumpWidget(_wrap(tasks: [active, frozen]));
    await tester.pumpAndSettle();

    // By default shows active tasks
    expect(find.text('Tarea active'), findsOneWidget);
    expect(find.text('Tarea frozen'), findsNothing);
  });
}
