// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Task {
  String get id => throw _privateConstructorUsedError;
  String get homeId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get visualKind =>
      throw _privateConstructorUsedError; // "emoji" | "icon"
  String get visualValue =>
      throw _privateConstructorUsedError; // "🏠" o nombre de icono Material
  TaskStatus get status => throw _privateConstructorUsedError;
  RecurrenceRule get recurrenceRule => throw _privateConstructorUsedError;
  String get assignmentMode =>
      throw _privateConstructorUsedError; // "basicRotation" | "smartDistribution"
  List<String> get assignmentOrder =>
      throw _privateConstructorUsedError; // UIDs en orden
  String? get currentAssigneeUid => throw _privateConstructorUsedError;
  DateTime get nextDueAt => throw _privateConstructorUsedError;
  double get difficultyWeight => throw _privateConstructorUsedError;
  int get completedCount90d => throw _privateConstructorUsedError;
  String get createdByUid => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String get onMissAssign => throw _privateConstructorUsedError;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res, Task>;
  @useResult
  $Res call(
      {String id,
      String homeId,
      String title,
      String? description,
      String visualKind,
      String visualValue,
      TaskStatus status,
      RecurrenceRule recurrenceRule,
      String assignmentMode,
      List<String> assignmentOrder,
      String? currentAssigneeUid,
      DateTime nextDueAt,
      double difficultyWeight,
      int completedCount90d,
      String createdByUid,
      DateTime createdAt,
      DateTime updatedAt,
      String onMissAssign});

  $RecurrenceRuleCopyWith<$Res> get recurrenceRule;
}

