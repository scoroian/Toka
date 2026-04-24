// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Home {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get ownerUid => throw _privateConstructorUsedError;
  String? get currentPayerUid => throw _privateConstructorUsedError;
  String? get lastPayerUid => throw _privateConstructorUsedError;
  HomePremiumStatus get premiumStatus => throw _privateConstructorUsedError;
  String? get premiumPlan => throw _privateConstructorUsedError;
  DateTime? get premiumEndsAt => throw _privateConstructorUsedError;
  DateTime? get restoreUntil => throw _privateConstructorUsedError;
  bool get autoRenewEnabled => throw _privateConstructorUsedError;
  HomeLimits get limits => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get lastBillingError => throw _privateConstructorUsedError;

  /// Create a copy of Home
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeCopyWith<Home> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeCopyWith<$Res> {
  factory $HomeCopyWith(Home value, $Res Function(Home) then) =
      _$HomeCopyWithImpl<$Res, Home>;
  @useResult
  $Res call(
      {String id,
      String name,
      String ownerUid,
      String? currentPayerUid,
      String? lastPayerUid,
      HomePremiumStatus premiumStatus,
      String? premiumPlan,
      DateTime? premiumEndsAt,
      DateTime? restoreUntil,
      bool autoRenewEnabled,
      HomeLimits limits,
      DateTime createdAt,
      DateTime updatedAt,
      String? lastBillingError});

  $HomeLimitsCopyWith<$Res> get limits;
}

