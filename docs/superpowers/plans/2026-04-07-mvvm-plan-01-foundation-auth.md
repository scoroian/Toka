# MVVM Refactor — Plan 01: Foundation + Auth

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce `SkinConfig` and create typed ViewModels for all 4 Auth screens so that presentation layer is decoupled from Riverpod internals.

**Architecture:** Each screen gets an `abstract class XxxViewModel` (the contract), a `XxxViewModelNotifier` (Riverpod Notifier that implements it), and a typed provider `xxxViewModelProvider` that returns the abstract type. Auth screens delegate all actions to the existing `authProvider` — they don't duplicate auth logic.

**Tech Stack:** Flutter 3.x, Riverpod 2 (`riverpod_annotation`), freezed, mocktail, dart build_runner.

**Spec:** `docs/superpowers/specs/2026-04-07-mvvm-skin-design.md`

---

## File Map

| Action | File |
|--------|------|
| Create | `lib/core/theme/app_skin.dart` |
| Create | `lib/features/auth/application/login_view_model.dart` |
| Create | `lib/features/auth/application/register_view_model.dart` |
| Create | `lib/features/auth/application/verify_email_view_model.dart` |
| Create | `lib/features/auth/application/forgot_password_view_model.dart` |
| Create | `test/unit/features/auth/login_view_model_test.dart` |
| Create | `test/unit/features/auth/register_view_model_test.dart` |
| Create | `test/unit/features/auth/verify_email_view_model_test.dart` |
| Create | `test/unit/features/auth/forgot_password_view_model_test.dart` |
| Modify | `lib/features/auth/presentation/login_screen.dart` |
| Modify | `lib/features/auth/presentation/register_screen.dart` |
| Modify | `lib/features/auth/presentation/verify_email_screen.dart` |
| Modify | `lib/features/auth/presentation/forgot_password_screen.dart` |
| Modify | `test/ui/features/auth/login_screen_test.dart` |
| Modify | `test/ui/features/auth/register_screen_test.dart` |

---

## Task 1: SkinConfig

**Files:**
- Create: `lib/core/theme/app_skin.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/core/theme/app_skin.dart

/// Identifies available visual skins.
/// Add a new value here when a new full redesign is introduced.
enum AppSkin { material }

/// Single point of control for which skin the app renders.
/// Change [current] to switch all screens to a different visual design.
/// In the future, this can read from Firebase Remote Config or SharedPreferences.
class SkinConfig {
  SkinConfig._();
  static AppSkin current = AppSkin.material;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/theme/app_skin.dart
git commit -m "feat(mvvm): add SkinConfig foundation"
```

---

## Task 2: LoginViewModel

**Files:**
- Create: `lib/features/auth/application/login_view_model.dart`
- Create: `test/unit/features/auth/login_view_model_test.dart`

- [ ] **Step 1: Create `login_view_model.dart`**

