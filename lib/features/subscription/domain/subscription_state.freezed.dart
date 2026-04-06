// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SubscriptionState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() free,
    required TResult Function(String plan, DateTime endsAt, bool autoRenew)
        active,
    required TResult Function(String plan, DateTime endsAt) cancelledPendingEnd,
    required TResult Function(String plan, DateTime? endsAt, int daysLeft)
        rescue,
    required TResult Function() expiredFree,
    required TResult Function(DateTime restoreUntil) restorable,
    required TResult Function() purged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? free,
    TResult? Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult? Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult? Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult? Function()? expiredFree,
    TResult? Function(DateTime restoreUntil)? restorable,
    TResult? Function()? purged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? free,
    TResult Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult Function()? expiredFree,
    TResult Function(DateTime restoreUntil)? restorable,
    TResult Function()? purged,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SubscriptionFree value) free,
    required TResult Function(SubscriptionActive value) active,
    required TResult Function(SubscriptionCancelledPendingEnd value)
        cancelledPendingEnd,
    required TResult Function(SubscriptionRescue value) rescue,
    required TResult Function(SubscriptionExpiredFree value) expiredFree,
    required TResult Function(SubscriptionRestorable value) restorable,
    required TResult Function(SubscriptionPurged value) purged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SubscriptionFree value)? free,
    TResult? Function(SubscriptionActive value)? active,
    TResult? Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult? Function(SubscriptionRescue value)? rescue,
    TResult? Function(SubscriptionExpiredFree value)? expiredFree,
    TResult? Function(SubscriptionRestorable value)? restorable,
    TResult? Function(SubscriptionPurged value)? purged,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SubscriptionFree value)? free,
    TResult Function(SubscriptionActive value)? active,
    TResult Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult Function(SubscriptionRescue value)? rescue,
    TResult Function(SubscriptionExpiredFree value)? expiredFree,
    TResult Function(SubscriptionRestorable value)? restorable,
    TResult Function(SubscriptionPurged value)? purged,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionStateCopyWith<$Res> {
  factory $SubscriptionStateCopyWith(
          SubscriptionState value, $Res Function(SubscriptionState) then) =
      _$SubscriptionStateCopyWithImpl<$Res, SubscriptionState>;
}

/// @nodoc
class _$SubscriptionStateCopyWithImpl<$Res, $Val extends SubscriptionState>
    implements $SubscriptionStateCopyWith<$Res> {
  _$SubscriptionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SubscriptionFreeImplCopyWith<$Res> {
  factory _$$SubscriptionFreeImplCopyWith(_$SubscriptionFreeImpl value,
          $Res Function(_$SubscriptionFreeImpl) then) =
      __$$SubscriptionFreeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SubscriptionFreeImplCopyWithImpl<$Res>
    extends _$SubscriptionStateCopyWithImpl<$Res, _$SubscriptionFreeImpl>
    implements _$$SubscriptionFreeImplCopyWith<$Res> {
  __$$SubscriptionFreeImplCopyWithImpl(_$SubscriptionFreeImpl _value,
      $Res Function(_$SubscriptionFreeImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SubscriptionFreeImpl implements SubscriptionFree {
  const _$SubscriptionFreeImpl();

  @override
  String toString() {
    return 'SubscriptionState.free()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SubscriptionFreeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() free,
    required TResult Function(String plan, DateTime endsAt, bool autoRenew)
        active,
    required TResult Function(String plan, DateTime endsAt) cancelledPendingEnd,
    required TResult Function(String plan, DateTime? endsAt, int daysLeft)
        rescue,
    required TResult Function() expiredFree,
    required TResult Function(DateTime restoreUntil) restorable,
    required TResult Function() purged,
  }) {
    return free();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? free,
    TResult? Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult? Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult? Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult? Function()? expiredFree,
    TResult? Function(DateTime restoreUntil)? restorable,
    TResult? Function()? purged,
  }) {
    return free?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? free,
    TResult Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult Function()? expiredFree,
    TResult Function(DateTime restoreUntil)? restorable,
    TResult Function()? purged,
    required TResult orElse(),
  }) {
    if (free != null) {
      return free();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SubscriptionFree value) free,
    required TResult Function(SubscriptionActive value) active,
    required TResult Function(SubscriptionCancelledPendingEnd value)
        cancelledPendingEnd,
    required TResult Function(SubscriptionRescue value) rescue,
    required TResult Function(SubscriptionExpiredFree value) expiredFree,
    required TResult Function(SubscriptionRestorable value) restorable,
    required TResult Function(SubscriptionPurged value) purged,
  }) {
    return free(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SubscriptionFree value)? free,
    TResult? Function(SubscriptionActive value)? active,
    TResult? Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult? Function(SubscriptionRescue value)? rescue,
    TResult? Function(SubscriptionExpiredFree value)? expiredFree,
    TResult? Function(SubscriptionRestorable value)? restorable,
    TResult? Function(SubscriptionPurged value)? purged,
  }) {
    return free?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SubscriptionFree value)? free,
    TResult Function(SubscriptionActive value)? active,
    TResult Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult Function(SubscriptionRescue value)? rescue,
    TResult Function(SubscriptionExpiredFree value)? expiredFree,
    TResult Function(SubscriptionRestorable value)? restorable,
    TResult Function(SubscriptionPurged value)? purged,
    required TResult orElse(),
  }) {
    if (free != null) {
      return free(this);
    }
    return orElse();
  }
}

