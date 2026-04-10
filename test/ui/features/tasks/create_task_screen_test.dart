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
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';
import 'package:toka/features/tasks/presentation/create_edit_task_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockTasksRepository extends Mock implements TasksRepository {}

class _FakeAuth extends Auth {
  _FakeAuth();
  @override
  AuthState build() => const AuthState.authenticated(AuthUser(
      uid: 'uid1',
      email: 'u@u.com',
      displayName: 'User',
      photoUrl: null,
      emailVerified: true,
      providers: []));
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
        id: 'h1',
        name: 'Casa',
        ownerUid: 'uid1',
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
  @override
  Future<void> switchHome(String homeId) async {}
}

Widget _wrap(_MockTasksRepository repo) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      tasksRepositoryProvider.overrideWithValue(repo),
      homeMembersProvider('h1').overrideWith(
        (ref) => Stream.value([]),
      ),
      userMembershipsProvider('uid1').overrideWith((ref) => Stream.value([
            HomeMembership(
              homeId: 'h1',
              homeNameSnapshot: 'Casa',
              role: MemberRole.admin,
              billingState: BillingState.none,
              status: MemberStatus.active,
              joinedAt: DateTime(2024),
            ),
          ])),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es')],
      home: CreateEditTaskScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const TaskInput(
      title: 'test',
      visualKind: 'emoji',
      visualValue: '🏠',
      recurrenceRule:
          RecurrenceRule.daily(every: 1, time: '20:00', timezone: 'Europe/Madrid'),
      assignmentMode: 'basicRotation',
      assignmentOrder: ['uid1'],
    ));
  });

  late _MockTasksRepository mockRepo;

  setUp(() {
    mockRepo = _MockTasksRepository();
    when(() => mockRepo.watchHomeTasks('h1'))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockRepo.createTask(any(), any(), any()))
        .thenAnswer((_) async => 'new-task-id');
  });

  testWidgets('pantalla muestra campo título', (tester) async {
    await tester.pumpWidget(_wrap(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task_title_field')), findsOneWidget);
  });

  testWidgets('pantalla muestra formulario de recurrencia', (tester) async {
    await tester.pumpWidget(_wrap(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recurrence_form')), findsOneWidget);
  });

  testWidgets('pantalla muestra botón guardar', (tester) async {
    await tester.pumpWidget(_wrap(mockRepo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save_task_button')), findsOneWidget);
  });

  testWidgets('título del AppBar es Crear tarea para nueva tarea',
      (tester) async {
    await tester.pumpWidget(_wrap(mockRepo));
    await tester.pumpAndSettle();

    expect(find.text('Crear tarea'), findsOneWidget);
  });
}