```dart
// lib/features/auth/application/login_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/failures/auth_failure.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

part 'login_view_model.freezed.dart';
part 'login_view_model.g.dart';

// ── 1. CONTRACT ────────────────────────────────────────────────────────────

abstract class LoginViewModel {
  bool get isLoading;
  bool get isAuthenticated;
  AuthFailure? get error;

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signInWithEmail(String email, String password);
  void clearError();
}

// ── 2. INTERNAL STATE ──────────────────────────────────────────────────────

@freezed
class _LoginState with _$_LoginState {
  const factory _LoginState({
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    AuthFailure? error,
  }) = __LoginState;
}

// ── 3. IMPLEMENTATION ──────────────────────────────────────────────────────

@riverpod
class LoginViewModelNotifier extends _$LoginViewModelNotifier
    implements LoginViewModel {
  @override
  _LoginState build() {
    ref.listen<AuthState>(authProvider, (_, s) {
      s.maybeWhen(
        loading: () => state = state.copyWith(isLoading: true, error: null),
        error: (f) => state = state.copyWith(isLoading: false, error: f),
        authenticated: (_) =>
            state = state.copyWith(isLoading: false, isAuthenticated: true),
        orElse: () => state = state.copyWith(isLoading: false),
      );
    });
    return const _LoginState();
  }

  @override
  bool get isLoading => state.isLoading;

  @override
  bool get isAuthenticated => state.isAuthenticated;

  @override
  AuthFailure? get error => state.error;

  @override
  Future<void> signInWithGoogle() =>
      ref.read(authProvider.notifier).signInWithGoogle();

  @override
  Future<void> signInWithApple() =>
      ref.read(authProvider.notifier).signInWithApple();

  @override
  Future<void> signInWithEmail(String email, String password) =>
      ref.read(authProvider.notifier).signInWithEmail(email, password);

  @override
  void clearError() => state = state.copyWith(error: null);
}

// ── 4. TYPED PROVIDER (what screens import) ────────────────────────────────

@riverpod
LoginViewModel loginViewModel(LoginViewModelRef ref) {
  ref.watch(loginViewModelNotifierProvider);
  return ref.read(loginViewModelNotifierProvider.notifier);
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `login_view_model.freezed.dart` and `login_view_model.g.dart` with no errors.

- [ ] **Step 3: Create `login_view_model_test.dart`**

```dart
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
```

- [ ] **Step 4: Run the test**

```bash
flutter test test/unit/features/auth/login_view_model_test.dart
```

Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/application/login_view_model.dart \
        lib/features/auth/application/login_view_model.freezed.dart \
        lib/features/auth/application/login_view_model.g.dart \
        test/unit/features/auth/login_view_model_test.dart
git commit -m "feat(mvvm): add LoginViewModel contract + notifier + tests"
```

---

## Task 3: RegisterViewModel

**Files:**
- Create: `lib/features/auth/application/register_view_model.dart`
- Create: `test/unit/features/auth/register_view_model_test.dart`

- [ ] **Step 1: Create `register_view_model.dart`**

```dart
// lib/features/auth/application/register_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/failures/auth_failure.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

part 'register_view_model.freezed.dart';
part 'register_view_model.g.dart';

abstract class RegisterViewModel {
  bool get isLoading;
  bool get registrationComplete;
  AuthFailure? get error;

  Future<void> register(String email, String password);
  void clearError();
}

@freezed
class _RegisterState with _$_RegisterState {
  const factory _RegisterState({
    @Default(false) bool isLoading,
    @Default(false) bool registrationComplete,
    AuthFailure? error,
  }) = __RegisterState;
}

@riverpod
class RegisterViewModelNotifier extends _$RegisterViewModelNotifier
    implements RegisterViewModel {
  @override
  _RegisterState build() {
    ref.listen<AuthState>(authProvider, (_, s) {
      s.maybeWhen(
        loading: () => state = state.copyWith(isLoading: true, error: null),
        error: (f) => state = state.copyWith(isLoading: false, error: f),
        authenticated: (_) =>
            state = state.copyWith(isLoading: false, registrationComplete: true),
        orElse: () => state = state.copyWith(isLoading: false),
      );
    });
    return const _RegisterState();
  }

  @override bool get isLoading => state.isLoading;
  @override bool get registrationComplete => state.registrationComplete;
  @override AuthFailure? get error => state.error;

  @override
  Future<void> register(String email, String password) =>
      ref.read(authProvider.notifier).register(email, password);

  @override
  void clearError() => state = state.copyWith(error: null);
}

@riverpod
RegisterViewModel registerViewModel(RegisterViewModelRef ref) {
  ref.watch(registerViewModelNotifierProvider);
  return ref.read(registerViewModelNotifierProvider.notifier);
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Create `register_view_model_test.dart`**

```dart
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
  @override AuthState build() => const AuthState.unauthenticated();
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
    const user = AuthUser(uid: 'u', email: 'e@e.com', displayName: 'U',
        photoUrl: null, emailVerified: false, providers: ['password']);
    fa.push(const AuthState.authenticated(user));
    await Future.microtask(() {});
    expect(container.read(registerViewModelProvider).registrationComplete, true);
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
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/unit/features/auth/register_view_model_test.dart
```

Expected: all 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/application/register_view_model.dart \
        lib/features/auth/application/register_view_model.freezed.dart \
        lib/features/auth/application/register_view_model.g.dart \
        test/unit/features/auth/register_view_model_test.dart
git commit -m "feat(mvvm): add RegisterViewModel contract + notifier + tests"
```

---

## Task 4: VerifyEmailViewModel

