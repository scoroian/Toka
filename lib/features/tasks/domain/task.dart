import 'package:freezed_annotation/freezed_annotation.dart';

import 'recurrence_rule.dart';
import 'task_status.dart';

part 'task.freezed.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String homeId,
    required String title,
    String? description,
    required String visualKind, // "emoji" | "icon"
    required String visualValue, // "🏠" o nombre de icono Material
    required TaskStatus status,
    required RecurrenceRule recurrenceRule,
    required String assignmentMode, // "basicRotation" | "smartDistribution"
    required List<String> assignmentOrder, // UIDs en orden
    String? currentAssigneeUid,
    required DateTime nextDueAt,
    required double difficultyWeight,
    required int completedCount90d,
    required String createdByUid,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;
}

@freezed
class TaskInput with _$TaskInput {
  const factory TaskInput({
    required String title,
    String? description,
    required String visualKind,
    required String visualValue,
    required RecurrenceRule recurrenceRule,
    required String assignmentMode,
    required List<String> assignmentOrder,
    @Default(1.0) double difficultyWeight,
  }) = _TaskInput;
}
