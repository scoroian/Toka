import 'package:flutter/widgets.dart';
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
import 'package:toka/features/homes/domain/homes_repository.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockHomesRepository extends Mock implements HomesRepository {}

class _TestAuth extends Auth {
  _TestAuth(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
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
// Fixtures
// ---------------------------------------------------------------------------

const _fakeUser = AuthUser(
  uid: 'uid1',
  email: 'user@example.com',
  displayName: 'User',
  photoUrl: null,
  emailVerified: true,
  providers: ['password'],
);

final _now = DateTime(2025, 1, 1);

HomeMembership _membership(String homeId, String name) => HomeMembership(
      homeId: homeId,
      homeNameSnapshot: name,
      role: MemberRole.member,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: _now,
    );

Home _home(String id, String name) => Home(
      id: id,
      name: name,
      ownerUid: 'uid1',
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: HomePremiumStatus.free,
      premiumPlan: null,
      premiumEndsAt: null,
      restoreUntil: null,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 5),
      createdAt: _now,
      updatedAt: _now,
    );

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer({
  required AuthState authState,
  required _MockHomesRepository repo,
  Stream<List<HomeMembership>>? membershipsStream,
}) {
  return ProviderContainer(
    overrides: [
      authProvider.overrideWith(() => _TestAuth(authState)),
      localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      homesRepositoryProvider.overrideWithValue(repo),
      if (membershipsStream != null)
        userMembershipsProvider('uid1')
            .overrideWith((ref) => membershipsStream),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockHomesRepository repo;

  setUp(() {
    repo = _MockHomesRepository();
  });

  tearDown(() {});

  test('with one membership returns the correct home', () async {
    final membership = _membership('h1', 'Casa Principal');
    final home = _home('h1', 'Casa Principal');

    when(() => repo.getLastSelectedHomeId('uid1'))
        .thenAnswer((_) async => null);
    when(() => repo.fetchHome('h1')).thenAnswer((_) async => home);

    final container = _makeContainer(
      authState: const AuthState.authenticated(_fakeUser),
      repo: repo,
      membershipsStream: Stream.value([membership]),
    );
    addTearDown(container.dispose);

    final result = await container.read(currentHomeProvider.future);
    expect(result, home);
  });

  test('with empty memberships returns null', () async {
    when(() => repo.getLastSelectedHomeId('uid1'))
        .thenAnswer((_) async => null);

    final container = _makeContainer(
      authState: const AuthState.authenticated(_fakeUser),
      repo: repo,
      membershipsStream: Stream.value([]),
    );
    addTearDown(container.dispose);

    final result = await container.read(currentHomeProvider.future);
    expect(result, isNull);
  });

  test('with unauthenticated auth state returns null', () async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          () => _TestAuth(const AuthState.unauthenticated()),
        ),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        homesRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(currentHomeProvider.future);
    expect(result, isNull);
  });

  test('switchHome calls updateLastSelectedHome and invalidates provider',
      () async {
    final membership = _membership('h1', 'Casa A');
    final home = _home('h1', 'Casa A');

    when(() => repo.getLastSelectedHomeId('uid1'))
        .thenAnswer((_) async => null);
    when(() => repo.fetchHome('h1')).thenAnswer((_) async => home);
    when(() => repo.updateLastSelectedHome('uid1', 'h2'))
        .thenAnswer((_) async {});
    // After invalidation the provider will rebuild — return null to keep test simple.
    when(() => repo.getLastSelectedHomeId('uid1'))
        .thenAnswer((_) async => 'h2');

    final container = _makeContainer(
      authState: const AuthState.authenticated(_fakeUser),
      repo: repo,
      membershipsStream: Stream.value([membership]),
    );
    addTearDown(container.dispose);

    // Prime the provider.
    await container.read(currentHomeProvider.future);

    await container.read(currentHomeProvider.notifier).switchHome('h2');

    verify(() => repo.updateLastSelectedHome('uid1', 'h2')).called(1);
  });
}
