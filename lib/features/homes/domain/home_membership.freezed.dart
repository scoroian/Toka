// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_membership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeMembership {
  String get homeId => throw _privateConstructorUsedError;
  String get homeNameSnapshot => throw _privateConstructorUsedError;
  MemberRole get role => throw _privateConstructorUsedError;
  BillingState get billingState => throw _privateConstructorUsedError;
  MemberStatus get status => throw _privateConstructorUsedError;
  DateTime get joinedAt => throw _privateConstructorUsedError;
  DateTime? get leftAt => throw _privateConstructorUsedError;
  bool get hasPendingToday => throw _privateConstructorUsedError;

  /// Create a copy of HomeMembership
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeMembershipCopyWith<HomeMembership> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeMembershipCopyWith<$Res> {
  factory $HomeMembershipCopyWith(
          HomeMembership value, $Res Function(HomeMembership) then) =
      _$HomeMembershipCopyWithImpl<$Res, HomeMembership>;
  @useResult
  $Res call(
      {String homeId,
      String homeNameSnapshot,
      MemberRole role,
      BillingState billingState,
      MemberStatus status,
      DateTime joinedAt,
      DateTime? leftAt,
      bool hasPendingToday});
}

/// @nodoc
class _$HomeMembershipCopyWithImpl<$Res, $Val extends HomeMembership>
    implements $HomeMembershipCopyWith<$Res> {
  _$HomeMembershipCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeMembership
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? homeId = null,
    Object? homeNameSnapshot = null,
    Object? role = null,
    Object? billingState = null,
    Object? status = null,
    Object? joinedAt = null,
    Object? leftAt = freezed,
    Object? hasPendingToday = null,
  }) {
    return _then(_value.copyWith(
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      homeNameSnapshot: null == homeNameSnapshot
          ? _value.homeNameSnapshot
          : homeNameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MemberRole,
      billingState: null == billingState
          ? _value.billingState
          : billingState // ignore: cast_nullable_to_non_nullable
              as BillingState,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MemberStatus,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      leftAt: freezed == leftAt
          ? _value.leftAt
          : leftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hasPendingToday: null == hasPendingToday
          ? _value.hasPendingToday
          : hasPendingToday // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeMembershipImplCopyWith<$Res>
    implements $HomeMembershipCopyWith<$Res> {
  factory _$$HomeMembershipImplCopyWith(_$HomeMembershipImpl value,
          $Res Function(_$HomeMembershipImpl) then) =
      __$$HomeMembershipImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String homeId,
      String homeNameSnapshot,
      MemberRole role,
      BillingState billingState,
      MemberStatus status,
      DateTime joinedAt,
      DateTime? leftAt,
      bool hasPendingToday});
}

/// @nodoc
class __$$HomeMembershipImplCopyWithImpl<$Res>
    extends _$HomeMembershipCopyWithImpl<$Res, _$HomeMembershipImpl>
    implements _$$HomeMembershipImplCopyWith<$Res> {
  __$$HomeMembershipImplCopyWithImpl(
      _$HomeMembershipImpl _value, $Res Function(_$HomeMembershipImpl) _then)
      : super(_value, _then);

  /// Create a copy of HomeMembership
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? homeId = null,
    Object? homeNameSnapshot = null,
    Object? role = null,
    Object? billingState = null,
    Object? status = null,
    Object? joinedAt = null,
    Object? leftAt = freezed,
    Object? hasPendingToday = null,
  }) {
    return _then(_$HomeMembershipImpl(
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      homeNameSnapshot: null == homeNameSnapshot
          ? _value.homeNameSnapshot
          : homeNameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MemberRole,
      billingState: null == billingState
          ? _value.billingState
          : billingState // ignore: cast_nullable_to_non_nullable
              as BillingState,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MemberStatus,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      leftAt: freezed == leftAt
          ? _value.leftAt
          : leftAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      hasPendingToday: null == hasPendingToday
          ? _value.hasPendingToday
          : hasPendingToday // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$HomeMembershipImpl implements _HomeMembership {
  const _$HomeMembershipImpl(
      {required this.homeId,
      required this.homeNameSnapshot,
      required this.role,
      required this.billingState,
      required this.status,
      required this.joinedAt,
      this.leftAt,
      this.hasPendingToday = false});

  @override
  final String homeId;
  @override
  final String homeNameSnapshot;
  @override
  final MemberRole role;
  @override
  final BillingState billingState;
  @override
  final MemberStatus status;
  @override
  final DateTime joinedAt;
  @override
  final DateTime? leftAt;
  @override
  @JsonKey()
  final bool hasPendingToday;

  @override
  String toString() {
    return 'HomeMembership(homeId: $homeId, homeNameSnapshot: $homeNameSnapshot, role: $role, billingState: $billingState, status: $status, joinedAt: $joinedAt, leftAt: $leftAt, hasPendingToday: $hasPendingToday)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeMembershipImpl &&
            (identical(other.homeId, homeId) || other.homeId == homeId) &&
            (identical(other.homeNameSnapshot, homeNameSnapshot) ||
                other.homeNameSnapshot == homeNameSnapshot) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.billingState, billingState) ||
                other.billingState == billingState) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.leftAt, leftAt) || other.leftAt == leftAt) &&
            (identical(other.hasPendingToday, hasPendingToday) ||
                other.hasPendingToday == hasPendingToday));
  }

  @override
  int get hashCode => Object.hash(runtimeType, homeId, homeNameSnapshot, role,
      billingState, status, joinedAt, leftAt, hasPendingToday);

  /// Create a copy of HomeMembership
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeMembershipImplCopyWith<_$HomeMembershipImpl> get copyWith =>
      __$$HomeMembershipImplCopyWithImpl<_$HomeMembershipImpl>(
          this, _$identity);
}

abstract class _HomeMembership implements HomeMembership {
  const factory _HomeMembership(
      {required final String homeId,
      required final String homeNameSnapshot,
      required final MemberRole role,
      required final BillingState billingState,
      required final MemberStatus status,
      required final DateTime joinedAt,
      final DateTime? leftAt,
      final bool hasPendingToday}) = _$HomeMembershipImpl;

  @override
  String get homeId;
  @override
  String get homeNameSnapshot;
  @override
  MemberRole get role;
  @override
  BillingState get billingState;
  @override
  MemberStatus get status;
  @override
  DateTime get joinedAt;
  @override
  DateTime? get leftAt;
  @override
  bool get hasPendingToday;

  /// Create a copy of HomeMembership
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeMembershipImplCopyWith<_$HomeMembershipImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
