// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downgrade_planner_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DowngradeVMState {
  Set<String> get selectedMemberIds => throw _privateConstructorUsedError;
  Set<String> get selectedTaskIds => throw _privateConstructorUsedError;
  bool get initialized => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get savedSuccessfully => throw _privateConstructorUsedError;

  /// Create a copy of _DowngradeVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$DowngradeVMStateCopyWith<_DowngradeVMState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$DowngradeVMStateCopyWith<$Res> {
  factory _$DowngradeVMStateCopyWith(
          _DowngradeVMState value, $Res Function(_DowngradeVMState) then) =
      __$DowngradeVMStateCopyWithImpl<$Res, _DowngradeVMState>;
  @useResult
  $Res call(
      {Set<String> selectedMemberIds,
      Set<String> selectedTaskIds,
      bool initialized,
      bool isLoading,
      bool savedSuccessfully});
}

/// @nodoc
class __$DowngradeVMStateCopyWithImpl<$Res, $Val extends _DowngradeVMState>
    implements _$DowngradeVMStateCopyWith<$Res> {
  __$DowngradeVMStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _DowngradeVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedMemberIds = null,
    Object? selectedTaskIds = null,
    Object? initialized = null,
    Object? isLoading = null,
    Object? savedSuccessfully = null,
  }) {
    return _then(_value.copyWith(
      selectedMemberIds: null == selectedMemberIds
          ? _value.selectedMemberIds
          : selectedMemberIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedTaskIds: null == selectedTaskIds
          ? _value.selectedTaskIds
          : selectedTaskIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      initialized: null == initialized
          ? _value.initialized
          : initialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      savedSuccessfully: null == savedSuccessfully
          ? _value.savedSuccessfully
          : savedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_DowngradeVMStateImplCopyWith<$Res>
    implements _$DowngradeVMStateCopyWith<$Res> {
  factory _$$_DowngradeVMStateImplCopyWith(_$_DowngradeVMStateImpl value,
          $Res Function(_$_DowngradeVMStateImpl) then) =
      __$$_DowngradeVMStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Set<String> selectedMemberIds,
      Set<String> selectedTaskIds,
      bool initialized,
      bool isLoading,
      bool savedSuccessfully});
}

/// @nodoc
class __$$_DowngradeVMStateImplCopyWithImpl<$Res>
    extends __$DowngradeVMStateCopyWithImpl<$Res, _$_DowngradeVMStateImpl>
    implements _$$_DowngradeVMStateImplCopyWith<$Res> {
  __$$_DowngradeVMStateImplCopyWithImpl(_$_DowngradeVMStateImpl _value,
      $Res Function(_$_DowngradeVMStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _DowngradeVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedMemberIds = null,
    Object? selectedTaskIds = null,
    Object? initialized = null,
    Object? isLoading = null,
    Object? savedSuccessfully = null,
  }) {
    return _then(_$_DowngradeVMStateImpl(
      selectedMemberIds: null == selectedMemberIds
          ? _value._selectedMemberIds
          : selectedMemberIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      selectedTaskIds: null == selectedTaskIds
          ? _value._selectedTaskIds
          : selectedTaskIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      initialized: null == initialized
          ? _value.initialized
          : initialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      savedSuccessfully: null == savedSuccessfully
          ? _value.savedSuccessfully
          : savedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_DowngradeVMStateImpl implements __DowngradeVMState {
  const _$_DowngradeVMStateImpl(
      {final Set<String> selectedMemberIds = const {},
      final Set<String> selectedTaskIds = const {},
      this.initialized = false,
      this.isLoading = false,
      this.savedSuccessfully = false})
      : _selectedMemberIds = selectedMemberIds,
        _selectedTaskIds = selectedTaskIds;

  final Set<String> _selectedMemberIds;
  @override
  @JsonKey()
  Set<String> get selectedMemberIds {
    if (_selectedMemberIds is EqualUnmodifiableSetView)
      return _selectedMemberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedMemberIds);
  }

  final Set<String> _selectedTaskIds;
  @override
  @JsonKey()
  Set<String> get selectedTaskIds {
    if (_selectedTaskIds is EqualUnmodifiableSetView) return _selectedTaskIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedTaskIds);
  }

  @override
  @JsonKey()
  final bool initialized;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool savedSuccessfully;

  @override
  String toString() {
    return '_DowngradeVMState(selectedMemberIds: $selectedMemberIds, selectedTaskIds: $selectedTaskIds, initialized: $initialized, isLoading: $isLoading, savedSuccessfully: $savedSuccessfully)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_DowngradeVMStateImpl &&
            const DeepCollectionEquality()
                .equals(other._selectedMemberIds, _selectedMemberIds) &&
            const DeepCollectionEquality()
                .equals(other._selectedTaskIds, _selectedTaskIds) &&
            (identical(other.initialized, initialized) ||
                other.initialized == initialized) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.savedSuccessfully, savedSuccessfully) ||
                other.savedSuccessfully == savedSuccessfully));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_selectedMemberIds),
      const DeepCollectionEquality().hash(_selectedTaskIds),
      initialized,
      isLoading,
      savedSuccessfully);

  /// Create a copy of _DowngradeVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_DowngradeVMStateImplCopyWith<_$_DowngradeVMStateImpl> get copyWith =>
      __$$_DowngradeVMStateImplCopyWithImpl<_$_DowngradeVMStateImpl>(
          this, _$identity);
}

abstract class __DowngradeVMState implements _DowngradeVMState {
  const factory __DowngradeVMState(
      {final Set<String> selectedMemberIds,
      final Set<String> selectedTaskIds,
      final bool initialized,
      final bool isLoading,
      final bool savedSuccessfully}) = _$_DowngradeVMStateImpl;

  @override
  Set<String> get selectedMemberIds;
  @override
  Set<String> get selectedTaskIds;
  @override
  bool get initialized;
  @override
  bool get isLoading;
  @override
  bool get savedSuccessfully;

  /// Create a copy of _DowngradeVMState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_DowngradeVMStateImplCopyWith<_$_DowngradeVMStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
