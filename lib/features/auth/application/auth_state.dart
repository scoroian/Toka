import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/auth_user.dart';
import '../domain/failures/auth_failure.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(AuthUser user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(AuthFailure failure) = _Error;
}
