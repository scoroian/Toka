// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthFailure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthFailureCopyWith<$Res> {
  factory $AuthFailureCopyWith(
          AuthFailure value, $Res Function(AuthFailure) then) =
      _$AuthFailureCopyWithImpl<$Res, AuthFailure>;
}

/// @nodoc
class _$AuthFailureCopyWithImpl<$Res, $Val extends AuthFailure>
    implements $AuthFailureCopyWith<$Res> {
  _$AuthFailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NetworkErrorImplCopyWith<$Res> {
  factory _$$NetworkErrorImplCopyWith(
          _$NetworkErrorImpl value, $Res Function(_$NetworkErrorImpl) then) =
      __$$NetworkErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NetworkErrorImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$NetworkErrorImpl>
    implements _$$NetworkErrorImplCopyWith<$Res> {
  __$$NetworkErrorImplCopyWithImpl(
      _$NetworkErrorImpl _value, $Res Function(_$NetworkErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NetworkErrorImpl implements _NetworkError {
  const _$NetworkErrorImpl();

  @override
  String toString() {
    return 'AuthFailure.networkError()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NetworkErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return networkError();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return networkError?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return networkError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return networkError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError(this);
    }
    return orElse();
  }
}

abstract class _NetworkError implements AuthFailure {
  const factory _NetworkError() = _$NetworkErrorImpl;
}

/// @nodoc
abstract class _$$InvalidCredentialsImplCopyWith<$Res> {
  factory _$$InvalidCredentialsImplCopyWith(_$InvalidCredentialsImpl value,
          $Res Function(_$InvalidCredentialsImpl) then) =
      __$$InvalidCredentialsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InvalidCredentialsImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$InvalidCredentialsImpl>
    implements _$$InvalidCredentialsImplCopyWith<$Res> {
  __$$InvalidCredentialsImplCopyWithImpl(_$InvalidCredentialsImpl _value,
      $Res Function(_$InvalidCredentialsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InvalidCredentialsImpl implements _InvalidCredentials {
  const _$InvalidCredentialsImpl();

  @override
  String toString() {
    return 'AuthFailure.invalidCredentials()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InvalidCredentialsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return invalidCredentials();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return invalidCredentials?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (invalidCredentials != null) {
      return invalidCredentials();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return invalidCredentials(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return invalidCredentials?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (invalidCredentials != null) {
      return invalidCredentials(this);
    }
    return orElse();
  }
}

abstract class _InvalidCredentials implements AuthFailure {
  const factory _InvalidCredentials() = _$InvalidCredentialsImpl;
}

/// @nodoc
abstract class _$$EmailAlreadyInUseImplCopyWith<$Res> {
  factory _$$EmailAlreadyInUseImplCopyWith(_$EmailAlreadyInUseImpl value,
          $Res Function(_$EmailAlreadyInUseImpl) then) =
      __$$EmailAlreadyInUseImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$EmailAlreadyInUseImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$EmailAlreadyInUseImpl>
    implements _$$EmailAlreadyInUseImplCopyWith<$Res> {
  __$$EmailAlreadyInUseImplCopyWithImpl(_$EmailAlreadyInUseImpl _value,
      $Res Function(_$EmailAlreadyInUseImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$EmailAlreadyInUseImpl implements _EmailAlreadyInUse {
  const _$EmailAlreadyInUseImpl();

  @override
  String toString() {
    return 'AuthFailure.emailAlreadyInUse()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$EmailAlreadyInUseImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return emailAlreadyInUse();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return emailAlreadyInUse?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (emailAlreadyInUse != null) {
      return emailAlreadyInUse();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return emailAlreadyInUse(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return emailAlreadyInUse?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (emailAlreadyInUse != null) {
      return emailAlreadyInUse(this);
    }
    return orElse();
  }
}

abstract class _EmailAlreadyInUse implements AuthFailure {
  const factory _EmailAlreadyInUse() = _$EmailAlreadyInUseImpl;
}

/// @nodoc
abstract class _$$UserNotFoundImplCopyWith<$Res> {
  factory _$$UserNotFoundImplCopyWith(
          _$UserNotFoundImpl value, $Res Function(_$UserNotFoundImpl) then) =
      __$$UserNotFoundImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$UserNotFoundImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$UserNotFoundImpl>
    implements _$$UserNotFoundImplCopyWith<$Res> {
  __$$UserNotFoundImplCopyWithImpl(
      _$UserNotFoundImpl _value, $Res Function(_$UserNotFoundImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$UserNotFoundImpl implements _UserNotFound {
  const _$UserNotFoundImpl();

  @override
  String toString() {
    return 'AuthFailure.userNotFound()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$UserNotFoundImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return userNotFound();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return userNotFound?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (userNotFound != null) {
      return userNotFound();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return userNotFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return userNotFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (userNotFound != null) {
      return userNotFound(this);
    }
    return orElse();
  }
}

abstract class _UserNotFound implements AuthFailure {
  const factory _UserNotFound() = _$UserNotFoundImpl;
}

/// @nodoc
abstract class _$$WeakPasswordImplCopyWith<$Res> {
  factory _$$WeakPasswordImplCopyWith(
          _$WeakPasswordImpl value, $Res Function(_$WeakPasswordImpl) then) =
      __$$WeakPasswordImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$WeakPasswordImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$WeakPasswordImpl>
    implements _$$WeakPasswordImplCopyWith<$Res> {
  __$$WeakPasswordImplCopyWithImpl(
      _$WeakPasswordImpl _value, $Res Function(_$WeakPasswordImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$WeakPasswordImpl implements _WeakPassword {
  const _$WeakPasswordImpl();

  @override
  String toString() {
    return 'AuthFailure.weakPassword()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$WeakPasswordImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return weakPassword();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return weakPassword?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (weakPassword != null) {
      return weakPassword();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return weakPassword(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return weakPassword?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (weakPassword != null) {
      return weakPassword(this);
    }
    return orElse();
  }
}

abstract class _WeakPassword implements AuthFailure {
  const factory _WeakPassword() = _$WeakPasswordImpl;
}

/// @nodoc
abstract class _$$EmailNotVerifiedImplCopyWith<$Res> {
  factory _$$EmailNotVerifiedImplCopyWith(_$EmailNotVerifiedImpl value,
          $Res Function(_$EmailNotVerifiedImpl) then) =
      __$$EmailNotVerifiedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$EmailNotVerifiedImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$EmailNotVerifiedImpl>
    implements _$$EmailNotVerifiedImplCopyWith<$Res> {
  __$$EmailNotVerifiedImplCopyWithImpl(_$EmailNotVerifiedImpl _value,
      $Res Function(_$EmailNotVerifiedImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$EmailNotVerifiedImpl implements _EmailNotVerified {
  const _$EmailNotVerifiedImpl();

  @override
  String toString() {
    return 'AuthFailure.emailNotVerified()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$EmailNotVerifiedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return emailNotVerified();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return emailNotVerified?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (emailNotVerified != null) {
      return emailNotVerified();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return emailNotVerified(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return emailNotVerified?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (emailNotVerified != null) {
      return emailNotVerified(this);
    }
    return orElse();
  }
}

abstract class _EmailNotVerified implements AuthFailure {
  const factory _EmailNotVerified() = _$EmailNotVerifiedImpl;
}

/// @nodoc
abstract class _$$AccountExistsWithDifferentCredentialImplCopyWith<$Res> {
  factory _$$AccountExistsWithDifferentCredentialImplCopyWith(
          _$AccountExistsWithDifferentCredentialImpl value,
          $Res Function(_$AccountExistsWithDifferentCredentialImpl) then) =
      __$$AccountExistsWithDifferentCredentialImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String email, List<String> providers});
}

/// @nodoc
class __$$AccountExistsWithDifferentCredentialImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res,
        _$AccountExistsWithDifferentCredentialImpl>
    implements _$$AccountExistsWithDifferentCredentialImplCopyWith<$Res> {
  __$$AccountExistsWithDifferentCredentialImplCopyWithImpl(
      _$AccountExistsWithDifferentCredentialImpl _value,
      $Res Function(_$AccountExistsWithDifferentCredentialImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? providers = null,
  }) {
    return _then(_$AccountExistsWithDifferentCredentialImpl(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      providers: null == providers
          ? _value._providers
          : providers // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$AccountExistsWithDifferentCredentialImpl
    implements _AccountExistsWithDifferentCredential {
  const _$AccountExistsWithDifferentCredentialImpl(
      {required this.email, required final List<String> providers})
      : _providers = providers;

  @override
  final String email;
  final List<String> _providers;
  @override
  List<String> get providers {
    if (_providers is EqualUnmodifiableListView) return _providers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_providers);
  }

  @override
  String toString() {
    return 'AuthFailure.accountExistsWithDifferentCredential(email: $email, providers: $providers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountExistsWithDifferentCredentialImpl &&
            (identical(other.email, email) || other.email == email) &&
            const DeepCollectionEquality()
                .equals(other._providers, _providers));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, email, const DeepCollectionEquality().hash(_providers));

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountExistsWithDifferentCredentialImplCopyWith<
          _$AccountExistsWithDifferentCredentialImpl>
      get copyWith => __$$AccountExistsWithDifferentCredentialImplCopyWithImpl<
          _$AccountExistsWithDifferentCredentialImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return accountExistsWithDifferentCredential(email, providers);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return accountExistsWithDifferentCredential?.call(email, providers);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (accountExistsWithDifferentCredential != null) {
      return accountExistsWithDifferentCredential(email, providers);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return accountExistsWithDifferentCredential(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return accountExistsWithDifferentCredential?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (accountExistsWithDifferentCredential != null) {
      return accountExistsWithDifferentCredential(this);
    }
    return orElse();
  }
}

abstract class _AccountExistsWithDifferentCredential implements AuthFailure {
  const factory _AccountExistsWithDifferentCredential(
          {required final String email,
          required final List<String> providers}) =
      _$AccountExistsWithDifferentCredentialImpl;

  String get email;
  List<String> get providers;

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountExistsWithDifferentCredentialImplCopyWith<
          _$AccountExistsWithDifferentCredentialImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TooManyRequestsImplCopyWith<$Res> {
  factory _$$TooManyRequestsImplCopyWith(_$TooManyRequestsImpl value,
          $Res Function(_$TooManyRequestsImpl) then) =
      __$$TooManyRequestsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TooManyRequestsImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$TooManyRequestsImpl>
    implements _$$TooManyRequestsImplCopyWith<$Res> {
  __$$TooManyRequestsImplCopyWithImpl(
      _$TooManyRequestsImpl _value, $Res Function(_$TooManyRequestsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$TooManyRequestsImpl implements _TooManyRequests {
  const _$TooManyRequestsImpl();

  @override
  String toString() {
    return 'AuthFailure.tooManyRequests()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$TooManyRequestsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return tooManyRequests();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return tooManyRequests?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (tooManyRequests != null) {
      return tooManyRequests();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return tooManyRequests(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return tooManyRequests?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (tooManyRequests != null) {
      return tooManyRequests(this);
    }
    return orElse();
  }
}

abstract class _TooManyRequests implements AuthFailure {
  const factory _TooManyRequests() = _$TooManyRequestsImpl;
}

/// @nodoc
abstract class _$$OperationCancelledImplCopyWith<$Res> {
  factory _$$OperationCancelledImplCopyWith(_$OperationCancelledImpl value,
          $Res Function(_$OperationCancelledImpl) then) =
      __$$OperationCancelledImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OperationCancelledImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$OperationCancelledImpl>
    implements _$$OperationCancelledImplCopyWith<$Res> {
  __$$OperationCancelledImplCopyWithImpl(_$OperationCancelledImpl _value,
      $Res Function(_$OperationCancelledImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OperationCancelledImpl implements _OperationCancelled {
  const _$OperationCancelledImpl();

  @override
  String toString() {
    return 'AuthFailure.operationCancelled()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$OperationCancelledImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return operationCancelled();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return operationCancelled?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (operationCancelled != null) {
      return operationCancelled();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return operationCancelled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return operationCancelled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (operationCancelled != null) {
      return operationCancelled(this);
    }
    return orElse();
  }
}

abstract class _OperationCancelled implements AuthFailure {
  const factory _OperationCancelled() = _$OperationCancelledImpl;
}

/// @nodoc
abstract class _$$UnknownImplCopyWith<$Res> {
  factory _$$UnknownImplCopyWith(
          _$UnknownImpl value, $Res Function(_$UnknownImpl) then) =
      __$$UnknownImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$UnknownImplCopyWithImpl<$Res>
    extends _$AuthFailureCopyWithImpl<$Res, _$UnknownImpl>
    implements _$$UnknownImplCopyWith<$Res> {
  __$$UnknownImplCopyWithImpl(
      _$UnknownImpl _value, $Res Function(_$UnknownImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$UnknownImpl(
      freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UnknownImpl implements _Unknown {
  const _$UnknownImpl([this.message]);

  @override
  final String? message;

  @override
  String toString() {
    return 'AuthFailure.unknown(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnknownImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnknownImplCopyWith<_$UnknownImpl> get copyWith =>
      __$$UnknownImplCopyWithImpl<_$UnknownImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() networkError,
    required TResult Function() invalidCredentials,
    required TResult Function() emailAlreadyInUse,
    required TResult Function() userNotFound,
    required TResult Function() weakPassword,
    required TResult Function() emailNotVerified,
    required TResult Function(String email, List<String> providers)
        accountExistsWithDifferentCredential,
    required TResult Function() tooManyRequests,
    required TResult Function() operationCancelled,
    required TResult Function(String? message) unknown,
  }) {
    return unknown(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? networkError,
    TResult? Function()? invalidCredentials,
    TResult? Function()? emailAlreadyInUse,
    TResult? Function()? userNotFound,
    TResult? Function()? weakPassword,
    TResult? Function()? emailNotVerified,
    TResult? Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult? Function()? tooManyRequests,
    TResult? Function()? operationCancelled,
    TResult? Function(String? message)? unknown,
  }) {
    return unknown?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? networkError,
    TResult Function()? invalidCredentials,
    TResult Function()? emailAlreadyInUse,
    TResult Function()? userNotFound,
    TResult Function()? weakPassword,
    TResult Function()? emailNotVerified,
    TResult Function(String email, List<String> providers)?
        accountExistsWithDifferentCredential,
    TResult Function()? tooManyRequests,
    TResult Function()? operationCancelled,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NetworkError value) networkError,
    required TResult Function(_InvalidCredentials value) invalidCredentials,
    required TResult Function(_EmailAlreadyInUse value) emailAlreadyInUse,
    required TResult Function(_UserNotFound value) userNotFound,
    required TResult Function(_WeakPassword value) weakPassword,
    required TResult Function(_EmailNotVerified value) emailNotVerified,
    required TResult Function(_AccountExistsWithDifferentCredential value)
        accountExistsWithDifferentCredential,
    required TResult Function(_TooManyRequests value) tooManyRequests,
    required TResult Function(_OperationCancelled value) operationCancelled,
    required TResult Function(_Unknown value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NetworkError value)? networkError,
    TResult? Function(_InvalidCredentials value)? invalidCredentials,
    TResult? Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult? Function(_UserNotFound value)? userNotFound,
    TResult? Function(_WeakPassword value)? weakPassword,
    TResult? Function(_EmailNotVerified value)? emailNotVerified,
    TResult? Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult? Function(_TooManyRequests value)? tooManyRequests,
    TResult? Function(_OperationCancelled value)? operationCancelled,
    TResult? Function(_Unknown value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NetworkError value)? networkError,
    TResult Function(_InvalidCredentials value)? invalidCredentials,
    TResult Function(_EmailAlreadyInUse value)? emailAlreadyInUse,
    TResult Function(_UserNotFound value)? userNotFound,
    TResult Function(_WeakPassword value)? weakPassword,
    TResult Function(_EmailNotVerified value)? emailNotVerified,
    TResult Function(_AccountExistsWithDifferentCredential value)?
        accountExistsWithDifferentCredential,
    TResult Function(_TooManyRequests value)? tooManyRequests,
    TResult Function(_OperationCancelled value)? operationCancelled,
    TResult Function(_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class _Unknown implements AuthFailure {
  const factory _Unknown([final String? message]) = _$UnknownImpl;

  String? get message;

  /// Create a copy of AuthFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnknownImplCopyWith<_$UnknownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
