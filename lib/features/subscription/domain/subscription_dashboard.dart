import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../homes/domain/home.dart';
import '../../tasks/domain/home_dashboard.dart';

part 'subscription_dashboard.freezed.dart';

/// Snapshot denormalizado que la pantalla Suscripción consume en stream. Se
/// nutre del documento `homes/{homeId}` (fuente de verdad de los campos
/// premium) y de `homes/{homeId}/views/dashboard` (sólo para `planCounters`).
@freezed
class SubscriptionDashboard with _$SubscriptionDashboard {
  const factory SubscriptionDashboard({
    required String homeId,
    required HomePremiumStatus status,
    required String? plan,
    required DateTime? endsAt,
    required DateTime? restoreUntil,
    required bool autoRenew,
    required String? currentPayerUid,
    required PlanCounters planCounters,
  }) = _SubscriptionDashboard;

  const SubscriptionDashboard._();

  /// Número de días completos que quedan hasta `endsAt`. Devuelve `0` si ya ha
  /// vencido o si `endsAt` es nulo. Clamp a 0..N para no mostrar negativos.
  int get daysLeft {
    if (endsAt == null) return 0;
    final diff = endsAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Número de días que quedan para restaurar Premium tras downgrade.
  int get restoreDaysLeft {
    if (restoreUntil == null) return 0;
    final diff = restoreUntil!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isPremium =>
      status == HomePremiumStatus.active ||
      status == HomePremiumStatus.cancelledPendingEnd ||
      status == HomePremiumStatus.rescue;

  factory SubscriptionDashboard.empty(String homeId) => SubscriptionDashboard(
        homeId: homeId,
        status: HomePremiumStatus.free,
        plan: null,
        endsAt: null,
        restoreUntil: null,
        autoRenew: false,
        currentPayerUid: null,
        planCounters: PlanCounters.empty(),
      );

  /// Construye el snapshot combinando el documento del hogar y (opcionalmente)
  /// los `planCounters` ya cargados desde la vista dashboard. Si los mapas
  /// vienen vacíos se devuelven valores seguros.
  factory SubscriptionDashboard.fromMaps({
    required String homeId,
    required Map<String, dynamic> home,
    Map<String, dynamic>? dashboard,
  }) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    final statusStr = home['premiumStatus'] as String?;
    final status = statusStr == null
        ? HomePremiumStatus.free
        : HomePremiumStatus.fromString(statusStr);

    final counters = dashboard != null && dashboard['planCounters'] is Map
        ? PlanCounters.fromMap(
            (dashboard['planCounters'] as Map).cast<String, dynamic>())
        : PlanCounters.empty();

    return SubscriptionDashboard(
      homeId: homeId,
      status: status,
      plan: home['premiumPlan'] as String?,
      endsAt: toDate(home['premiumEndsAt']),
      restoreUntil: toDate(home['restoreUntil']),
      autoRenew: home['autoRenewEnabled'] as bool? ?? false,
      currentPayerUid: home['currentPayerUid'] as String?,
      planCounters: counters,
    );
  }
}
