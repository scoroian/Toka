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
import 'package:toka/features/homes/domain/homes_repository.dart';
import 'package:toka/features/homes/presentation/home_selector_widget.dart';
import 'package:toka/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fakes & mocks
// ---------------------------------------------------------------------------

class _MockHomesRepository extends Mock implements HomesRepository {}

class _FakeAuth extends Auth {
  _FakeAuth(this._authState);
  final AuthState _authState;

  @override
  AuthState build() => _authState;
}

class _FakeCurrentHome extends CurrentHome {
  _FakeCurrentHome(this._home);
  final Home? _home;

  @override
  Future<Home?> build() async => _home;

  @override
  Future<void> switchHome(String homeId) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _fakeUser = AuthUser(
  uid: 'uid1',
  email: 'u@u.com',
  displayName: 'User',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

Home _makeHome({required String id, required String name}) => Home(
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
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

HomeMembership _makeMembership({
  required String homeId,
  required String homeName,
  MemberRole role = MemberRole.member,
}) =>
    HomeMembership(
      homeId: homeId,
      homeNameSnapshot: homeName,
      role: role,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
    );

Widget _wrap(
  Widget child, {
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        appBar: AppBar(title: child),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockHomesRepository mockRepo;

  setUp(() {
    mockRepo = _MockHomesRepository();
    // stub methods called transitively if needed
    when(() => mockRepo.getLastSelectedHomeId(any()))
        .thenAnswer((_) async => null);
  });

  testWidgets('con un hogar muestra el nombre sin flecha de selector',
      (tester) async {
    final home = _makeHome(id: 'h1', name: 'Casa Única');
    final memberships = [
      _makeMembership(homeId: 'h1', homeName: 'Casa Única'),
    ];

    await tester.pumpWidget(
      _wrap(
        const HomeSelectorWidget(),
        overrides: [
          authProvider.overrideWith(() => _FakeAuth(
                const AuthState.authenticated(_fakeUser),
              )),
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(home)),
          homesRepositoryProvider.overrideWithValue(mockRepo),
          userMembershipsProvider('uid1').overrideWith(
            (ref) => Stream.value(memberships),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa Única'), findsOneWidget);
    expect(find.byKey(const Key('selector_arrow')), findsNothing);
  });

  testWidgets('con dos hogares muestra flecha del selector', (tester) async {
    final home = _makeHome(id: 'h1', name: 'Casa Principal');
    final memberships = [
      _makeMembership(homeId: 'h1', homeName: 'Casa Principal'),
      _makeMembership(homeId: 'h2', homeName: 'Casa Secundaria'),
    ];

    await tester.pumpWidget(
      _wrap(
        const HomeSelectorWidget(),
        overrides: [
          authProvider.overrideWith(() => _FakeAuth(
                const AuthState.authenticated(_fakeUser),
              )),
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(home)),
          homesRepositoryProvider.overrideWithValue(mockRepo),
          userMembershipsProvider('uid1').overrideWith(
            (ref) => Stream.value(memberships),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa Principal'), findsOneWidget);
    expect(find.byKey(const Key('selector_arrow')), findsOneWidget);
  });

  testWidgets('al tocar abre lista con ambos hogares', (tester) async {
    final home = _makeHome(id: 'h1', name: 'Casa A');
    final memberships = [
      _makeMembership(homeId: 'h1', homeName: 'Casa A'),
      _makeMembership(homeId: 'h2', homeName: 'Casa B'),
    ];

    await tester.pumpWidget(
      _wrap(
        const HomeSelectorWidget(),
        overrides: [
          authProvider.overrideWith(() => _FakeAuth(
                const AuthState.authenticated(_fakeUser),
              )),
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(home)),
          homesRepositoryProvider.overrideWithValue(mockRepo),
          userMembershipsProvider('uid1').overrideWith(
            (ref) => Stream.value(memberships),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_selector')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_selector_list')), findsOneWidget);
    expect(find.byKey(const Key('home_tile_h1')), findsOneWidget);
    expect(find.byKey(const Key('home_tile_h2')), findsOneWidget);
  });

  testWidgets('golden: selector con 3 hogares', (tester) async {
    final home = _makeHome(id: 'h1', name: 'Casa A');
    final memberships = [
      _makeMembership(homeId: 'h1', homeName: 'Casa A'),
      _makeMembership(homeId: 'h2', homeName: 'Casa B'),
      _makeMembership(homeId: 'h3', homeName: 'Casa C'),
    ];

    await tester.pumpWidget(
      _wrap(
        const HomeSelectorWidget(),
        overrides: [
          authProvider.overrideWith(() => _FakeAuth(
                const AuthState.authenticated(_fakeUser),
              )),
          currentHomeProvider
              .overrideWith(() => _FakeCurrentHome(home)),
          homesRepositoryProvider.overrideWithValue(mockRepo),
          userMembershipsProvider('uid1').overrideWith(
            (ref) => Stream.value(memberships),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Open the selector bottom sheet
    await tester.tap(find.byKey(const Key('home_selector')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_selector_3_homes.png'),
    );
  });
}