/// @nodoc
class _$TaskCopyWithImpl<$Res, $Val extends Task>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? homeId = null,
    Object? title = null,
    Object? description = freezed,
    Object? visualKind = null,
    Object? visualValue = null,
    Object? status = null,
    Object? recurrenceRule = null,
    Object? assignmentMode = null,
    Object? assignmentOrder = null,
    Object? currentAssigneeUid = freezed,
    Object? nextDueAt = null,
    Object? difficultyWeight = null,
    Object? completedCount90d = null,
    Object? createdByUid = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? onMissAssign = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      visualKind: null == visualKind
          ? _value.visualKind
          : visualKind // ignore: cast_nullable_to_non_nullable
              as String,
      visualValue: null == visualValue
          ? _value.visualValue
          : visualValue // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TaskStatus,
      recurrenceRule: null == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as RecurrenceRule,
      assignmentMode: null == assignmentMode
          ? _value.assignmentMode
          : assignmentMode // ignore: cast_nullable_to_non_nullable
              as String,
      assignmentOrder: null == assignmentOrder
          ? _value.assignmentOrder
          : assignmentOrder // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentAssigneeUid: freezed == currentAssigneeUid
          ? _value.currentAssigneeUid
          : currentAssigneeUid // ignore: cast_nullable_to_non_nullable
              as String?,
      nextDueAt: null == nextDueAt
          ? _value.nextDueAt
          : nextDueAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      difficultyWeight: null == difficultyWeight
          ? _value.difficultyWeight
          : difficultyWeight // ignore: cast_nullable_to_non_nullable
              as double,
      completedCount90d: null == completedCount90d
          ? _value.completedCount90d
          : completedCount90d // ignore: cast_nullable_to_non_nullable
              as int,
      createdByUid: null == createdByUid
          ? _value.createdByUid
          : createdByUid // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      onMissAssign: null == onMissAssign
          ? _value.onMissAssign
          : onMissAssign // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecurrenceRuleCopyWith<$Res> get recurrenceRule {
    return $RecurrenceRuleCopyWith<$Res>(_value.recurrenceRule, (value) {
      return _then(_value.copyWith(recurrenceRule: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TaskImplCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$$TaskImplCopyWith(
          _$TaskImpl value, $Res Function(_$TaskImpl) then) =
      __$$TaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String homeId,
      String title,
      String? description,
      String visualKind,
      String visualValue,
      TaskStatus status,
      RecurrenceRule recurrenceRule,
      String assignmentMode,
      List<String> assignmentOrder,
      String? currentAssigneeUid,
      DateTime nextDueAt,
      double difficultyWeight,
      int completedCount90d,
      String createdByUid,
      DateTime createdAt,
      DateTime updatedAt,
      String onMissAssign});

  @override
  $RecurrenceRuleCopyWith<$Res> get recurrenceRule;
}

/// @nodoc
class __$$TaskImplCopyWithImpl<$Res>
    extends _$TaskCopyWithImpl<$Res, _$TaskImpl>
    implements _$$TaskImplCopyWith<$Res> {
  __$$TaskImplCopyWithImpl(_$TaskImpl _value, $Res Function(_$TaskImpl) _then)
      : super(_value, _then);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? homeId = null,
    Object? title = null,
    Object? description = freezed,
    Object? visualKind = null,
    Object? visualValue = null,
    Object? status = null,
    Object? recurrenceRule = null,
    Object? assignmentMode = null,
    Object? assignmentOrder = null,
    Object? currentAssigneeUid = freezed,
    Object? nextDueAt = null,
    Object? difficultyWeight = null,
    Object? completedCount90d = null,
    Object? createdByUid = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? onMissAssign = null,
  }) {
    return _then(_$TaskImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      homeId: null == homeId
          ? _value.homeId
          : homeId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      visualKind: null == visualKind
          ? _value.visualKind
          : visualKind // ignore: cast_nullable_to_non_nullable
              as String,
      visualValue: null == visualValue
          ? _value.visualValue
          : visualValue // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TaskStatus,
      recurrenceRule: null == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as RecurrenceRule,
      assignmentMode: null == assignmentMode
          ? _value.assignmentMode
          : assignmentMode // ignore: cast_nullable_to_non_nullable
              as String,
      assignmentOrder: null == assignmentOrder
          ? _value._assignmentOrder
          : assignmentOrder // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentAssigneeUid: freezed == currentAssigneeUid
          ? _value.currentAssigneeUid
          : currentAssigneeUid // ignore: cast_nullable_to_non_nullable
              as String?,
      nextDueAt: null == nextDueAt
          ? _value.nextDueAt
          : nextDueAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      difficultyWeight: null == difficultyWeight
          ? _value.difficultyWeight
          : difficultyWeight // ignore: cast_nullable_to_non_nullable
              as double,
      completedCount90d: null == completedCount90d
          ? _value.completedCount90d
          : completedCount90d // ignore: cast_nullable_to_non_nullable
              as int,
      createdByUid: null == createdByUid
          ? _value.createdByUid
          : createdByUid // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      onMissAssign: null == onMissAssign
          ? _value.onMissAssign
          : onMissAssign // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TaskImpl implements _Task {
  const _$TaskImpl(
      {required this.id,
      required this.homeId,
      required this.title,
      this.description,
      required this.visualKind,
      required this.visualValue,
      required this.status,
      required this.recurrenceRule,
      required this.assignmentMode,
      required final List<String> assignmentOrder,
      this.currentAssigneeUid,
      required this.nextDueAt,
      required this.difficultyWeight,
      required this.completedCount90d,
      required this.createdByUid,
      required this.createdAt,
      required this.updatedAt,
      this.onMissAssign = 'sameAssignee'})
      : _assignmentOrder = assignmentOrder;

  @override
  final String id;
  @override
  final String homeId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String visualKind;
// "emoji" | "icon"
  @override
  final String visualValue;
// "🏠" o nombre de icono Material
  @override
  final TaskStatus status;
  @override
  final RecurrenceRule recurrenceRule;
  @override
  final String assignmentMode;
// "basicRotation" | "smartDistribution"
  final List<String> _assignmentOrder;
// "basicRotation" | "smartDistribution"
  @override
  List<String> get assignmentOrder {
    if (_assignmentOrder is EqualUnmodifiableListView) return _assignmentOrder;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignmentOrder);
  }

// UIDs en orden
  @override
  final String? currentAssigneeUid;
  @override
  final DateTime nextDueAt;
  @override
  final double difficultyWeight;
  @override
  final int completedCount90d;
  @override
  final String createdByUid;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final String onMissAssign;

  @override
  String toString() {
    return 'Task(id: $id, homeId: $homeId, title: $title, description: $description, visualKind: $visualKind, visualValue: $visualValue, status: $status, recurrenceRule: $recurrenceRule, assignmentMode: $assignmentMode, assignmentOrder: $assignmentOrder, currentAssigneeUid: $currentAssigneeUid, nextDueAt: $nextDueAt, difficultyWeight: $difficultyWeight, completedCount90d: $completedCount90d, createdByUid: $createdByUid, createdAt: $createdAt, updatedAt: $updatedAt, onMissAssign: $onMissAssign)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.homeId, homeId) || other.homeId == homeId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.visualKind, visualKind) ||
                other.visualKind == visualKind) &&
            (identical(other.visualValue, visualValue) ||
                other.visualValue == visualValue) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.assignmentMode, assignmentMode) ||
                other.assignmentMode == assignmentMode) &&
            const DeepCollectionEquality()
                .equals(other._assignmentOrder, _assignmentOrder) &&
            (identical(other.currentAssigneeUid, currentAssigneeUid) ||
                other.currentAssigneeUid == currentAssigneeUid) &&
            (identical(other.nextDueAt, nextDueAt) ||
                other.nextDueAt == nextDueAt) &&
            (identical(other.difficultyWeight, difficultyWeight) ||
                other.difficultyWeight == difficultyWeight) &&
            (identical(other.completedCount90d, completedCount90d) ||
                other.completedCount90d == completedCount90d) &&
            (identical(other.createdByUid, createdByUid) ||
                other.createdByUid == createdByUid) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.onMissAssign, onMissAssign) ||
                other.onMissAssign == onMissAssign));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      homeId,
      title,
      description,
      visualKind,
      visualValue,
      status,
      recurrenceRule,
      assignmentMode,
      const DeepCollectionEquality().hash(_assignmentOrder),
      currentAssigneeUid,
      nextDueAt,
      difficultyWeight,
      completedCount90d,
      createdByUid,
      createdAt,
      updatedAt,
      onMissAssign);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      __$$TaskImplCopyWithImpl<_$TaskImpl>(this, _$identity);
}

