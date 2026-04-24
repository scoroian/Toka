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
mixin _$NotificationSettingsView {
  NotificationPreferences get prefs => throw _privateConstructorUsedError;
  bool get isPremium => throw _privateConstructorUsedError;
  bool get systemAuthorized => throw _privateConstructorUsedError;

  /// Create a copy of NotificationSettingsView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationSettingsViewCopyWith<NotificationSettingsView> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationSettingsViewCopyWith<$Res> {
  factory $NotificationSettingsViewCopyWith(NotificationSettingsView value,
          $Res Function(NotificationSettingsView) then) =
      _$NotificationSettingsViewCopyWithImpl<$Res, NotificationSettingsView>;
  @useResult
  $Res call(
      {NotificationPreferences prefs, bool isPremium, bool systemAuthorized});

  $NotificationPreferencesCopyWith<$Res> get prefs;
}

/// @nodoc
class _$NotificationSettingsViewCopyWithImpl<$Res,
        $Val extends NotificationSettingsView>
    implements $NotificationSettingsViewCopyWith<$Res> {
  _$NotificationSettingsViewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationSettingsView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prefs = null,
    Object? isPremium = null,
    Object? systemAuthorized = null,
  }) {
    return _then(_value.copyWith(
      prefs: null == prefs
          ? _value.prefs
          : prefs // ignore: cast_nullable_to_non_nullable
              as NotificationPreferences,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      systemAuthorized: null == systemAuthorized
          ? _value.systemAuthorized
          : systemAuthorized // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of NotificationSettingsView
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationPreferencesCopyWith<$Res> get prefs {
    return $NotificationPreferencesCopyWith<$Res>(_value.prefs, (value) {
      return _then(_value.copyWith(prefs: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NotificationSettingsViewImplCopyWith<$Res>
    implements $NotificationSettingsViewCopyWith<$Res> {
  factory _$$NotificationSettingsViewImplCopyWith(
          _$NotificationSettingsViewImpl value,
          $Res Function(_$NotificationSettingsViewImpl) then) =
      __$$NotificationSettingsViewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {NotificationPreferences prefs, bool isPremium, bool systemAuthorized});

  @override
  $NotificationPreferencesCopyWith<$Res> get prefs;
}

/// @nodoc
class __$$NotificationSettingsViewImplCopyWithImpl<$Res>
    extends _$NotificationSettingsViewCopyWithImpl<$Res,
        _$NotificationSettingsViewImpl>
    implements _$$NotificationSettingsViewImplCopyWith<$Res> {
  __$$NotificationSettingsViewImplCopyWithImpl(
      _$NotificationSettingsViewImpl _value,
      $Res Function(_$NotificationSettingsViewImpl) _then)
      : super(_value, _then);

  /// Create a copy of NotificationSettingsView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prefs = null,
    Object? isPremium = null,
    Object? systemAuthorized = null,
  }) {
    return _then(_$NotificationSettingsViewImpl(
      prefs: null == prefs
          ? _value.prefs
          : prefs // ignore: cast_nullable_to_non_nullable
              as NotificationPreferences,
      isPremium: null == isPremium
          ? _value.isPremium
          : isPremium // ignore: cast_nullable_to_non_nullable
              as bool,
      systemAuthorized: null == systemAuthorized
          ? _value.systemAuthorized
          : systemAuthorized // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$NotificationSettingsViewImpl implements _NotificationSettingsView {
  const _$NotificationSettingsViewImpl(
      {required this.prefs,
      required this.isPremium,
      required this.systemAuthorized});

  @override
  final NotificationPreferences prefs;
  @override
  final bool isPremium;
  @override
  final bool systemAuthorized;

  @override
  String toString() {
    return 'NotificationSettingsView(prefs: $prefs, isPremium: $isPremium, systemAuthorized: $systemAuthorized)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationSettingsViewImpl &&
            (identical(other.prefs, prefs) || other.prefs == prefs) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.systemAuthorized, systemAuthorized) ||
                other.systemAuthorized == systemAuthorized));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, prefs, isPremium, systemAuthorized);

  /// Create a copy of NotificationSettingsView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationSettingsViewImplCopyWith<_$NotificationSettingsViewImpl>
      get copyWith => __$$NotificationSettingsViewImplCopyWithImpl<
          _$NotificationSettingsViewImpl>(this, _$identity);
}

abstract class _NotificationSettingsView implements NotificationSettingsView {
  const factory _NotificationSettingsView(
      {required final NotificationPreferences prefs,
      required final bool isPremium,
      required final bool systemAuthorized}) = _$NotificationSettingsViewImpl;

  @override
  NotificationPreferences get prefs;
  @override
  bool get isPremium;
  @override
  bool get systemAuthorized;

  /// Create a copy of NotificationSettingsView
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationSettingsViewImplCopyWith<_$NotificationSettingsViewImpl>
      get copyWith => throw _privateConstructorUsedError;
}
