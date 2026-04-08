// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'all_tasks_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AllTasksFilter {
  TaskStatus get status => throw _privateConstructorUsedError;
  String? get assigneeUid => throw _privateConstructorUsedError;

  /// Create a copy of AllTasksFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AllTasksFilterCopyWith<AllTasksFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AllTasksFilterCopyWith<$Res> {
  factory $AllTasksFilterCopyWith(
          AllTasksFilter value, $Res Function(AllTasksFilter) then) =
      _$AllTasksFilterCopyWithImpl<$Res, AllTasksFilter>;
  @useResult
  $Res call({TaskStatus status, String? assigneeUid});
}

/// @nodoc
class _$AllTasksFilterCopyWithImpl<$Res, $Val extends AllTasksFilter>
    implements $AllTasksFilterCopyWith<$Res> {
  _$AllTasksFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AllTasksFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? assigneeUid = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TaskStatus,
      assigneeUid: freezed == assigneeUid
          ? _value.assigneeUid
          : assigneeUid // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AllTasksFilterImplCopyWith<$Res>
    implements $AllTasksFilterCopyWith<$Res> {
  factory _$$AllTasksFilterImplCopyWith(_$AllTasksFilterImpl value,
          $Res Function(_$AllTasksFilterImpl) then) =
      __$$AllTasksFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TaskStatus status, String? assigneeUid});
}

/// @nodoc
class __$$AllTasksFilterImplCopyWithImpl<$Res>
    extends _$AllTasksFilterCopyWithImpl<$Res, _$AllTasksFilterImpl>
    implements _$$AllTasksFilterImplCopyWith<$Res> {
  __$$AllTasksFilterImplCopyWithImpl(
      _$AllTasksFilterImpl _value, $Res Function(_$AllTasksFilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of AllTasksFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? assigneeUid = freezed,
  }) {
    return _then(_$AllTasksFilterImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TaskStatus,
      assigneeUid: freezed == assigneeUid
          ? _value.assigneeUid
          : assigneeUid // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AllTasksFilterImpl implements _AllTasksFilter {
  const _$AllTasksFilterImpl(
      {this.status = TaskStatus.active, this.assigneeUid});

  @override
  @JsonKey()
  final TaskStatus status;
  @override
  final String? assigneeUid;

  @override
  String toString() {
    return 'AllTasksFilter(status: $status, assigneeUid: $assigneeUid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AllTasksFilterImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.assigneeUid, assigneeUid) ||
                other.assigneeUid == assigneeUid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status, assigneeUid);

  /// Create a copy of AllTasksFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AllTasksFilterImplCopyWith<_$AllTasksFilterImpl> get copyWith =>
      __$$AllTasksFilterImplCopyWithImpl<_$AllTasksFilterImpl>(
          this, _$identity);
}

abstract class _AllTasksFilter implements AllTasksFilter {
  const factory _AllTasksFilter(
      {final TaskStatus status,
      final String? assigneeUid}) = _$AllTasksFilterImpl;

  @override
  TaskStatus get status;
  @override
  String? get assigneeUid;

  /// Create a copy of AllTasksFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AllTasksFilterImplCopyWith<_$AllTasksFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
