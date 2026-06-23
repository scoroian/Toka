// Hallazgo #12 — Gobernanza de roles (UI de Ajustes del hogar).
//
// Verifica la salida limpia del owner a nivel de tiles:
//   - El OWNER NO ve "Abandonar" (antes lo veía y devolvía error → SPOF);
//     en su lugar ve "Transferir y salir".
//   - Un MIEMBRO normal sí ve "Abandonar" y NO ve los tiles de owner.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/domain/invitation.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/homes/presentation/skins/home_settings_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

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

const _fakeUser = AuthUser(
  uid: 'uid1',
  email: 'u@u.com',
  displayName: 'User',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

Home _makeHome() => Home(
      id: 'h1',
      name: 'Mi Casa',
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

HomeMembership _membership(MemberRole role) => HomeMembership(
      homeId: 'h1',
      homeNameSnapshot: 'Mi Casa',
      role: role,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
    );

GoRouter _router() => GoRouter(
      initialLocation: AppRoutes.homeSettings,
      routes: [
        GoRoute(
          path: AppRoutes.homeSettings,
          builder: (_, __) => const HomeSettingsScreenV2(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: AppRoutes.members,
          builder: (_, __) => const Scaffold(body: Text('members')),
        ),
      ],
    );

Widget _wrap(MemberRole role) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        () => _FakeAuth(const AuthState.authenticated(_fakeUser)),
      ),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(_makeHome())),
      userMembershipsProvider('uid1')
          .overrideWith((ref) => Stream.value([_membership(role)])),
      homeMembersProvider('h1')
          .overrideWith((ref) => Stream.value(const <Member>[])),
      pendingInvitationsProvider('h1')
          .overrideWith((ref) => Stream.value(const <Invitation>[])),
    ],
    child: MaterialApp.router(
      routerConfig: _router(),
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

void main() {
  testWidgets('OWNER: ve "Transferir y salir" y NO ve "Abandonar"',
      (tester) async {
    await tester.pumpWidget(_wrap(MemberRole.owner));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transfer_and_leave_tile')), findsOneWidget);
    expect(find.byKey(const Key('transfer_ownership_tile')), findsOneWidget);
    expect(find.byKey(const Key('leave_home_tile')), findsNothing);
  });

  testWidgets('MIEMBRO: ve "Abandonar" y NO ve tiles de owner',
      (tester) async {
    await tester.pumpWidget(_wrap(MemberRole.member));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('leave_home_tile')), findsOneWidget);
    expect(find.byKey(const Key('transfer_and_leave_tile')), findsNothing);
    expect(find.byKey(const Key('transfer_ownership_tile')), findsNothing);
  });
}
