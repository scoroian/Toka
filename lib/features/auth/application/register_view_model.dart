// lib/features/auth/application/register_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/failures/auth_failure.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

part 'register_view_model.freezed.dart';
part 'register_view_model.g.dart';

// ── 1. CONTRACT ────────────────────────────────────────────────────────────

abstract class RegisterViewModel {
  bool get isLoading;
  bool get registrationComplete;
  AuthFailure? get error;

  Future<void> register(String email, String password);
  void clearError();
}

// ── 2. INTERNAL STATE ──────────────────────────────────────────────────────

@freezed
class _RegisterState with _$RegisterState {
  const factory _RegisterState({
    @Default(false) bool isLoading,
    @Default(false) bool registrationComplete,
    AuthFailure? error,
  }) = __RegisterState;
}

// ── 3. IMPLEMENTATION ──────────────────────────────────────────────────────

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

  @override
  bool get isLoading => state.isLoading;

  @override
  bool get registrationComplete => state.registrationComplete;

  @override
  AuthFailure? get error => state.error;

  @override
  Future<void> register(String email, String password) =>
      ref.read(authProvider.notifier).register(email, password);

  @override
  void clearError() => state = state.copyWith(error: null);
}

// ── 4. TYPED PROVIDER (what screens import) ────────────────────────────────

@riverpod
RegisterViewModel registerViewModel(RegisterViewModelRef ref) {
  ref.watch(registerViewModelNotifierProvider);
  return ref.read(registerViewModelNotifierProvider.notifier);
}
