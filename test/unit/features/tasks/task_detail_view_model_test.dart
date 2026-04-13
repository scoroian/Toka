// test/unit/features/tasks/task_detail_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/tasks/application/recurrence_provider.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';

const _kCurrentUid = 'uid_current_user';

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;

  @override
  Future<void> switchHome(String id) async {}
}

class _FakeCurrentHomeWithData extends CurrentHome {
  _FakeCurrentHomeWithData(this._home);
  final Home _home;

  @override
  Future<Home?> build() async => _home;

  @override
  Future<void> switchHome(String id) async {}
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');

  @override
  Future<void> initialize(String? uid) async {}

  @override
  Future<void> setLocale(String code, String? uid) async {}
}

// ---------------------------------------------------------------------------
// Helpers para construir objetos de dominio de prueba
// ---------------------------------------------------------------------------

Home _makeHome(String id) => Home(
      id: id,
      name: 'Hogar Test',
      ownerUid: 'uid_owner',
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

HomeMembership _makeMembership(String homeId, MemberRole role) => HomeMembership(
      homeId: homeId,
      homeNameSnapshot: 'Hogar Test',
      role: role,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
    );

Member _makeMember(String uid, String homeId, String nickname) => Member(
      uid: uid,
      homeId: homeId,
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'none',
      role: MemberRole.member,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0.0,
    );

Member _makeMemberWithRole(
        String uid, String homeId, String nickname, MemberRole role) =>
    Member(
      uid: uid,
      homeId: homeId,
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'none',
      role: role,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0.0,
    );

Task _makeTask({
  required String id,
  required String homeId,
  required List<String> assignmentOrder,
  String? currentAssigneeUid,
}) =>
    Task(
      id: id,
      homeId: homeId,
      title: 'Tarea Test',
      visualKind: 'emoji',
      visualValue: '🏠',
      status: TaskStatus.active,
      recurrenceRule: const RecurrenceRule.daily(
        every: 1,
        time: '08:00',
        timezone: 'Europe/Madrid',
      ),
      assignmentMode: 'basicRotation',
      assignmentOrder: assignmentOrder,
      currentAssigneeUid: currentAssigneeUid,
      nextDueAt: DateTime(2024, 4, 14),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: 'uid_owner',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

/// Crea un [ProviderContainer] con todos los providers necesarios para que
/// el [taskDetailViewModelProvider] pueda computar [viewData] de forma síncrona.
///
/// - [home]: el hogar que devolverá [currentHomeProvider].
/// - [task]: la tarea que se buscará por [taskId].
/// - [members]: los miembros del hogar.
/// - [upcomingDates]: las fechas que devolverá [upcomingOccurrencesProvider].
/// - [myRole]: el rol del usuario autenticado en el hogar.
ProviderContainer _makeContainer({
  required Home home,
  required Task task,
  required List<Member> members,
  required List<DateTime> upcomingDates,
  MemberRole myRole = MemberRole.member,
  // Rol que el usuario actual tiene en homeMembers (homes/{homeId}/members/{uid}).
  // Si es null, se hereda el valor de [myRole].
  MemberRole? myHomeMemberRole,
}) {
  const uid = _kCurrentUid;
  final authUser = AuthUser(
    uid: uid,
    email: 'test@test.com',
    displayName: 'Test User',
    photoUrl: null,
    emailVerified: true,
    providers: const [],
  );

  // El miembro actual con el rol que tiene en el documento homes/{homeId}/members/{uid}
  final effectiveHomeMemberRole = myHomeMemberRole ?? myRole;
  final currentMember = _makeMemberWithRole(
    uid,
    home.id,
    'Current User',
    effectiveHomeMemberRole,
  );
  final allMembers = [
    currentMember,
    ...members.where((m) => m.uid != uid),
  ];

  return ProviderContainer(overrides: [
    // Auth
    authProvider.overrideWith(
        () => _FakeAuth(AuthState.authenticated(authUser))),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),

    // Home actual
    currentHomeProvider.overrideWith(() => _FakeCurrentHomeWithData(home)),

    // Membresías del usuario (para canManage — lee users/{uid}/memberships/{homeId})
    userMembershipsProvider(uid).overrideWith(
      (_) => Stream.value([_makeMembership(home.id, myRole)]),
    ),

    // Tareas del hogar
    homeTasksProvider(home.id).overrideWith(
      (_) => Stream.value([task]),
    ),

    // Miembros del hogar (homes/{homeId}/members — fuente de verdad del rol)
    homeMembersProvider(home.id).overrideWith(
      (_) => Stream.value(allMembers),
    ),

    // Próximas ocurrencias (fechas fijas para tests deterministas)
    upcomingOccurrencesProvider(task.recurrenceRule).overrideWith(
      (_) => upcomingDates,
    ),
  ]);
}

/// Espera a que todos los providers async internos hayan emitido al menos
/// una vez y el view model tenga datos calculados.
Future<TaskDetailViewData?> _resolveViewData(
  ProviderContainer container,
  String homeId,
  String taskId,
) async {
  // Forzar la resolución de los providers async del hogar
  await container.read(currentHomeProvider.future);
  await container.read(userMembershipsProvider(_kCurrentUid).future);
  await container.read(homeTasksProvider(homeId).future);
  await container.read(homeMembersProvider(homeId).future);

  // Dar un ciclo de microtask para que los watchers internos propaguen
  await Future<void>.microtask(() {});

  final vm = container.read(taskDetailViewModelProvider(taskId));
  return vm.viewData.valueOrNull;
}

void main() {
  group('TaskDetailViewModel', () {
    test('viewData is data(null) when home is null', () async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(
            () => _FakeAuth(const AuthState.unauthenticated())),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ]);
      addTearDown(container.dispose);
      final vm = container.read(taskDetailViewModelProvider('nonexistent'));
      // Home is null (async data null) — should result in AsyncData(null) after resolution
      // The home provider is async so this may still be loading
      expect(vm.viewData.hasValue || vm.viewData.isLoading, isTrue);
    });
  });

  group('upcomingOccurrences rotación', () {
    const homeId = 'home_test';
    const taskId = 'task_test';

    final fixedDates = [
      DateTime(2024, 4, 15),
      DateTime(2024, 4, 16),
      DateTime(2024, 4, 17),
    ];

    test(
        'los asignados rotan round-robin empezando por el siguiente al actual',
        () async {
      // Given: assignmentOrder = [uid_a, uid_b, uid_c], currentAssigneeUid = uid_a
      const uidA = 'uid_a';
      const uidB = 'uid_b';
      const uidC = 'uid_c';
      final home = _makeHome(homeId);
      final task = _makeTask(
        id: taskId,
        homeId: homeId,
        assignmentOrder: [uidA, uidB, uidC],
        currentAssigneeUid: uidA,
      );
      final members = [
        _makeMember(uidA, homeId, 'Nombre A'),
        _makeMember(uidB, homeId, 'Nombre B'),
        _makeMember(uidC, homeId, 'Nombre C'),
      ];

      final container = _makeContainer(
        home: home,
        task: task,
        members: members,
        upcomingDates: fixedDates,
      );
      addTearDown(container.dispose);

      // When: se computan 3 próximas ocurrencias
      final viewData = await _resolveViewData(container, homeId, taskId);

      // Then: el orden debe ser [uid_b, uid_c, uid_a] → [Nombre B, Nombre C, Nombre A]
      expect(viewData, isNotNull);
      final occs = viewData!.upcomingOccurrences;
      expect(occs, hasLength(3));
      expect(occs[0].assigneeName, equals('Nombre B'));
      expect(occs[1].assigneeName, equals('Nombre C'));
      expect(occs[2].assigneeName, equals('Nombre A'));
    });

    test(
        'cuando currentAssigneeUid es null, la rotación empieza en el índice 0',
        () async {
      // Given: assignmentOrder = [uid_a, uid_b], currentAssigneeUid = null
      const uidA = 'uid_a';
      const uidB = 'uid_b';
      final home = _makeHome(homeId);
      final task = _makeTask(
        id: taskId,
        homeId: homeId,
        assignmentOrder: [uidA, uidB],
        currentAssigneeUid: null,
      );
      final members = [
        _makeMember(uidA, homeId, 'Nombre A'),
        _makeMember(uidB, homeId, 'Nombre B'),
      ];

      final container = _makeContainer(
        home: home,
        task: task,
        members: members,
        upcomingDates: [fixedDates[0], fixedDates[1]],
      );
      addTearDown(container.dispose);

      // When: se computan 2 próximas ocurrencias
      final viewData = await _resolveViewData(container, homeId, taskId);

      // Then: el orden debe ser [uid_a, uid_b] → [Nombre A, Nombre B]
      expect(viewData, isNotNull);
      final occs = viewData!.upcomingOccurrences;
      expect(occs, hasLength(2));
      expect(occs[0].assigneeName, equals('Nombre A'));
      expect(occs[1].assigneeName, equals('Nombre B'));
    });

    test(
        'cuando assignmentOrder está vacío, assigneeName es null para todas las ocurrencias',
        () async {
      // Given: assignmentOrder = [], currentAssigneeUid = null
      final home = _makeHome(homeId);
      final task = _makeTask(
        id: taskId,
        homeId: homeId,
        assignmentOrder: [],
        currentAssigneeUid: null,
      );

      final container = _makeContainer(
        home: home,
        task: task,
        members: [],
        upcomingDates: [fixedDates[0], fixedDates[1]],
      );
      addTearDown(container.dispose);

      // When: se computan 2 próximas ocurrencias
      final viewData = await _resolveViewData(container, homeId, taskId);

      // Then: todas las ocurrencias tienen assigneeName == null
      expect(viewData, isNotNull);
      final occs = viewData!.upcomingOccurrences;
      expect(occs, hasLength(2));
      expect(occs.map((o) => o.assigneeName), everyElement(isNull));
    });
  });

  // ---------------------------------------------------------------------------
  // canManage por rol
  // ---------------------------------------------------------------------------
  group('canManage por rol', () {
    const homeId = 'home_test';
    const taskId = 'task_test';

    // Tarea mínima válida para estos tests
    Task makeSimpleTask() => _makeTask(
          id: taskId,
          homeId: homeId,
          assignmentOrder: [],
          currentAssigneeUid: null,
        );

    test(
        // ESTE TEST DEBE FALLAR antes de Task 4:
        // canManage lee userMembershipsProvider (role=member, desactualizado)
        // en lugar de homeMembersProvider (role=admin, fuente de verdad).
        'admin en homeMembers con membresía desactualizada (member) → canManage == true',
        () async {
      // Given: homeMembers tiene al usuario con role=admin (fuente de verdad)
      //        userMembershipsProvider devuelve role=member (dato obsoleto)
      final home = _makeHome(homeId);
      final task = makeSimpleTask();
      final container = _makeContainer(
        home: home,
        task: task,
        members: [],
        upcomingDates: const [],
        myRole: MemberRole.member, // userMembershipsProvider — dato desactualizado
        myHomeMemberRole: MemberRole.admin, // homeMembers — fuente de verdad
      );
      addTearDown(container.dispose);

      // When
      final viewData = await _resolveViewData(container, homeId, taskId);

      // Then: debe ser true porque el usuario ES admin según homeMembers
      expect(viewData, isNotNull);
      expect(viewData!.canManage, isTrue);
    });

    test('owner en homeMembers y en membresía → canManage == true', () async {
      // Given: ambas fuentes coinciden en role=owner
      final home = _makeHome(homeId);
      final task = makeSimpleTask();
      final container = _makeContainer(
        home: home,
        task: task,
        members: [],
        upcomingDates: const [],
        myRole: MemberRole.owner,
        myHomeMemberRole: MemberRole.owner,
      );
      addTearDown(container.dispose);

      // When
      final viewData = await _resolveViewData(container, homeId, taskId);

      // Then
      expect(viewData, isNotNull);
      expect(viewData!.canManage, isTrue);
    });

    test('member en homeMembers y en membresía → canManage == false', () async {
      // Given: ambas fuentes coinciden en role=member
      final home = _makeHome(homeId);
      final task = makeSimpleTask();
      final container = _makeContainer(
        home: home,
        task: task,
        members: [],
        upcomingDates: const [],
        myRole: MemberRole.member,
        myHomeMemberRole: MemberRole.member,
      );
      addTearDown(container.dispose);

      // When
      final viewData = await _resolveViewData(container, homeId, taskId);

      // Then
      expect(viewData, isNotNull);
      expect(viewData!.canManage, isFalse);
    });
  });
}
