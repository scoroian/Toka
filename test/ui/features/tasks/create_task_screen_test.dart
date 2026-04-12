import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:toka/features/tasks/presentation/create_edit_task_screen.dart';
import 'package:toka/features/tasks/presentation/widgets/assignment_form.dart';
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

final _fakeHome = Home(
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

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => _fakeHome;

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
  final router = GoRouter(
    initialLocation: '/tasks/new',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold()),
      GoRoute(
        path: '/tasks/new',
        builder: (_, __) => const CreateEditTaskScreen(),
      ),
    ],
  );
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
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
    ),
  );
}

/// Pumps until the widget tree is fully settled, including async providers
/// that need multiple event-loop turns to resolve (currentHomeProvider async
/// build → homeMembersProvider stream emission).
Future<void> _pumpUntilSettled(WidgetTester tester) async {
  // pumpWidget already ran; run pumpAndSettle once to drain microtasks
  // (currentHomeProvider.build() future resolves → AsyncData(_fakeHome)).
  await tester.pumpAndSettle();
  // One extra pump to process the Stream.value event that arrives after
  // homeMembersProvider is first subscribed in the frame above.
  await tester.pump();
  // Settle any resulting rebuilds.
  await tester.pumpAndSettle();
}

/// Sets a logical viewport large enough to avoid layout overflows in the
/// RecurrenceForm, which uses DropdownButtonFormField widgets that need space.
void _setLargeViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1080, 2400);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
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
    _setLargeViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(_wrap(mockRepo));
    await _pumpUntilSettled(tester);

    expect(find.byKey(const Key('assignee_checkbox_uid1')), findsOneWidget);
  });

  testWidgets(
      'guardar sin asignatarios muestra error de asignatarios',
      (tester) async {
    _setLargeViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(_wrap(mockRepo));
    await _pumpUntilSettled(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CreateEditTaskScreen)),
    );
    final formNotifier = container.read(taskFormNotifierProvider.notifier);

    // Set recurrence so validation proceeds past recurrence check.
    formNotifier.setRecurrenceRule(
      const RecurrenceRule.daily(
          every: 1, time: '09:00', timezone: 'Europe/Madrid'),
    );
    // Set a non-empty title so title check passes.
    formNotifier.setTitle('Limpiar');
    // Leave assignmentOrder empty (default []).
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    final formState = container.read(taskFormNotifierProvider);
    expect(formState.fieldErrors['assignees'], equals('tasks_validation_no_assignees'));
    expect(formState.fieldErrors['title'], isNull);
    expect(formState.fieldErrors['recurrence'], isNull);
  });

  testWidgets(
      'guardar sin título muestra error de título',
      (tester) async {
    _setLargeViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(_wrap(mockRepo));
    await _pumpUntilSettled(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CreateEditTaskScreen)),
    );
    final formNotifier = container.read(taskFormNotifierProvider.notifier);

    // Set recurrenceRule so that validation proceeds past recurrence check.
    formNotifier.setRecurrenceRule(
      const RecurrenceRule.daily(
          every: 1, time: '09:00', timezone: 'Europe/Madrid'),
    );
    // Add uid1 to assignmentOrder so assignees check passes too.
    formNotifier.setAssignmentOrder(['uid1']);
    // Leave title empty (default '').
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    final formState = container.read(taskFormNotifierProvider);
    expect(formState.fieldErrors['title'], equals('tasks_validation_title_empty'));
    expect(formState.fieldErrors['assignees'], isNull);
    expect(formState.fieldErrors['recurrence'], isNull);
  });

  testWidgets(
      'guardar con datos válidos llama a createTask',
      (tester) async {
    _setLargeViewport(tester);
    addTearDown(() => _resetViewport(tester));

    await tester.pumpWidget(_wrap(mockRepo));
    await _pumpUntilSettled(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CreateEditTaskScreen)),
    );
    final formNotifier = container.read(taskFormNotifierProvider.notifier);

    // Set all required fields.
    formNotifier.setRecurrenceRule(
      const RecurrenceRule.daily(
          every: 1, time: '09:00', timezone: 'Europe/Madrid'),
    );
    formNotifier.setAssignmentOrder(['uid1']);
    await tester.pump();

    await tester.enterText(
        find.byKey(const Key('task_title_field')), 'Limpiar cocina');
    await tester.pump();

    await tester.tap(find.byKey(const Key('save_task_button')).first);
    await tester.pumpAndSettle();

    verify(() => mockRepo.createTask('h1', any(), 'uid1')).called(1);
  });

  group('AssignmentForm — avatar e iniciales', () {
    testWidgets('muestra CircleAvatar con inicial del nickname', (tester) async {
      final member = Member(
        uid: 'uid1',
        homeId: 'h1',
        nickname: 'Ana García',
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

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: AssignmentForm(
            availableMembers: [member],
            selectedOrder: const [],
            onChanged: (_) {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Ana García'), findsOneWidget);
      expect(find.text('uid1'), findsNothing);
    });
  });
}
