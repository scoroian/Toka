// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_form_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TaskFormState {
  TaskFormMode get mode => throw _privateConstructorUsedError;
  String? get editingTaskId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get visualKind => throw _privateConstructorUsedError;
  String get visualValue => throw _privateConstructorUsedError;
  RecurrenceRule? get recurrenceRule => throw _privateConstructorUsedError;
  String get assignmentMode => throw _privateConstructorUsedError;
  List<String> get assignmentOrder => throw _privateConstructorUsedError;
  double get difficultyWeight => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  Map<String, String> get fieldErrors => throw _privateConstructorUsedError;
  String? get globalError => throw _privateConstructorUsedError;

  /// Create a copy of TaskFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskFormStateCopyWith<TaskFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskFormStateCopyWith<$Res> {
  factory $TaskFormStateCopyWith(
          TaskFormState value, $Res Function(TaskFormState) then) =
      _$TaskFormStateCopyWithImpl<$Res, TaskFormState>;
  @useResult
  $Res call(
      {TaskFormMode mode,
      String? editingTaskId,
      String title,
      String description,
      String visualKind,
      String visualValue,
      RecurrenceRule? recurrenceRule,
      String assignmentMode,
      List<String> assignmentOrder,
      double difficultyWeight,
      bool isLoading,
      Map<String, String> fieldErrors,
      String? globalError});

  $RecurrenceRuleCopyWith<$Res>? get recurrenceRule;
}

