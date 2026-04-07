// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TaskEvent {
  String get id => throw _privateConstructorUsedError;
  String get taskId => throw _privateConstructorUsedError;
  String get taskTitleSnapshot => throw _privateConstructorUsedError;
  TaskVisual get taskVisualSnapshot => throw _privateConstructorUsedError;
  String get actorUid => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)
        completed,
    required TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)
        passed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)?
        completed,
    TResult? Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)?
        passed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)?
        completed,
    TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)?
        passed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CompletedEvent value) completed,
    required TResult Function(PassedEvent value) passed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CompletedEvent value)? completed,
    TResult? Function(PassedEvent value)? passed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CompletedEvent value)? completed,
    TResult Function(PassedEvent value)? passed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskEventCopyWith<TaskEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskEventCopyWith<$Res> {
  factory $TaskEventCopyWith(TaskEvent value, $Res Function(TaskEvent) then) =
      _$TaskEventCopyWithImpl<$Res, TaskEvent>;
  @useResult
  $Res call(
      {String id,
      String taskId,
      String taskTitleSnapshot,
      TaskVisual taskVisualSnapshot,
      String actorUid,
      DateTime createdAt});
}

/// @nodoc
class _$TaskEventCopyWithImpl<$Res, $Val extends TaskEvent>
    implements $TaskEventCopyWith<$Res> {
  _$TaskEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taskId = null,
    Object? taskTitleSnapshot = null,
    Object? taskVisualSnapshot = null,
    Object? actorUid = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      taskTitleSnapshot: null == taskTitleSnapshot
          ? _value.taskTitleSnapshot
          : taskTitleSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      taskVisualSnapshot: null == taskVisualSnapshot
          ? _value.taskVisualSnapshot
          : taskVisualSnapshot // ignore: cast_nullable_to_non_nullable
              as TaskVisual,
      actorUid: null == actorUid
          ? _value.actorUid
          : actorUid // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompletedEventImplCopyWith<$Res>
    implements $TaskEventCopyWith<$Res> {
  factory _$$CompletedEventImplCopyWith(_$CompletedEventImpl value,
          $Res Function(_$CompletedEventImpl) then) =
      __$$CompletedEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String taskId,
      String taskTitleSnapshot,
      TaskVisual taskVisualSnapshot,
      String actorUid,
      String performerUid,
      DateTime completedAt,
      DateTime createdAt});
}

/// @nodoc
class __$$CompletedEventImplCopyWithImpl<$Res>
    extends _$TaskEventCopyWithImpl<$Res, _$CompletedEventImpl>
    implements _$$CompletedEventImplCopyWith<$Res> {
  __$$CompletedEventImplCopyWithImpl(
      _$CompletedEventImpl _value, $Res Function(_$CompletedEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taskId = null,
    Object? taskTitleSnapshot = null,
    Object? taskVisualSnapshot = null,
    Object? actorUid = null,
    Object? performerUid = null,
    Object? completedAt = null,
    Object? createdAt = null,
  }) {
    return _then(_$CompletedEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      taskTitleSnapshot: null == taskTitleSnapshot
          ? _value.taskTitleSnapshot
          : taskTitleSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      taskVisualSnapshot: null == taskVisualSnapshot
          ? _value.taskVisualSnapshot
          : taskVisualSnapshot // ignore: cast_nullable_to_non_nullable
              as TaskVisual,
      actorUid: null == actorUid
          ? _value.actorUid
          : actorUid // ignore: cast_nullable_to_non_nullable
              as String,
      performerUid: null == performerUid
          ? _value.performerUid
          : performerUid // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$CompletedEventImpl implements CompletedEvent {
  const _$CompletedEventImpl(
      {required this.id,
      required this.taskId,
      required this.taskTitleSnapshot,
      required this.taskVisualSnapshot,
      required this.actorUid,
      required this.performerUid,
      required this.completedAt,
      required this.createdAt});

  @override
  final String id;
  @override
  final String taskId;
  @override
  final String taskTitleSnapshot;
  @override
  final TaskVisual taskVisualSnapshot;
  @override
  final String actorUid;
  @override
  final String performerUid;
  @override
  final DateTime completedAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'TaskEvent.completed(id: $id, taskId: $taskId, taskTitleSnapshot: $taskTitleSnapshot, taskVisualSnapshot: $taskVisualSnapshot, actorUid: $actorUid, performerUid: $performerUid, completedAt: $completedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletedEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.taskTitleSnapshot, taskTitleSnapshot) ||
                other.taskTitleSnapshot == taskTitleSnapshot) &&
            (identical(other.taskVisualSnapshot, taskVisualSnapshot) ||
                other.taskVisualSnapshot == taskVisualSnapshot) &&
            (identical(other.actorUid, actorUid) ||
                other.actorUid == actorUid) &&
            (identical(other.performerUid, performerUid) ||
                other.performerUid == performerUid) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, taskId, taskTitleSnapshot,
      taskVisualSnapshot, actorUid, performerUid, completedAt, createdAt);

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompletedEventImplCopyWith<_$CompletedEventImpl> get copyWith =>
      __$$CompletedEventImplCopyWithImpl<_$CompletedEventImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)
        completed,
    required TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)
        passed,
  }) {
    return completed(id, taskId, taskTitleSnapshot, taskVisualSnapshot,
        actorUid, performerUid, completedAt, createdAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)?
        completed,
    TResult? Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)?
        passed,
  }) {
    return completed?.call(id, taskId, taskTitleSnapshot, taskVisualSnapshot,
        actorUid, performerUid, completedAt, createdAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)?
        completed,
    TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)?
        passed,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(id, taskId, taskTitleSnapshot, taskVisualSnapshot,
          actorUid, performerUid, completedAt, createdAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CompletedEvent value) completed,
    required TResult Function(PassedEvent value) passed,
  }) {
    return completed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CompletedEvent value)? completed,
    TResult? Function(PassedEvent value)? passed,
  }) {
    return completed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CompletedEvent value)? completed,
    TResult Function(PassedEvent value)? passed,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(this);
    }
    return orElse();
  }
}

