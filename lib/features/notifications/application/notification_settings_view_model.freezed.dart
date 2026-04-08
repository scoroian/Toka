// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_settings_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NotifVMState {
  bool get isLoaded => throw _privateConstructorUsedError;
  bool get isPremium => throw _privateConstructorUsedError;
  NotificationPreferences? get prefs => throw _privateConstructorUsedError;

  /// Create a copy of _NotifVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$NotifVMStateCopyWith<_NotifVMState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$NotifVMStateCopyWith<$Res> {
  factory _$NotifVMStateCopyWith(
          _NotifVMState value, $Res Function(_NotifVMState) then) =
      __$NotifVMStateCopyWithImpl<$Res, _NotifVMState>;
  @useResult
  $Res call({bool isLoaded, bool isPremium, NotificationPreferences? prefs});

  $NotificationPreferencesCopyWith<$Res>? get prefs;
}

/// @nodoc
class __$NotifVMStateCopyWithImpl<$Res, $Val extends _NotifVMState>
    implements _$NotifVMStateCopyWith<$Res> {
  __$NotifVMStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of _NotifVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoaded = null,
    Object? isPremium = null,
    Object? prefs = freezed,
  }) {
    return _then(_value.copyWith(
      isLoaded: null == isLoaded
          ? _value.isLoaded
          : isLoaded // ignore: cast_nullable_to_non_nullable
              as bool,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      prefs: freezed == prefs
          ? _value.prefs
          : prefs // ignore: cast_nullable_to_non_nullable
              as NotificationPreferences?,
    ) as $Val);
  }

  /// Create a copy of _NotifVMState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationPreferencesCopyWith<$Res>? get prefs {
    if (_value.prefs == null) {
      return null;
    }

    return $NotificationPreferencesCopyWith<$Res>(_value.prefs!, (value) {
      return _then(_value.copyWith(prefs: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_NotifVMStateImplCopyWith<$Res>
    implements _$NotifVMStateCopyWith<$Res> {
  factory _$$_NotifVMStateImplCopyWith(
          _$_NotifVMStateImpl value, $Res Function(_$_NotifVMStateImpl) then) =
      __$$_NotifVMStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoaded, bool isPremium, NotificationPreferences? prefs});

  @override
  $NotificationPreferencesCopyWith<$Res>? get prefs;
}

/// @nodoc
class __$$_NotifVMStateImplCopyWithImpl<$Res>
    extends __$NotifVMStateCopyWithImpl<$Res, _$_NotifVMStateImpl>
    implements _$$_NotifVMStateImplCopyWith<$Res> {
  __$$_NotifVMStateImplCopyWithImpl(
      _$_NotifVMStateImpl _value, $Res Function(_$_NotifVMStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of _NotifVMState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoaded = null,
    Object? isPremium = null,
    Object? prefs = freezed,
  }) {
    return _then(_$_NotifVMStateImpl(
      isLoaded: null == isLoaded
          ? _value.isLoaded
          : isLoaded // ignore: cast_nullable_to_non_nullable
              as bool,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      prefs: freezed == prefs
          ? _value.prefs
          : prefs // ignore: cast_nullable_to_non_nullable
              as NotificationPreferences?,
    ));
  }
}

/// @nodoc

class _$_NotifVMStateImpl implements __NotifVMState {
  const _$_NotifVMStateImpl(
      {this.isLoaded = false, this.isPremium = false, this.prefs});

  @override
  @JsonKey()
  final bool isLoaded;
  @override
  @JsonKey()
  final bool isPremium;
  @override
  final NotificationPreferences? prefs;

  @override
  String toString() {
    return '_NotifVMState(isLoaded: $isLoaded, isPremium: $isPremium, prefs: $prefs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_NotifVMStateImpl &&
            (identical(other.isLoaded, isLoaded) ||
                other.isLoaded == isLoaded) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.prefs, prefs) || other.prefs == prefs));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoaded, isPremium, prefs);

  /// Create a copy of _NotifVMState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$_NotifVMStateImplCopyWith<_$_NotifVMStateImpl> get copyWith =>
      __$$_NotifVMStateImplCopyWithImpl<_$_NotifVMStateImpl>(this, _$identity);
}

abstract class __NotifVMState implements _NotifVMState {
  const factory __NotifVMState(
      {final bool isLoaded,
      final bool isPremium,
      final NotificationPreferences? prefs}) = _$_NotifVMStateImpl;

  @override
  bool get isLoaded;
  @override
  bool get isPremium;
  @override
  NotificationPreferences? get prefs;

  /// Create a copy of _NotifVMState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$_NotifVMStateImplCopyWith<_$_NotifVMStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
