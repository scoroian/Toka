import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_dashboard.freezed.dart';

@freezed
class TaskPreview with _$TaskPreview {
  const factory TaskPreview({
    required String taskId,
    required String title,
    required String visualKind,
    required String visualValue,
    required String recurrenceType,
    required String? currentAssigneeUid,
    required String? currentAssigneeName,
    required String? currentAssigneePhoto,
    required DateTime nextDueAt,
    required bool isOverdue,
    required String status,
  }) = _TaskPreview;

  factory TaskPreview.fromMap(Map<String, dynamic> map) => TaskPreview(
        taskId: map['taskId'] as String,
        title: map['title'] as String,
        visualKind: map['visualKind'] as String? ?? 'emoji',
        visualValue: map['visualValue'] as String? ?? '',
        recurrenceType: map['recurrenceType'] as String,
        currentAssigneeUid: map['currentAssigneeUid'] as String?,
        currentAssigneeName: map['currentAssigneeName'] as String?,
        currentAssigneePhoto: map['currentAssigneePhoto'] as String?,
        nextDueAt: (map['nextDueAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isOverdue: map['isOverdue'] as bool? ?? false,
        status: map['status'] as String? ?? 'active',
      );
}

@freezed
class DoneTaskPreview with _$DoneTaskPreview {
  const factory DoneTaskPreview({
    required String taskId,
    required String title,
    required String visualKind,
    required String visualValue,
    required String recurrenceType,
    required String completedByUid,
    required String completedByName,
    required String? completedByPhoto,
    required DateTime completedAt,
  }) = _DoneTaskPreview;

  factory DoneTaskPreview.fromMap(Map<String, dynamic> map) => DoneTaskPreview(
        taskId: map['taskId'] as String,
        title: map['title'] as String,
        visualKind: map['visualKind'] as String? ?? 'emoji',
        visualValue: map['visualValue'] as String? ?? '',
        recurrenceType: map['recurrenceType'] as String,
        completedByUid: map['completedByUid'] as String,
        completedByName: map['completedByName'] as String,
        completedByPhoto: map['completedByPhoto'] as String?,
        completedAt: (map['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

@freezed
class DashboardCounters with _$DashboardCounters {
  const factory DashboardCounters({
    required int totalActiveTasks,
    required int totalMembers,
    required int tasksDueToday,
    required int tasksDoneToday,
  }) = _DashboardCounters;

  factory DashboardCounters.fromMap(Map<String, dynamic> map) =>
      DashboardCounters(
        totalActiveTasks: (map['totalActiveTasks'] as int?) ?? 0,
        totalMembers: (map['totalMembers'] as int?) ?? 0,
        tasksDueToday: (map['tasksDueToday'] as int?) ?? 0,
        tasksDoneToday: (map['tasksDoneToday'] as int?) ?? 0,
      );

  factory DashboardCounters.empty() => const DashboardCounters(
        totalActiveTasks: 0,
        totalMembers: 0,
        tasksDueToday: 0,
        tasksDoneToday: 0,
      );
}

@freezed
class MemberPreview with _$MemberPreview {
  const factory MemberPreview({
    required String uid,
    required String name,
    required String? photoUrl,
    required String role,
    required String status,
    required int tasksDueCount,
  }) = _MemberPreview;

  factory MemberPreview.fromMap(Map<String, dynamic> map) => MemberPreview(
        uid: map['uid'] as String,
        name: map['name'] as String,
        photoUrl: map['photoUrl'] as String?,
        role: map['role'] as String? ?? 'member',
        status: map['status'] as String? ?? 'active',
        tasksDueCount: (map['tasksDueCount'] as int?) ?? 0,
      );
}

@freezed
class PremiumFlags with _$PremiumFlags {
  const factory PremiumFlags({
    required bool isPremium,
    required bool showAds,
    required bool canUseSmartDistribution,
    required bool canUseVacations,
    required bool canUseReviews,
  }) = _PremiumFlags;

  factory PremiumFlags.fromMap(Map<String, dynamic> map) => PremiumFlags(
        isPremium: map['isPremium'] as bool? ?? false,
        showAds: map['showAds'] as bool? ?? true,
        canUseSmartDistribution:
            map['canUseSmartDistribution'] as bool? ?? false,
        canUseVacations: map['canUseVacations'] as bool? ?? false,
        canUseReviews: map['canUseReviews'] as bool? ?? false,
      );

  factory PremiumFlags.free() => const PremiumFlags(
        isPremium: false,
        showAds: true,
        canUseSmartDistribution: false,
        canUseVacations: false,
        canUseReviews: false,
      );
}

@freezed
class AdFlags with _$AdFlags {
  const factory AdFlags({
    required bool showBanner,
    required String bannerUnit,
  }) = _AdFlags;

  factory AdFlags.fromMap(Map<String, dynamic> map) => AdFlags(
        showBanner: map['showBanner'] as bool? ?? false,
        bannerUnit: map['bannerUnit'] as String? ?? '',
      );

  factory AdFlags.empty() =>
      const AdFlags(showBanner: false, bannerUnit: '');
}

@freezed
class RescueFlags with _$RescueFlags {
  const factory RescueFlags({
    required bool isInRescue,
    required int? daysLeft,
  }) = _RescueFlags;

  factory RescueFlags.fromMap(Map<String, dynamic> map) => RescueFlags(
        isInRescue: map['isInRescue'] as bool? ?? false,
        daysLeft: map['daysLeft'] as int?,
      );

  factory RescueFlags.empty() =>
      const RescueFlags(isInRescue: false, daysLeft: null);
}

@freezed
class HomeDashboard with _$HomeDashboard {
  const factory HomeDashboard({
    required List<TaskPreview> activeTasksPreview,
    required List<DoneTaskPreview> doneTasksPreview,
    required DashboardCounters counters,
    required List<MemberPreview> memberPreview,
    required PremiumFlags premiumFlags,
    required AdFlags adFlags,
    required RescueFlags rescueFlags,
    required DateTime updatedAt,
  }) = _HomeDashboard;

  factory HomeDashboard.fromFirestore(Map<String, dynamic> data) {
    final activeList =
        (data['activeTasksPreview'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(TaskPreview.fromMap)
            .toList();
    final doneList =
        (data['doneTasksPreview'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(DoneTaskPreview.fromMap)
            .toList();
    final memberList =
        (data['memberPreview'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(MemberPreview.fromMap)
            .toList();

    Map<String, dynamic> asStringMap(dynamic value) =>
        (value as Map?)?.cast<String, dynamic>() ?? {};

    return HomeDashboard(
      activeTasksPreview: activeList,
      doneTasksPreview: doneList,
      counters: DashboardCounters.fromMap(asStringMap(data['counters'])),
      memberPreview: memberList,
      premiumFlags: PremiumFlags.fromMap(asStringMap(data['premiumFlags'])),
      adFlags: AdFlags.fromMap(asStringMap(data['adFlags'])),
      rescueFlags: RescueFlags.fromMap(asStringMap(data['rescueFlags'])),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