abstract class SubscriptionFree implements SubscriptionState {
  const factory SubscriptionFree() = _$SubscriptionFreeImpl;
}

/// @nodoc
abstract class _$$SubscriptionActiveImplCopyWith<$Res> {
  factory _$$SubscriptionActiveImplCopyWith(_$SubscriptionActiveImpl value,
          $Res Function(_$SubscriptionActiveImpl) then) =
      __$$SubscriptionActiveImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String plan, DateTime endsAt, bool autoRenew});
}

/// @nodoc
class __$$SubscriptionActiveImplCopyWithImpl<$Res>
    extends _$SubscriptionStateCopyWithImpl<$Res, _$SubscriptionActiveImpl>
    implements _$$SubscriptionActiveImplCopyWith<$Res> {
  __$$SubscriptionActiveImplCopyWithImpl(_$SubscriptionActiveImpl _value,
      $Res Function(_$SubscriptionActiveImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? endsAt = null,
    Object? autoRenew = null,
  }) {
    return _then(_$SubscriptionActiveImpl(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      autoRenew: null == autoRenew
          ? _value.autoRenew
          : autoRenew // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$SubscriptionActiveImpl implements SubscriptionActive {
  const _$SubscriptionActiveImpl(
      {required this.plan, required this.endsAt, required this.autoRenew});

  @override
  final String plan;
  @override
  final DateTime endsAt;
  @override
  final bool autoRenew;

  @override
  String toString() {
    return 'SubscriptionState.active(plan: $plan, endsAt: $endsAt, autoRenew: $autoRenew)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionActiveImpl &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.autoRenew, autoRenew) ||
                other.autoRenew == autoRenew));
  }

  @override
  int get hashCode => Object.hash(runtimeType, plan, endsAt, autoRenew);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionActiveImplCopyWith<_$SubscriptionActiveImpl> get copyWith =>
      __$$SubscriptionActiveImplCopyWithImpl<_$SubscriptionActiveImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() free,
    required TResult Function(String plan, DateTime endsAt, bool autoRenew)
        active,
    required TResult Function(String plan, DateTime endsAt) cancelledPendingEnd,
    required TResult Function(String plan, DateTime? endsAt, int daysLeft)
        rescue,
    required TResult Function() expiredFree,
    required TResult Function(DateTime restoreUntil) restorable,
    required TResult Function() purged,
  }) {
    return active(plan, endsAt, autoRenew);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? free,
    TResult? Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult? Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult? Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult? Function()? expiredFree,
    TResult? Function(DateTime restoreUntil)? restorable,
    TResult? Function()? purged,
  }) {
    return active?.call(plan, endsAt, autoRenew);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? free,
    TResult Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult Function()? expiredFree,
    TResult Function(DateTime restoreUntil)? restorable,
    TResult Function()? purged,
    required TResult orElse(),
  }) {
    if (active != null) {
      return active(plan, endsAt, autoRenew);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SubscriptionFree value) free,
    required TResult Function(SubscriptionActive value) active,
    required TResult Function(SubscriptionCancelledPendingEnd value)
        cancelledPendingEnd,
    required TResult Function(SubscriptionRescue value) rescue,
    required TResult Function(SubscriptionExpiredFree value) expiredFree,
    required TResult Function(SubscriptionRestorable value) restorable,
    required TResult Function(SubscriptionPurged value) purged,
  }) {
    return active(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SubscriptionFree value)? free,
    TResult? Function(SubscriptionActive value)? active,
    TResult? Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult? Function(SubscriptionRescue value)? rescue,
    TResult? Function(SubscriptionExpiredFree value)? expiredFree,
    TResult? Function(SubscriptionRestorable value)? restorable,
    TResult? Function(SubscriptionPurged value)? purged,
  }) {
    return active?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SubscriptionFree value)? free,
    TResult Function(SubscriptionActive value)? active,
    TResult Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult Function(SubscriptionRescue value)? rescue,
    TResult Function(SubscriptionExpiredFree value)? expiredFree,
    TResult Function(SubscriptionRestorable value)? restorable,
    TResult Function(SubscriptionPurged value)? purged,
    required TResult orElse(),
  }) {
    if (active != null) {
      return active(this);
    }
    return orElse();
  }
}