/// @nodoc
class _$HomeCopyWithImpl<$Res, $Val extends Home>
    implements $HomeCopyWith<$Res> {
  _$HomeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Home
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ownerUid = null,
    Object? currentPayerUid = freezed,
    Object? lastPayerUid = freezed,
    Object? premiumStatus = null,
    Object? premiumPlan = freezed,
    Object? premiumEndsAt = freezed,
    Object? restoreUntil = freezed,
    Object? autoRenewEnabled = null,
    Object? limits = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? lastBillingError = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ownerUid: null == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String,
      currentPayerUid: freezed == currentPayerUid
          ? _value.currentPayerUid
          : currentPayerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      lastPayerUid: freezed == lastPayerUid
          ? _value.lastPayerUid
          : lastPayerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumStatus: null == premiumStatus
          ? _value.premiumStatus
          : premiumStatus // ignore: cast_nullable_to_non_nullable
              as HomePremiumStatus,
      premiumPlan: freezed == premiumPlan
          ? _value.premiumPlan
          : premiumPlan // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumEndsAt: freezed == premiumEndsAt
          ? _value.premiumEndsAt
          : premiumEndsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      restoreUntil: freezed == restoreUntil
          ? _value.restoreUntil
          : restoreUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      autoRenewEnabled: null == autoRenewEnabled
          ? _value.autoRenewEnabled
          : autoRenewEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      limits: null == limits
          ? _value.limits
          : limits // ignore: cast_nullable_to_non_nullable
              as HomeLimits,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastBillingError: freezed == lastBillingError
          ? _value.lastBillingError
          : lastBillingError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of Home
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HomeLimitsCopyWith<$Res> get limits {
    return $HomeLimitsCopyWith<$Res>(_value.limits, (value) {
      return _then(_value.copyWith(limits: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HomeImplCopyWith<$Res> implements $HomeCopyWith<$Res> {
  factory _$$HomeImplCopyWith(
          _$HomeImpl value, $Res Function(_$HomeImpl) then) =
      __$$HomeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String ownerUid,
      String? currentPayerUid,
      String? lastPayerUid,
      HomePremiumStatus premiumStatus,
      String? premiumPlan,
      DateTime? premiumEndsAt,
      DateTime? restoreUntil,
      bool autoRenewEnabled,
      HomeLimits limits,
      DateTime createdAt,
      DateTime updatedAt,
      String? lastBillingError});

  @override
  $HomeLimitsCopyWith<$Res> get limits;
}

/// @nodoc
class __$$HomeImplCopyWithImpl<$Res>
    extends _$HomeCopyWithImpl<$Res, _$HomeImpl>
    implements _$$HomeImplCopyWith<$Res> {
  __$$HomeImplCopyWithImpl(_$HomeImpl _value, $Res Function(_$HomeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Home
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ownerUid = null,
    Object? currentPayerUid = freezed,
    Object? lastPayerUid = freezed,
    Object? premiumStatus = null,
    Object? premiumPlan = freezed,
    Object? premiumEndsAt = freezed,
    Object? restoreUntil = freezed,
    Object? autoRenewEnabled = null,
    Object? limits = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? lastBillingError = freezed,
  }) {
    return _then(_$HomeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      ownerUid: null == ownerUid
          ? _value.ownerUid
          : ownerUid // ignore: cast_nullable_to_non_nullable
              as String,
      currentPayerUid: freezed == currentPayerUid
          ? _value.currentPayerUid
          : currentPayerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      lastPayerUid: freezed == lastPayerUid
          ? _value.lastPayerUid
          : lastPayerUid // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumStatus: null == premiumStatus
          ? _value.premiumStatus
          : premiumStatus // ignore: cast_nullable_to_non_nullable
              as HomePremiumStatus,
      premiumPlan: freezed == premiumPlan
          ? _value.premiumPlan
          : premiumPlan // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumEndsAt: freezed == premiumEndsAt
          ? _value.premiumEndsAt
          : premiumEndsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      restoreUntil: freezed == restoreUntil
          ? _value.restoreUntil
          : restoreUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      autoRenewEnabled: null == autoRenewEnabled
          ? _value.autoRenewEnabled
          : autoRenewEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      limits: null == limits
          ? _value.limits
          : limits // ignore: cast_nullable_to_non_nullable
              as HomeLimits,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastBillingError: freezed == lastBillingError
          ? _value.lastBillingError
          : lastBillingError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$HomeImpl implements _Home {
  const _$HomeImpl(
      {required this.id,
      required this.name,
      required this.ownerUid,
      required this.currentPayerUid,
      required this.lastPayerUid,
      required this.premiumStatus,
      required this.premiumPlan,
      required this.premiumEndsAt,
      required this.restoreUntil,
      required this.autoRenewEnabled,
      required this.limits,
      required this.createdAt,
      required this.updatedAt,
      this.lastBillingError});

  @override
  final String id;
  @override
  final String name;
  @override
  final String ownerUid;
  @override
  final String? currentPayerUid;
  @override
  final String? lastPayerUid;
  @override
  final HomePremiumStatus premiumStatus;
  @override
  final String? premiumPlan;
  @override
  final DateTime? premiumEndsAt;
  @override
  final DateTime? restoreUntil;
  @override
  final bool autoRenewEnabled;
  @override
  final HomeLimits limits;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? lastBillingError;

  @override
  String toString() {
    return 'Home(id: $id, name: $name, ownerUid: $ownerUid, currentPayerUid: $currentPayerUid, lastPayerUid: $lastPayerUid, premiumStatus: $premiumStatus, premiumPlan: $premiumPlan, premiumEndsAt: $premiumEndsAt, restoreUntil: $restoreUntil, autoRenewEnabled: $autoRenewEnabled, limits: $limits, createdAt: $createdAt, updatedAt: $updatedAt, lastBillingError: $lastBillingError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ownerUid, ownerUid) ||
                other.ownerUid == ownerUid) &&
            (identical(other.currentPayerUid, currentPayerUid) ||
                other.currentPayerUid == currentPayerUid) &&
            (identical(other.lastPayerUid, lastPayerUid) ||
                other.lastPayerUid == lastPayerUid) &&
            (identical(other.premiumStatus, premiumStatus) ||
                other.premiumStatus == premiumStatus) &&
            (identical(other.premiumPlan, premiumPlan) ||
                other.premiumPlan == premiumPlan) &&
            (identical(other.premiumEndsAt, premiumEndsAt) ||
                other.premiumEndsAt == premiumEndsAt) &&
            (identical(other.restoreUntil, restoreUntil) ||
                other.restoreUntil == restoreUntil) &&
            (identical(other.autoRenewEnabled, autoRenewEnabled) ||
                other.autoRenewEnabled == autoRenewEnabled) &&
            (identical(other.limits, limits) || other.limits == limits) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastBillingError, lastBillingError) ||
                other.lastBillingError == lastBillingError));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      ownerUid,
      currentPayerUid,
      lastPayerUid,
      premiumStatus,
      premiumPlan,
      premiumEndsAt,
      restoreUntil,
      autoRenewEnabled,
      limits,
      createdAt,
      updatedAt,
      lastBillingError);

  /// Create a copy of Home
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeImplCopyWith<_$HomeImpl> get copyWith =>
      __$$HomeImplCopyWithImpl<_$HomeImpl>(this, _$identity);
}

abstract class _Home implements Home {
  const factory _Home(
      {required final String id,
      required final String name,
      required final String ownerUid,
      required final String? currentPayerUid,
      required final String? lastPayerUid,
      required final HomePremiumStatus premiumStatus,
      required final String? premiumPlan,
      required final DateTime? premiumEndsAt,
      required final DateTime? restoreUntil,
      required final bool autoRenewEnabled,
      required final HomeLimits limits,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? lastBillingError}) = _$HomeImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get ownerUid;
  @override
  String? get currentPayerUid;
  @override
  String? get lastPayerUid;
  @override
  HomePremiumStatus get premiumStatus;
  @override
  String? get premiumPlan;
  @override
  DateTime? get premiumEndsAt;
  @override
  DateTime? get restoreUntil;
  @override
  bool get autoRenewEnabled;
  @override
  HomeLimits get limits;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get lastBillingError;

  /// Create a copy of Home
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeImplCopyWith<_$HomeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
