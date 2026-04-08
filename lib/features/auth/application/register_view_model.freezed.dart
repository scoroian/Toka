// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'register_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RegisterState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get registrationComplete => throw _privateConstructorUsedError;
  AuthFailure? get error => throw _privateConstructorUsedError;

  /// Create a copy of _RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$RegisterStateCopyWith<_RegisterState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$RegisterStateCopyWith<$Res> {
  factory _$RegisterStateCopyWith(
          _RegisterState value, $Res Function(_RegisterState) then) =
      __$RegisterStateCopyWithImpl<$Res, _RegisterState>;
  @useResult
  $Res call({bool isLoading, bool registrationComplete, AuthFailure? error});

  $AuthFailureCopyWith<$Res>? get error;
}

/// @nodoc
class __$RegisterStateCopyWithImpl<$Res, $Val extends _RegisterState>
    implements _$RegisterStateCopyWith<$Res> {
  __$RegisterStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? registrationComplete = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      registrationComplete: null == registrationComplete
          ? _value.registrationComplete
          : registrationComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as AuthFailure?,
    ) as $Val);
  }

  /// Create a copy of _RegisterState
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
abstract class _$$_RegisterStateImplCopyWith<$Res>
    implements _$RegisterStateCopyWith<$Res> {
  factory _$$_RegisterStateImplCopyWith(_$_RegisterStateImpl value,
          $Res Function(_$_RegisterStateImpl) then) =
      __$$_RegisterStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, bool registrationComplete, AuthFailure? error});

  @override
  $AuthFailureCopyWith<$Res>? get error;
}

/// @nodoc
class __$$_RegisterStateImplCopyWithImpl<$Res>
    extends __$RegisterStateCopyWithImpl<$Res, _$_RegisterStateImpl>
    implements _$$_RegisterStateImplCopyWith<$Res> {
  __$$_RegisterStateImplCopyWithImpl(
      _$_RegisterStateImpl _value, $Res Function(_$_RegisterStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? registrationComplete = null,
    Object? error = freezed,
  }) {
    return _then(_$_RegisterStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      registrationComplete: null == registrationComplete
          ? _value.registrationComplete
          : registrationComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as AuthFailure?,
    ));
  }
}

/// @nodoc

class _$_RegisterStateImpl implements __RegisterState {
  const _$_RegisterStateImpl(
      {this.isLoading = false, this.registrationComplete = false, this.error});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool registrationComplete;
  @override
  final AuthFailure? error;

  @override
  String toString() {
    return '_RegisterState(isLoading: $isLoading, registrationComplete: $registrationComplete, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_RegisterStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.registrationComplete, registrationComplete) ||
                other.registrationComplete == registrationComplete) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isLoading, registrationComplete, error);

  /// Create a copy of _RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_RegisterStateImplCopyWith<_$_RegisterStateImpl> get copyWith =>
      __$$_RegisterStateImplCopyWithImpl<_$_RegisterStateImpl>(
          this, _$identity);
}

abstract class __RegisterState implements _RegisterState {
  const factory __RegisterState(
      {final bool isLoading,
      final bool registrationComplete,
      final AuthFailure? error}) = _$_RegisterStateImpl;

  @override
  bool get isLoading;
  @override
  bool get registrationComplete;
  @override
  AuthFailure? get error;

  /// Create a copy of _RegisterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_RegisterStateImplCopyWith<_$_RegisterStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