**Files:**
- Create: `lib/features/auth/application/verify_email_view_model.dart`
- Create: `test/unit/features/auth/verify_email_view_model_test.dart`

- [ ] **Step 1: Create `verify_email_view_model.dart`**

```dart
// lib/features/auth/application/verify_email_view_model.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';

part 'verify_email_view_model.freezed.dart';
part 'verify_email_view_model.g.dart';

abstract class VerifyEmailViewModel {
  String get email;
  int get resendCooldownSeconds;
  bool get isSending;

  Future<void> resendVerification();
}

@freezed
class _VerifyEmailState with _$_VerifyEmailState {
  const factory _VerifyEmailState({
    @Default('') String email,
    @Default(0) int resendCooldownSeconds,
    @Default(false) bool isSending,
  }) = __VerifyEmailState;
}

@riverpod
class VerifyEmailViewModelNotifier extends _$VerifyEmailViewModelNotifier
    implements VerifyEmailViewModel {
  Timer? _timer;

  @override
  _VerifyEmailState build() {
    ref.onDispose(() => _timer?.cancel());
    return _VerifyEmailState(
      email: ref.read(authRepositoryProvider).currentUser?.email ?? '',
    );
  }

  @override String get email => state.email;
  @override int get resendCooldownSeconds => state.resendCooldownSeconds;
  @override bool get isSending => state.isSending;

  @override
  Future<void> resendVerification() async {
    if (state.isSending || state.resendCooldownSeconds > 0) return;
    state = state.copyWith(isSending: true);
    await ref.read(authRepositoryProvider).sendEmailVerification();
    state = state.copyWith(isSending: false, resendCooldownSeconds: 60);
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.resendCooldownSeconds <= 1) {
        _timer?.cancel();
        state = state.copyWith(resendCooldownSeconds: 0);
      } else {
        state = state.copyWith(
            resendCooldownSeconds: state.resendCooldownSeconds - 1);
      }
    });
  }
}

@riverpod
VerifyEmailViewModel verifyEmailViewModel(VerifyEmailViewModelRef ref) {
  ref.watch(verifyEmailViewModelNotifierProvider);
  return ref.read(verifyEmailViewModelNotifierProvider.notifier);
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Create `verify_email_view_model_test.dart`**

```dart
// test/unit/features/auth/verify_email_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/verify_email_view_model.dart';
import 'package:toka/features/auth/domain/auth_repository.dart';
import 'package:toka/features/auth/domain/auth_user.dart';

class _FakeRepo implements AuthRepository {
  @override Stream<AuthUser?> get authStateChanges => const Stream.empty();
  @override AuthUser? get currentUser => const AuthUser(
        uid: 'u', email: 'test@test.com', displayName: 'U',
        photoUrl: null, emailVerified: false, providers: ['password']);
  @override Future<void> signOut() async {}
  @override Future<AuthUser> signInWithGoogle() => throw UnimplementedError();
  @override Future<AuthUser> signInWithApple() => throw UnimplementedError();
  @override Future<AuthUser> signInWithEmailPassword(String e, String p) =>
      throw UnimplementedError();
  @override Future<AuthUser> registerWithEmailPassword(String e, String p) =>
      throw UnimplementedError();
  @override Future<void> sendPasswordResetEmail(String e) =>
      throw UnimplementedError();
  @override Future<void> sendEmailVerification() async {}
  @override Future<void> linkWithGoogle() => throw UnimplementedError();
  @override Future<void> linkWithApple() => throw UnimplementedError();
  @override Future<void> linkWithEmailPassword(String e, String p) =>
      throw UnimplementedError();
  @override Future<void> updatePassword(String c, String n) =>
      throw UnimplementedError();
}