abstract class _Task implements Task {
  const factory _Task(
      {required final String id,
      required final String homeId,
      required final String title,
      final String? description,
      required final String visualKind,
      required final String visualValue,
      required final TaskStatus status,
      required final RecurrenceRule recurrenceRule,
      required final String assignmentMode,
      required final List<String> assignmentOrder,
      final String? currentAssigneeUid,
      required final DateTime nextDueAt,
      required final double difficultyWeight,
      required final int completedCount90d,
      required final String createdByUid,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String onMissAssign}) = _$TaskImpl;

  @override
  String get id;
  @override
  String get homeId;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get visualKind; // "emoji" | "icon"
  @override
  String get visualValue; // "🏠" o nombre de icono Material
  @override
  TaskStatus get status;
  @override
  RecurrenceRule get recurrenceRule;
  @override
  String get assignmentMode; // "basicRotation" | "smartDistribution"
  @override
  List<String> get assignmentOrder; // UIDs en orden
  @override
  String? get currentAssigneeUid;
  @override
  DateTime get nextDueAt;
  @override
  double get difficultyWeight;
  @override
  int get completedCount90d;
  @override
  String get createdByUid;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String get onMissAssign;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TaskInput {
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get visualKind => throw _privateConstructorUsedError;
  String get visualValue => throw _privateConstructorUsedError;
  RecurrenceRule get recurrenceRule => throw _privateConstructorUsedError;
  String get assignmentMode => throw _privateConstructorUsedError;
  List<String> get assignmentOrder => throw _privateConstructorUsedError;
  double get difficultyWeight => throw _privateConstructorUsedError;
  String get onMissAssign => throw _privateConstructorUsedError;

  /// Create a copy of TaskInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskInputCopyWith<TaskInput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskInputCopyWith<$Res> {
  factory $TaskInputCopyWith(TaskInput value, $Res Function(TaskInput) then) =
      _$TaskInputCopyWithImpl<$Res, TaskInput>;
  @useResult
  $Res call(
      {String title,
      String? description,
      String visualKind,
      String visualValue,
      RecurrenceRule recurrenceRule,
      String assignmentMode,
      List<String> assignmentOrder,
      double difficultyWeight,
      String onMissAssign});

  $RecurrenceRuleCopyWith<$Res> get recurrenceRule;
}

/// @nodoc
class _$TaskInputCopyWithImpl<$Res, $Val extends TaskInput>
    implements $TaskInputCopyWith<$Res> {
  _$TaskInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = freezed,
    Object? visualKind = null,
    Object? visualValue = null,
    Object? recurrenceRule = null,
    Object? assignmentMode = null,
    Object? assignmentOrder = null,
    Object? difficultyWeight = null,
    Object? onMissAssign = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      visualKind: null == visualKind
          ? _value.visualKind
          : visualKind // ignore: cast_nullable_to_non_nullable
              as String,
      visualValue: null == visualValue
          ? _value.visualValue
          : visualValue // ignore: cast_nullable_to_non_nullable
              as String,
      recurrenceRule: null == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as RecurrenceRule,
      assignmentMode: null == assignmentMode
          ? _value.assignmentMode
          : assignmentMode // ignore: cast_nullable_to_non_nullable
              as String,
      assignmentOrder: null == assignmentOrder
          ? _value.assignmentOrder
          : assignmentOrder // ignore: cast_nullable_to_non_nullable
              as List<String>,
      difficultyWeight: null == difficultyWeight
          ? _value.difficultyWeight
          : difficultyWeight // ignore: cast_nullable_to_non_nullable
              as double,
      onMissAssign: null == onMissAssign
          ? _value.onMissAssign
          : onMissAssign // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of TaskInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecurrenceRuleCopyWith<$Res> get recurrenceRule {
    return $RecurrenceRuleCopyWith<$Res>(_value.recurrenceRule, (value) {
      return _then(_value.copyWith(recurrenceRule: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TaskInputImplCopyWith<$Res>
    implements $TaskInputCopyWith<$Res> {
  factory _$$TaskInputImplCopyWith(
          _$TaskInputImpl value, $Res Function(_$TaskInputImpl) then) =
      __$$TaskInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title,
      String? description,
      String visualKind,
      String visualValue,
      RecurrenceRule recurrenceRule,
      String assignmentMode,
      List<String> assignmentOrder,
      double difficultyWeight,
      String onMissAssign});

  @override
  $RecurrenceRuleCopyWith<$Res> get recurrenceRule;
}

/// @nodoc
class __$$TaskInputImplCopyWithImpl<$Res>
    extends _$TaskInputCopyWithImpl<$Res, _$TaskInputImpl>
    implements _$$TaskInputImplCopyWith<$Res> {
  __$$TaskInputImplCopyWithImpl(
      _$TaskInputImpl _value, $Res Function(_$TaskInputImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = freezed,
    Object? visualKind = null,
    Object? visualValue = null,
    Object? recurrenceRule = null,
    Object? assignmentMode = null,
    Object? assignmentOrder = null,
    Object? difficultyWeight = null,
    Object? onMissAssign = null,
  }) {
    return _then(_$TaskInputImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      visualKind: null == visualKind
          ? _value.visualKind
          : visualKind // ignore: cast_nullable_to_non_nullable
              as String,
      visualValue: null == visualValue
          ? _value.visualValue
          : visualValue // ignore: cast_nullable_to_non_nullable
              as String,
      recurrenceRule: null == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as RecurrenceRule,
      assignmentMode: null == assignmentMode
          ? _value.assignmentMode
          : assignmentMode // ignore: cast_nullable_to_non_nullable
              as String,
      assignmentOrder: null == assignmentOrder
          ? _value._assignmentOrder
          : assignmentOrder // ignore: cast_nullable_to_non_nullable
              as List<String>,
      difficultyWeight: null == difficultyWeight
          ? _value.difficultyWeight
          : difficultyWeight // ignore: cast_nullable_to_non_nullable
              as double,
      onMissAssign: null == onMissAssign
          ? _value.onMissAssign
          : onMissAssign // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TaskInputImpl implements _TaskInput {
  const _$TaskInputImpl(
      {required this.title,
      this.description,
      required this.visualKind,
      required this.visualValue,
      required this.recurrenceRule,
      required this.assignmentMode,
      required final List<String> assignmentOrder,
      this.difficultyWeight = 1.0,
      this.onMissAssign = 'sameAssignee'})
      : _assignmentOrder = assignmentOrder;

  @override
  final String title;
  @override
  final String? description;
  @override
  final String visualKind;
  @override
  final String visualValue;
  @override
  final RecurrenceRule recurrenceRule;
  @override
  final String assignmentMode;
  final List<String> _assignmentOrder;
  @override
  List<String> get assignmentOrder {
    if (_assignmentOrder is EqualUnmodifiableListView) return _assignmentOrder;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignmentOrder);
  }

  @override
  @JsonKey()
  final double difficultyWeight;
  @override
  @JsonKey()
  final String onMissAssign;

  @override
  String toString() {
    return 'TaskInput(title: $title, description: $description, visualKind: $visualKind, visualValue: $visualValue, recurrenceRule: $recurrenceRule, assignmentMode: $assignmentMode, assignmentOrder: $assignmentOrder, difficultyWeight: $difficultyWeight, onMissAssign: $onMissAssign)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskInputImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.visualKind, visualKind) ||
                other.visualKind == visualKind) &&
            (identical(other.visualValue, visualValue) ||
                other.visualValue == visualValue) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.assignmentMode, assignmentMode) ||
                other.assignmentMode == assignmentMode) &&
            const DeepCollectionEquality()
                .equals(other._assignmentOrder, _assignmentOrder) &&
            (identical(other.difficultyWeight, difficultyWeight) ||
                other.difficultyWeight == difficultyWeight) &&
            (identical(other.onMissAssign, onMissAssign) ||
                other.onMissAssign == onMissAssign));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      description,
      visualKind,
      visualValue,
      recurrenceRule,
      assignmentMode,
      const DeepCollectionEquality().hash(_assignmentOrder),
      difficultyWeight,
      onMissAssign);

  /// Create a copy of TaskInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskInputImplCopyWith<_$TaskInputImpl> get copyWith =>
      __$$TaskInputImplCopyWithImpl<_$TaskInputImpl>(this, _$identity);
}

abstract class _TaskInput implements TaskInput {
  const factory _TaskInput(
      {required final String title,
      final String? description,
      required final String visualKind,
      required final String visualValue,
      required final RecurrenceRule recurrenceRule,
      required final String assignmentMode,
      required final List<String> assignmentOrder,
      final double difficultyWeight,
      final String onMissAssign}) = _$TaskInputImpl;

  @override
  String get title;
  @override
  String? get description;
  @override
  String get visualKind;
  @override
  String get visualValue;
  @override
  RecurrenceRule get recurrenceRule;
  @override
  String get assignmentMode;
  @override
  List<String> get assignmentOrder;
  @override
  double get difficultyWeight;
  @override
  String get onMissAssign;

  /// Create a copy of TaskInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskInputImplCopyWith<_$TaskInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
