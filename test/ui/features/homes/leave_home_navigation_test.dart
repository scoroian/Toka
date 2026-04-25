// Verifica BUG-26: tras "Salir del hogar", la navegación debe ocurrir antes
// de que el callable de leaveHome resuelva. De otro modo, durante 1-2 frames
// HomeSettingsScreen se quedaría montada con currentHomeProvider==null y
// mostraría un Scaffold zombie con error genérico antes del redirect.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';
import 'package:toka/features/homes/presentation/skins/home_settings_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

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
      ownerUid: 'someone-else',
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

HomeMembership _makeMembership() => HomeMembership(
      homeId: 'h1',
      homeNameSnapshot: 'Mi Casa',
      role: MemberRole.member,
      billingState: BillingState.none,
      status: MemberStatus.active,
      joinedAt: DateTime(2024),
    );

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.homeSettings,
    routes: [
      GoRoute(
        path: AppRoutes.homeSettings,
        builder: (_, __) => const HomeSettingsScreenV2(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(
          key: Key('fake_home_destination'),
          body: Center(child: Text('home destination')),
        ),
      ),
    ],
  );
}

Widget _wrap(_MockHomesRepository repo) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        () => _FakeAuth(const AuthState.authenticated(_fakeUser)),
      ),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(_makeHome())),
      homesRepositoryProvider.overrideWithValue(repo),
      userMembershipsProvider('uid1').overrideWith(
        (ref) => Stream.value([_makeMembership()]),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: _buildRouter(),
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
  setUpAll(() {
    registerFallbackValue('');
  });

  testWidgets(
    'BUG-26: navega a /home antes de que leaveHome resuelva (no zombie scaffold)',
    (tester) async {
      final repo = _MockHomesRepository();
      // El callable nunca resuelve durante el test → simula la latencia
      // en la que originalmente se veía la pantalla en blanco.
      final completer = Completer<void>();
      when(() => repo.leaveHome(any(), uid: any(named: 'uid')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(find.byType(HomeSettingsScreenV2), findsOneWidget);

      await tester.tap(find.byKey(const Key('leave_home_tile')));
      await tester.pumpAndSettle();

      // Confirmar el diálogo
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // El callable sigue pendiente, pero la pantalla ya debió migrar al
      // destino seguro: el fake_home_destination, NO el HomeSettingsScreen.
      expect(find.byKey(const Key('fake_home_destination')), findsOneWidget);
      expect(find.byType(HomeSettingsScreenV2), findsNothing);

      // El callable se invocó.
      verify(() => repo.leaveHome('h1', uid: 'uid1')).called(1);

      // Cerramos el completer para evitar que el test deje futuros pendientes.
      completer.complete();
      await tester.pumpAndSettle();
    },
  );
}