void main() {
  late ProviderContainer container;
  tearDown(() => container.dispose());

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(_FakeRepo()),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      ]);

  test('email is read from currentUser on build', () {
    container = makeContainer();
    final vm = container.read(verifyEmailViewModelProvider);
    expect(vm.email, 'test@test.com');
  });

  test('isSending false initially, resendCooldownSeconds 0', () {
    container = makeContainer();
    final vm = container.read(verifyEmailViewModelProvider);
    expect(vm.isSending, false);
    expect(vm.resendCooldownSeconds, 0);
  });

  test('resendVerification is ignored when already sending', () async {
    container = makeContainer();
    container.read(verifyEmailViewModelProvider);
    // Manually set isSending = true by calling twice without await
    final notifier =
        container.read(verifyEmailViewModelNotifierProvider.notifier);
    notifier.state =
        notifier.state.copyWith(isSending: true); // direct state manipulation
    await notifier.resendVerification(); // should be a no-op
    // isSending stays true (no second send triggered)
    expect(container.read(verifyEmailViewModelProvider).isSending, true);
  });

  test('after resendVerification cooldown is set to 60', () async {
    container = makeContainer();
    container.read(verifyEmailViewModelProvider);
    await container
        .read(verifyEmailViewModelNotifierProvider.notifier)
        .resendVerification();
    expect(container.read(verifyEmailViewModelProvider).resendCooldownSeconds,
        60);
    expect(container.read(verifyEmailViewModelProvider).isSending, false);
  });
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/unit/features/auth/verify_email_view_model_test.dart
```

Expected: all 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/application/verify_email_view_model.dart \
        lib/features/auth/application/verify_email_view_model.freezed.dart \
        lib/features/auth/application/verify_email_view_model.g.dart \
        test/unit/features/auth/verify_email_view_model_test.dart
git commit -m "feat(mvvm): add VerifyEmailViewModel with cooldown timer + tests"
```

---

## Task 5: ForgotPasswordViewModel

**Files:**
- Create: `lib/features/auth/application/forgot_password_view_model.dart`
- Create: `test/unit/features/auth/forgot_password_view_model_test.dart`

- [ ] **Step 1: Create `forgot_password_view_model.dart`**

```dart
// lib/features/auth/application/forgot_password_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';

part 'forgot_password_view_model.freezed.dart';
part 'forgot_password_view_model.g.dart';

abstract class ForgotPasswordViewModel {
  bool get isLoading;
  bool get resetSent;

  Future<void> sendPasswordReset(String email);
}

@freezed
class _ForgotPasswordState with _$_ForgotPasswordState {
  const factory _ForgotPasswordState({
    @Default(false) bool isLoading,
    @Default(false) bool resetSent,
  }) = __ForgotPasswordState;
}

@riverpod
class ForgotPasswordViewModelNotifier
    extends _$ForgotPasswordViewModelNotifier
    implements ForgotPasswordViewModel {
  @override
  _ForgotPasswordState build() => const _ForgotPasswordState();

  @override bool get isLoading => state.isLoading;
  @override bool get resetSent => state.resetSent;

  @override
  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true);
    await ref.read(authProvider.notifier).sendPasswordReset(email);
    state = state.copyWith(isLoading: false, resetSent: true);
  }
}

@riverpod
ForgotPasswordViewModel forgotPasswordViewModel(
    ForgotPasswordViewModelRef ref) {
  ref.watch(forgotPasswordViewModelNotifierProvider);
  return ref.read(forgotPasswordViewModelNotifierProvider.notifier);
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Create `forgot_password_view_model_test.dart`**

```dart
// test/unit/features/auth/forgot_password_view_model_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/application/forgot_password_view_model.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';

class _FakeAuth extends Auth {
  @override AuthState build() => const AuthState.unauthenticated();
  void push(AuthState s) => state = s;
  @override Future<void> signInWithGoogle() async {}
  @override Future<void> signInWithApple() async {}
  @override Future<void> signInWithEmail(String e, String p) async {}
  @override Future<void> register(String e, String p) async {}
  @override Future<void> sendPasswordReset(String email) async {}
  @override Future<void> signOut() async {}
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override Locale build() => const Locale('es');
  @override Future<void> initialize(String? uid) async {}
  @override Future<void> setLocale(String code, String? uid) async {}
}

ProviderContainer _makeContainer() => ProviderContainer(overrides: [
      authProvider.overrideWith(() => _FakeAuth()),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
    ]);

