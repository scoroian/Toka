// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_limits.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeLimits {
  int get maxMembers => throw _privateConstructorUsedError;

  /// Create a copy of HomeLimits
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeLimitsCopyWith<HomeLimits> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeLimitsCopyWith<$Res> {
  factory $HomeLimitsCopyWith(
          HomeLimits value, $Res Function(HomeLimits) then) =
      _$HomeLimitsCopyWithImpl<$Res, HomeLimits>;
  @useResult
  $Res call({int maxMembers});
}

/// @nodoc
class _$HomeLimitsCopyWithImpl<$Res, $Val extends HomeLimits>
    implements $HomeLimitsCopyWith<$Res> {
  _$HomeLimitsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeLimits
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxMembers = null,
  }) {
    return _then(_value.copyWith(
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeLimitsImplCopyWith<$Res>
    implements $HomeLimitsCopyWith<$Res> {
  factory _$$HomeLimitsImplCopyWith(
          _$HomeLimitsImpl value, $Res Function(_$HomeLimitsImpl) then) =
      __$$HomeLimitsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int maxMembers});
}

/// @nodoc
class __$$HomeLimitsImplCopyWithImpl<$Res>
    extends _$HomeLimitsCopyWithImpl<$Res, _$HomeLimitsImpl>
    implements _$$HomeLimitsImplCopyWith<$Res> {
  __$$HomeLimitsImplCopyWithImpl(
      _$HomeLimitsImpl _value, $Res Function(_$HomeLimitsImpl) _then)
      : super(_value, _then);

  /// Create a copy of HomeLimits
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxMembers = null,
  }) {
    return _then(_$HomeLimitsImpl(
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$HomeLimitsImpl implements _HomeLimits {
  const _$HomeLimitsImpl({required this.maxMembers});

  @override
  final int maxMembers;

  @override
  String toString() {
    return 'HomeLimits(maxMembers: $maxMembers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeLimitsImpl &&
            (identical(other.maxMembers, maxMembers) ||
                other.maxMembers == maxMembers));
  }

  @override
  int get hashCode => Object.hash(runtimeType, maxMembers);

  /// Create a copy of HomeLimits
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeLimitsImplCopyWith<_$HomeLimitsImpl> get copyWith =>
      __$$HomeLimitsImplCopyWithImpl<_$HomeLimitsImpl>(this, _$identity);
}

abstract class _HomeLimits implements HomeLimits {
  const factory _HomeLimits({required final int maxMembers}) = _$HomeLimitsImpl;

  @override
  int get maxMembers;

  /// Create a copy of HomeLimits
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeLimitsImplCopyWith<_$HomeLimitsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