abstract class SubscriptionActive implements SubscriptionState {
  const factory SubscriptionActive(
      {required final String plan,
      required final DateTime endsAt,
      required final bool autoRenew}) = _$SubscriptionActiveImpl;

  String get plan;
  DateTime get endsAt;
  bool get autoRenew;

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionActiveImplCopyWith<_$SubscriptionActiveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SubscriptionCancelledPendingEndImplCopyWith<$Res> {
  factory _$$SubscriptionCancelledPendingEndImplCopyWith(
          _$SubscriptionCancelledPendingEndImpl value,
          $Res Function(_$SubscriptionCancelledPendingEndImpl) then) =
      __$$SubscriptionCancelledPendingEndImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String plan, DateTime endsAt});
}

/// @nodoc
class __$$SubscriptionCancelledPendingEndImplCopyWithImpl<$Res>
    extends _$SubscriptionStateCopyWithImpl<$Res,
        _$SubscriptionCancelledPendingEndImpl>
    implements _$$SubscriptionCancelledPendingEndImplCopyWith<$Res> {
  __$$SubscriptionCancelledPendingEndImplCopyWithImpl(
      _$SubscriptionCancelledPendingEndImpl _value,
      $Res Function(_$SubscriptionCancelledPendingEndImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? endsAt = null,
  }) {
    return _then(_$SubscriptionCancelledPendingEndImpl(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$SubscriptionCancelledPendingEndImpl
    implements SubscriptionCancelledPendingEnd {
  const _$SubscriptionCancelledPendingEndImpl(
      {required this.plan, required this.endsAt});

  @override
  final String plan;
  @override
  final DateTime endsAt;

  @override
  String toString() {
    return 'SubscriptionState.cancelledPendingEnd(plan: $plan, endsAt: $endsAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionCancelledPendingEndImpl &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, plan, endsAt);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionCancelledPendingEndImplCopyWith<
          _$SubscriptionCancelledPendingEndImpl>
      get copyWith => __$$SubscriptionCancelledPendingEndImplCopyWithImpl<
          _$SubscriptionCancelledPendingEndImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() free,
    required TResult Function(String plan, DateTime endsAt, bool autoRenew)
        active,
    required TResult Function(String plan, DateTime endsAt) cancelledPendingEnd,
    required TResult Function(String plan, DateTime? endsAt, int daysLeft)
        rescue,
    required TResult Function() expiredFree,
    required TResult Function(DateTime restoreUntil) restorable,
    required TResult Function() purged,
  }) {
    return cancelledPendingEnd(plan, endsAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? free,
    TResult? Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult? Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult? Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult? Function()? expiredFree,
    TResult? Function(DateTime restoreUntil)? restorable,
    TResult? Function()? purged,
  }) {
    return cancelledPendingEnd?.call(plan, endsAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? free,
    TResult Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult Function()? expiredFree,
    TResult Function(DateTime restoreUntil)? restorable,
    TResult Function()? purged,
    required TResult orElse(),
  }) {
    if (cancelledPendingEnd != null) {
      return cancelledPendingEnd(plan, endsAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SubscriptionFree value) free,
    required TResult Function(SubscriptionActive value) active,
    required TResult Function(SubscriptionCancelledPendingEnd value)
        cancelledPendingEnd,
    required TResult Function(SubscriptionRescue value) rescue,
    required TResult Function(SubscriptionExpiredFree value) expiredFree,
    required TResult Function(SubscriptionRestorable value) restorable,
    required TResult Function(SubscriptionPurged value) purged,
  }) {
    return cancelledPendingEnd(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SubscriptionFree value)? free,
    TResult? Function(SubscriptionActive value)? active,
    TResult? Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult? Function(SubscriptionRescue value)? rescue,
    TResult? Function(SubscriptionExpiredFree value)? expiredFree,
    TResult? Function(SubscriptionRestorable value)? restorable,
    TResult? Function(SubscriptionPurged value)? purged,
  }) {
    return cancelledPendingEnd?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SubscriptionFree value)? free,
    TResult Function(SubscriptionActive value)? active,
    TResult Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult Function(SubscriptionRescue value)? rescue,
    TResult Function(SubscriptionExpiredFree value)? expiredFree,
    TResult Function(SubscriptionRestorable value)? restorable,
    TResult Function(SubscriptionPurged value)? purged,
    required TResult orElse(),
  }) {
    if (cancelledPendingEnd != null) {
      return cancelledPendingEnd(this);
    }
    return orElse();
  }
}