void main() {
  late ProviderContainer container;
  tearDown(() => container.dispose());

  test('initial state: not loading, not sent', () {
    container = _makeContainer();
    final vm = container.read(forgotPasswordViewModelProvider);
    expect(vm.isLoading, false);
    expect(vm.resetSent, false);
  });

  test('sendPasswordReset sets resetSent to true on completion', () async {
    container = _makeContainer();
    await container
        .read(forgotPasswordViewModelProvider)
        .sendPasswordReset('user@example.com');
    expect(container.read(forgotPasswordViewModelProvider).resetSent, true);
    expect(container.read(forgotPasswordViewModelProvider).isLoading, false);
  });
}
```

- [ ] **Step 4: Run tests**

```bash
flutter test test/unit/features/auth/forgot_password_view_model_test.dart
```

Expected: both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/application/forgot_password_view_model.dart \
        lib/features/auth/application/forgot_password_view_model.freezed.dart \
        lib/features/auth/application/forgot_password_view_model.g.dart \
        test/unit/features/auth/forgot_password_view_model_test.dart
git commit -m "feat(mvvm): add ForgotPasswordViewModel + tests"
```

---

## Task 6: Update LoginScreen + UI test

**Files:**
- Modify: `lib/features/auth/presentation/login_screen.dart`
- Modify: `test/ui/features/auth/login_screen_test.dart`

- [ ] **Step 1: Replace `login_screen.dart` content**

```dart
// lib/features/auth/presentation/login_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../i18n/presentation/language_selector_widget.dart';
import '../application/login_view_model.dart';
import '../domain/failures/auth_failure.dart';
import 'widgets/email_auth_form.dart';
import 'widgets/social_auth_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(loginViewModelProvider);

    ref.listen<LoginViewModel>(loginViewModelProvider, (_, next) {
      if (next.isAuthenticated) {
        context.go(AppRoutes.home);
        return;
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_failureMessage(next.error!, l10n))),
        );
        next.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const LanguageSelectorWidget(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                l10n.auth_title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.auth_subtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              SocialAuthButton(
                label: l10n.auth_google,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                isLoading: vm.isLoading,
                onPressed: () => vm.signInWithGoogle(),
              ),
              if (Platform.isIOS || Platform.isMacOS) ...[
                const SizedBox(height: 12),
                SocialAuthButton(
                  key: const Key('apple_button'),
                  label: l10n.auth_apple,
                  icon: const Icon(Icons.apple, size: 24),
                  isLoading: vm.isLoading,
                  onPressed: () => vm.signInWithApple(),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.auth_or_divider,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              EmailAuthForm(
                isLoading: vm.isLoading,
                submitLabel: l10n.auth_login,
                onSubmit: (email, password) =>
                    vm.signInWithEmail(email, password),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                child: Text(l10n.auth_forgot_password),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: Text(l10n.auth_no_account),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _failureMessage(AuthFailure failure, AppLocalizations l10n) =>
      failure.when(
        networkError: () => l10n.auth_error_network,
        invalidCredentials: () => l10n.auth_error_invalid_credentials,
        emailAlreadyInUse: () => l10n.auth_error_email_in_use,
        userNotFound: () => l10n.auth_error_user_not_found,
        weakPassword: () => l10n.auth_error_weak_password,
        emailNotVerified: () => l10n.error_generic,
        accountExistsWithDifferentCredential: (_, __) => l10n.error_generic,
        tooManyRequests: () => l10n.auth_error_too_many_requests,
        operationCancelled: () => l10n.error_generic,
        unknown: (_) => l10n.error_generic,
      );
}
```

- [ ] **Step 2: Replace `login_screen_test.dart` content**

```dart
// test/ui/features/auth/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/login_view_model.dart';
import 'package:toka/features/auth/presentation/login_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockLoginViewModel extends Mock implements LoginViewModel {}

GoRouter _fakeRouter() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const Scaffold()),
        GoRoute(
            path: '/forgot-password', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/', builder: (_, __) => const Scaffold()),
      ],
    );

_MockLoginViewModel _defaultMock() {
  final m = _MockLoginViewModel();
  when(() => m.isLoading).thenReturn(false);
  when(() => m.error).thenReturn(null);
  when(() => m.isAuthenticated).thenReturn(false);
  when(() => m.signInWithGoogle()).thenAnswer((_) async {});
  when(() => m.signInWithApple()).thenAnswer((_) async {});
  when(() => m.signInWithEmail(any(), any())).thenAnswer((_) async {});
  when(() => m.clearError()).thenReturn(null);
  return m;
}

Widget _wrap({_MockLoginViewModel? vm}) {
  return ProviderScope(
    overrides: [
      loginViewModelProvider.overrideWithValue(vm ?? _defaultMock()),
    ],
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      routerConfig: _fakeRouter(),
    ),
  );
}

void main() {
  testWidgets('renders Google button and email form fields', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('Apple button is NOT visible on non-iOS test platform',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('apple_button')), findsNothing);
  });

  testWidgets('email form shows validation errors when submitted empty',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio'), findsWidgets);
  });

  testWidgets('shows spinner when loading', (tester) async {
    final m = _MockLoginViewModel();
    when(() => m.isLoading).thenReturn(true);
    when(() => m.error).thenReturn(null);
    when(() => m.isAuthenticated).thenReturn(false);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('golden: login screen default state', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen.png'),
    );
  });
}
```

