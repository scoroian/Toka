// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PurchaseResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chargeId) success,
    required TResult Function() alreadyOwned,
    required TResult Function() cancelled,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chargeId)? success,
    TResult? Function()? alreadyOwned,
    TResult? Function()? cancelled,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chargeId)? success,
    TResult Function()? alreadyOwned,
    TResult Function()? cancelled,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PurchaseResultSuccess value) success,
    required TResult Function(PurchaseResultAlreadyOwned value) alreadyOwned,
    required TResult Function(PurchaseResultCancelled value) cancelled,
    required TResult Function(PurchaseResultError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PurchaseResultSuccess value)? success,
    TResult? Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult? Function(PurchaseResultCancelled value)? cancelled,
    TResult? Function(PurchaseResultError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PurchaseResultSuccess value)? success,
    TResult Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult Function(PurchaseResultCancelled value)? cancelled,
    TResult Function(PurchaseResultError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseResultCopyWith<$Res> {
  factory $PurchaseResultCopyWith(
          PurchaseResult value, $Res Function(PurchaseResult) then) =
      _$PurchaseResultCopyWithImpl<$Res, PurchaseResult>;
}

/// @nodoc
class _$PurchaseResultCopyWithImpl<$Res, $Val extends PurchaseResult>
    implements $PurchaseResultCopyWith<$Res> {
  _$PurchaseResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PurchaseResultSuccessImplCopyWith<$Res> {
  factory _$$PurchaseResultSuccessImplCopyWith(
          _$PurchaseResultSuccessImpl value,
          $Res Function(_$PurchaseResultSuccessImpl) then) =
      __$$PurchaseResultSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String chargeId});
}