abstract class SubscriptionCancelledPendingEnd implements SubscriptionState {
  const factory SubscriptionCancelledPendingEnd(
      {required final String plan,
      required final DateTime endsAt}) = _$SubscriptionCancelledPendingEndImpl;

  String get plan;
  DateTime get endsAt;

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionCancelledPendingEndImplCopyWith<
          _$SubscriptionCancelledPendingEndImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SubscriptionRescueImplCopyWith<$Res> {
  factory _$$SubscriptionRescueImplCopyWith(_$SubscriptionRescueImpl value,
          $Res Function(_$SubscriptionRescueImpl) then) =
      __$$SubscriptionRescueImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String plan, DateTime? endsAt, int daysLeft});
}

/// @nodoc
class __$$SubscriptionRescueImplCopyWithImpl<$Res>
    extends _$SubscriptionStateCopyWithImpl<$Res, _$SubscriptionRescueImpl>
    implements _$$SubscriptionRescueImplCopyWith<$Res> {
  __$$SubscriptionRescueImplCopyWithImpl(_$SubscriptionRescueImpl _value,
      $Res Function(_$SubscriptionRescueImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? endsAt = freezed,
    Object? daysLeft = null,
  }) {
    return _then(_$SubscriptionRescueImpl(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as String,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      daysLeft: null == daysLeft
          ? _value.daysLeft
          : daysLeft // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$SubscriptionRescueImpl implements SubscriptionRescue {
  const _$SubscriptionRescueImpl(
      {required this.plan, required this.endsAt, required this.daysLeft});

  @override
  final String plan;
  @override
  final DateTime? endsAt;
  @override
  final int daysLeft;

  @override
  String toString() {
    return 'SubscriptionState.rescue(plan: $plan, endsAt: $endsAt, daysLeft: $daysLeft)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionRescueImpl &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.daysLeft, daysLeft) ||
                other.daysLeft == daysLeft));
  }

  @override
  int get hashCode => Object.hash(runtimeType, plan, endsAt, daysLeft);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionRescueImplCopyWith<_$SubscriptionRescueImpl> get copyWith =>
      __$$SubscriptionRescueImplCopyWithImpl<_$SubscriptionRescueImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() free,
    required TResult Function(String plan, DateTime endsAt, bool autoRenew)
        active,
    required TResult Function(String plan, DateTime endsAt) cancelledPendingEnd,
    required TResult Function(String plan, DateTime? endsAt, int daysLeft)
        rescue,
    required TResult Function() expiredFree,
    required TResult Function(DateTime restoreUntil) restorable,
    required TResult Function() purged,
  }) {
    return rescue(plan, endsAt, daysLeft);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? free,
    TResult? Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult? Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult? Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult? Function()? expiredFree,
    TResult? Function(DateTime restoreUntil)? restorable,
    TResult? Function()? purged,
  }) {
    return rescue?.call(plan, endsAt, daysLeft);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? free,
    TResult Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult Function()? expiredFree,
    TResult Function(DateTime restoreUntil)? restorable,
    TResult Function()? purged,
    required TResult orElse(),
  }) {
    if (rescue != null) {
      return rescue(plan, endsAt, daysLeft);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SubscriptionFree value) free,
    required TResult Function(SubscriptionActive value) active,
    required TResult Function(SubscriptionCancelledPendingEnd value)
        cancelledPendingEnd,
    required TResult Function(SubscriptionRescue value) rescue,
    required TResult Function(SubscriptionExpiredFree value) expiredFree,
    required TResult Function(SubscriptionRestorable value) restorable,
    required TResult Function(SubscriptionPurged value) purged,
  }) {
    return rescue(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SubscriptionFree value)? free,
    TResult? Function(SubscriptionActive value)? active,
    TResult? Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult? Function(SubscriptionRescue value)? rescue,
    TResult? Function(SubscriptionExpiredFree value)? expiredFree,
    TResult? Function(SubscriptionRestorable value)? restorable,
    TResult? Function(SubscriptionPurged value)? purged,
  }) {
    return rescue?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SubscriptionFree value)? free,
    TResult Function(SubscriptionActive value)? active,
    TResult Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult Function(SubscriptionRescue value)? rescue,
    TResult Function(SubscriptionExpiredFree value)? expiredFree,
    TResult Function(SubscriptionRestorable value)? restorable,
    TResult Function(SubscriptionPurged value)? purged,
    required TResult orElse(),
  }) {
    if (rescue != null) {
      return rescue(this);
    }
    return orElse();
  }
}