- [ ] **Step 3: Run UI tests**

```bash
flutter test test/ui/features/auth/login_screen_test.dart
```

Expected: all tests PASS. If the golden test fails with a pixel diff, regenerate:
```bash
flutter test test/ui/features/auth/login_screen_test.dart --update-goldens
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/presentation/login_screen.dart \
        test/ui/features/auth/login_screen_test.dart \
        test/ui/features/auth/goldens/login_screen.png
git commit -m "feat(mvvm): migrate LoginScreen to use LoginViewModel contract"
```

---

## Task 7: Update RegisterScreen + UI test

**Files:**
- Modify: `lib/features/auth/presentation/register_screen.dart`
- Modify: `test/ui/features/auth/register_screen_test.dart`

- [ ] **Step 1: Replace `register_screen.dart` content**

```dart
// lib/features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../application/register_view_model.dart';
import '../domain/failures/auth_failure.dart';
import 'widgets/email_auth_form.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(registerViewModelProvider);

    ref.listen<RegisterViewModel>(registerViewModelProvider, (_, next) {
      if (next.registrationComplete) {
        context.go(AppRoutes.verifyEmail);
        return;
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_failureMessage(next.error!, l10n))),
        );
        next.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auth_register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailAuthForm(
                showPasswordConfirm: true,
                isLoading: vm.isLoading,
                submitLabel: l10n.auth_register,
                onSubmit: (email, password) => vm.register(email, password),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.auth_have_account),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _failureMessage(AuthFailure failure, AppLocalizations l10n) =>
      failure.when(
        networkError: () => l10n.auth_error_network,
        invalidCredentials: () => l10n.auth_error_invalid_credentials,
        emailAlreadyInUse: () => l10n.auth_error_email_in_use,
        userNotFound: () => l10n.auth_error_user_not_found,
        weakPassword: () => l10n.auth_error_weak_password,
        emailNotVerified: () => l10n.error_generic,
        accountExistsWithDifferentCredential: (_, __) => l10n.error_generic,
        tooManyRequests: () => l10n.auth_error_too_many_requests,
        operationCancelled: () => l10n.error_generic,
        unknown: (_) => l10n.error_generic,
      );
}
```

- [ ] **Step 2: Replace `register_screen_test.dart` content**

Read `test/ui/features/auth/register_screen_test.dart` first to see existing test structure, then replace with:

```dart
// test/ui/features/auth/register_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/register_view_model.dart';
import 'package:toka/features/auth/presentation/register_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockRegisterViewModel extends Mock implements RegisterViewModel {}

GoRouter _fakeRouter() => GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/verify-email', builder: (_, __) => const Scaffold()),
      ],
    );

_MockRegisterViewModel _defaultMock() {
  final m = _MockRegisterViewModel();
  when(() => m.isLoading).thenReturn(false);
  when(() => m.error).thenReturn(null);
  when(() => m.registrationComplete).thenReturn(false);
  when(() => m.register(any(), any())).thenAnswer((_) async {});
  when(() => m.clearError()).thenReturn(null);
  return m;
}

Widget _wrap({_MockRegisterViewModel? vm}) => ProviderScope(
      overrides: [
        registerViewModelProvider.overrideWithValue(vm ?? _defaultMock()),
      ],
      child: MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        routerConfig: _fakeRouter(),
      ),
    );

void main() {
  testWidgets('renders email and password fields', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('shows spinner when loading', (tester) async {
    final m = _MockRegisterViewModel();
    when(() => m.isLoading).thenReturn(true);
    when(() => m.error).thenReturn(null);
    when(() => m.registrationComplete).thenReturn(false);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
```

