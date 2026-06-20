import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/app.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
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
  @override
  Future<Home?> build() async => null;
  @override
  Future<void> switchHome(String homeId) async {}
}

class _MockGoRouterState extends Mock implements GoRouterState {}

class _MockBuildContext extends Mock implements BuildContext {}

ProviderContainer _container(AuthState authState) => ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _FakeAuth(authState)),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
        onboardingCompletedProvider.overrideWith((ref) async => false),
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
}