abstract class CompletedEvent implements TaskEvent {
  const factory CompletedEvent(
      {required final String id,
      required final String taskId,
      required final String taskTitleSnapshot,
      required final TaskVisual taskVisualSnapshot,
      required final String actorUid,
      required final String performerUid,
      required final DateTime completedAt,
      required final DateTime createdAt}) = _$CompletedEventImpl;

  @override
  String get id;
  @override
  String get taskId;
  @override
  String get taskTitleSnapshot;
  @override
  TaskVisual get taskVisualSnapshot;
  @override
  String get actorUid;
  String get performerUid;
  DateTime get completedAt;
  @override
  DateTime get createdAt;

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompletedEventImplCopyWith<_$CompletedEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PassedEventImplCopyWith<$Res>
    implements $TaskEventCopyWith<$Res> {
  factory _$$PassedEventImplCopyWith(
          _$PassedEventImpl value, $Res Function(_$PassedEventImpl) then) =
      __$$PassedEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String taskId,
      String taskTitleSnapshot,
      TaskVisual taskVisualSnapshot,
      String actorUid,
      String fromUid,
      String toUid,
      String? reason,
      bool penaltyApplied,
      double? complianceBefore,
      double? complianceAfter,
      DateTime createdAt});
}

/// @nodoc
class __$$PassedEventImplCopyWithImpl<$Res>
    extends _$TaskEventCopyWithImpl<$Res, _$PassedEventImpl>
    implements _$$PassedEventImplCopyWith<$Res> {
  __$$PassedEventImplCopyWithImpl(
      _$PassedEventImpl _value, $Res Function(_$PassedEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taskId = null,
    Object? taskTitleSnapshot = null,
    Object? taskVisualSnapshot = null,
    Object? actorUid = null,
    Object? fromUid = null,
    Object? toUid = null,
    Object? reason = freezed,
    Object? penaltyApplied = null,
    Object? complianceBefore = freezed,
    Object? complianceAfter = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$PassedEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskId: null == taskId
          ? _value.taskId
          : taskId // ignore: cast_nullable_to_non_nullable
              as String,
      taskTitleSnapshot: null == taskTitleSnapshot
          ? _value.taskTitleSnapshot
          : taskTitleSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      taskVisualSnapshot: null == taskVisualSnapshot
          ? _value.taskVisualSnapshot
          : taskVisualSnapshot // ignore: cast_nullable_to_non_nullable
              as TaskVisual,
      actorUid: null == actorUid
          ? _value.actorUid
          : actorUid // ignore: cast_nullable_to_non_nullable
              as String,
      fromUid: null == fromUid
          ? _value.fromUid
          : fromUid // ignore: cast_nullable_to_non_nullable
              as String,
      toUid: null == toUid
          ? _value.toUid
          : toUid // ignore: cast_nullable_to_non_nullable
              as String,
      reason: freezed == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      penaltyApplied: null == penaltyApplied
          ? _value.penaltyApplied
          : penaltyApplied // ignore: cast_nullable_to_non_nullable
              as bool,
      complianceBefore: freezed == complianceBefore
          ? _value.complianceBefore
          : complianceBefore // ignore: cast_nullable_to_non_nullable
              as double?,
      complianceAfter: freezed == complianceAfter
          ? _value.complianceAfter
          : complianceAfter // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$PassedEventImpl implements PassedEvent {
  const _$PassedEventImpl(
      {required this.id,
      required this.taskId,
      required this.taskTitleSnapshot,
      required this.taskVisualSnapshot,
      required this.actorUid,
      required this.fromUid,
      required this.toUid,
      this.reason,
      required this.penaltyApplied,
      required this.complianceBefore,
      required this.complianceAfter,
      required this.createdAt});

  @override
  final String id;
  @override
  final String taskId;
  @override
  final String taskTitleSnapshot;
  @override
  final TaskVisual taskVisualSnapshot;
  @override
  final String actorUid;
  @override
  final String fromUid;
  @override
  final String toUid;
  @override
  final String? reason;
  @override
  final bool penaltyApplied;
  @override
  final double? complianceBefore;
  @override
  final double? complianceAfter;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'TaskEvent.passed(id: $id, taskId: $taskId, taskTitleSnapshot: $taskTitleSnapshot, taskVisualSnapshot: $taskVisualSnapshot, actorUid: $actorUid, fromUid: $fromUid, toUid: $toUid, reason: $reason, penaltyApplied: $penaltyApplied, complianceBefore: $complianceBefore, complianceAfter: $complianceAfter, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PassedEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.taskTitleSnapshot, taskTitleSnapshot) ||
                other.taskTitleSnapshot == taskTitleSnapshot) &&
            (identical(other.taskVisualSnapshot, taskVisualSnapshot) ||
                other.taskVisualSnapshot == taskVisualSnapshot) &&
            (identical(other.actorUid, actorUid) ||
                other.actorUid == actorUid) &&
            (identical(other.fromUid, fromUid) || other.fromUid == fromUid) &&
            (identical(other.toUid, toUid) || other.toUid == toUid) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.penaltyApplied, penaltyApplied) ||
                other.penaltyApplied == penaltyApplied) &&
            (identical(other.complianceBefore, complianceBefore) ||
                other.complianceBefore == complianceBefore) &&
            (identical(other.complianceAfter, complianceAfter) ||
                other.complianceAfter == complianceAfter) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      taskId,
      taskTitleSnapshot,
      taskVisualSnapshot,
      actorUid,
      fromUid,
      toUid,
      reason,
      penaltyApplied,
      complianceBefore,
      complianceAfter,
      createdAt);

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PassedEventImplCopyWith<_$PassedEventImpl> get copyWith =>
      __$$PassedEventImplCopyWithImpl<_$PassedEventImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)
        completed,
    required TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)
        passed,
  }) {
    return passed(
        id,
        taskId,
        taskTitleSnapshot,
        taskVisualSnapshot,
        actorUid,
        fromUid,
        toUid,
        reason,
        penaltyApplied,
        complianceBefore,
        complianceAfter,
        createdAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)?
        completed,
    TResult? Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)?
        passed,
  }) {
    return passed?.call(
        id,
        taskId,
        taskTitleSnapshot,
        taskVisualSnapshot,
        actorUid,
        fromUid,
        toUid,
        reason,
        penaltyApplied,
        complianceBefore,
        complianceAfter,
        createdAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String performerUid,
            DateTime completedAt,
            DateTime createdAt)?
        completed,
    TResult Function(
            String id,
            String taskId,
            String taskTitleSnapshot,
            TaskVisual taskVisualSnapshot,
            String actorUid,
            String fromUid,
            String toUid,
            String? reason,
            bool penaltyApplied,
            double? complianceBefore,
            double? complianceAfter,
            DateTime createdAt)?
        passed,
    required TResult orElse(),
  }) {
    if (passed != null) {
      return passed(
          id,
          taskId,
          taskTitleSnapshot,
          taskVisualSnapshot,
          actorUid,
          fromUid,
          toUid,
          reason,
          penaltyApplied,
          complianceBefore,
          complianceAfter,
          createdAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CompletedEvent value) completed,
    required TResult Function(PassedEvent value) passed,
  }) {
    return passed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CompletedEvent value)? completed,
    TResult? Function(PassedEvent value)? passed,
  }) {
    return passed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CompletedEvent value)? completed,
    TResult Function(PassedEvent value)? passed,
    required TResult orElse(),
  }) {
    if (passed != null) {
      return passed(this);
    }
    return orElse();
  }
}

abstract class PassedEvent implements TaskEvent {
  const factory PassedEvent(
      {required final String id,
      required final String taskId,
      required final String taskTitleSnapshot,
      required final TaskVisual taskVisualSnapshot,
      required final String actorUid,
      required final String fromUid,
      required final String toUid,
      final String? reason,
      required final bool penaltyApplied,
      required final double? complianceBefore,
      required final double? complianceAfter,
      required final DateTime createdAt}) = _$PassedEventImpl;

  @override
  String get id;
  @override
  String get taskId;
  @override
  String get taskTitleSnapshot;
  @override
  TaskVisual get taskVisualSnapshot;
  @override
  String get actorUid;
  String get fromUid;
  String get toUid;
  String? get reason;
  bool get penaltyApplied;
  double? get complianceBefore;
  double? get complianceAfter;
  @override
  DateTime get createdAt;

  /// Create a copy of TaskEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PassedEventImplCopyWith<_$PassedEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
