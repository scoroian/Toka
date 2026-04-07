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
class _ForgotPasswordState with _$ForgotPasswordState {
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

  @override
  bool get isLoading => state.isLoading;

  @override
  bool get resetSent => state.resetSent;

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
