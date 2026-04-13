// test/unit/features/tasks/all_tasks_view_model_test.dart
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
import 'package:toka/features/tasks/application/all_tasks_view_model.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/task_status.dart';

// ---------------------------------------------------------------------------
// Constantes de test
// ---------------------------------------------------------------------------

const _kCurrentUid = 'uid_current_user';
const _kHomeId = 'home_test';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
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

HomeMembership _makeMembership(String homeId, MemberRole role) =>
    HomeMembership(
      homeId: homeId,
      homeNameSnapshot: 'Hogar Test',
      role: role,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
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

/// Crea un [ProviderContainer] con los providers mínimos para que
/// [allTasksViewModelProvider] pueda computar [viewData] de forma síncrona.
///
/// - [staleRole]: el rol que devuelve [userMembershipsProvider] (dato obsoleto).
/// - [authoritativeRole]: el rol que devuelve [homeMembersProvider] (fuente de verdad).
ProviderContainer _makeCanCreateContainer({
  required MemberRole staleRole,
  required MemberRole authoritativeRole,
}) {
  const uid = _kCurrentUid;
  const homeId = _kHomeId;
  final home = _makeHome(homeId);

  const authUser = AuthUser(
    uid: uid,
    email: 'test@test.com',
    displayName: 'Test User',
    photoUrl: null,
    emailVerified: true,
    providers: [],
  );

  return ProviderContainer(overrides: [
    // Auth
    authProvider.overrideWith(
        () => _FakeAuth(const AuthState.authenticated(authUser))),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),

    // Home actual
    currentHomeProvider.overrideWith(() => _FakeCurrentHomeWithData(home)),

    // Membresías del usuario (users/{uid}/memberships — dato posiblemente desactualizado)
    userMembershipsProvider(uid).overrideWith(
      (_) => Stream.value([_makeMembership(homeId, staleRole)]),
    ),

    // Miembros del hogar (homes/{homeId}/members — fuente de verdad del rol)
    homeMembersProvider(homeId).overrideWith(
      (_) => Stream.value([
        _makeMemberWithRole(uid, homeId, 'Current User', authoritativeRole),
      ]),
    ),

    // Tareas vacías — no interesan para canCreate
    homeTasksProvider(homeId).overrideWith(
      (_) => Stream.value([]),
    ),
  ]);
}

/// Resuelve el [AllTasksViewData] esperando a que todos los providers async
/// internos hayan emitido al menos una vez.
Future<AllTasksViewData?> _resolveViewData(
    ProviderContainer container) async {
  await container.read(currentHomeProvider.future);
  await container.read(userMembershipsProvider(_kCurrentUid).future);
  await container.read(homeTasksProvider(_kHomeId).future);

  // Dar un ciclo de microtask para que los watchers internos propaguen
  await Future<void>.microtask(() {});

  final vm = container.read(allTasksViewModelProvider);
  return vm.viewData.valueOrNull;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AllTasksFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() => container.dispose());

    test('initial status is active', () {
      expect(
        container.read(allTasksFilterNotifierProvider).status,
        TaskStatus.active,
      );
    });

    test('setStatus updates status', () {
      container
          .read(allTasksFilterNotifierProvider.notifier)
          .setStatus(TaskStatus.frozen);
      expect(
        container.read(allTasksFilterNotifierProvider).status,
        TaskStatus.frozen,
      );
    });

    test('setAssignee updates assigneeUid', () {
      container
          .read(allTasksFilterNotifierProvider.notifier)
          .setAssignee('uid123');
      expect(
        container.read(allTasksFilterNotifierProvider).assigneeUid,
        'uid123',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // canCreate por rol
  // ---------------------------------------------------------------------------
  group('AllTasksViewModel canCreate', () {
    test(
      // ESTE TEST DEBE FALLAR antes de Task 6:
      // canCreate lee userMembershipsProvider (role=member, desactualizado)
      // en lugar de homeMembersProvider (role=admin, fuente de verdad).
      // Cuando se promueve a admin, solo homes/{homeId}/members/{uid}.role
      // se actualiza; users/{uid}/memberships/{homeId}.role permanece obsoleto.
      'admin en homeMembers con membresía desactualizada (member) → canCreate == true',
      () async {
        // Given: homeMembersProvider tiene al usuario con role=admin (fuente de verdad)
        //        userMembershipsProvider devuelve role=member (dato obsoleto tras promoción)
        final container = _makeCanCreateContainer(
          staleRole: MemberRole.member, // userMemberships — dato desactualizado
          authoritativeRole: MemberRole.admin, // homeMembers — fuente de verdad
        );
        addTearDown(container.dispose);

        // When: se resuelve el view model
        final viewData = await _resolveViewData(container);

        // Then: debe ser true porque el usuario ES admin según homeMembers
        // ACTUALMENTE FALLA: canCreate lee userMemberships y devuelve false
        expect(viewData, isNotNull);
        expect(viewData!.canCreate, isTrue);
      },
    );

    test('owner en ambas fuentes → canCreate == true', () async {
      // Given: ambas fuentes coinciden en role=owner
      final container = _makeCanCreateContainer(
        staleRole: MemberRole.owner,
        authoritativeRole: MemberRole.owner,
      );
      addTearDown(container.dispose);

      // When
      final viewData = await _resolveViewData(container);

      // Then
      expect(viewData, isNotNull);
      expect(viewData!.canCreate, isTrue);
    });

    test('member en ambas fuentes → canCreate == false', () async {
      // Given: ambas fuentes coinciden en role=member
      final container = _makeCanCreateContainer(
        staleRole: MemberRole.member,
        authoritativeRole: MemberRole.member,
      );
      addTearDown(container.dispose);

      // When
      final viewData = await _resolveViewData(container);

      // Then
      expect(viewData, isNotNull);
      expect(viewData!.canCreate, isFalse);
    });
  });
}
