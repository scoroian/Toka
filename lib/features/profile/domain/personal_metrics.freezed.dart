// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PersonalMetrics {
  int get tasksCompleted => throw _privateConstructorUsedError;
  int get passedCount => throw _privateConstructorUsedError;

  /// Puntualidad en % (0–100), derivada de `complianceRate`.
  double get compliancePercent => throw _privateConstructorUsedError;
  int get currentStreak => throw _privateConstructorUsedError;

  /// Puntuación media recibida (0–10).
  double get averageScore => throw _privateConstructorUsedError;

  /// Reparto: % de tareas completadas por el usuario sobre el total
  /// completado por los miembros vigentes del hogar (0–100).
  double get sharePercent => throw _privateConstructorUsedError;

  /// Si el usuario tiene alguna actividad (para el estado vacío).
  bool get hasData => throw _privateConstructorUsedError;

  /// Create a copy of PersonalMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonalMetricsCopyWith<PersonalMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalMetricsCopyWith<$Res> {
  factory $PersonalMetricsCopyWith(
          PersonalMetrics value, $Res Function(PersonalMetrics) then) =
      _$PersonalMetricsCopyWithImpl<$Res, PersonalMetrics>;
  @useResult
  $Res call(
      {int tasksCompleted,
      int passedCount,
      double compliancePercent,
      int currentStreak,
      double averageScore,
      double sharePercent,
      bool hasData});
}