abstract class SubscriptionRescue implements SubscriptionState {
  const factory SubscriptionRescue(
      {required final String plan,
      required final DateTime? endsAt,
      required final int daysLeft}) = _$SubscriptionRescueImpl;

  String get plan;
  DateTime? get endsAt;
  int get daysLeft;

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionRescueImplCopyWith<_$SubscriptionRescueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SubscriptionExpiredFreeImplCopyWith<$Res> {
  factory _$$SubscriptionExpiredFreeImplCopyWith(
          _$SubscriptionExpiredFreeImpl value,
          $Res Function(_$SubscriptionExpiredFreeImpl) then) =
      __$$SubscriptionExpiredFreeImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SubscriptionExpiredFreeImplCopyWithImpl<$Res>
    extends _$SubscriptionStateCopyWithImpl<$Res, _$SubscriptionExpiredFreeImpl>
    implements _$$SubscriptionExpiredFreeImplCopyWith<$Res> {
  __$$SubscriptionExpiredFreeImplCopyWithImpl(
      _$SubscriptionExpiredFreeImpl _value,
      $Res Function(_$SubscriptionExpiredFreeImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SubscriptionExpiredFreeImpl implements SubscriptionExpiredFree {
  const _$SubscriptionExpiredFreeImpl();

  @override
  String toString() {
    return 'SubscriptionState.expiredFree()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionExpiredFreeImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() free,
    required TResult Function(String plan, DateTime endsAt, bool autoRenew)
        active,
    required TResult Function(String plan, DateTime endsAt) cancelledPendingEnd,
    required TResult Function(String plan, DateTime? endsAt, int daysLeft)
        rescue,
    required TResult Function() expiredFree,
    required TResult Function(DateTime restoreUntil) restorable,
    required TResult Function() purged,
  }) {
    return expiredFree();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? free,
    TResult? Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult? Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult? Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult? Function()? expiredFree,
    TResult? Function(DateTime restoreUntil)? restorable,
    TResult? Function()? purged,
  }) {
    return expiredFree?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? free,
    TResult Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult Function()? expiredFree,
    TResult Function(DateTime restoreUntil)? restorable,
    TResult Function()? purged,
    required TResult orElse(),
  }) {
    if (expiredFree != null) {
      return expiredFree();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SubscriptionFree value) free,
    required TResult Function(SubscriptionActive value) active,
    required TResult Function(SubscriptionCancelledPendingEnd value)
        cancelledPendingEnd,
    required TResult Function(SubscriptionRescue value) rescue,
    required TResult Function(SubscriptionExpiredFree value) expiredFree,
    required TResult Function(SubscriptionRestorable value) restorable,
    required TResult Function(SubscriptionPurged value) purged,
  }) {
    return expiredFree(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SubscriptionFree value)? free,
    TResult? Function(SubscriptionActive value)? active,
    TResult? Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult? Function(SubscriptionRescue value)? rescue,
    TResult? Function(SubscriptionExpiredFree value)? expiredFree,
    TResult? Function(SubscriptionRestorable value)? restorable,
    TResult? Function(SubscriptionPurged value)? purged,
  }) {
    return expiredFree?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SubscriptionFree value)? free,
    TResult Function(SubscriptionActive value)? active,
    TResult Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult Function(SubscriptionRescue value)? rescue,
    TResult Function(SubscriptionExpiredFree value)? expiredFree,
    TResult Function(SubscriptionRestorable value)? restorable,
    TResult Function(SubscriptionPurged value)? purged,
    required TResult orElse(),
  }) {
    if (expiredFree != null) {
      return expiredFree(this);
    }
    return orElse();
  }
}

