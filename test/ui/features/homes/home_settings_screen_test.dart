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
import 'package:toka/features/homes/presentation/home_settings_screen.dart';
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

Home _makeHome({String id = 'h1', String name = 'Mi Casa'}) => Home(
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
  required MemberRole role,
  String homeId = 'h1',
  BillingState billingState = BillingState.none,
}) =>
    HomeMembership(
      homeId: homeId,
      homeNameSnapshot: 'Mi Casa',
      role: role,
      billingState: billingState,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
    );

Widget _wrap({
  required MemberRole role,
  BillingState billingState = BillingState.none,
  _MockHomesRepository? repo,
}) {
  final home = _makeHome();
  final membership = _makeMembership(role: role, billingState: billingState);
  final mockRepo = repo ?? _MockHomesRepository();

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        () => _FakeAuth(const AuthState.authenticated(_fakeUser)),
      ),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(home)),
      homesRepositoryProvider.overrideWithValue(mockRepo),
      userMembershipsProvider('uid1').overrideWith(
        (ref) => Stream.value([membership]),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es')],
      home: HomeSettingsScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('owner ve botón Cerrar hogar', (tester) async {
    await tester.pumpWidget(_wrap(role: MemberRole.owner));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('close_home_tile')), findsOneWidget);
  });

  testWidgets('miembro NO ve botón Cerrar hogar', (tester) async {
    await tester.pumpWidget(_wrap(role: MemberRole.member));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('close_home_tile')), findsNothing);
  });

  testWidgets('admin ve campo de nombre editable', (tester) async {
    await tester.pumpWidget(_wrap(role: MemberRole.admin));
    await tester.pumpAndSettle();

    // For admin (canEdit=true) the widget is a TextField
    expect(find.byKey(const Key('home_name_field')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('miembro NO ve campo de nombre editable', (tester) async {
    await tester.pumpWidget(_wrap(role: MemberRole.member));
    await tester.pumpAndSettle();

    // For member (canEdit=false) the widget is a read-only ListTile (no TextField)
    expect(find.byKey(const Key('home_name_field')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('golden: pantalla de ajustes como owner', (tester) async {
    await tester.pumpWidget(_wrap(role: MemberRole.owner));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeSettingsScreen),
      matchesGoldenFile('goldens/home_settings_owner.png'),
    );
  });
}