/// @nodoc
class _$TaskFormStateCopyWithImpl<$Res, $Val extends TaskFormState>
    implements $TaskFormStateCopyWith<$Res> {
  _$TaskFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? editingTaskId = freezed,
    Object? title = null,
    Object? description = null,
    Object? visualKind = null,
    Object? visualValue = null,
    Object? recurrenceRule = freezed,
    Object? assignmentMode = null,
    Object? assignmentOrder = null,
    Object? difficultyWeight = null,
    Object? isLoading = null,
    Object? fieldErrors = null,
    Object? globalError = freezed,
  }) {
    return _then(_value.copyWith(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as TaskFormMode,
      editingTaskId: freezed == editingTaskId
          ? _value.editingTaskId
          : editingTaskId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      visualKind: null == visualKind
          ? _value.visualKind
          : visualKind // ignore: cast_nullable_to_non_nullable
              as String,
      visualValue: null == visualValue
          ? _value.visualValue
          : visualValue // ignore: cast_nullable_to_non_nullable
              as String,
      recurrenceRule: freezed == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as RecurrenceRule?,
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
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      fieldErrors: null == fieldErrors
          ? _value.fieldErrors
          : fieldErrors // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      globalError: freezed == globalError
          ? _value.globalError
          : globalError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of TaskFormState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RecurrenceRuleCopyWith<$Res>? get recurrenceRule {
    if (_value.recurrenceRule == null) {
      return null;
    }

    return $RecurrenceRuleCopyWith<$Res>(_value.recurrenceRule!, (value) {
      return _then(_value.copyWith(recurrenceRule: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TaskFormStateImplCopyWith<$Res>
    implements $TaskFormStateCopyWith<$Res> {
  factory _$$TaskFormStateImplCopyWith(
          _$TaskFormStateImpl value, $Res Function(_$TaskFormStateImpl) then) =
      __$$TaskFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {TaskFormMode mode,
      String? editingTaskId,
      String title,
      String description,
      String visualKind,
      String visualValue,
      RecurrenceRule? recurrenceRule,
      String assignmentMode,
      List<String> assignmentOrder,
      double difficultyWeight,
      bool isLoading,
      Map<String, String> fieldErrors,
      String? globalError});

  @override
  $RecurrenceRuleCopyWith<$Res>? get recurrenceRule;
}

/// @nodoc
class __$$TaskFormStateImplCopyWithImpl<$Res>
    extends _$TaskFormStateCopyWithImpl<$Res, _$TaskFormStateImpl>
    implements _$$TaskFormStateImplCopyWith<$Res> {
  __$$TaskFormStateImplCopyWithImpl(
      _$TaskFormStateImpl _value, $Res Function(_$TaskFormStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? editingTaskId = freezed,
    Object? title = null,
    Object? description = null,
    Object? visualKind = null,
    Object? visualValue = null,
    Object? recurrenceRule = freezed,
    Object? assignmentMode = null,
    Object? assignmentOrder = null,
    Object? difficultyWeight = null,
    Object? isLoading = null,
    Object? fieldErrors = null,
    Object? globalError = freezed,
  }) {
    return _then(_$TaskFormStateImpl(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as TaskFormMode,
      editingTaskId: freezed == editingTaskId
          ? _value.editingTaskId
          : editingTaskId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      visualKind: null == visualKind
          ? _value.visualKind
          : visualKind // ignore: cast_nullable_to_non_nullable
              as String,
      visualValue: null == visualValue
          ? _value.visualValue
          : visualValue // ignore: cast_nullable_to_non_nullable
              as String,
      recurrenceRule: freezed == recurrenceRule
          ? _value.recurrenceRule
          : recurrenceRule // ignore: cast_nullable_to_non_nullable
              as RecurrenceRule?,
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
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      fieldErrors: null == fieldErrors
          ? _value._fieldErrors
          : fieldErrors // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      globalError: freezed == globalError
          ? _value.globalError
          : globalError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$TaskFormStateImpl implements _TaskFormState {
  const _$TaskFormStateImpl(
      {this.mode = TaskFormMode.create,
      this.editingTaskId,
      this.title = '',
      this.description = '',
      this.visualKind = 'emoji',
      this.visualValue = '🏠',
      this.recurrenceRule,
      this.assignmentMode = 'basicRotation',
      final List<String> assignmentOrder = const [],
      this.difficultyWeight = 1.0,
      this.isLoading = false,
      final Map<String, String> fieldErrors = const {},
      this.globalError})
      : _assignmentOrder = assignmentOrder,
        _fieldErrors = fieldErrors;

  @override
  @JsonKey()
  final TaskFormMode mode;
  @override
  final String? editingTaskId;
  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final String visualKind;
  @override
  @JsonKey()
  final String visualValue;
  @override
  final RecurrenceRule? recurrenceRule;
  @override
  @JsonKey()
  final String assignmentMode;
  final List<String> _assignmentOrder;
  @override
  @JsonKey()
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
  final bool isLoading;
  final Map<String, String> _fieldErrors;
  @override
  @JsonKey()
  Map<String, String> get fieldErrors {
    if (_fieldErrors is EqualUnmodifiableMapView) return _fieldErrors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_fieldErrors);
  }

  @override
  final String? globalError;

  @override
  String toString() {
    return 'TaskFormState(mode: $mode, editingTaskId: $editingTaskId, title: $title, description: $description, visualKind: $visualKind, visualValue: $visualValue, recurrenceRule: $recurrenceRule, assignmentMode: $assignmentMode, assignmentOrder: $assignmentOrder, difficultyWeight: $difficultyWeight, isLoading: $isLoading, fieldErrors: $fieldErrors, globalError: $globalError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskFormStateImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.editingTaskId, editingTaskId) ||
                other.editingTaskId == editingTaskId) &&
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
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality()
                .equals(other._fieldErrors, _fieldErrors) &&
            (identical(other.globalError, globalError) ||
                other.globalError == globalError));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      mode,
      editingTaskId,
      title,
      description,
      visualKind,
      visualValue,
      recurrenceRule,
      assignmentMode,
      const DeepCollectionEquality().hash(_assignmentOrder),
      difficultyWeight,
      isLoading,
      const DeepCollectionEquality().hash(_fieldErrors),
      globalError);

  /// Create a copy of TaskFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskFormStateImplCopyWith<_$TaskFormStateImpl> get copyWith =>
      __$$TaskFormStateImplCopyWithImpl<_$TaskFormStateImpl>(this, _$identity);
}

abstract class _TaskFormState implements TaskFormState {
  const factory _TaskFormState(
      {final TaskFormMode mode,
      final String? editingTaskId,
      final String title,
      final String description,
      final String visualKind,
      final String visualValue,
      final RecurrenceRule? recurrenceRule,
      final String assignmentMode,
      final List<String> assignmentOrder,
      final double difficultyWeight,
      final bool isLoading,
      final Map<String, String> fieldErrors,
      final String? globalError}) = _$TaskFormStateImpl;

  @override
  TaskFormMode get mode;
  @override
  String? get editingTaskId;
  @override
  String get title;
  @override
  String get description;
  @override
  String get visualKind;
  @override
  String get visualValue;
  @override
  RecurrenceRule? get recurrenceRule;
  @override
  String get assignmentMode;
  @override
  List<String> get assignmentOrder;
  @override
  double get difficultyWeight;
  @override
  bool get isLoading;
  @override
  Map<String, String> get fieldErrors;
  @override
  String? get globalError;

  /// Create a copy of TaskFormState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskFormStateImplCopyWith<_$TaskFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
