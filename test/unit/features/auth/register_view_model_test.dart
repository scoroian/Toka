// test/unit/features/auth/register_view_model_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/application/register_view_model.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/auth/domain/failures/auth_failure.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.unauthenticated();
  void push(AuthState s) => state = s;
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signInWithApple() async {}
  @override
  Future<void> signInWithEmail(String e, String p) async {}
  @override
  Future<void> register(String e, String p) async {}
  @override
  Future<void> sendPasswordReset(String e) async {}
  @override
  Future<void> signOut() async {}
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');
  @override
  Future<void> initialize(String? uid) async {}
  @override
  Future<void> setLocale(String code, String? uid) async {}
}

ProviderContainer _makeContainer(_FakeAuth fakeAuth) => ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => fakeAuth),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
      ],
    );

void main() {
  late ProviderContainer container;
  tearDown(() => container.dispose());

  test('initial state: not loading, no error, not complete', () {
    final fa = _FakeAuth();
    container = _makeContainer(fa);
    final vm = container.read(registerViewModelProvider);
    expect(vm.isLoading, false);
    expect(vm.error, null);
    expect(vm.registrationComplete, false);
  });

  test('registrationComplete becomes true on authenticated', () async {
    final fa = _FakeAuth();
    container = _makeContainer(fa);
    container.read(registerViewModelProvider);
    const user = AuthUser(
        uid: 'u',
        email: 'e@e.com',
        displayName: 'U',
        photoUrl: null,
        emailVerified: false,
        providers: ['password']);
    fa.push(const AuthState.authenticated(user));
    await Future.microtask(() {});
    expect(
        container.read(registerViewModelProvider).registrationComplete, true);
  });

  test('error propagates from authProvider', () async {
    final fa = _FakeAuth();
    container = _makeContainer(fa);
    container.read(registerViewModelProvider);
    fa.push(const AuthState.error(AuthFailure.emailAlreadyInUse()));
    await Future.microtask(() {});
    expect(container.read(registerViewModelProvider).error,
        const AuthFailure.emailAlreadyInUse());
  });

  test('clearError clears the error', () async {
    final fa = _FakeAuth();
    container = _makeContainer(fa);
    container.read(registerViewModelProvider);
    fa.push(const AuthState.error(AuthFailure.networkError()));
    await Future.microtask(() {});
    container.read(registerViewModelProvider).clearError();
    expect(container.read(registerViewModelProvider).error, null);
  });
}
