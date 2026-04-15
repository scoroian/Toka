// lib/features/history/domain/task_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_event.freezed.dart';

class TaskVisual {
  const TaskVisual({required this.kind, required this.value});
  final String kind;
  final String value;

  factory TaskVisual.fromMap(Map<String, dynamic> map) => TaskVisual(
        kind: map['kind'] as String? ?? 'emoji',
        value: map['value'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is TaskVisual && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

@freezed
sealed class TaskEvent with _$TaskEvent {
  const factory TaskEvent.completed({
    required String id,
    required String taskId,
    required String taskTitleSnapshot,
    required TaskVisual taskVisualSnapshot,
    required String actorUid,
    required String performerUid,
    required DateTime completedAt,
    required DateTime createdAt,
  }) = CompletedEvent;

  const factory TaskEvent.passed({
    required String id,
    required String taskId,
    required String taskTitleSnapshot,
    required TaskVisual taskVisualSnapshot,
    required String actorUid,
    required String fromUid,
    required String toUid,
    String? reason,
    required bool penaltyApplied,
    required double? complianceBefore,
    required double? complianceAfter,
    required DateTime createdAt,
  }) = PassedEvent;

  const factory TaskEvent.missed({
    required String id,
    required String taskId,
    required String taskTitleSnapshot,
    required TaskVisual taskVisualSnapshot,
    required String actorUid,
    required String toUid,
    required bool penaltyApplied,
    double? complianceBefore,
    double? complianceAfter,
    required DateTime missedAt,
    required DateTime createdAt,
  }) = MissedEvent;

  static TaskEvent fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromMap(doc.id, doc.data()!);
  }

  static TaskEvent fromMap(String id, Map<String, dynamic> data) {
    final eventType = data['eventType'] as String? ?? 'completed';
    final visual = TaskVisual.fromMap(
      (data['taskVisualSnapshot'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    if (eventType == 'missed') {
      return TaskEvent.missed(
        id: id,
        taskId: data['taskId'] as String? ?? '',
        taskTitleSnapshot: data['taskTitleSnapshot'] as String? ?? '',
        taskVisualSnapshot: visual,
        actorUid: data['actorUid'] as String? ?? '',
        toUid: data['toUid'] as String? ?? '',
        penaltyApplied: data['penaltyApplied'] as bool? ?? true,
        complianceBefore: (data['complianceBefore'] as num?)?.toDouble(),
        complianceAfter: (data['complianceAfter'] as num?)?.toDouble(),
        missedAt: (data['missedAt'] as Timestamp?)?.toDate() ?? createdAt,
        createdAt: createdAt,
      );
    }

    if (eventType == 'passed') {
      return TaskEvent.passed(
        id: id,
        taskId: data['taskId'] as String? ?? '',
        taskTitleSnapshot: data['taskTitleSnapshot'] as String? ?? '',
        taskVisualSnapshot: visual,
        actorUid: data['actorUid'] as String? ?? '',
        fromUid: data['fromUid'] as String? ?? '',
        toUid: data['toUid'] as String? ?? '',
        reason: data['reason'] as String?,
        penaltyApplied: data['penaltyApplied'] as bool? ?? false,
        complianceBefore: (data['complianceBefore'] as num?)?.toDouble(),
        complianceAfter: (data['complianceAfter'] as num?)?.toDouble(),
        createdAt: createdAt,
      );
    }

    return TaskEvent.completed(
      id: id,
      taskId: data['taskId'] as String? ?? '',
      taskTitleSnapshot: data['taskTitleSnapshot'] as String? ?? '',
      taskVisualSnapshot: visual,
      actorUid: data['actorUid'] as String? ?? '',
      performerUid: data['performerUid'] as String? ?? '',
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? createdAt,
      createdAt: createdAt,
    );
  }
}
