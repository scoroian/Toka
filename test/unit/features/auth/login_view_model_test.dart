// test/unit/features/auth/login_view_model_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/application/login_view_model.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/auth/domain/failures/auth_failure.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';

class _FakeAuth extends Auth {
  _FakeAuth([this._initial = const AuthState.unauthenticated()]);
  final AuthState _initial;

  @override
  AuthState build() => _initial;

  // Expose protected state setter for tests
  void push(AuthState s) => state = s;

  @override Future<void> signInWithGoogle() async {}
  @override Future<void> signInWithApple() async {}
  @override Future<void> signInWithEmail(String e, String p) async {}
  @override Future<void> register(String e, String p) async {}
  @override Future<void> sendPasswordReset(String e) async {}
  @override Future<void> signOut() async {}
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override Locale build() => const Locale('es');
  @override Future<void> initialize(String? uid) async {}
  @override Future<void> setLocale(String code, String? uid) async {}
}

ProviderContainer _makeContainer(_FakeAuth fakeAuth) {
  return ProviderContainer(overrides: [
    authProvider.overrideWith(() => fakeAuth),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
  ]);
}

void main() {
  late ProviderContainer container;
  tearDown(() => container.dispose());

  test('initial: isLoading false, error null, isAuthenticated false', () {
    final fakeAuth = _FakeAuth();
    container = _makeContainer(fakeAuth);
    final vm = container.read(loginViewModelProvider);
    expect(vm.isLoading, false);
    expect(vm.error, null);
    expect(vm.isAuthenticated, false);
  });

  test('isLoading true when authProvider emits loading', () async {
    final fakeAuth = _FakeAuth();
    container = _makeContainer(fakeAuth);
    container.read(loginViewModelProvider);
    fakeAuth.push(const AuthState.loading());
    await Future.microtask(() {});
    expect(container.read(loginViewModelProvider).isLoading, true);
  });

  test('error is set when authProvider emits error', () async {
    final fakeAuth = _FakeAuth();
    container = _makeContainer(fakeAuth);
    container.read(loginViewModelProvider);
    fakeAuth.push(const AuthState.error(AuthFailure.invalidCredentials()));
    await Future.microtask(() {});
    expect(container.read(loginViewModelProvider).error,
        const AuthFailure.invalidCredentials());
  });

  test('isAuthenticated true when authProvider emits authenticated', () async {
    final fakeAuth = _FakeAuth();
    container = _makeContainer(fakeAuth);
    container.read(loginViewModelProvider);
    const user = AuthUser(
      uid: 'u1', email: 'a@b.com', displayName: 'A',
      photoUrl: null, emailVerified: true, providers: ['password'],
    );
    fakeAuth.push(const AuthState.authenticated(user));
    await Future.microtask(() {});
    expect(container.read(loginViewModelProvider).isAuthenticated, true);
  });

  test('clearError resets error to null', () async {
    final fakeAuth = _FakeAuth();
    container = _makeContainer(fakeAuth);
    container.read(loginViewModelProvider);
    fakeAuth.push(const AuthState.error(AuthFailure.networkError()));
    await Future.microtask(() {});
    container.read(loginViewModelProvider).clearError();
    expect(container.read(loginViewModelProvider).error, null);
  });
}
