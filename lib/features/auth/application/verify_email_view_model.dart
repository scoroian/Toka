// lib/features/auth/application/verify_email_view_model.dart
//
// Falsos positivos del analyzer: ver explicación en `login_view_model.dart`.
// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
import 'dart:async';

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
class _VerifyEmailState with _$VerifyEmailState {
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

  @override
  String get email => state.email;

  @override
  int get resendCooldownSeconds => state.resendCooldownSeconds;

  @override
  bool get isSending => state.isSending;

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
