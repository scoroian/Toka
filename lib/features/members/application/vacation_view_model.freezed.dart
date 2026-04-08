// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vacation_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VacationVMState {
  bool get isInitialized => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  bool get savedSuccessfully => throw _privateConstructorUsedError;

  /// Create a copy of _VacationVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$VacationVMStateCopyWith<_VacationVMState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$VacationVMStateCopyWith<$Res> {
  factory _$VacationVMStateCopyWith(
          _VacationVMState value, $Res Function(_VacationVMState) then) =
      __$VacationVMStateCopyWithImpl<$Res, _VacationVMState>;
  @useResult
  $Res call(
      {bool isInitialized,
      bool isActive,
      DateTime? startDate,
      DateTime? endDate,
      bool savedSuccessfully});
}

/// @nodoc
class __$VacationVMStateCopyWithImpl<$Res, $Val extends _VacationVMState>
    implements _$VacationVMStateCopyWith<$Res> {
  __$VacationVMStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _VacationVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isActive = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? savedSuccessfully = null,
  }) {
    return _then(_value.copyWith(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      savedSuccessfully: null == savedSuccessfully
          ? _value.savedSuccessfully
          : savedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_VacationVMStateImplCopyWith<$Res>
    implements _$VacationVMStateCopyWith<$Res> {
  factory _$$_VacationVMStateImplCopyWith(_$_VacationVMStateImpl value,
          $Res Function(_$_VacationVMStateImpl) then) =
      __$$_VacationVMStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isInitialized,
      bool isActive,
      DateTime? startDate,
      DateTime? endDate,
      bool savedSuccessfully});
}

/// @nodoc
class __$$_VacationVMStateImplCopyWithImpl<$Res>
    extends __$VacationVMStateCopyWithImpl<$Res, _$_VacationVMStateImpl>
    implements _$$_VacationVMStateImplCopyWith<$Res> {
  __$$_VacationVMStateImplCopyWithImpl(_$_VacationVMStateImpl _value,
      $Res Function(_$_VacationVMStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _VacationVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isActive = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? savedSuccessfully = null,
  }) {
    return _then(_$_VacationVMStateImpl(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      savedSuccessfully: null == savedSuccessfully
          ? _value.savedSuccessfully
          : savedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_VacationVMStateImpl implements __VacationVMState {
  const _$_VacationVMStateImpl(
      {this.isInitialized = false,
      this.isActive = false,
      this.startDate,
      this.endDate,
      this.savedSuccessfully = false});

  @override
  @JsonKey()
  final bool isInitialized;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  @JsonKey()
  final bool savedSuccessfully;

  @override
  String toString() {
    return '_VacationVMState(isInitialized: $isInitialized, isActive: $isActive, startDate: $startDate, endDate: $endDate, savedSuccessfully: $savedSuccessfully)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_VacationVMStateImpl &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.savedSuccessfully, savedSuccessfully) ||
                other.savedSuccessfully == savedSuccessfully));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isInitialized, isActive,
      startDate, endDate, savedSuccessfully);

  /// Create a copy of _VacationVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_VacationVMStateImplCopyWith<_$_VacationVMStateImpl> get copyWith =>
      __$$_VacationVMStateImplCopyWithImpl<_$_VacationVMStateImpl>(
          this, _$identity);
}

abstract class __VacationVMState implements _VacationVMState {
  const factory __VacationVMState(
      {final bool isInitialized,
      final bool isActive,
      final DateTime? startDate,
      final DateTime? endDate,
      final bool savedSuccessfully}) = _$_VacationVMStateImpl;

  @override
  bool get isInitialized;
  @override
  bool get isActive;
  @override
  DateTime? get startDate;
  @override
  DateTime? get endDate;
  @override
  bool get savedSuccessfully;

  /// Create a copy of _VacationVMState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_VacationVMStateImplCopyWith<_$_VacationVMStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
