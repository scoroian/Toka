// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failed_completion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FailedCompletion {
  String get homeId => throw _privateConstructorUsedError;
  String get taskId => throw _privateConstructorUsedError;
  String get taskTitle => throw _privateConstructorUsedError;
  String get completionId => throw _privateConstructorUsedError;
  CompletionFailureKind get kind => throw _privateConstructorUsedError;

  /// Create a copy of FailedCompletion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FailedCompletionCopyWith<FailedCompletion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FailedCompletionCopyWith<$Res> {
  factory $FailedCompletionCopyWith(
          FailedCompletion value, $Res Function(FailedCompletion) then) =
      _$FailedCompletionCopyWithImpl<$Res, FailedCompletion>;
  @useResult
  $Res call(
      {String homeId,
      String taskId,
      String taskTitle,
      String completionId,
      CompletionFailureKind kind});
}

/// @nodoc
class _$FailedCompletionCopyWithImpl<$Res, $Val extends FailedCompletion>
    implements $FailedCompletionCopyWith<$Res> {
  _$FailedCompletionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FailedCompletion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? homeId = null,
    Object? taskId = null,
    Object? taskTitle = null,
    Object? completionId = null,
    Object? kind = null,
  }) {
    return _then(_value.copyWith(
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      taskTitle: null == taskTitle
          ? _value.taskTitle
          : taskTitle // ignore: cast_nullable_to_non_nullable
              as String,
      completionId: null == completionId
          ? _value.completionId
          : completionId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as CompletionFailureKind,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FailedCompletionImplCopyWith<$Res>
    implements $FailedCompletionCopyWith<$Res> {
  factory _$$FailedCompletionImplCopyWith(_$FailedCompletionImpl value,
          $Res Function(_$FailedCompletionImpl) then) =
      __$$FailedCompletionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String homeId,
      String taskId,
      String taskTitle,
      String completionId,
      CompletionFailureKind kind});
}

/// @nodoc
class __$$FailedCompletionImplCopyWithImpl<$Res>
    extends _$FailedCompletionCopyWithImpl<$Res, _$FailedCompletionImpl>
    implements _$$FailedCompletionImplCopyWith<$Res> {
  __$$FailedCompletionImplCopyWithImpl(_$FailedCompletionImpl _value,
      $Res Function(_$FailedCompletionImpl) _then)
      : super(_value, _then);

  /// Create a copy of FailedCompletion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? homeId = null,
    Object? taskId = null,
    Object? taskTitle = null,
    Object? completionId = null,
    Object? kind = null,
  }) {
    return _then(_$FailedCompletionImpl(
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      taskTitle: null == taskTitle
          ? _value.taskTitle
          : taskTitle // ignore: cast_nullable_to_non_nullable
              as String,
      completionId: null == completionId
          ? _value.completionId
          : completionId // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as CompletionFailureKind,
    ));
  }
}

/// @nodoc

class _$FailedCompletionImpl implements _FailedCompletion {
  const _$FailedCompletionImpl(
      {required this.homeId,
      required this.taskId,
      required this.taskTitle,
      required this.completionId,
      required this.kind});

  @override
  final String homeId;
  @override
  final String taskId;
  @override
  final String taskTitle;
  @override
  final String completionId;
  @override
  final CompletionFailureKind kind;

  @override
  String toString() {
    return 'FailedCompletion(homeId: $homeId, taskId: $taskId, taskTitle: $taskTitle, completionId: $completionId, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FailedCompletionImpl &&
            (identical(other.homeId, homeId) || other.homeId == homeId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.taskTitle, taskTitle) ||
                other.taskTitle == taskTitle) &&
            (identical(other.completionId, completionId) ||
                other.completionId == completionId) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, homeId, taskId, taskTitle, completionId, kind);

  /// Create a copy of FailedCompletion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FailedCompletionImplCopyWith<_$FailedCompletionImpl> get copyWith =>
      __$$FailedCompletionImplCopyWithImpl<_$FailedCompletionImpl>(
          this, _$identity);
}

abstract class _FailedCompletion implements FailedCompletion {
  const factory _FailedCompletion(
      {required final String homeId,
      required final String taskId,
      required final String taskTitle,
      required final String completionId,
      required final CompletionFailureKind kind}) = _$FailedCompletionImpl;

  @override
  String get homeId;
  @override
  String get taskId;
  @override
  String get taskTitle;
  @override
  String get completionId;
  @override
  CompletionFailureKind get kind;

  /// Create a copy of FailedCompletion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FailedCompletionImplCopyWith<_$FailedCompletionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