abstract class SubscriptionExpiredFree implements SubscriptionState {
  const factory SubscriptionExpiredFree() = _$SubscriptionExpiredFreeImpl;
}

/// @nodoc
abstract class _$$SubscriptionRestorableImplCopyWith<$Res> {
  factory _$$SubscriptionRestorableImplCopyWith(
          _$SubscriptionRestorableImpl value,
          $Res Function(_$SubscriptionRestorableImpl) then) =
      __$$SubscriptionRestorableImplCopyWithImpl<$Res>;
  @useResult
  $Res call({DateTime restoreUntil});
}

/// @nodoc
class __$$SubscriptionRestorableImplCopyWithImpl<$Res>
    extends _$SubscriptionStateCopyWithImpl<$Res, _$SubscriptionRestorableImpl>
    implements _$$SubscriptionRestorableImplCopyWith<$Res> {
  __$$SubscriptionRestorableImplCopyWithImpl(
      _$SubscriptionRestorableImpl _value,
      $Res Function(_$SubscriptionRestorableImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? restoreUntil = null,
  }) {
    return _then(_$SubscriptionRestorableImpl(
      restoreUntil: null == restoreUntil
          ? _value.restoreUntil
          : restoreUntil // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$SubscriptionRestorableImpl implements SubscriptionRestorable {
  const _$SubscriptionRestorableImpl({required this.restoreUntil});

  @override
  final DateTime restoreUntil;

  @override
  String toString() {
    return 'SubscriptionState.restorable(restoreUntil: $restoreUntil)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionRestorableImpl &&
            (identical(other.restoreUntil, restoreUntil) ||
                other.restoreUntil == restoreUntil));
  }

  @override
  int get hashCode => Object.hash(runtimeType, restoreUntil);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionRestorableImplCopyWith<_$SubscriptionRestorableImpl>
      get copyWith => __$$SubscriptionRestorableImplCopyWithImpl<
          _$SubscriptionRestorableImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() free,
    required TResult Function(String plan, DateTime endsAt, bool autoRenew)
        active,
    required TResult Function(String plan, DateTime endsAt) cancelledPendingEnd,
    required TResult Function(String plan, DateTime? endsAt, int daysLeft)
        rescue,
    required TResult Function() expiredFree,
    required TResult Function(DateTime restoreUntil) restorable,
    required TResult Function() purged,
  }) {
    return restorable(restoreUntil);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? free,
    TResult? Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult? Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult? Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult? Function()? expiredFree,
    TResult? Function(DateTime restoreUntil)? restorable,
    TResult? Function()? purged,
  }) {
    return restorable?.call(restoreUntil);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? free,
    TResult Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult Function()? expiredFree,
    TResult Function(DateTime restoreUntil)? restorable,
    TResult Function()? purged,
    required TResult orElse(),
  }) {
    if (restorable != null) {
      return restorable(restoreUntil);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SubscriptionFree value) free,
    required TResult Function(SubscriptionActive value) active,
    required TResult Function(SubscriptionCancelledPendingEnd value)
        cancelledPendingEnd,
    required TResult Function(SubscriptionRescue value) rescue,
    required TResult Function(SubscriptionExpiredFree value) expiredFree,
    required TResult Function(SubscriptionRestorable value) restorable,
    required TResult Function(SubscriptionPurged value) purged,
  }) {
    return restorable(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SubscriptionFree value)? free,
    TResult? Function(SubscriptionActive value)? active,
    TResult? Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult? Function(SubscriptionRescue value)? rescue,
    TResult? Function(SubscriptionExpiredFree value)? expiredFree,
    TResult? Function(SubscriptionRestorable value)? restorable,
    TResult? Function(SubscriptionPurged value)? purged,
  }) {
    return restorable?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SubscriptionFree value)? free,
    TResult Function(SubscriptionActive value)? active,
    TResult Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult Function(SubscriptionRescue value)? rescue,
    TResult Function(SubscriptionExpiredFree value)? expiredFree,
    TResult Function(SubscriptionRestorable value)? restorable,
    TResult Function(SubscriptionPurged value)? purged,
    required TResult orElse(),
  }) {
    if (restorable != null) {
      return restorable(this);
    }
    return orElse();
  }
}

