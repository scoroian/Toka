import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_repository.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/auth/domain/failures/auth_failure.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => null;
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');

  @override
  Future<void> initialize(String? uid) async {}

  @override
  Future<void> setLocale(String code, String? uid) async {}
}

class _FakeRepo implements AuthRepository {
  _FakeRepo({
    Stream<AuthUser?> Function()? stateChanges,
    Future<AuthUser> Function(String, String)? register,
    Future<void> Function()? sendVerification,
  })  : _stateChanges = stateChanges ?? (() => const Stream.empty()),
        _register = register,
        _sendVerification = sendVerification;

  final Stream<AuthUser?> Function() _stateChanges;
  final Future<AuthUser> Function(String, String)? _register;
  final Future<void> Function()? _sendVerification;

  @override
  Stream<AuthUser?> get authStateChanges => _stateChanges();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AuthUser> signInWithApple() => throw UnimplementedError();

  @override
  Future<AuthUser> signInWithEmailPassword(String e, String p) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> registerWithEmailPassword(String e, String p) =>
      _register != null ? _register(e, p) : throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String e) => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() =>
      _sendVerification != null ? _sendVerification() : throw UnimplementedError();

  @override
  Future<void> linkWithGoogle() => throw UnimplementedError();

  @override
  Future<void> linkWithApple() => throw UnimplementedError();

  @override
  Future<void> linkWithEmailPassword(String e, String p) =>
      throw UnimplementedError();

  @override
  Future<void> updatePassword(String c, String n) =>
      throw UnimplementedError();
}

void main() {
  late ProviderContainer container;

  tearDown(() => container.dispose());

  test('initial state is AuthState.initial', () {
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ],
    );
    expect(container.read(authProvider), const AuthState.initial());
  });

  test('state becomes authenticated when user received', () async {
    const user = AuthUser(
      uid: 'uid',
      email: 'u@u.com',
      displayName: 'U',
      photoUrl: null,
      emailVerified: true,
      providers: ['password'],
    );
    final controller = StreamController<AuthUser?>();
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => controller.stream),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ],
    );

    container.read(authProvider);
    controller.add(user);
    await Future.microtask(() {});

    expect(container.read(authProvider), const AuthState.authenticated(user));
    await controller.close();
  });

  test('state becomes unauthenticated when null received', () async {
    final controller = StreamController<AuthUser?>();
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => controller.stream),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ],
    );

    container.read(authProvider);
    controller.add(null);
    await Future.microtask(() {});

    expect(container.read(authProvider), const AuthState.unauthenticated());
    await controller.close();
  });

  test('signOut resets provider state to initial', () async {
    const user = AuthUser(
      uid: 'uid',
      email: 'u@u.com',
      displayName: 'U',
      photoUrl: null,
      emailVerified: true,
      providers: ['password'],
    );
    final controller = StreamController<AuthUser?>.broadcast();
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => controller.stream),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        authRepositoryProvider.overrideWithValue(_FakeRepo()),
        // Override to break circular dependency: currentHomeProvider watches
        // authProvider, so invalidating it from authProvider requires a stub.
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      ],
    );

    container.read(authProvider);
    controller.add(user);
    await Future.microtask(() {});
    expect(container.read(authProvider), const AuthState.authenticated(user));

    await container.read(authProvider.notifier).signOut();
    await Future.microtask(() {});

    expect(container.read(authProvider), const AuthState.initial());
    await controller.close();
  });

  // El email de verificación es best-effort: si falla (p.ej. 'too-many-requests'
  // que Firebase aplica con frecuencia, o un fallo de red) NO debe revertir un
  // registro que ya creó al usuario, mandándolo de vuelta al login.
  test('register: fallo de sendEmailVerification no tira el registro a login',
      () async {
    const user = AuthUser(
      uid: 'uid-new',
      email: 'new@u.com',
      displayName: 'New',
      photoUrl: null,
      emailVerified: false,
      providers: ['password'],
    );
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        authRepositoryProvider.overrideWithValue(_FakeRepo(
          register: (_, __) async => user,
          sendVerification: () async =>
              throw const AuthFailure.tooManyRequests(),
        )),
      ],
    );

    container.read(authProvider);
    await container.read(authProvider.notifier).register('new@u.com', 'pw123456');

    expect(container.read(authProvider), const AuthState.authenticated(user));
  });

  test('register: un fallo real del alta (email en uso) sí deja AuthState.error',
      () async {
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        authRepositoryProvider.overrideWithValue(_FakeRepo(
          register: (_, __) async =>
              throw const AuthFailure.emailAlreadyInUse(),
        )),
      ],
    );

    container.read(authProvider);
    await container.read(authProvider.notifier).register('dup@u.com', 'pw123456');

    expect(
      container.read(authProvider),
      const AuthState.error(AuthFailure.emailAlreadyInUse()),
    );
  });
}
