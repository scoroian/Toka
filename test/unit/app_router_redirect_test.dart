import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/app.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/auth/domain/failures/auth_failure.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/onboarding/application/onboarding_provider.dart';

class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  // Fijar AsyncData(null) síncronamente antes de que el Future devuelva,
  // para que redirect() lea el estado "data" sin necesidad de await.
  @override
  Future<Home?> build() {
    state = const AsyncData(null);
    return Future.value(null);
  }

  @override
  Future<void> switchHome(String homeId) async {}
}

/// Simula la pérdida de acceso al hogar (p. ej. el usuario fue expulsado):
/// la lectura de Firestore falla por permisos y el provider queda en error.
class _ErrorCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => throw Exception('sin acceso al hogar');
  @override
  Future<void> switchHome(String homeId) async {}
}

class _MockGoRouterState extends Mock implements GoRouterState {}

class _MockBuildContext extends Mock implements BuildContext {}

ProviderContainer _container(AuthState authState) => ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _FakeAuth(authState)),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        // Retorna bool síncrono (FutureOr<bool>) → Riverpod resuelve a
        // AsyncData(false) en el mismo tick, sin necesidad de await.
        onboardingCompletedProvider.overrideWith((ref) => false),
      ],
    );

String? _redirectFor(AuthState authState, String location) {
  final container = _container(authState);
  addTearDown(container.dispose);
  final notifier = container.read(routerNotifierProvider.notifier);
  final state = _MockGoRouterState();
  when(() => state.matchedLocation).thenReturn(location);
  return notifier.redirect(_MockBuildContext(), state);
}

void main() {
  const errorState = AuthState.error(AuthFailure.emailAlreadyInUse());

  test('error en /register NO redirige a login (se queda para mostrar el error)',
      () {
    expect(_redirectFor(errorState, AppRoutes.register), isNull);
  });

  test('error en /login se queda en login', () {
    expect(_redirectFor(errorState, AppRoutes.login), isNull);
  });

  test('error en /forgot-password se queda (pantalla de auth)', () {
    expect(_redirectFor(errorState, AppRoutes.forgotPassword), isNull);
  });

  test('error fuera de pantallas de auth sí redirige a login', () {
    expect(_redirectFor(errorState, AppRoutes.home), AppRoutes.login);
  });

  test(
      'error en /verify-email redirige a /login '
      '(solo válida para autenticado-sin-verificar, no para estado error)', () {
    expect(_redirectFor(errorState, AppRoutes.verifyEmail), AppRoutes.login);
  });

  group('unauthenticated redirige correctamente (Hallazgo #03 regresión)', () {
    const unauthed = AuthState.unauthenticated();

    test('unauthenticated en /login se queda (null)', () {
      expect(_redirectFor(unauthed, AppRoutes.login), isNull);
    });

    test('unauthenticated en /register se queda (null)', () {
      expect(_redirectFor(unauthed, AppRoutes.register), isNull);
    });

    test('unauthenticated en /home redirige a /login', () {
      expect(_redirectFor(unauthed, AppRoutes.home), AppRoutes.login);
    });

    test(
        'unauthenticated en /verify-email redirige a /login '
        '(regresión: "Volver"→signOut dejaba atrapado en /verify-email)', () {
      expect(_redirectFor(unauthed, AppRoutes.verifyEmail), AppRoutes.login);
    });
  });

  // loading ocurre durante un intento de login/registro. Si redirige a /splash,
  // al llegar el error siguiente la location ya no es /register y se acaba en
  // /login (perdiendo el formulario). En pantallas de auth, loading debe QUEDARSE.
  group('loading durante intento de auth', () {
    const loadingState = AuthState.loading();

    test('loading en /register se queda (no va a splash)', () {
      expect(_redirectFor(loadingState, AppRoutes.register), isNull);
    });

    test('loading en /login se queda', () {
      expect(_redirectFor(loadingState, AppRoutes.login), isNull);
    });

    test('loading inicial (no en pantalla de auth) sí va a splash', () {
      expect(_redirectFor(loadingState, AppRoutes.home), AppRoutes.splash);
    });

    test('loading en splash se queda en splash', () {
      expect(_redirectFor(loadingState, AppRoutes.splash), isNull);
    });
  });

  group('enforcement de email verificado (modelo A, Hallazgo #03)', () {
    AuthState unverifiedPassword() => const AuthState.authenticated(AuthUser(
          uid: 'u',
          email: 'a@b.c',
          displayName: null,
          photoUrl: null,
          emailVerified: false,
          providers: ['password'],
        ));

    AuthState verifiedPassword() => const AuthState.authenticated(AuthUser(
          uid: 'u',
          email: 'a@b.c',
          displayName: null,
          photoUrl: null,
          emailVerified: true,
          providers: ['password'],
        ));

    AuthState socialUser() => const AuthState.authenticated(AuthUser(
          uid: 'g',
          email: 'g@b.c',
          displayName: null,
          photoUrl: null,
          emailVerified: true,
          providers: ['google.com'],
        ));

    test('password sin verificar en /home redirige a /verify-email', () {
      expect(_redirectFor(unverifiedPassword(), AppRoutes.home),
          AppRoutes.verifyEmail);
    });

    test('password sin verificar en /onboarding redirige a /verify-email', () {
      expect(_redirectFor(unverifiedPassword(), AppRoutes.onboarding),
          AppRoutes.verifyEmail);
    });

    test('password sin verificar en /splash redirige a /verify-email', () {
      expect(_redirectFor(unverifiedPassword(), AppRoutes.splash),
          AppRoutes.verifyEmail);
    });

    test('password sin verificar YA en /verify-email se queda', () {
      expect(_redirectFor(unverifiedPassword(), AppRoutes.verifyEmail), isNull);
    });

    test('password verificado en /verify-email avanza (no se queda)', () {
      // currentHome=null + onboardingCompleted=false → /onboarding.
      expect(_redirectFor(verifiedPassword(), AppRoutes.verifyEmail),
          AppRoutes.onboarding);
    });

    test('cuenta social no se bloquea aunque pase por /home', () {
      expect(_redirectFor(socialUser(), AppRoutes.home), isNull);
    });
  });

  group('pérdida de hogar dentro de la app (Hallazgo #6)', () {
    final authed = AuthState.authenticated(const AuthUser(
      uid: 'u1',
      email: 'a@b.c',
      displayName: null,
      photoUrl: null,
      emailVerified: true,
      providers: ['password'],
    ));

    Future<String?> redirectWithErrorHome(String location) async {
      final container = ProviderContainer(overrides: [
        authProvider.overrideWith(() => _FakeAuth(authed)),
        currentHomeProvider.overrideWith(() => _ErrorCurrentHome()),
        onboardingCompletedProvider.overrideWith((ref) async => false),
      ]);
      addTearDown(container.dispose);
      // Forzar la resolución del AsyncNotifier a AsyncError antes del redirect.
      await expectLater(
          container.read(currentHomeProvider.future), throwsA(anything));
      final notifier = container.read(routerNotifierProvider.notifier);
      final state = _MockGoRouterState();
      when(() => state.matchedLocation).thenReturn(location);
      return notifier.redirect(_MockBuildContext(), state);
    }

    test('expulsado en subpantalla (currentHome error) redirige a /home',
        () async {
      expect(await redirectWithErrorHome(AppRoutes.historyEventDetail),
          AppRoutes.home);
    });

    test('en /home con currentHome error NO rebota (evita bucle de redirect)',
        () async {
      expect(await redirectWithErrorHome(AppRoutes.home), isNull);
    });
  });
}