- [ ] **Step 3: Run UI tests**

```bash
flutter test test/ui/features/auth/register_screen_test.dart
```

Expected: all tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/presentation/register_screen.dart \
        test/ui/features/auth/register_screen_test.dart
git commit -m "feat(mvvm): migrate RegisterScreen to use RegisterViewModel contract"
```

---

## Task 8: Update VerifyEmailScreen

**Files:**
- Modify: `lib/features/auth/presentation/verify_email_screen.dart`

Note: `VerifyEmailScreen` currently is a `ConsumerStatefulWidget` with timer logic. After this task it becomes a `ConsumerWidget` — the timer is in the ViewModel.

- [ ] **Step 1: Replace `verify_email_screen.dart` content**

```dart
// lib/features/auth/presentation/verify_email_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/verify_email_view_model.dart';

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(verifyEmailViewModelProvider);
    final isDisabled = vm.isSending || vm.resendCooldownSeconds > 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auth_verify_email_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80),
              const SizedBox(height: 24),
              Text(
                l10n.auth_verify_email_title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.auth_verify_email_body(vm.email),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: isDisabled ? null : vm.resendVerification,
                child: Text(
                  vm.resendCooldownSeconds > 0
                      ? l10n.auth_resend_cooldown(vm.resendCooldownSeconds)
                      : l10n.auth_resend_email,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run all auth tests to verify nothing broke**

```bash
flutter test test/unit/features/auth/ test/ui/features/auth/
```

Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/verify_email_screen.dart
git commit -m "feat(mvvm): migrate VerifyEmailScreen to ConsumerWidget via VerifyEmailViewModel"
```

---

## Task 9: Update ForgotPasswordScreen

**Files:**
- Modify: `lib/features/auth/presentation/forgot_password_screen.dart`

Note: `_loading` and `_sent` state fields move to ViewModel. Screen keeps form key and email controller (pure UI).

- [ ] **Step 1: Replace `forgot_password_screen.dart` content**

```dart
// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/forgot_password_view_model.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  static final _emailRegex = RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-z]{2,}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(forgotPasswordViewModelProvider)
        .sendPasswordReset(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(forgotPasswordViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auth_forgot_password_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: vm.resetSent
              ? _ConfirmationView(l10n: l10n)
              : _FormView(
                  formKey: _formKey,
                  emailCtrl: _emailCtrl,
                  loading: vm.isLoading,
                  onSend: _send,
                  l10n: l10n,
                  emailRegex: _emailRegex,
                ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.onSend,
    required this.l10n,
    required this.emailRegex,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSend;
  final AppLocalizations l10n;
  final RegExp emailRegex;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.auth_forgot_password_body),
          const SizedBox(height: 24),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.auth_email_label),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.auth_validation_required;
              }
              if (!emailRegex.hasMatch(v.trim())) {
                return l10n.auth_validation_email_invalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading ? null : onSend,
            style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(l10n.auth_send_reset_link),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          l10n.auth_reset_sent,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run all auth tests**

```bash
flutter test test/unit/features/auth/ test/ui/features/auth/
```

Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/forgot_password_screen.dart
git commit -m "feat(mvvm): migrate ForgotPasswordScreen — move loading/sent state to ViewModel"
```

---

## Pruebas manuales requeridas

Tras completar todos los tasks de este plan:

1. **Login con Google**: Tocar "Continuar con Google" → debe mostrar spinner → en caso de éxito navegar a Home.
2. **Login con email**: Introducir credenciales correctas → navegar a Home. Credenciales incorrectas → snackbar con mensaje de error.
3. **Registro**: Crear cuenta nueva → navegar a `VerifyEmailScreen`.
4. **VerifyEmail**: Tocar "Reenviar" → botón se deshabilita 60 segundos → cuenta atrás visible.
5. **ForgotPassword**: Introducir email válido → vista cambia a confirmación (sin recargar pantalla).
6. **Skin change**: Cambiar `SkinConfig.current` en `app_skin.dart` (cuando se añadan skins V2) y verificar que el router carga el skin correcto.
