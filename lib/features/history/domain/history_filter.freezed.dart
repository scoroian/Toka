// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HistoryFilter {
  String? get memberUid => throw _privateConstructorUsedError;
  String? get taskId => throw _privateConstructorUsedError;
  String? get eventType => throw _privateConstructorUsedError;

  /// Create a copy of HistoryFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HistoryFilterCopyWith<HistoryFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HistoryFilterCopyWith<$Res> {
  factory $HistoryFilterCopyWith(
          HistoryFilter value, $Res Function(HistoryFilter) then) =
      _$HistoryFilterCopyWithImpl<$Res, HistoryFilter>;
  @useResult
  $Res call({String? memberUid, String? taskId, String? eventType});
}

/// @nodoc
class _$HistoryFilterCopyWithImpl<$Res, $Val extends HistoryFilter>
    implements $HistoryFilterCopyWith<$Res> {
  _$HistoryFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HistoryFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberUid = freezed,
    Object? taskId = freezed,
    Object? eventType = freezed,
  }) {
    return _then(_value.copyWith(
      memberUid: freezed == memberUid
          ? _value.memberUid
          : memberUid // ignore: cast_nullable_to_non_nullable
              as String?,
      taskId: freezed == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HistoryFilterImplCopyWith<$Res>
    implements $HistoryFilterCopyWith<$Res> {
  factory _$$HistoryFilterImplCopyWith(
          _$HistoryFilterImpl value, $Res Function(_$HistoryFilterImpl) then) =
      __$$HistoryFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? memberUid, String? taskId, String? eventType});
}

/// @nodoc
class __$$HistoryFilterImplCopyWithImpl<$Res>
    extends _$HistoryFilterCopyWithImpl<$Res, _$HistoryFilterImpl>
    implements _$$HistoryFilterImplCopyWith<$Res> {
  __$$HistoryFilterImplCopyWithImpl(
      _$HistoryFilterImpl _value, $Res Function(_$HistoryFilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of HistoryFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memberUid = freezed,
    Object? taskId = freezed,
    Object? eventType = freezed,
  }) {
    return _then(_$HistoryFilterImpl(
      memberUid: freezed == memberUid
          ? _value.memberUid
          : memberUid // ignore: cast_nullable_to_non_nullable
              as String?,
      taskId: freezed == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$HistoryFilterImpl implements _HistoryFilter {
  const _$HistoryFilterImpl({this.memberUid, this.taskId, this.eventType});

  @override
  final String? memberUid;
  @override
  final String? taskId;
  @override
  final String? eventType;

  @override
  String toString() {
    return 'HistoryFilter(memberUid: $memberUid, taskId: $taskId, eventType: $eventType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryFilterImpl &&
            (identical(other.memberUid, memberUid) ||
                other.memberUid == memberUid) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, memberUid, taskId, eventType);

  /// Create a copy of HistoryFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoryFilterImplCopyWith<_$HistoryFilterImpl> get copyWith =>
      __$$HistoryFilterImplCopyWithImpl<_$HistoryFilterImpl>(this, _$identity);
}

abstract class _HistoryFilter implements HistoryFilter {
  const factory _HistoryFilter(
      {final String? memberUid,
      final String? taskId,
      final String? eventType}) = _$HistoryFilterImpl;

  @override
  String? get memberUid;
  @override
  String? get taskId;
  @override
  String? get eventType;

  /// Create a copy of HistoryFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoryFilterImplCopyWith<_$HistoryFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