/// @nodoc
class _$PersonalMetricsCopyWithImpl<$Res, $Val extends PersonalMetrics>
    implements $PersonalMetricsCopyWith<$Res> {
  _$PersonalMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PersonalMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tasksCompleted = null,
    Object? passedCount = null,
    Object? compliancePercent = null,
    Object? currentStreak = null,
    Object? averageScore = null,
    Object? sharePercent = null,
    Object? hasData = null,
  }) {
    return _then(_value.copyWith(
      tasksCompleted: null == tasksCompleted
          ? _value.tasksCompleted
          : tasksCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      passedCount: null == passedCount
          ? _value.passedCount
          : passedCount // ignore: cast_nullable_to_non_nullable
              as int,
      compliancePercent: null == compliancePercent
          ? _value.compliancePercent
          : compliancePercent // ignore: cast_nullable_to_non_nullable
              as double,
      currentStreak: null == currentStreak
          ? _value.currentStreak
          : currentStreak // ignore: cast_nullable_to_non_nullable
              as int,
      averageScore: null == averageScore
          ? _value.averageScore
          : averageScore // ignore: cast_nullable_to_non_nullable
              as double,
      sharePercent: null == sharePercent
          ? _value.sharePercent
          : sharePercent // ignore: cast_nullable_to_non_nullable
              as double,
      hasData: null == hasData
          ? _value.hasData
          : hasData // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PersonalMetricsImplCopyWith<$Res>
    implements $PersonalMetricsCopyWith<$Res> {
  factory _$$PersonalMetricsImplCopyWith(_$PersonalMetricsImpl value,
          $Res Function(_$PersonalMetricsImpl) then) =
      __$$PersonalMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int tasksCompleted,
      int passedCount,
      double compliancePercent,
      int currentStreak,
      double averageScore,
      double sharePercent,
      bool hasData});
}

/// @nodoc
class __$$PersonalMetricsImplCopyWithImpl<$Res>
    extends _$PersonalMetricsCopyWithImpl<$Res, _$PersonalMetricsImpl>
    implements _$$PersonalMetricsImplCopyWith<$Res> {
  __$$PersonalMetricsImplCopyWithImpl(
      _$PersonalMetricsImpl _value, $Res Function(_$PersonalMetricsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PersonalMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tasksCompleted = null,
    Object? passedCount = null,
    Object? compliancePercent = null,
    Object? currentStreak = null,
    Object? averageScore = null,
    Object? sharePercent = null,
    Object? hasData = null,
  }) {
    return _then(_$PersonalMetricsImpl(
      tasksCompleted: null == tasksCompleted
          ? _value.tasksCompleted
          : tasksCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      passedCount: null == passedCount
          ? _value.passedCount
          : passedCount // ignore: cast_nullable_to_non_nullable
              as int,
      compliancePercent: null == compliancePercent
          ? _value.compliancePercent
          : compliancePercent // ignore: cast_nullable_to_non_nullable
              as double,
      currentStreak: null == currentStreak
          ? _value.currentStreak
          : currentStreak // ignore: cast_nullable_to_non_nullable
              as int,
      averageScore: null == averageScore
          ? _value.averageScore
          : averageScore // ignore: cast_nullable_to_non_nullable
              as double,
      sharePercent: null == sharePercent
          ? _value.sharePercent
          : sharePercent // ignore: cast_nullable_to_non_nullable
              as double,
      hasData: null == hasData
          ? _value.hasData
          : hasData // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PersonalMetricsImpl extends _PersonalMetrics {
  const _$PersonalMetricsImpl(
      {required this.tasksCompleted,
      required this.passedCount,
      required this.compliancePercent,
      required this.currentStreak,
      required this.averageScore,
      required this.sharePercent,
      required this.hasData})
      : super._();

  @override
  final int tasksCompleted;
  @override
  final int passedCount;

  /// Puntualidad en % (0–100), derivada de `complianceRate`.
  @override
  final double compliancePercent;
  @override
  final int currentStreak;

  /// Puntuación media recibida (0–10).
  @override
  final double averageScore;

  /// Reparto: % de tareas completadas por el usuario sobre el total
  /// completado por los miembros vigentes del hogar (0–100).
  @override
  final double sharePercent;

  /// Si el usuario tiene alguna actividad (para el estado vacío).
  @override
  final bool hasData;

  @override
  String toString() {
    return 'PersonalMetrics(tasksCompleted: $tasksCompleted, passedCount: $passedCount, compliancePercent: $compliancePercent, currentStreak: $currentStreak, averageScore: $averageScore, sharePercent: $sharePercent, hasData: $hasData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalMetricsImpl &&
            (identical(other.tasksCompleted, tasksCompleted) ||
                other.tasksCompleted == tasksCompleted) &&
            (identical(other.passedCount, passedCount) ||
                other.passedCount == passedCount) &&
            (identical(other.compliancePercent, compliancePercent) ||
                other.compliancePercent == compliancePercent) &&
            (identical(other.currentStreak, currentStreak) ||
                other.currentStreak == currentStreak) &&
            (identical(other.averageScore, averageScore) ||
                other.averageScore == averageScore) &&
            (identical(other.sharePercent, sharePercent) ||
                other.sharePercent == sharePercent) &&
            (identical(other.hasData, hasData) || other.hasData == hasData));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tasksCompleted, passedCount,
      compliancePercent, currentStreak, averageScore, sharePercent, hasData);

  /// Create a copy of PersonalMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalMetricsImplCopyWith<_$PersonalMetricsImpl> get copyWith =>
      __$$PersonalMetricsImplCopyWithImpl<_$PersonalMetricsImpl>(
          this, _$identity);
}

abstract class _PersonalMetrics extends PersonalMetrics {
  const factory _PersonalMetrics(
      {required final int tasksCompleted,
      required final int passedCount,
      required final double compliancePercent,
      required final int currentStreak,
      required final double averageScore,
      required final double sharePercent,
      required final bool hasData}) = _$PersonalMetricsImpl;
  const _PersonalMetrics._() : super._();

  @override
  int get tasksCompleted;
  @override
  int get passedCount;

  /// Puntualidad en % (0–100), derivada de `complianceRate`.
  @override
  double get compliancePercent;
  @override
  int get currentStreak;

  /// Puntuación media recibida (0–10).
  @override
  double get averageScore;

  /// Reparto: % de tareas completadas por el usuario sobre el total
  /// completado por los miembros vigentes del hogar (0–100).
  @override
  double get sharePercent;

  /// Si el usuario tiene alguna actividad (para el estado vacío).
  @override
  bool get hasData;

  /// Create a copy of PersonalMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonalMetricsImplCopyWith<_$PersonalMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
