// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LoginState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isAuthenticated => throw _privateConstructorUsedError;
  AuthFailure? get error => throw _privateConstructorUsedError;

  /// Create a copy of _LoginState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$LoginStateCopyWith<_LoginState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$LoginStateCopyWith<$Res> {
  factory _$LoginStateCopyWith(
          _LoginState value, $Res Function(_LoginState) then) =
      __$LoginStateCopyWithImpl<$Res, _LoginState>;
  @useResult
  $Res call({bool isLoading, bool isAuthenticated, AuthFailure? error});

  $AuthFailureCopyWith<$Res>? get error;
}

/// @nodoc
class __$LoginStateCopyWithImpl<$Res, $Val extends _LoginState>
    implements _$LoginStateCopyWith<$Res> {
  __$LoginStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _LoginState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isAuthenticated = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAuthenticated: null == isAuthenticated
          ? _value.isAuthenticated
          : isAuthenticated // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as AuthFailure?,
    ) as $Val);
  }

  /// Create a copy of _LoginState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthFailureCopyWith<$Res>? get error {
    if (_value.error == null) {
      return null;
    }

    return $AuthFailureCopyWith<$Res>(_value.error!, (value) {
      return _then(_value.copyWith(error: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_LoginStateImplCopyWith<$Res>
    implements _$LoginStateCopyWith<$Res> {
  factory _$$_LoginStateImplCopyWith(
          _$_LoginStateImpl value, $Res Function(_$_LoginStateImpl) then) =
      __$$_LoginStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, bool isAuthenticated, AuthFailure? error});

  @override
  $AuthFailureCopyWith<$Res>? get error;
}

/// @nodoc
class __$$_LoginStateImplCopyWithImpl<$Res>
    extends __$LoginStateCopyWithImpl<$Res, _$_LoginStateImpl>
    implements _$$_LoginStateImplCopyWith<$Res> {
  __$$_LoginStateImplCopyWithImpl(
      _$_LoginStateImpl _value, $Res Function(_$_LoginStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _LoginState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isAuthenticated = null,
    Object? error = freezed,
  }) {
    return _then(_$_LoginStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAuthenticated: null == isAuthenticated
          ? _value.isAuthenticated
          : isAuthenticated // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as AuthFailure?,
    ));
  }
}

/// @nodoc

class _$_LoginStateImpl implements __LoginState {
  const _$_LoginStateImpl(
      {this.isLoading = false, this.isAuthenticated = false, this.error});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isAuthenticated;
  @override
  final AuthFailure? error;

  @override
  String toString() {
    return '_LoginState(isLoading: $isLoading, isAuthenticated: $isAuthenticated, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_LoginStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isAuthenticated, isAuthenticated) ||
                other.isAuthenticated == isAuthenticated) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isLoading, isAuthenticated, error);

  /// Create a copy of _LoginState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_LoginStateImplCopyWith<_$_LoginStateImpl> get copyWith =>
      __$$_LoginStateImplCopyWithImpl<_$_LoginStateImpl>(this, _$identity);
}

abstract class __LoginState implements _LoginState {
  const factory __LoginState(
      {final bool isLoading,
      final bool isAuthenticated,
      final AuthFailure? error}) = _$_LoginStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isAuthenticated;
  @override
  AuthFailure? get error;

  /// Create a copy of _LoginState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_LoginStateImplCopyWith<_$_LoginStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
