// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verify_email_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VerifyEmailState {
  String get email => throw _privateConstructorUsedError;
  int get resendCooldownSeconds => throw _privateConstructorUsedError;
  bool get isSending => throw _privateConstructorUsedError;

  /// Create a copy of _VerifyEmailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$VerifyEmailStateCopyWith<_VerifyEmailState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$VerifyEmailStateCopyWith<$Res> {
  factory _$VerifyEmailStateCopyWith(
          _VerifyEmailState value, $Res Function(_VerifyEmailState) then) =
      __$VerifyEmailStateCopyWithImpl<$Res, _VerifyEmailState>;
  @useResult
  $Res call({String email, int resendCooldownSeconds, bool isSending});
}

/// @nodoc
class __$VerifyEmailStateCopyWithImpl<$Res, $Val extends _VerifyEmailState>
    implements _$VerifyEmailStateCopyWith<$Res> {
  __$VerifyEmailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _VerifyEmailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? resendCooldownSeconds = null,
    Object? isSending = null,
  }) {
    return _then(_value.copyWith(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      resendCooldownSeconds: null == resendCooldownSeconds
          ? _value.resendCooldownSeconds
          : resendCooldownSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      isSending: null == isSending
          ? _value.isSending
          : isSending // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_VerifyEmailStateImplCopyWith<$Res>
    implements _$VerifyEmailStateCopyWith<$Res> {
  factory _$$_VerifyEmailStateImplCopyWith(_$_VerifyEmailStateImpl value,
          $Res Function(_$_VerifyEmailStateImpl) then) =
      __$$_VerifyEmailStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String email, int resendCooldownSeconds, bool isSending});
}

/// @nodoc
class __$$_VerifyEmailStateImplCopyWithImpl<$Res>
    extends __$VerifyEmailStateCopyWithImpl<$Res, _$_VerifyEmailStateImpl>
    implements _$$_VerifyEmailStateImplCopyWith<$Res> {
  __$$_VerifyEmailStateImplCopyWithImpl(_$_VerifyEmailStateImpl _value,
      $Res Function(_$_VerifyEmailStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _VerifyEmailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? resendCooldownSeconds = null,
    Object? isSending = null,
  }) {
    return _then(_$_VerifyEmailStateImpl(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      resendCooldownSeconds: null == resendCooldownSeconds
          ? _value.resendCooldownSeconds
          : resendCooldownSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      isSending: null == isSending
          ? _value.isSending
          : isSending // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_VerifyEmailStateImpl implements __VerifyEmailState {
  const _$_VerifyEmailStateImpl(
      {this.email = '',
      this.resendCooldownSeconds = 0,
      this.isSending = false});

  @override
  @JsonKey()
  final String email;
  @override
  @JsonKey()
  final int resendCooldownSeconds;
  @override
  @JsonKey()
  final bool isSending;

  @override
  String toString() {
    return '_VerifyEmailState(email: $email, resendCooldownSeconds: $resendCooldownSeconds, isSending: $isSending)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_VerifyEmailStateImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.resendCooldownSeconds, resendCooldownSeconds) ||
                other.resendCooldownSeconds == resendCooldownSeconds) &&
            (identical(other.isSending, isSending) ||
                other.isSending == isSending));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, email, resendCooldownSeconds, isSending);

  /// Create a copy of _VerifyEmailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_VerifyEmailStateImplCopyWith<_$_VerifyEmailStateImpl> get copyWith =>
      __$$_VerifyEmailStateImplCopyWithImpl<_$_VerifyEmailStateImpl>(
          this, _$identity);
}

abstract class __VerifyEmailState implements _VerifyEmailState {
  const factory __VerifyEmailState(
      {final String email,
      final int resendCooldownSeconds,
      final bool isSending}) = _$_VerifyEmailStateImpl;

  @override
  String get email;
  @override
  int get resendCooldownSeconds;
  @override
  bool get isSending;

  /// Create a copy of _VerifyEmailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_VerifyEmailStateImplCopyWith<_$_VerifyEmailStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
