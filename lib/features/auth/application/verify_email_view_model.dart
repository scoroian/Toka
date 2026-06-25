// lib/features/auth/application/verify_email_view_model.dart
//
// Falsos positivos del analyzer: ver explicación en `login_view_model.dart`.
// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/failures/auth_failure.dart';
import 'auth_provider.dart';

part 'verify_email_view_model.freezed.dart';
part 'verify_email_view_model.g.dart';

enum VerifyCheckOutcome { verified, notVerified, networkError, unknownError }

abstract class VerifyEmailViewModel {
  String get email;
  int get resendCooldownSeconds;
  bool get isSending;
  bool get isChecking;

  Future<void> resendVerification();
  Future<VerifyCheckOutcome> continueIfVerified();
  Future<void> pollVerification();
  Future<void> cancelAndSignOut();
}

@freezed
class _VerifyEmailState with _$VerifyEmailState {
  const factory _VerifyEmailState({
    @Default('') String email,
    @Default(0) int resendCooldownSeconds,
    @Default(false) bool isSending,
    @Default(false) bool isChecking,
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

  @override
  bool get isChecking => state.isChecking;

  @override
  Future<VerifyCheckOutcome> continueIfVerified() async {
    if (state.isChecking) return VerifyCheckOutcome.notVerified;
    state = state.copyWith(isChecking: true);
    try {
      final verified =
          await ref.read(authProvider.notifier).refreshEmailVerified();
      // Si quedó verificado, el router avanza y esta pantalla se desmonta:
      // NO tocamos el estado para evitar escribir tras el dispose.
      if (verified) return VerifyCheckOutcome.verified;
      state = state.copyWith(isChecking: false);
      return VerifyCheckOutcome.notVerified;
    } on AuthFailure catch (f) {
      state = state.copyWith(isChecking: false);
      return f.maybeWhen(
        networkError: () => VerifyCheckOutcome.networkError,
        orElse: () => VerifyCheckOutcome.unknownError,
      );
    } catch (_) {
      state = state.copyWith(isChecking: false);
      return VerifyCheckOutcome.unknownError;
    }
  }

  @override
  Future<void> pollVerification() async {
    try {
      await ref.read(authProvider.notifier).refreshEmailVerified();
    } catch (_) {
      // Silencioso: el polling no molesta al usuario con errores.
    }
  }

  @override
  Future<void> cancelAndSignOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

@riverpod
VerifyEmailViewModel verifyEmailViewModel(VerifyEmailViewModelRef ref) {
  ref.watch(verifyEmailViewModelNotifierProvider);
  return ref.read(verifyEmailViewModelNotifierProvider.notifier);
}
