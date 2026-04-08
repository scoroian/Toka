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
class _LoginState with _$LoginState {
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
