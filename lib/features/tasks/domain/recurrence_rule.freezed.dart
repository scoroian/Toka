// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RecurrenceRule {
// "HH:mm"
  String get timezone => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecurrenceRuleCopyWith<RecurrenceRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecurrenceRuleCopyWith<$Res> {
  factory $RecurrenceRuleCopyWith(
          RecurrenceRule value, $Res Function(RecurrenceRule) then) =
      _$RecurrenceRuleCopyWithImpl<$Res, RecurrenceRule>;
  @useResult
  $Res call({String timezone});
}

/// @nodoc
class _$RecurrenceRuleCopyWithImpl<$Res, $Val extends RecurrenceRule>
    implements $RecurrenceRuleCopyWith<$Res> {
  _$RecurrenceRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timezone = null,
  }) {
    return _then(_value.copyWith(
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OneTimeRuleImplCopyWith<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  factory _$$OneTimeRuleImplCopyWith(
          _$OneTimeRuleImpl value, $Res Function(_$OneTimeRuleImpl) then) =
      __$$OneTimeRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, String time, String timezone});
}

/// @nodoc
class __$$OneTimeRuleImplCopyWithImpl<$Res>
    extends _$RecurrenceRuleCopyWithImpl<$Res, _$OneTimeRuleImpl>
    implements _$$OneTimeRuleImplCopyWith<$Res> {
  __$$OneTimeRuleImplCopyWithImpl(
      _$OneTimeRuleImpl _value, $Res Function(_$OneTimeRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? time = null,
    Object? timezone = null,
  }) {
    return _then(_$OneTimeRuleImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$OneTimeRuleImpl implements OneTimeRule {
  const _$OneTimeRuleImpl(
      {required this.date, required this.time, required this.timezone});

  @override
  final String date;
// "YYYY-MM-DD"
  @override
  final String time;
// "HH:mm"
  @override
  final String timezone;

  @override
  String toString() {
    return 'RecurrenceRule.oneTime(date: $date, time: $time, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OneTimeRuleImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, time, timezone);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OneTimeRuleImplCopyWith<_$OneTimeRuleImpl> get copyWith =>
      __$$OneTimeRuleImplCopyWithImpl<_$OneTimeRuleImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) {
    return oneTime(date, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) {
    return oneTime?.call(date, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) {
    if (oneTime != null) {
      return oneTime(date, time, timezone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) {
    return oneTime(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) {
    return oneTime?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) {
    if (oneTime != null) {
      return oneTime(this);
    }
    return orElse();
  }
}

abstract class OneTimeRule implements RecurrenceRule {
  const factory OneTimeRule(
      {required final String date,
      required final String time,
      required final String timezone}) = _$OneTimeRuleImpl;

  String get date; // "YYYY-MM-DD"
  String get time; // "HH:mm"
  @override
  String get timezone;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OneTimeRuleImplCopyWith<_$OneTimeRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$HourlyRuleImplCopyWith<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  factory _$$HourlyRuleImplCopyWith(
          _$HourlyRuleImpl value, $Res Function(_$HourlyRuleImpl) then) =
      __$$HourlyRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int every, String startTime, String? endTime, String timezone});
}

/// @nodoc
class __$$HourlyRuleImplCopyWithImpl<$Res>
    extends _$RecurrenceRuleCopyWithImpl<$Res, _$HourlyRuleImpl>
    implements _$$HourlyRuleImplCopyWith<$Res> {
  __$$HourlyRuleImplCopyWithImpl(
      _$HourlyRuleImpl _value, $Res Function(_$HourlyRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? every = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? timezone = null,
  }) {
    return _then(_$HourlyRuleImpl(
      every: null == every
          ? _value.every
          : every // ignore: cast_nullable_to_non_nullable
              as int,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String?,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$HourlyRuleImpl implements HourlyRule {
  const _$HourlyRuleImpl(
      {required this.every,
      required this.startTime,
      this.endTime,
      required this.timezone});

  @override
  final int every;
  @override
  final String startTime;
// "HH:mm"
  @override
  final String? endTime;
// "HH:mm" opcional
  @override
  final String timezone;

  @override
  String toString() {
    return 'RecurrenceRule.hourly(every: $every, startTime: $startTime, endTime: $endTime, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HourlyRuleImpl &&
            (identical(other.every, every) || other.every == every) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, every, startTime, endTime, timezone);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HourlyRuleImplCopyWith<_$HourlyRuleImpl> get copyWith =>
      __$$HourlyRuleImplCopyWithImpl<_$HourlyRuleImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) {
    return hourly(every, startTime, endTime, timezone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) {
    return hourly?.call(every, startTime, endTime, timezone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) {
    if (hourly != null) {
      return hourly(every, startTime, endTime, timezone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) {
    return hourly(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) {
    return hourly?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) {
    if (hourly != null) {
      return hourly(this);
    }
    return orElse();
  }
}

abstract class HourlyRule implements RecurrenceRule {
  const factory HourlyRule(
      {required final int every,
      required final String startTime,
      final String? endTime,
      required final String timezone}) = _$HourlyRuleImpl;

  int get every;
  String get startTime; // "HH:mm"
  String? get endTime; // "HH:mm" opcional
  @override
  String get timezone;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HourlyRuleImplCopyWith<_$HourlyRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DailyRuleImplCopyWith<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  factory _$$DailyRuleImplCopyWith(
          _$DailyRuleImpl value, $Res Function(_$DailyRuleImpl) then) =
      __$$DailyRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int every, String time, String timezone});
}

/// @nodoc
class __$$DailyRuleImplCopyWithImpl<$Res>
    extends _$RecurrenceRuleCopyWithImpl<$Res, _$DailyRuleImpl>
    implements _$$DailyRuleImplCopyWith<$Res> {
  __$$DailyRuleImplCopyWithImpl(
      _$DailyRuleImpl _value, $Res Function(_$DailyRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? every = null,
    Object? time = null,
    Object? timezone = null,
  }) {
    return _then(_$DailyRuleImpl(
      every: null == every
          ? _value.every
          : every // ignore: cast_nullable_to_non_nullable
              as int,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DailyRuleImpl implements DailyRule {
  const _$DailyRuleImpl(
      {required this.every, required this.time, required this.timezone});

  @override
  final int every;
  @override
  final String time;
// "HH:mm"
  @override
  final String timezone;

  @override
  String toString() {
    return 'RecurrenceRule.daily(every: $every, time: $time, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyRuleImpl &&
            (identical(other.every, every) || other.every == every) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @override
  int get hashCode => Object.hash(runtimeType, every, time, timezone);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyRuleImplCopyWith<_$DailyRuleImpl> get copyWith =>
      __$$DailyRuleImplCopyWithImpl<_$DailyRuleImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) {
    return daily(every, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) {
    return daily?.call(every, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) {
    if (daily != null) {
      return daily(every, time, timezone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) {
    return daily(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) {
    return daily?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) {
    if (daily != null) {
      return daily(this);
    }
    return orElse();
  }
}

abstract class DailyRule implements RecurrenceRule {
  const factory DailyRule(
      {required final int every,
      required final String time,
      required final String timezone}) = _$DailyRuleImpl;

  int get every;
  String get time; // "HH:mm"
  @override
  String get timezone;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyRuleImplCopyWith<_$DailyRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$WeeklyRuleImplCopyWith<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  factory _$$WeeklyRuleImplCopyWith(
          _$WeeklyRuleImpl value, $Res Function(_$WeeklyRuleImpl) then) =
      __$$WeeklyRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> weekdays, String time, String timezone});
}

/// @nodoc
class __$$WeeklyRuleImplCopyWithImpl<$Res>
    extends _$RecurrenceRuleCopyWithImpl<$Res, _$WeeklyRuleImpl>
    implements _$$WeeklyRuleImplCopyWith<$Res> {
  __$$WeeklyRuleImplCopyWithImpl(
      _$WeeklyRuleImpl _value, $Res Function(_$WeeklyRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekdays = null,
    Object? time = null,
    Object? timezone = null,
  }) {
    return _then(_$WeeklyRuleImpl(
      weekdays: null == weekdays
          ? _value._weekdays
          : weekdays // ignore: cast_nullable_to_non_nullable
              as List<String>,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$WeeklyRuleImpl implements WeeklyRule {
  const _$WeeklyRuleImpl(
      {required final List<String> weekdays,
      required this.time,
      required this.timezone})
      : _weekdays = weekdays;

  final List<String> _weekdays;
  @override
  List<String> get weekdays {
    if (_weekdays is EqualUnmodifiableListView) return _weekdays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weekdays);
  }

// ["MON","WED","FRI"]
  @override
  final String time;
  @override
  final String timezone;

  @override
  String toString() {
    return 'RecurrenceRule.weekly(weekdays: $weekdays, time: $time, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeeklyRuleImpl &&
            const DeepCollectionEquality().equals(other._weekdays, _weekdays) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_weekdays), time, timezone);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeeklyRuleImplCopyWith<_$WeeklyRuleImpl> get copyWith =>
      __$$WeeklyRuleImplCopyWithImpl<_$WeeklyRuleImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) {
    return weekly(weekdays, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) {
    return weekly?.call(weekdays, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) {
    if (weekly != null) {
      return weekly(weekdays, time, timezone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) {
    return weekly(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) {
    return weekly?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) {
    if (weekly != null) {
      return weekly(this);
    }
    return orElse();
  }
}

abstract class WeeklyRule implements RecurrenceRule {
  const factory WeeklyRule(
      {required final List<String> weekdays,
      required final String time,
      required final String timezone}) = _$WeeklyRuleImpl;

  List<String> get weekdays; // ["MON","WED","FRI"]
  String get time;
  @override
  String get timezone;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeeklyRuleImplCopyWith<_$WeeklyRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MonthlyFixedRuleImplCopyWith<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  factory _$$MonthlyFixedRuleImplCopyWith(_$MonthlyFixedRuleImpl value,
          $Res Function(_$MonthlyFixedRuleImpl) then) =
      __$$MonthlyFixedRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int day, String time, String timezone});
}

/// @nodoc
class __$$MonthlyFixedRuleImplCopyWithImpl<$Res>
    extends _$RecurrenceRuleCopyWithImpl<$Res, _$MonthlyFixedRuleImpl>
    implements _$$MonthlyFixedRuleImplCopyWith<$Res> {
  __$$MonthlyFixedRuleImplCopyWithImpl(_$MonthlyFixedRuleImpl _value,
      $Res Function(_$MonthlyFixedRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? day = null,
    Object? time = null,
    Object? timezone = null,
  }) {
    return _then(_$MonthlyFixedRuleImpl(
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as int,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MonthlyFixedRuleImpl implements MonthlyFixedRule {
  const _$MonthlyFixedRuleImpl(
      {required this.day, required this.time, required this.timezone});

  @override
  final int day;
// 1-31
  @override
  final String time;
  @override
  final String timezone;

  @override
  String toString() {
    return 'RecurrenceRule.monthlyFixed(day: $day, time: $time, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlyFixedRuleImpl &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @override
  int get hashCode => Object.hash(runtimeType, day, time, timezone);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlyFixedRuleImplCopyWith<_$MonthlyFixedRuleImpl> get copyWith =>
      __$$MonthlyFixedRuleImplCopyWithImpl<_$MonthlyFixedRuleImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) {
    return monthlyFixed(day, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) {
    return monthlyFixed?.call(day, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) {
    if (monthlyFixed != null) {
      return monthlyFixed(day, time, timezone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) {
    return monthlyFixed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) {
    return monthlyFixed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) {
    if (monthlyFixed != null) {
      return monthlyFixed(this);
    }
    return orElse();
  }
}

abstract class MonthlyFixedRule implements RecurrenceRule {
  const factory MonthlyFixedRule(
      {required final int day,
      required final String time,
      required final String timezone}) = _$MonthlyFixedRuleImpl;

  int get day; // 1-31
  String get time;
  @override
  String get timezone;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlyFixedRuleImplCopyWith<_$MonthlyFixedRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MonthlyNthRuleImplCopyWith<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  factory _$$MonthlyNthRuleImplCopyWith(_$MonthlyNthRuleImpl value,
          $Res Function(_$MonthlyNthRuleImpl) then) =
      __$$MonthlyNthRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int weekOfMonth, String weekday, String time, String timezone});
}

/// @nodoc
class __$$MonthlyNthRuleImplCopyWithImpl<$Res>
    extends _$RecurrenceRuleCopyWithImpl<$Res, _$MonthlyNthRuleImpl>
    implements _$$MonthlyNthRuleImplCopyWith<$Res> {
  __$$MonthlyNthRuleImplCopyWithImpl(
      _$MonthlyNthRuleImpl _value, $Res Function(_$MonthlyNthRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekOfMonth = null,
    Object? weekday = null,
    Object? time = null,
    Object? timezone = null,
  }) {
    return _then(_$MonthlyNthRuleImpl(
      weekOfMonth: null == weekOfMonth
          ? _value.weekOfMonth
          : weekOfMonth // ignore: cast_nullable_to_non_nullable
              as int,
      weekday: null == weekday
          ? _value.weekday
          : weekday // ignore: cast_nullable_to_non_nullable
              as String,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MonthlyNthRuleImpl implements MonthlyNthRule {
  const _$MonthlyNthRuleImpl(
      {required this.weekOfMonth,
      required this.weekday,
      required this.time,
      required this.timezone});

  @override
  final int weekOfMonth;
// 1-4
  @override
  final String weekday;
// "MON"-"SUN"
  @override
  final String time;
  @override
  final String timezone;

  @override
  String toString() {
    return 'RecurrenceRule.monthlyNth(weekOfMonth: $weekOfMonth, weekday: $weekday, time: $time, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonthlyNthRuleImpl &&
            (identical(other.weekOfMonth, weekOfMonth) ||
                other.weekOfMonth == weekOfMonth) &&
            (identical(other.weekday, weekday) || other.weekday == weekday) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, weekOfMonth, weekday, time, timezone);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonthlyNthRuleImplCopyWith<_$MonthlyNthRuleImpl> get copyWith =>
      __$$MonthlyNthRuleImplCopyWithImpl<_$MonthlyNthRuleImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) {
    return monthlyNth(weekOfMonth, weekday, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) {
    return monthlyNth?.call(weekOfMonth, weekday, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) {
    if (monthlyNth != null) {
      return monthlyNth(weekOfMonth, weekday, time, timezone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) {
    return monthlyNth(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) {
    return monthlyNth?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) {
    if (monthlyNth != null) {
      return monthlyNth(this);
    }
    return orElse();
  }
}

abstract class MonthlyNthRule implements RecurrenceRule {
  const factory MonthlyNthRule(
      {required final int weekOfMonth,
      required final String weekday,
      required final String time,
      required final String timezone}) = _$MonthlyNthRuleImpl;

  int get weekOfMonth; // 1-4
  String get weekday; // "MON"-"SUN"
  String get time;
  @override
  String get timezone;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonthlyNthRuleImplCopyWith<_$MonthlyNthRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$YearlyFixedRuleImplCopyWith<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  factory _$$YearlyFixedRuleImplCopyWith(_$YearlyFixedRuleImpl value,
          $Res Function(_$YearlyFixedRuleImpl) then) =
      __$$YearlyFixedRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int month, int day, String time, String timezone});
}

/// @nodoc
class __$$YearlyFixedRuleImplCopyWithImpl<$Res>
    extends _$RecurrenceRuleCopyWithImpl<$Res, _$YearlyFixedRuleImpl>
    implements _$$YearlyFixedRuleImplCopyWith<$Res> {
  __$$YearlyFixedRuleImplCopyWithImpl(
      _$YearlyFixedRuleImpl _value, $Res Function(_$YearlyFixedRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? day = null,
    Object? time = null,
    Object? timezone = null,
  }) {
    return _then(_$YearlyFixedRuleImpl(
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as int,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$YearlyFixedRuleImpl implements YearlyFixedRule {
  const _$YearlyFixedRuleImpl(
      {required this.month,
      required this.day,
      required this.time,
      required this.timezone});

  @override
  final int month;
// 1-12
  @override
  final int day;
  @override
  final String time;
  @override
  final String timezone;

  @override
  String toString() {
    return 'RecurrenceRule.yearlyFixed(month: $month, day: $day, time: $time, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$YearlyFixedRuleImpl &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @override
  int get hashCode => Object.hash(runtimeType, month, day, time, timezone);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$YearlyFixedRuleImplCopyWith<_$YearlyFixedRuleImpl> get copyWith =>
      __$$YearlyFixedRuleImplCopyWithImpl<_$YearlyFixedRuleImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) {
    return yearlyFixed(month, day, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) {
    return yearlyFixed?.call(month, day, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) {
    if (yearlyFixed != null) {
      return yearlyFixed(month, day, time, timezone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) {
    return yearlyFixed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) {
    return yearlyFixed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) {
    if (yearlyFixed != null) {
      return yearlyFixed(this);
    }
    return orElse();
  }
}

abstract class YearlyFixedRule implements RecurrenceRule {
  const factory YearlyFixedRule(
      {required final int month,
      required final int day,
      required final String time,
      required final String timezone}) = _$YearlyFixedRuleImpl;

  int get month; // 1-12
  int get day;
  String get time;
  @override
  String get timezone;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$YearlyFixedRuleImplCopyWith<_$YearlyFixedRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$YearlyNthRuleImplCopyWith<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  factory _$$YearlyNthRuleImplCopyWith(
          _$YearlyNthRuleImpl value, $Res Function(_$YearlyNthRuleImpl) then) =
      __$$YearlyNthRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int month,
      int weekOfMonth,
      String weekday,
      String time,
      String timezone});
}

/// @nodoc
class __$$YearlyNthRuleImplCopyWithImpl<$Res>
    extends _$RecurrenceRuleCopyWithImpl<$Res, _$YearlyNthRuleImpl>
    implements _$$YearlyNthRuleImplCopyWith<$Res> {
  __$$YearlyNthRuleImplCopyWithImpl(
      _$YearlyNthRuleImpl _value, $Res Function(_$YearlyNthRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? month = null,
    Object? weekOfMonth = null,
    Object? weekday = null,
    Object? time = null,
    Object? timezone = null,
  }) {
    return _then(_$YearlyNthRuleImpl(
      month: null == month
          ? _value.month
          : month // ignore: cast_nullable_to_non_nullable
              as int,
      weekOfMonth: null == weekOfMonth
          ? _value.weekOfMonth
          : weekOfMonth // ignore: cast_nullable_to_non_nullable
              as int,
      weekday: null == weekday
          ? _value.weekday
          : weekday // ignore: cast_nullable_to_non_nullable
              as String,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as String,
      timezone: null == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$YearlyNthRuleImpl implements YearlyNthRule {
  const _$YearlyNthRuleImpl(
      {required this.month,
      required this.weekOfMonth,
      required this.weekday,
      required this.time,
      required this.timezone});

  @override
  final int month;
  @override
  final int weekOfMonth;
  @override
  final String weekday;
  @override
  final String time;
  @override
  final String timezone;

  @override
  String toString() {
    return 'RecurrenceRule.yearlyNth(month: $month, weekOfMonth: $weekOfMonth, weekday: $weekday, time: $time, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$YearlyNthRuleImpl &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.weekOfMonth, weekOfMonth) ||
                other.weekOfMonth == weekOfMonth) &&
            (identical(other.weekday, weekday) || other.weekday == weekday) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, month, weekOfMonth, weekday, time, timezone);

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$YearlyNthRuleImplCopyWith<_$YearlyNthRuleImpl> get copyWith =>
      __$$YearlyNthRuleImplCopyWithImpl<_$YearlyNthRuleImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String date, String time, String timezone)
        oneTime,
    required TResult Function(
            int every, String startTime, String? endTime, String timezone)
        hourly,
    required TResult Function(int every, String time, String timezone) daily,
    required TResult Function(
            List<String> weekdays, String time, String timezone)
        weekly,
    required TResult Function(int day, String time, String timezone)
        monthlyFixed,
    required TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)
        monthlyNth,
    required TResult Function(int month, int day, String time, String timezone)
        yearlyFixed,
    required TResult Function(int month, int weekOfMonth, String weekday,
            String time, String timezone)
        yearlyNth,
  }) {
    return yearlyNth(month, weekOfMonth, weekday, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String date, String time, String timezone)? oneTime,
    TResult? Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult? Function(int every, String time, String timezone)? daily,
    TResult? Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult? Function(int day, String time, String timezone)? monthlyFixed,
    TResult? Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult? Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult? Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
  }) {
    return yearlyNth?.call(month, weekOfMonth, weekday, time, timezone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String date, String time, String timezone)? oneTime,
    TResult Function(
            int every, String startTime, String? endTime, String timezone)?
        hourly,
    TResult Function(int every, String time, String timezone)? daily,
    TResult Function(List<String> weekdays, String time, String timezone)?
        weekly,
    TResult Function(int day, String time, String timezone)? monthlyFixed,
    TResult Function(
            int weekOfMonth, String weekday, String time, String timezone)?
        monthlyNth,
    TResult Function(int month, int day, String time, String timezone)?
        yearlyFixed,
    TResult Function(int month, int weekOfMonth, String weekday, String time,
            String timezone)?
        yearlyNth,
    required TResult orElse(),
  }) {
    if (yearlyNth != null) {
      return yearlyNth(month, weekOfMonth, weekday, time, timezone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OneTimeRule value) oneTime,
    required TResult Function(HourlyRule value) hourly,
    required TResult Function(DailyRule value) daily,
    required TResult Function(WeeklyRule value) weekly,
    required TResult Function(MonthlyFixedRule value) monthlyFixed,
    required TResult Function(MonthlyNthRule value) monthlyNth,
    required TResult Function(YearlyFixedRule value) yearlyFixed,
    required TResult Function(YearlyNthRule value) yearlyNth,
  }) {
    return yearlyNth(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OneTimeRule value)? oneTime,
    TResult? Function(HourlyRule value)? hourly,
    TResult? Function(DailyRule value)? daily,
    TResult? Function(WeeklyRule value)? weekly,
    TResult? Function(MonthlyFixedRule value)? monthlyFixed,
    TResult? Function(MonthlyNthRule value)? monthlyNth,
    TResult? Function(YearlyFixedRule value)? yearlyFixed,
    TResult? Function(YearlyNthRule value)? yearlyNth,
  }) {
    return yearlyNth?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OneTimeRule value)? oneTime,
    TResult Function(HourlyRule value)? hourly,
    TResult Function(DailyRule value)? daily,
    TResult Function(WeeklyRule value)? weekly,
    TResult Function(MonthlyFixedRule value)? monthlyFixed,
    TResult Function(MonthlyNthRule value)? monthlyNth,
    TResult Function(YearlyFixedRule value)? yearlyFixed,
    TResult Function(YearlyNthRule value)? yearlyNth,
    required TResult orElse(),
  }) {
    if (yearlyNth != null) {
      return yearlyNth(this);
    }
    return orElse();
  }
}

abstract class YearlyNthRule implements RecurrenceRule {
  const factory YearlyNthRule(
      {required final int month,
      required final int weekOfMonth,
      required final String weekday,
      required final String time,
      required final String timezone}) = _$YearlyNthRuleImpl;

  int get month;
  int get weekOfMonth;
  String get weekday;
  String get time;
  @override
  String get timezone;

  /// Create a copy of RecurrenceRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$YearlyNthRuleImplCopyWith<_$YearlyNthRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
