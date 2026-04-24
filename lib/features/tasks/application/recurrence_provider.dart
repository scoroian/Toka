import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/recurrence_calculator.dart';
import '../domain/recurrence_rule.dart';

part 'recurrence_provider.freezed.dart';
part 'recurrence_provider.g.dart';

@riverpod
List<DateTime> upcomingOccurrences(
    UpcomingOccurrencesRef ref, RecurrenceRule? rule) {
  if (rule == null) return [];
  try {
    return RecurrenceCalculator.nextNOccurrences(rule, DateTime.now(), 5);
  } catch (_) {
    return [];
  }
}

/// Estado interno del formulario de recurrencia. Expone los campos que la UI
/// necesita para renderizar cualquiera de las 8 variantes de [RecurrenceRule].
///
/// [hydrationVersion] se incrementa en cada llamada a
/// [RecurrenceNotifier.hydrateFrom] y permite al widget detectar hidrataciones
/// externas (edición de tarea) sin confundirlas con actualizaciones internas
/// del usuario.
@freezed
class RecurrenceFormState with _$RecurrenceFormState {
  const factory RecurrenceFormState({
    @Default('daily') String selectedType,
    @Default(1) int every,
    @Default('09:00') String time,
    @Default('08:00') String startTime,
    String? endTime,
    @Default(['MON']) List<String> weekdays,
    @Default(1) int dayOfMonth,
    @Default(1) int weekOfMonth,
    @Default('MON') String weekday,
    @Default(1) int month,
    @Default('Europe/Madrid') String timezone,
    @Default('') String oneTimeDate,
    @Default('') String oneTimeTime,
    @Default(0) int hydrationVersion,
  }) = _RecurrenceFormState;
}

@riverpod
class RecurrenceNotifier extends _$RecurrenceNotifier {
  @override
  RecurrenceFormState build() => const RecurrenceFormState();

  /// Mapea una [RecurrenceRule] concreta al estado interno del formulario,
  /// incluyendo las 8 variantes (oneTime, hourly, daily, weekly, monthlyFixed,
  /// monthlyNth, yearlyFixed, yearlyNth). Incrementa [hydrationVersion] para
  /// que el widget pueda reaccionar a la hidratación externa.
  void hydrateFrom(RecurrenceRule? rule) {
    final nextVersion = state.hydrationVersion + 1;
    if (rule == null) {
      state = RecurrenceFormState(hydrationVersion: nextVersion);
      return;
    }
    state = switch (rule) {
      OneTimeRule r => state.copyWith(
          selectedType: 'oneTime',
          oneTimeDate: r.date,
          oneTimeTime: r.time,
          timezone: r.timezone,
          hydrationVersion: nextVersion,
        ),
      HourlyRule r => state.copyWith(
          selectedType: 'hourly',
          every: r.every,
          startTime: r.startTime,
          endTime: r.endTime,
          timezone: r.timezone,
          hydrationVersion: nextVersion,
        ),
      DailyRule r => state.copyWith(
          selectedType: 'daily',
          every: r.every,
          time: r.time,
          timezone: r.timezone,
          hydrationVersion: nextVersion,
        ),
      WeeklyRule r => state.copyWith(
          selectedType: 'weekly',
          weekdays: List<String>.from(r.weekdays),
          time: r.time,
          timezone: r.timezone,
          hydrationVersion: nextVersion,
        ),
      MonthlyFixedRule r => state.copyWith(
          selectedType: 'monthlyFixed',
          dayOfMonth: r.day,
          time: r.time,
          timezone: r.timezone,
          hydrationVersion: nextVersion,
        ),
      MonthlyNthRule r => state.copyWith(
          selectedType: 'monthlyNth',
          weekOfMonth: r.weekOfMonth,
          weekday: r.weekday,
          time: r.time,
          timezone: r.timezone,
          hydrationVersion: nextVersion,
        ),
      YearlyFixedRule r => state.copyWith(
          selectedType: 'yearlyFixed',
          month: r.month,
          dayOfMonth: r.day,
          time: r.time,
          timezone: r.timezone,
          hydrationVersion: nextVersion,
        ),
      YearlyNthRule r => state.copyWith(
          selectedType: 'yearlyNth',
          month: r.month,
          weekOfMonth: r.weekOfMonth,
          weekday: r.weekday,
          time: r.time,
          timezone: r.timezone,
          hydrationVersion: nextVersion,
        ),
    };
  }
}
