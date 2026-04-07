// lib/features/history/domain/history_filter.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_filter.freezed.dart';

@freezed
class HistoryFilter with _$HistoryFilter {
  const factory HistoryFilter({
    String? memberUid,
    String? taskId,
    String? eventType,
  }) = _HistoryFilter;
}
