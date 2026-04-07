import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/recurrence_calculator.dart';
import '../domain/recurrence_rule.dart';

part 'recurrence_provider.g.dart';

@riverpod
List<DateTime> upcomingOccurrences(
    UpcomingOccurrencesRef ref, RecurrenceRule? rule) {
  if (rule == null) return [];
  try {
    return RecurrenceCalculator.nextNOccurrences(rule, DateTime.now(), 3);
  } catch (_) {
    return [];
  }
}