/// @nodoc
class __$$PurchaseResultSuccessImplCopyWithImpl<$Res>
    extends _$PurchaseResultCopyWithImpl<$Res, _$PurchaseResultSuccessImpl>
    implements _$$PurchaseResultSuccessImplCopyWith<$Res> {
  __$$PurchaseResultSuccessImplCopyWithImpl(_$PurchaseResultSuccessImpl _value,
      $Res Function(_$PurchaseResultSuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chargeId = null,
  }) {
    return _then(_$PurchaseResultSuccessImpl(
      chargeId: null == chargeId
          ? _value.chargeId
          : chargeId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PurchaseResultSuccessImpl implements PurchaseResultSuccess {
  const _$PurchaseResultSuccessImpl({required this.chargeId});

  @override
  final String chargeId;

  @override
  String toString() {
    return 'PurchaseResult.success(chargeId: $chargeId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseResultSuccessImpl &&
            (identical(other.chargeId, chargeId) ||
                other.chargeId == chargeId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, chargeId);

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseResultSuccessImplCopyWith<_$PurchaseResultSuccessImpl>
      get copyWith => __$$PurchaseResultSuccessImplCopyWithImpl<
          _$PurchaseResultSuccessImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chargeId) success,
    required TResult Function() alreadyOwned,
    required TResult Function() cancelled,
    required TResult Function(String message) error,
  }) {
    return success(chargeId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chargeId)? success,
    TResult? Function()? alreadyOwned,
    TResult? Function()? cancelled,
    TResult? Function(String message)? error,
  }) {
    return success?.call(chargeId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chargeId)? success,
    TResult Function()? alreadyOwned,
    TResult Function()? cancelled,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(chargeId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PurchaseResultSuccess value) success,
    required TResult Function(PurchaseResultAlreadyOwned value) alreadyOwned,
    required TResult Function(PurchaseResultCancelled value) cancelled,
    required TResult Function(PurchaseResultError value) error,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PurchaseResultSuccess value)? success,
    TResult? Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult? Function(PurchaseResultCancelled value)? cancelled,
    TResult? Function(PurchaseResultError value)? error,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PurchaseResultSuccess value)? success,
    TResult Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult Function(PurchaseResultCancelled value)? cancelled,
    TResult Function(PurchaseResultError value)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class PurchaseResultSuccess implements PurchaseResult {
  const factory PurchaseResultSuccess({required final String chargeId}) =
      _$PurchaseResultSuccessImpl;

  String get chargeId;

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseResultSuccessImplCopyWith<_$PurchaseResultSuccessImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PurchaseResultAlreadyOwnedImplCopyWith<$Res> {
  factory _$$PurchaseResultAlreadyOwnedImplCopyWith(
          _$PurchaseResultAlreadyOwnedImpl value,
          $Res Function(_$PurchaseResultAlreadyOwnedImpl) then) =
      __$$PurchaseResultAlreadyOwnedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PurchaseResultAlreadyOwnedImplCopyWithImpl<$Res>
    extends _$PurchaseResultCopyWithImpl<$Res, _$PurchaseResultAlreadyOwnedImpl>
    implements _$$PurchaseResultAlreadyOwnedImplCopyWith<$Res> {
  __$$PurchaseResultAlreadyOwnedImplCopyWithImpl(
      _$PurchaseResultAlreadyOwnedImpl _value,
      $Res Function(_$PurchaseResultAlreadyOwnedImpl) _then)
      : super(_value, _then);

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PurchaseResultAlreadyOwnedImpl implements PurchaseResultAlreadyOwned {
  const _$PurchaseResultAlreadyOwnedImpl();

  @override
  String toString() {
    return 'PurchaseResult.alreadyOwned()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseResultAlreadyOwnedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chargeId) success,
    required TResult Function() alreadyOwned,
    required TResult Function() cancelled,
    required TResult Function(String message) error,
  }) {
    return alreadyOwned();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chargeId)? success,
    TResult? Function()? alreadyOwned,
    TResult? Function()? cancelled,
    TResult? Function(String message)? error,
  }) {
    return alreadyOwned?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chargeId)? success,
    TResult Function()? alreadyOwned,
    TResult Function()? cancelled,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (alreadyOwned != null) {
      return alreadyOwned();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PurchaseResultSuccess value) success,
    required TResult Function(PurchaseResultAlreadyOwned value) alreadyOwned,
    required TResult Function(PurchaseResultCancelled value) cancelled,
    required TResult Function(PurchaseResultError value) error,
  }) {
    return alreadyOwned(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PurchaseResultSuccess value)? success,
    TResult? Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult? Function(PurchaseResultCancelled value)? cancelled,
    TResult? Function(PurchaseResultError value)? error,
  }) {
    return alreadyOwned?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PurchaseResultSuccess value)? success,
    TResult Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult Function(PurchaseResultCancelled value)? cancelled,
    TResult Function(PurchaseResultError value)? error,
    required TResult orElse(),
  }) {
    if (alreadyOwned != null) {
      return alreadyOwned(this);
    }
    return orElse();
  }
}

abstract class PurchaseResultAlreadyOwned implements PurchaseResult {
  const factory PurchaseResultAlreadyOwned() = _$PurchaseResultAlreadyOwnedImpl;
}

