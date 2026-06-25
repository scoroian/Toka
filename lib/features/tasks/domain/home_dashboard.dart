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
    // Calculado por el backend en la zona horaria del hogar (igual que
    // `counters.tasksDueToday`). El tile lo usa para decidir la etiqueta "Hoy",
    // de modo que el contador y las etiquetas siempre cuadran. Para snapshots
    // antiguos sin el campo, cae a false.
    @Default(false) bool isDueToday,
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
        nextDueAt: (map['nextDueAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
        isOverdue: map['isOverdue'] as bool? ?? false,
        isDueToday: map['isDueToday'] as bool? ?? false,
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
        completedAt: (map['completedAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
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

/// Packs de miembro vigentes del hogar (eje aditivo sobre el tier Grupo),
/// proyectados por el backend en `premiumFlags.memberPacks`. El cliente solo los
/// LEE; el tope efectivo ya viene resuelto en `premiumFlags.maxMembers`. Modelo
/// de datos puro (sin dependencia del catálogo de SKUs).
@freezed
class MemberPacks with _$MemberPacks {
  const MemberPacks._();

  const factory MemberPacks({
    @Default(false) bool plus5,
    @Default(false) bool plus10,
  }) = _MemberPacks;

  factory MemberPacks.fromMap(Map<String, dynamic> map) => MemberPacks(
        plus5: map['plus5'] as bool? ?? false,
        plus10: map['plus10'] as bool? ?? false,
      );

  /// Ningún pack activo.
  static const empty = MemberPacks();

  /// Número de packs activos (0..2).
  int get activeCount => (plus5 ? 1 : 0) + (plus10 ? 1 : 0);

  /// True cuando ambos packs están activos (hogar en el tope absoluto de 25).
  bool get isMaxed => plus5 && plus10;
}

@freezed
class PremiumFlags with _$PremiumFlags {
  const factory PremiumFlags({
    required bool isPremium,
    required bool showAds,
    required bool canUseSmartDistribution,
    required bool canUseVacations,
    required bool canUseReviews,
    // Tier efectivo + tope de miembros denormalizados por el backend
    // (`functions/src/entitlement`). El cliente los LEE, nunca los recomputa.
    // `tier`: 'pareja' | 'familia' | 'grupo' | 'free' | null (flag de tiers OFF).
    // `maxMembers`: 2 | 5 | 10 | 3 (o hasta 25 con packs). null en dashboards
    // antiguos.
    String? tier,
    int? maxMembers,
    // Packs de miembro activos (`{plus5, plus10}`). null en dashboards legacy
    // o cuando el backend no proyecta packs (flag de packs OFF).
    MemberPacks? memberPacks,
  }) = _PremiumFlags;

  factory PremiumFlags.fromMap(Map<String, dynamic> map) => PremiumFlags(
        isPremium: map['isPremium'] as bool? ?? false,
        showAds: map['showAds'] as bool? ?? true,
        canUseSmartDistribution:
            map['canUseSmartDistribution'] as bool? ?? false,
        canUseVacations: map['canUseVacations'] as bool? ?? false,
        canUseReviews: map['canUseReviews'] as bool? ?? false,
        tier: map['tier'] as String?,
        maxMembers: map['maxMembers'] as int?,
        memberPacks: map['memberPacks'] is Map
            ? MemberPacks.fromMap(
                (map['memberPacks'] as Map).cast<String, dynamic>())
            : null,
      );

  factory PremiumFlags.free() => const PremiumFlags(
        isPremium: false,
        showAds: true,
        canUseSmartDistribution: false,
        canUseVacations: false,
        canUseReviews: false,
        tier: 'free',
        maxMembers: 3,
      );
}

@freezed
class AdFlags with _$AdFlags {
  const AdFlags._();

  const factory AdFlags({
    required bool showBanner,
    // `bannerUnit` se mantiene por compatibilidad con clientes/documentos
    // viejos (= unit de Android). Los nuevos clientes usan los campos por
    // plataforma.
    required String bannerUnit,
    required String bannerUnitAndroid,
    required String bannerUnitIos,
  }) = _AdFlags;

  factory AdFlags.fromMap(Map<String, dynamic> map) {
    final legacy = map['bannerUnit'] as String? ?? '';
    return AdFlags(
      showBanner: map['showBanner'] as bool? ?? false,
      bannerUnit: legacy,
      // Fallback al campo legacy si el dashboard aún no trae los por-plataforma.
      bannerUnitAndroid: map['bannerUnitAndroid'] as String? ?? legacy,
      bannerUnitIos: map['bannerUnitIos'] as String? ?? legacy,
    );
  }

  factory AdFlags.empty() => const AdFlags(
        showBanner: false,
        bannerUnit: '',
        bannerUnitAndroid: '',
        bannerUnitIos: '',
      );

  /// Unit ID del banner para la plataforma actual. iOS → `bannerUnitIos`,
  /// cualquier otra (Android) → `bannerUnitAndroid`.
  String bannerUnitFor({required bool isIos}) =>
      isIos ? bannerUnitIos : bannerUnitAndroid;
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

/// Contadores del plan del hogar (independientes de la pantalla Hoy). Se
/// escriben tanto en Free como en Premium para que la UI pueda:
/// - En Free: mostrar "X / Y" y desactivar acciones al alcanzar el tope.
/// - En Premium: mostrar información de uso en Ajustes del hogar.
@freezed
class PlanCounters with _$PlanCounters {
  const factory PlanCounters({
    required int activeMembers,
    required int activeTasks,
    required int automaticRecurringTasks,
    required int totalAdmins,
  }) = _PlanCounters;

  factory PlanCounters.fromMap(Map<String, dynamic> map) => PlanCounters(
        activeMembers: (map['activeMembers'] as int?) ?? 0,
        activeTasks: (map['activeTasks'] as int?) ?? 0,
        automaticRecurringTasks: (map['automaticRecurringTasks'] as int?) ?? 0,
        totalAdmins: (map['totalAdmins'] as int?) ?? 0,
      );

  factory PlanCounters.empty() => const PlanCounters(
        activeMembers: 0,
        activeTasks: 0,
        automaticRecurringTasks: 0,
        totalAdmins: 0,
      );
}

@freezed
class HomeDashboard with _$HomeDashboard {
  const factory HomeDashboard({
    required List<TaskPreview> activeTasksPreview,
    required List<DoneTaskPreview> doneTasksPreview,
    required DashboardCounters counters,
    required PlanCounters planCounters,
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
      planCounters: data.containsKey('planCounters')
          ? PlanCounters.fromMap(asStringMap(data['planCounters']))
          : PlanCounters.empty(),
      memberPreview: memberList,
      premiumFlags: PremiumFlags.fromMap(asStringMap(data['premiumFlags'])),
      adFlags: AdFlags.fromMap(asStringMap(data['adFlags'])),
      rescueFlags: RescueFlags.fromMap(asStringMap(data['rescueFlags'])),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
