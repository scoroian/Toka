// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OnboardingVMState {
  bool get isInitialized => throw _privateConstructorUsedError;
  bool get shouldNavigateHome => throw _privateConstructorUsedError;

  /// Create a copy of _OnboardingVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$OnboardingVMStateCopyWith<_OnboardingVMState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$OnboardingVMStateCopyWith<$Res> {
  factory _$OnboardingVMStateCopyWith(
          _OnboardingVMState value, $Res Function(_OnboardingVMState) then) =
      __$OnboardingVMStateCopyWithImpl<$Res, _OnboardingVMState>;
  @useResult
  $Res call({bool isInitialized, bool shouldNavigateHome});
}

/// @nodoc
class __$OnboardingVMStateCopyWithImpl<$Res, $Val extends _OnboardingVMState>
    implements _$OnboardingVMStateCopyWith<$Res> {
  __$OnboardingVMStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _OnboardingVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? shouldNavigateHome = null,
  }) {
    return _then(_value.copyWith(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      shouldNavigateHome: null == shouldNavigateHome
          ? _value.shouldNavigateHome
          : shouldNavigateHome // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_OnboardingVMStateImplCopyWith<$Res>
    implements _$OnboardingVMStateCopyWith<$Res> {
  factory _$$_OnboardingVMStateImplCopyWith(_$_OnboardingVMStateImpl value,
          $Res Function(_$_OnboardingVMStateImpl) then) =
      __$$_OnboardingVMStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isInitialized, bool shouldNavigateHome});
}

/// @nodoc
class __$$_OnboardingVMStateImplCopyWithImpl<$Res>
    extends __$OnboardingVMStateCopyWithImpl<$Res, _$_OnboardingVMStateImpl>
    implements _$$_OnboardingVMStateImplCopyWith<$Res> {
  __$$_OnboardingVMStateImplCopyWithImpl(_$_OnboardingVMStateImpl _value,
      $Res Function(_$_OnboardingVMStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _OnboardingVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? shouldNavigateHome = null,
  }) {
    return _then(_$_OnboardingVMStateImpl(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      shouldNavigateHome: null == shouldNavigateHome
          ? _value.shouldNavigateHome
          : shouldNavigateHome // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_OnboardingVMStateImpl implements __OnboardingVMState {
  const _$_OnboardingVMStateImpl(
      {this.isInitialized = false, this.shouldNavigateHome = false});

  @override
  @JsonKey()
  final bool isInitialized;
  @override
  @JsonKey()
  final bool shouldNavigateHome;

  @override
  String toString() {
    return '_OnboardingVMState(isInitialized: $isInitialized, shouldNavigateHome: $shouldNavigateHome)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_OnboardingVMStateImpl &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.shouldNavigateHome, shouldNavigateHome) ||
                other.shouldNavigateHome == shouldNavigateHome));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isInitialized, shouldNavigateHome);

  /// Create a copy of _OnboardingVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_OnboardingVMStateImplCopyWith<_$_OnboardingVMStateImpl> get copyWith =>
      __$$_OnboardingVMStateImplCopyWithImpl<_$_OnboardingVMStateImpl>(
          this, _$identity);
}

abstract class __OnboardingVMState implements _OnboardingVMState {
  const factory __OnboardingVMState(
      {final bool isInitialized,
      final bool shouldNavigateHome}) = _$_OnboardingVMStateImpl;

  @override
  bool get isInitialized;
  @override
  bool get shouldNavigateHome;

  /// Create a copy of _OnboardingVMState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_OnboardingVMStateImplCopyWith<_$_OnboardingVMStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
