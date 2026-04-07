import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurrence_rule.freezed.dart';

@freezed
sealed class RecurrenceRule with _$RecurrenceRule {
  const factory RecurrenceRule.hourly({
    required int every,
    required String startTime, // "HH:mm"
    String? endTime, // "HH:mm" opcional
    required String timezone,
  }) = HourlyRule;

  const factory RecurrenceRule.daily({
    required int every,
    required String time, // "HH:mm"
    required String timezone,
  }) = DailyRule;

  const factory RecurrenceRule.weekly({
    required List<String> weekdays, // ["MON","WED","FRI"]
    required String time,
    required String timezone,
  }) = WeeklyRule;

  const factory RecurrenceRule.monthlyFixed({
    required int day, // 1-31
    required String time,
    required String timezone,
  }) = MonthlyFixedRule;

  const factory RecurrenceRule.monthlyNth({
    required int weekOfMonth, // 1-4
    required String weekday, // "MON"-"SUN"
    required String time,
    required String timezone,
  }) = MonthlyNthRule;

  const factory RecurrenceRule.yearlyFixed({
    required int month, // 1-12
    required int day,
    required String time,
    required String timezone,
  }) = YearlyFixedRule;

  const factory RecurrenceRule.yearlyNth({
    required int month,
    required int weekOfMonth,
    required String weekday,
    required String time,
    required String timezone,
  }) = YearlyNthRule;
}
