// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ForgotPasswordState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get resetSent => throw _privateConstructorUsedError;

  /// Create a copy of _ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$ForgotPasswordStateCopyWith<_ForgotPasswordState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$ForgotPasswordStateCopyWith<$Res> {
  factory _$ForgotPasswordStateCopyWith(_ForgotPasswordState value,
          $Res Function(_ForgotPasswordState) then) =
      __$ForgotPasswordStateCopyWithImpl<$Res, _ForgotPasswordState>;
  @useResult
  $Res call({bool isLoading, bool resetSent});
}

/// @nodoc
class __$ForgotPasswordStateCopyWithImpl<$Res,
        $Val extends _ForgotPasswordState>
    implements _$ForgotPasswordStateCopyWith<$Res> {
  __$ForgotPasswordStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? resetSent = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      resetSent: null == resetSent
          ? _value.resetSent
          : resetSent // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ForgotPasswordStateImplCopyWith<$Res>
    implements _$ForgotPasswordStateCopyWith<$Res> {
  factory _$$_ForgotPasswordStateImplCopyWith(_$_ForgotPasswordStateImpl value,
          $Res Function(_$_ForgotPasswordStateImpl) then) =
      __$$_ForgotPasswordStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, bool resetSent});
}

/// @nodoc
class __$$_ForgotPasswordStateImplCopyWithImpl<$Res>
    extends __$ForgotPasswordStateCopyWithImpl<$Res, _$_ForgotPasswordStateImpl>
    implements _$$_ForgotPasswordStateImplCopyWith<$Res> {
  __$$_ForgotPasswordStateImplCopyWithImpl(_$_ForgotPasswordStateImpl _value,
      $Res Function(_$_ForgotPasswordStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? resetSent = null,
  }) {
    return _then(_$_ForgotPasswordStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      resetSent: null == resetSent
          ? _value.resetSent
          : resetSent // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_ForgotPasswordStateImpl implements __ForgotPasswordState {
  const _$_ForgotPasswordStateImpl(
      {this.isLoading = false, this.resetSent = false});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool resetSent;

  @override
  String toString() {
    return '_ForgotPasswordState(isLoading: $isLoading, resetSent: $resetSent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ForgotPasswordStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.resetSent, resetSent) ||
                other.resetSent == resetSent));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading, resetSent);

  /// Create a copy of _ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_ForgotPasswordStateImplCopyWith<_$_ForgotPasswordStateImpl>
      get copyWith =>
          __$$_ForgotPasswordStateImplCopyWithImpl<_$_ForgotPasswordStateImpl>(
              this, _$identity);
}

abstract class __ForgotPasswordState implements _ForgotPasswordState {
  const factory __ForgotPasswordState(
      {final bool isLoading,
      final bool resetSent}) = _$_ForgotPasswordStateImpl;

  @override
  bool get isLoading;
  @override
  bool get resetSent;

  /// Create a copy of _ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_ForgotPasswordStateImplCopyWith<_$_ForgotPasswordStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