abstract class SubscriptionRestorable implements SubscriptionState {
  const factory SubscriptionRestorable({required final DateTime restoreUntil}) =
      _$SubscriptionRestorableImpl;

  DateTime get restoreUntil;

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubscriptionRestorableImplCopyWith<_$SubscriptionRestorableImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SubscriptionPurgedImplCopyWith<$Res> {
  factory _$$SubscriptionPurgedImplCopyWith(_$SubscriptionPurgedImpl value,
          $Res Function(_$SubscriptionPurgedImpl) then) =
      __$$SubscriptionPurgedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SubscriptionPurgedImplCopyWithImpl<$Res>
    extends _$SubscriptionStateCopyWithImpl<$Res, _$SubscriptionPurgedImpl>
    implements _$$SubscriptionPurgedImplCopyWith<$Res> {
  __$$SubscriptionPurgedImplCopyWithImpl(_$SubscriptionPurgedImpl _value,
      $Res Function(_$SubscriptionPurgedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubscriptionState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SubscriptionPurgedImpl implements SubscriptionPurged {
  const _$SubscriptionPurgedImpl();

  @override
  String toString() {
    return 'SubscriptionState.purged()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SubscriptionPurgedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() free,
    required TResult Function(String plan, DateTime endsAt, bool autoRenew)
        active,
    required TResult Function(String plan, DateTime endsAt) cancelledPendingEnd,
    required TResult Function(String plan, DateTime? endsAt, int daysLeft)
        rescue,
    required TResult Function() expiredFree,
    required TResult Function(DateTime restoreUntil) restorable,
    required TResult Function() purged,
  }) {
    return purged();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? free,
    TResult? Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult? Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult? Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult? Function()? expiredFree,
    TResult? Function(DateTime restoreUntil)? restorable,
    TResult? Function()? purged,
  }) {
    return purged?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? free,
    TResult Function(String plan, DateTime endsAt, bool autoRenew)? active,
    TResult Function(String plan, DateTime endsAt)? cancelledPendingEnd,
    TResult Function(String plan, DateTime? endsAt, int daysLeft)? rescue,
    TResult Function()? expiredFree,
    TResult Function(DateTime restoreUntil)? restorable,
    TResult Function()? purged,
    required TResult orElse(),
  }) {
    if (purged != null) {
      return purged();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SubscriptionFree value) free,
    required TResult Function(SubscriptionActive value) active,
    required TResult Function(SubscriptionCancelledPendingEnd value)
        cancelledPendingEnd,
    required TResult Function(SubscriptionRescue value) rescue,
    required TResult Function(SubscriptionExpiredFree value) expiredFree,
    required TResult Function(SubscriptionRestorable value) restorable,
    required TResult Function(SubscriptionPurged value) purged,
  }) {
    return purged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SubscriptionFree value)? free,
    TResult? Function(SubscriptionActive value)? active,
    TResult? Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult? Function(SubscriptionRescue value)? rescue,
    TResult? Function(SubscriptionExpiredFree value)? expiredFree,
    TResult? Function(SubscriptionRestorable value)? restorable,
    TResult? Function(SubscriptionPurged value)? purged,
  }) {
    return purged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SubscriptionFree value)? free,
    TResult Function(SubscriptionActive value)? active,
    TResult Function(SubscriptionCancelledPendingEnd value)?
        cancelledPendingEnd,
    TResult Function(SubscriptionRescue value)? rescue,
    TResult Function(SubscriptionExpiredFree value)? expiredFree,
    TResult Function(SubscriptionRestorable value)? restorable,
    TResult Function(SubscriptionPurged value)? purged,
    required TResult orElse(),
  }) {
    if (purged != null) {
      return purged(this);
    }
    return orElse();
  }
}

abstract class SubscriptionPurged implements SubscriptionState {
  const factory SubscriptionPurged() = _$SubscriptionPurgedImpl;
}