/// @nodoc
abstract class _$$PurchaseResultCancelledImplCopyWith<$Res> {
  factory _$$PurchaseResultCancelledImplCopyWith(
          _$PurchaseResultCancelledImpl value,
          $Res Function(_$PurchaseResultCancelledImpl) then) =
      __$$PurchaseResultCancelledImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PurchaseResultCancelledImplCopyWithImpl<$Res>
    extends _$PurchaseResultCopyWithImpl<$Res, _$PurchaseResultCancelledImpl>
    implements _$$PurchaseResultCancelledImplCopyWith<$Res> {
  __$$PurchaseResultCancelledImplCopyWithImpl(
      _$PurchaseResultCancelledImpl _value,
      $Res Function(_$PurchaseResultCancelledImpl) _then)
      : super(_value, _then);

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PurchaseResultCancelledImpl implements PurchaseResultCancelled {
  const _$PurchaseResultCancelledImpl();

  @override
  String toString() {
    return 'PurchaseResult.cancelled()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseResultCancelledImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chargeId) success,
    required TResult Function() alreadyOwned,
    required TResult Function() cancelled,
    required TResult Function(String message) error,
  }) {
    return cancelled();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chargeId)? success,
    TResult? Function()? alreadyOwned,
    TResult? Function()? cancelled,
    TResult? Function(String message)? error,
  }) {
    return cancelled?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chargeId)? success,
    TResult Function()? alreadyOwned,
    TResult Function()? cancelled,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (cancelled != null) {
      return cancelled();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PurchaseResultSuccess value) success,
    required TResult Function(PurchaseResultAlreadyOwned value) alreadyOwned,
    required TResult Function(PurchaseResultCancelled value) cancelled,
    required TResult Function(PurchaseResultError value) error,
  }) {
    return cancelled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PurchaseResultSuccess value)? success,
    TResult? Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult? Function(PurchaseResultCancelled value)? cancelled,
    TResult? Function(PurchaseResultError value)? error,
  }) {
    return cancelled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PurchaseResultSuccess value)? success,
    TResult Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult Function(PurchaseResultCancelled value)? cancelled,
    TResult Function(PurchaseResultError value)? error,
    required TResult orElse(),
  }) {
    if (cancelled != null) {
      return cancelled(this);
    }
    return orElse();
  }
}

abstract class PurchaseResultCancelled implements PurchaseResult {
  const factory PurchaseResultCancelled() = _$PurchaseResultCancelledImpl;
}

/// @nodoc
abstract class _$$PurchaseResultErrorImplCopyWith<$Res> {
  factory _$$PurchaseResultErrorImplCopyWith(_$PurchaseResultErrorImpl value,
          $Res Function(_$PurchaseResultErrorImpl) then) =
      __$$PurchaseResultErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$PurchaseResultErrorImplCopyWithImpl<$Res>
    extends _$PurchaseResultCopyWithImpl<$Res, _$PurchaseResultErrorImpl>
    implements _$$PurchaseResultErrorImplCopyWith<$Res> {
  __$$PurchaseResultErrorImplCopyWithImpl(_$PurchaseResultErrorImpl _value,
      $Res Function(_$PurchaseResultErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$PurchaseResultErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PurchaseResultErrorImpl implements PurchaseResultError {
  const _$PurchaseResultErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'PurchaseResult.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseResultErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseResultErrorImplCopyWith<_$PurchaseResultErrorImpl> get copyWith =>
      __$$PurchaseResultErrorImplCopyWithImpl<_$PurchaseResultErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String chargeId) success,
    required TResult Function() alreadyOwned,
    required TResult Function() cancelled,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String chargeId)? success,
    TResult? Function()? alreadyOwned,
    TResult? Function()? cancelled,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String chargeId)? success,
    TResult Function()? alreadyOwned,
    TResult Function()? cancelled,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PurchaseResultSuccess value) success,
    required TResult Function(PurchaseResultAlreadyOwned value) alreadyOwned,
    required TResult Function(PurchaseResultCancelled value) cancelled,
    required TResult Function(PurchaseResultError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PurchaseResultSuccess value)? success,
    TResult? Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult? Function(PurchaseResultCancelled value)? cancelled,
    TResult? Function(PurchaseResultError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PurchaseResultSuccess value)? success,
    TResult Function(PurchaseResultAlreadyOwned value)? alreadyOwned,
    TResult Function(PurchaseResultCancelled value)? cancelled,
    TResult Function(PurchaseResultError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class PurchaseResultError implements PurchaseResult {
  const factory PurchaseResultError({required final String message}) =
      _$PurchaseResultErrorImpl;

  String get message;

  /// Create a copy of PurchaseResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseResultErrorImplCopyWith<_$PurchaseResultErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
