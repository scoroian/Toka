// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vacation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Vacation {
  String get uid => throw _privateConstructorUsedError;
  String get homeId => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Vacation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VacationCopyWith<Vacation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VacationCopyWith<$Res> {
  factory $VacationCopyWith(Vacation value, $Res Function(Vacation) then) =
      _$VacationCopyWithImpl<$Res, Vacation>;
  @useResult
  $Res call(
      {String uid,
      String homeId,
      DateTime? startDate,
      DateTime? endDate,
      bool isActive,
      String? reason,
      DateTime createdAt});
}

/// @nodoc
class _$VacationCopyWithImpl<$Res, $Val extends Vacation>
    implements $VacationCopyWith<$Res> {
  _$VacationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Vacation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? homeId = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? isActive = null,
    Object? reason = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VacationImplCopyWith<$Res>
    implements $VacationCopyWith<$Res> {
  factory _$$VacationImplCopyWith(
          _$VacationImpl value, $Res Function(_$VacationImpl) then) =
      __$$VacationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String homeId,
      DateTime? startDate,
      DateTime? endDate,
      bool isActive,
      String? reason,
      DateTime createdAt});
}

/// @nodoc
class __$$VacationImplCopyWithImpl<$Res>
    extends _$VacationCopyWithImpl<$Res, _$VacationImpl>
    implements _$$VacationImplCopyWith<$Res> {
  __$$VacationImplCopyWithImpl(
      _$VacationImpl _value, $Res Function(_$VacationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Vacation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? homeId = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? isActive = null,
    Object? reason = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$VacationImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$VacationImpl extends _Vacation {
  const _$VacationImpl(
      {required this.uid,
      required this.homeId,
      this.startDate,
      this.endDate,
      this.isActive = false,
      this.reason,
      required this.createdAt})
      : super._();

  @override
  final String uid;
  @override
  final String homeId;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final String? reason;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Vacation(uid: $uid, homeId: $homeId, startDate: $startDate, endDate: $endDate, isActive: $isActive, reason: $reason, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VacationImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.homeId, homeId) || other.homeId == homeId) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, uid, homeId, startDate, endDate,
      isActive, reason, createdAt);

  /// Create a copy of Vacation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VacationImplCopyWith<_$VacationImpl> get copyWith =>
      __$$VacationImplCopyWithImpl<_$VacationImpl>(this, _$identity);
}

abstract class _Vacation extends Vacation {
  const factory _Vacation(
      {required final String uid,
      required final String homeId,
      final DateTime? startDate,
      final DateTime? endDate,
      final bool isActive,
      final String? reason,
      required final DateTime createdAt}) = _$VacationImpl;
  const _Vacation._() : super._();

  @override
  String get uid;
  @override
  String get homeId;
  @override
  DateTime? get startDate;
  @override
  DateTime? get endDate;
  @override
  bool get isActive;
  @override
  String? get reason;
  @override
  DateTime get createdAt;

  /// Create a copy of Vacation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VacationImplCopyWith<_$VacationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
