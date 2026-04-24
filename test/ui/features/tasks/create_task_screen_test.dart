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
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/tasks/application/task_form_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';
import 'package:toka/features/tasks/presentation/skins/create_edit_task_screen_v2.dart';
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

final _testMember = Member(
  uid: 'uid1',
  homeId: 'h1',
  nickname: 'Test User',
  photoUrl: null,
  bio: null,
  phone: null,
  phoneVisibility: 'hidden',
  role: MemberRole.owner,
  status: MemberStatus.active,
  joinedAt: DateTime(2024),
  tasksCompleted: 0,
  passedCount: 0,
  complianceRate: 1.0,
  currentStreak: 0,
  averageScore: 0.0,
);

Widget _wrap(_MockTasksRepository repo) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      tasksRepositoryProvider.overrideWithValue(repo),
      homeMembersProvider('h1').overrideWith(
        (ref) => Stream.value([_testMember]),
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
      home: CreateEditTaskScreenV2(),
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

  testWidgets('AssignmentForm muestra checkbox para cada miembro del hogar',
      (tester) async {
    await tester.pumpWidget(_wrap(mockRepo));
    await tester.pumpAndSettle();
    // Stream.value emits asynchronously; pump once more to let the stream
    // value arrive and trigger the final widget rebuild.
    await tester.pump();

    expect(find.byKey(const Key('assignee_checkbox_uid1')), findsOneWidget);
  });

  testWidgets('guardar sin seleccionar asignado muestra error de asignados',
      (tester) async {
    await tester.pumpWidget(_wrap(mockRepo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('task_title_field')), 'Mi tarea');
    await tester.pump();

    // No tap on checkbox — assignmentOrder stays []
    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('task_title_field'))));
    expect(find.text(l10n.tasks_validation_no_assignees), findsOneWidget);
  });

  testWidgets('guardar sin título muestra error de título vacío', (tester) async {
    // Enlarge viewport so the AssignmentForm is visible without scrolling.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(mockRepo));
    await tester.pumpAndSettle();

    // Force the recurrence rule so the form passes the recurrence check.
    // The real RecurrenceForm sets this via addPostFrameCallback, but that
    // callback fires before the initCreate() microtask which then resets it.
    final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('task_title_field'))));
    container
        .read(taskFormNotifierProvider.notifier)
        .setRecurrenceRule(const RecurrenceRule.daily(
          every: 1,
          time: '09:00',
          timezone: 'Europe/Madrid',
        ));
    await tester.pump();

    // Select the assignee checkbox (visible in the large viewport)
    await tester.tap(find.byKey(const Key('assignee_checkbox_uid1')).first);
    await tester.pump();

    // No title entered (defaults to empty)
    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('task_title_field'))));
    expect(find.text(l10n.tasks_validation_title_empty), findsOneWidget);
  });

  testWidgets('guardar con datos válidos llama a createTask del repositorio',
      (tester) async {
    // Enlarge viewport so the AssignmentForm is visible without scrolling.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(mockRepo));
    await tester.pumpAndSettle();

    // Force the recurrence rule so the form passes the recurrence check.
    final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('task_title_field'))));
    container
        .read(taskFormNotifierProvider.notifier)
        .setRecurrenceRule(const RecurrenceRule.daily(
          every: 1,
          time: '09:00',
          timezone: 'Europe/Madrid',
        ));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('task_title_field')), 'Tarea test');
    await tester.pump();

    await tester.tap(find.byKey(const Key('assignee_checkbox_uid1')).first);
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    verify(() => mockRepo.createTask('h1', any(), 'uid1')).called(1);
  });
}
