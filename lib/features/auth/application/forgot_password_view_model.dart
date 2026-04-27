// lib/features/auth/application/forgot_password_view_model.dart
//
// Los warnings de `unused_element_parameter` son falsos positivos: los
// campos del factory `_State` se usan vía `copyWith()`, que el analyzer
// no rastrea. `library_private_types_in_public_api` es deliberado — la
// API pública es la clase abstracta `ForgotPasswordViewModel`.
// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
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
