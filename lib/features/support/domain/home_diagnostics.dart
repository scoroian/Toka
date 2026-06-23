import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_diagnostics.freezed.dart';

/// Resultado REDACTADO del diagnóstico de soporte de un hogar (Hallazgo #17).
///
/// Espejo del payload que devuelve la callable `supportDiagnoseHome`. El backend
/// ya redacta los datos privados: aquí NUNCA llegan teléfonos en claro, tokens
/// FCM ni notas de valoración — solo presencia (`hasPhone`/`hasFcmToken`). Las
/// fechas vienen como ISO-8601 (toJsonSafe en el backend) y se conservan como
/// String para mostrarlas tal cual (herramienta interna).
@freezed
class HomeDiagnostics with _$HomeDiagnostics {
  const factory HomeDiagnostics({
    required String homeId,
    required String? generatedAt,
    required String? requestedBy,
    required DiagHome? home,
    required int memberCount,
    required List<DiagMember> members,
    required List<DiagTask> upcomingTasks,
    required List<DiagEvent> recentEvents,
  }) = _HomeDiagnostics;

  factory HomeDiagnostics.fromMap(Map<String, dynamic> m) {
    final homeMap = m['home'] as Map<String, dynamic>?;
    return HomeDiagnostics(
      homeId: (m['homeId'] as String?) ?? '',
      generatedAt: m['generatedAt'] as String?,
      requestedBy: m['requestedBy'] as String?,
      home: homeMap == null ? null : DiagHome.fromMap(homeMap),
      memberCount: (m['memberCount'] as num?)?.toInt() ?? 0,
      members: _list(m['members']).map(DiagMember.fromMap).toList(),
      upcomingTasks: _list(m['upcomingTasks']).map(DiagTask.fromMap).toList(),
      recentEvents: _list(m['recentEvents']).map(DiagEvent.fromMap).toList(),
    );
  }
}

@freezed
class DiagHome with _$DiagHome {
  const factory DiagHome({
    required String? name,
    required String premiumStatus,
    required String? premiumPlan,
    required String? premiumEndsAt,
    required String? restoreUntil,
    required String? ownerUid,
    required String? currentPayerUid,
    required String? timezone,
    required bool? autoRenewEnabled,
  }) = _DiagHome;

  factory DiagHome.fromMap(Map<String, dynamic> m) => DiagHome(
        name: m['name'] as String?,
        premiumStatus: (m['premiumStatus'] as String?) ?? 'free',
        premiumPlan: m['premiumPlan'] as String?,
        premiumEndsAt: m['premiumEndsAt'] as String?,
        restoreUntil: m['restoreUntil'] as String?,
        ownerUid: m['ownerUid'] as String?,
        currentPayerUid: m['currentPayerUid'] as String?,
        timezone: m['timezone'] as String?,
        autoRenewEnabled: m['autoRenewEnabled'] as bool?,
      );
}

@freezed
class DiagMember with _$DiagMember {
  const factory DiagMember({
    required String uid,
    required String? nickname,
    required String? role,
    required String? status,
    required String? billingState,
    required int tasksCompleted,
    required double averageScore,
    required int ratingsCount,
    required int currentStreak,
    required String? phoneVisibility,
    required bool hasPhone,
    required bool hasFcmToken,
  }) = _DiagMember;

  factory DiagMember.fromMap(Map<String, dynamic> m) => DiagMember(
        uid: (m['uid'] as String?) ?? '',
        nickname: m['nickname'] as String?,
        role: m['role'] as String?,
        status: m['status'] as String?,
        billingState: m['billingState'] as String?,
        tasksCompleted: (m['tasksCompleted'] as num?)?.toInt() ?? 0,
        averageScore: (m['averageScore'] as num?)?.toDouble() ?? 0,
        ratingsCount: (m['ratingsCount'] as num?)?.toInt() ?? 0,
        currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
        phoneVisibility: m['phoneVisibility'] as String?,
        hasPhone: m['hasPhone'] == true,
        hasFcmToken: m['hasFcmToken'] == true,
      );
}

@freezed
class DiagTask with _$DiagTask {
  const factory DiagTask({
    required String taskId,
    required String? title,
    required String? status,
    required String? nextDueAt,
    required String? currentAssigneeUid,
    required String? recurrenceType,
  }) = _DiagTask;

  factory DiagTask.fromMap(Map<String, dynamic> m) => DiagTask(
        taskId: (m['taskId'] as String?) ?? '',
        title: m['title'] as String?,
        status: m['status'] as String?,
        nextDueAt: m['nextDueAt'] as String?,
        currentAssigneeUid: m['currentAssigneeUid'] as String?,
        recurrenceType: m['recurrenceType'] as String?,
      );
}

@freezed
class DiagEvent with _$DiagEvent {
  const factory DiagEvent({
    required String eventId,
    required String? eventType,
    required String? taskId,
    required String? performerUid,
    required String? createdAt,
  }) = _DiagEvent;

  factory DiagEvent.fromMap(Map<String, dynamic> m) => DiagEvent(
        eventId: (m['eventId'] as String?) ?? '',
        eventType: m['eventType'] as String?,
        taskId: m['taskId'] as String?,
        performerUid: m['performerUid'] as String?,
        createdAt: m['createdAt'] as String?,
      );
}

/// Normaliza una lista dinámica del callable a `List<Map<String,dynamic>>`.
List<Map<String, dynamic>> _list(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
      .toList();
}
