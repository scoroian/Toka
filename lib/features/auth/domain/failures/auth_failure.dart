import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_failure.freezed.dart';

@freezed
class AuthFailure with _$AuthFailure {
  const factory AuthFailure.networkError() = _NetworkError;
  const factory AuthFailure.invalidCredentials() = _InvalidCredentials;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.userNotFound() = _UserNotFound;
  const factory AuthFailure.weakPassword() = _WeakPassword;
  const factory AuthFailure.emailNotVerified() = _EmailNotVerified;
  const factory AuthFailure.accountExistsWithDifferentCredential({
    required String email,
    required List<String> providers,
  }) = _AccountExistsWithDifferentCredential;
  const factory AuthFailure.tooManyRequests() = _TooManyRequests;
  const factory AuthFailure.operationCancelled() = _OperationCancelled;
  const factory AuthFailure.unknown([String? message]) = _Unknown;
}
