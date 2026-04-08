// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_edit_task_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CreateEditVMState {
  bool get savedSuccessfully => throw _privateConstructorUsedError;
  String? get loadedTitle => throw _privateConstructorUsedError;
  String? get loadedDescription => throw _privateConstructorUsedError;

  /// Create a copy of _CreateEditVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$CreateEditVMStateCopyWith<_CreateEditVMState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$CreateEditVMStateCopyWith<$Res> {
  factory _$CreateEditVMStateCopyWith(
          _CreateEditVMState value, $Res Function(_CreateEditVMState) then) =
      __$CreateEditVMStateCopyWithImpl<$Res, _CreateEditVMState>;
  @useResult
  $Res call(
      {bool savedSuccessfully, String? loadedTitle, String? loadedDescription});
}

/// @nodoc
class __$CreateEditVMStateCopyWithImpl<$Res, $Val extends _CreateEditVMState>
    implements _$CreateEditVMStateCopyWith<$Res> {
  __$CreateEditVMStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _CreateEditVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? savedSuccessfully = null,
    Object? loadedTitle = freezed,
    Object? loadedDescription = freezed,
  }) {
    return _then(_value.copyWith(
      savedSuccessfully: null == savedSuccessfully
          ? _value.savedSuccessfully
          : savedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      loadedTitle: freezed == loadedTitle
          ? _value.loadedTitle
          : loadedTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      loadedDescription: freezed == loadedDescription
          ? _value.loadedDescription
          : loadedDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_CreateEditVMStateImplCopyWith<$Res>
    implements _$CreateEditVMStateCopyWith<$Res> {
  factory _$$_CreateEditVMStateImplCopyWith(_$_CreateEditVMStateImpl value,
          $Res Function(_$_CreateEditVMStateImpl) then) =
      __$$_CreateEditVMStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool savedSuccessfully, String? loadedTitle, String? loadedDescription});
}

/// @nodoc
class __$$_CreateEditVMStateImplCopyWithImpl<$Res>
    extends __$CreateEditVMStateCopyWithImpl<$Res, _$_CreateEditVMStateImpl>
    implements _$$_CreateEditVMStateImplCopyWith<$Res> {
  __$$_CreateEditVMStateImplCopyWithImpl(_$_CreateEditVMStateImpl _value,
      $Res Function(_$_CreateEditVMStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _CreateEditVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? savedSuccessfully = null,
    Object? loadedTitle = freezed,
    Object? loadedDescription = freezed,
  }) {
    return _then(_$_CreateEditVMStateImpl(
      savedSuccessfully: null == savedSuccessfully
          ? _value.savedSuccessfully
          : savedSuccessfully // ignore: cast_nullable_to_non_nullable
              as bool,
      loadedTitle: freezed == loadedTitle
          ? _value.loadedTitle
          : loadedTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      loadedDescription: freezed == loadedDescription
          ? _value.loadedDescription
          : loadedDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$_CreateEditVMStateImpl implements __CreateEditVMState {
  const _$_CreateEditVMStateImpl(
      {this.savedSuccessfully = false,
      this.loadedTitle,
      this.loadedDescription});

  @override
  @JsonKey()
  final bool savedSuccessfully;
  @override
  final String? loadedTitle;
  @override
  final String? loadedDescription;

  @override
  String toString() {
    return '_CreateEditVMState(savedSuccessfully: $savedSuccessfully, loadedTitle: $loadedTitle, loadedDescription: $loadedDescription)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CreateEditVMStateImpl &&
            (identical(other.savedSuccessfully, savedSuccessfully) ||
                other.savedSuccessfully == savedSuccessfully) &&
            (identical(other.loadedTitle, loadedTitle) ||
                other.loadedTitle == loadedTitle) &&
            (identical(other.loadedDescription, loadedDescription) ||
                other.loadedDescription == loadedDescription));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, savedSuccessfully, loadedTitle, loadedDescription);

  /// Create a copy of _CreateEditVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_CreateEditVMStateImplCopyWith<_$_CreateEditVMStateImpl> get copyWith =>
      __$$_CreateEditVMStateImplCopyWithImpl<_$_CreateEditVMStateImpl>(
          this, _$identity);
}

abstract class __CreateEditVMState implements _CreateEditVMState {
  const factory __CreateEditVMState(
      {final bool savedSuccessfully,
      final String? loadedTitle,
      final String? loadedDescription}) = _$_CreateEditVMStateImpl;

  @override
  bool get savedSuccessfully;
  @override
  String? get loadedTitle;
  @override
  String? get loadedDescription;

  /// Create a copy of _CreateEditVMState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_CreateEditVMStateImplCopyWith<_$_CreateEditVMStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
