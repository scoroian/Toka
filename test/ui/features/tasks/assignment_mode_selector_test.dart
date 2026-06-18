// UI del selector "Modo de asignación" (rotación básica vs distribución
// inteligente) en Crear/Editar tarea — fix QA §8.
//
// Cubre:
//  - Premium + ≥2 miembros: se puede seleccionar "Distribución inteligente" y
//    se persiste assignmentMode = smartDistribution.
//  - Free + ≥2 miembros: la opción smart está bloqueada → al pulsarla se abre
//    el paywall y el modo NO cambia (sigue basicRotation).
//  - <2 miembros asignados: el selector queda deshabilitado con el aviso de
//    "requiere al menos 2 miembros".
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/tasks/application/task_form_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';
import 'package:toka/features/tasks/presentation/skins/create_edit_task_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockTasksRepository extends Mock implements TasksRepository {}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.authenticated(AuthUser(
        uid: 'uid1',
        email: 'u@u.com',
        displayName: 'User',
        photoUrl: null,
        emailVerified: true,
        providers: [],
      ));
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

Member _member(String uid, String nick) => Member(
      uid: uid,
      homeId: 'h1',
      nickname: nick,
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

HomeDashboard _dashboard({required bool premium}) => HomeDashboard(
      activeTasksPreview: const [],
      doneTasksPreview: const [],
      counters: DashboardCounters.empty(),
      planCounters: const PlanCounters(
        activeMembers: 2,
        activeTasks: 0,
        automaticRecurringTasks: 0,
        totalAdmins: 1,
      ),
      memberPreview: const [],
      premiumFlags: premium
          ? const PremiumFlags(
              isPremium: true,
              showAds: false,
              canUseSmartDistribution: true,
              canUseVacations: true,
              canUseReviews: true,
            )
          : PremiumFlags.free(),
      adFlags: AdFlags.empty(),
      rescueFlags: RescueFlags.empty(),
      updatedAt: DateTime(2026),
    );

const _paywallMarker = 'PAYWALL_SCREEN_MARKER';

Widget _wrap(
  _MockTasksRepository repo, {
  required bool premium,
  required List<Member> members,
}) {
  final router = GoRouter(
    initialLocation: '/create',
    routes: [
      GoRoute(
        path: '/create',
        builder: (_, __) => const CreateEditTaskScreenV2(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text(_paywallMarker))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
      tasksRepositoryProvider.overrideWithValue(repo),
      homeMembersProvider('h1').overrideWith((ref) => Stream.value(members)),
      dashboardProvider
          .overrideWith((ref) => Stream.value(_dashboard(premium: premium))),
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

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(
        tester.element(find.byKey(const Key('task_title_field'))));

void main() {
  setUpAll(() {
    // upcomingDates del VM usa tz.getLocation(); sin la base de datos de
    // timezones inicializada lanza UninitializedTimezoneException al construir.
    tzdata.initializeTimeZones();
    registerFallbackValue(const TaskInput(
      title: 'test',
      visualKind: 'emoji',
      visualValue: '🏠',
      recurrenceRule: RecurrenceRule.daily(
          every: 1, time: '20:00', timezone: 'Europe/Madrid'),
      assignmentMode: 'basicRotation',
      assignmentOrder: ['uid1'],
    ));
  });

  late _MockTasksRepository repo;

  setUp(() {
    repo = _MockTasksRepository();
    when(() => repo.watchHomeTasks('h1')).thenAnswer((_) => Stream.value([]));
    when(() => repo.createTask(any(), any(), any()))
        .thenAnswer((_) async => 'new-task-id');
  });

  // Viewport amplio para que el selector (al fondo del ListView) sea visible.
  void enlarge(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('con <2 miembros asignados el selector está deshabilitado',
      (tester) async {
    enlarge(tester);
    await tester.pumpWidget(_wrap(repo,
        premium: true,
        members: [_member('uid1', 'Ana'), _member('uid2', 'Bea')]));
    await tester.pumpAndSettle();

    // Solo 1 miembro asignado.
    _containerOf(tester)
        .read(taskFormNotifierProvider.notifier)
        .setAssignmentOrder(['uid1']);
    await tester.pump();

    expect(find.byKey(const Key('assignment_mode_selector')), findsOneWidget);
    final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('task_title_field'))));
    // El hint del selector de modo (clave propia) avisa de los 2 miembros.
    final hint = tester
        .widget<Text>(find.byKey(const Key('assignment_mode_hint')));
    expect(hint.data, l10n.tasks_rotation_requires_two_members);

    // Deshabilitado: pulsar "smart" no cambia el modo ni navega al paywall.
    await tester.tap(find.text(l10n.tasks_assignment_smart));
    await tester.pumpAndSettle();
    expect(_containerOf(tester).read(taskFormNotifierProvider).assignmentMode,
        'basicRotation');
    expect(find.text(_paywallMarker), findsNothing);
  });

  testWidgets(
      'Premium + 2 miembros: seleccionar smart persiste smartDistribution',
      (tester) async {
    enlarge(tester);
    await tester.pumpWidget(_wrap(repo,
        premium: true,
        members: [_member('uid1', 'Ana'), _member('uid2', 'Bea')]));
    await tester.pumpAndSettle();

    final container = _containerOf(tester);
    container
        .read(taskFormNotifierProvider.notifier)
        .setAssignmentOrder(['uid1', 'uid2']);
    await tester.pump();

    expect(find.byKey(const Key('assignment_mode_selector')), findsOneWidget);
    // Estado inicial: rotación básica.
    expect(container.read(taskFormNotifierProvider).assignmentMode,
        'basicRotation');

    final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('task_title_field'))));
    await tester.tap(find.text(l10n.tasks_assignment_smart));
    await tester.pumpAndSettle();

    expect(container.read(taskFormNotifierProvider).assignmentMode,
        'smartDistribution');
    // No navegó al paywall.
    expect(find.text(_paywallMarker), findsNothing);
  });

  testWidgets('Free + 2 miembros: pulsar smart abre paywall y no cambia el modo',
      (tester) async {
    enlarge(tester);
    await tester.pumpWidget(_wrap(repo,
        premium: false,
        members: [_member('uid1', 'Ana'), _member('uid2', 'Bea')]));
    await tester.pumpAndSettle();

    final container = _containerOf(tester);
    container
        .read(taskFormNotifierProvider.notifier)
        .setAssignmentOrder(['uid1', 'uid2']);
    await tester.pump();

    final l10n = AppLocalizations.of(
        tester.element(find.byKey(const Key('task_title_field'))));
    // Aviso de bloqueo Premium visible.
    expect(find.text(l10n.tasks_assignment_premium_locked), findsOneWidget);

    await tester.tap(find.text(l10n.tasks_assignment_smart));
    await tester.pumpAndSettle();

    // Navegó al paywall y el modo NO cambió.
    expect(find.text(_paywallMarker), findsOneWidget);
    expect(container.read(taskFormNotifierProvider).assignmentMode,
        'basicRotation');
  });
}
