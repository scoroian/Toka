// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plus_entitlement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PlusEntitlement {
  String get status => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  String? get cycle => throw _privateConstructorUsedError;
  DateTime? get startsAt => throw _privateConstructorUsedError;
  DateTime? get endsAt => throw _privateConstructorUsedError;
  bool get autoRenewEnabled => throw _privateConstructorUsedError;
  String? get productId => throw _privateConstructorUsedError;

  /// Create a copy of PlusEntitlement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlusEntitlementCopyWith<PlusEntitlement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlusEntitlementCopyWith<$Res> {
  factory $PlusEntitlementCopyWith(
          PlusEntitlement value, $Res Function(PlusEntitlement) then) =
      _$PlusEntitlementCopyWithImpl<$Res, PlusEntitlement>;
  @useResult
  $Res call(
      {String status,
      bool active,
      String? cycle,
      DateTime? startsAt,
      DateTime? endsAt,
      bool autoRenewEnabled,
      String? productId});
}

/// @nodoc
class _$PlusEntitlementCopyWithImpl<$Res, $Val extends PlusEntitlement>
    implements $PlusEntitlementCopyWith<$Res> {
  _$PlusEntitlementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlusEntitlement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? active = null,
    Object? cycle = freezed,
    Object? startsAt = freezed,
    Object? endsAt = freezed,
    Object? autoRenewEnabled = null,
    Object? productId = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      cycle: freezed == cycle
          ? _value.cycle
          : cycle // ignore: cast_nullable_to_non_nullable
              as String?,
      startsAt: freezed == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      autoRenewEnabled: null == autoRenewEnabled
          ? _value.autoRenewEnabled
          : autoRenewEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      productId: freezed == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlusEntitlementImplCopyWith<$Res>
    implements $PlusEntitlementCopyWith<$Res> {
  factory _$$PlusEntitlementImplCopyWith(_$PlusEntitlementImpl value,
          $Res Function(_$PlusEntitlementImpl) then) =
      __$$PlusEntitlementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String status,
      bool active,
      String? cycle,
      DateTime? startsAt,
      DateTime? endsAt,
      bool autoRenewEnabled,
      String? productId});
}

/// @nodoc
class __$$PlusEntitlementImplCopyWithImpl<$Res>
    extends _$PlusEntitlementCopyWithImpl<$Res, _$PlusEntitlementImpl>
    implements _$$PlusEntitlementImplCopyWith<$Res> {
  __$$PlusEntitlementImplCopyWithImpl(
      _$PlusEntitlementImpl _value, $Res Function(_$PlusEntitlementImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlusEntitlement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? active = null,
    Object? cycle = freezed,
    Object? startsAt = freezed,
    Object? endsAt = freezed,
    Object? autoRenewEnabled = null,
    Object? productId = freezed,
  }) {
    return _then(_$PlusEntitlementImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      cycle: freezed == cycle
          ? _value.cycle
          : cycle // ignore: cast_nullable_to_non_nullable
              as String?,
      startsAt: freezed == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      autoRenewEnabled: null == autoRenewEnabled
          ? _value.autoRenewEnabled
          : autoRenewEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      productId: freezed == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PlusEntitlementImpl extends _PlusEntitlement {
  const _$PlusEntitlementImpl(
      {required this.status,
      required this.active,
      this.cycle,
      this.startsAt,
      this.endsAt,
      this.autoRenewEnabled = false,
      this.productId})
      : super._();

  @override
  final String status;
  @override
  final bool active;
  @override
  final String? cycle;
  @override
  final DateTime? startsAt;
  @override
  final DateTime? endsAt;
  @override
  @JsonKey()
  final bool autoRenewEnabled;
  @override
  final String? productId;

  @override
  String toString() {
    return 'PlusEntitlement(status: $status, active: $active, cycle: $cycle, startsAt: $startsAt, endsAt: $endsAt, autoRenewEnabled: $autoRenewEnabled, productId: $productId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlusEntitlementImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.cycle, cycle) || other.cycle == cycle) &&
            (identical(other.startsAt, startsAt) ||
                other.startsAt == startsAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.autoRenewEnabled, autoRenewEnabled) ||
                other.autoRenewEnabled == autoRenewEnabled) &&
            (identical(other.productId, productId) ||
                other.productId == productId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, active, cycle, startsAt,
      endsAt, autoRenewEnabled, productId);

  /// Create a copy of PlusEntitlement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlusEntitlementImplCopyWith<_$PlusEntitlementImpl> get copyWith =>
      __$$PlusEntitlementImplCopyWithImpl<_$PlusEntitlementImpl>(
          this, _$identity);
}

abstract class _PlusEntitlement extends PlusEntitlement {
  const factory _PlusEntitlement(
      {required final String status,
      required final bool active,
      final String? cycle,
      final DateTime? startsAt,
      final DateTime? endsAt,
      final bool autoRenewEnabled,
      final String? productId}) = _$PlusEntitlementImpl;
  const _PlusEntitlement._() : super._();

  @override
  String get status;
  @override
  bool get active;
  @override
  String? get cycle;
  @override
  DateTime? get startsAt;
  @override
  DateTime? get endsAt;
  @override
  bool get autoRenewEnabled;
  @override
  String? get productId;

  /// Create a copy of PlusEntitlement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlusEntitlementImplCopyWith<_$PlusEntitlementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
