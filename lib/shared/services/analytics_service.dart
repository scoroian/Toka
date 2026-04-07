import 'package:firebase_analytics/firebase_analytics.dart';
import '../../core/utils/logger.dart';

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  // ─── Métodos base ─────────────────────────────────────────────────────────

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e, st) {
      AppLogger.error('Analytics logEvent failed: $name', e, st);
    }
  }

  Future<void> setUserId(String? uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } catch (e, st) {
      AppLogger.error('Analytics setUserId failed', e, st);
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e, st) {
      AppLogger.error('Analytics logScreenView failed', e, st);
    }
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<void> logSignupCompleted({required String method}) =>
      logEvent('auth_signup_completed', parameters: {'method': method});

  // ─── Homes ────────────────────────────────────────────────────────────────

  Future<void> logHomeCreated({required String homeId}) =>
      logEvent('home_created', parameters: {'home_id': homeId});

  Future<void> logHomeJoined({required String homeId}) =>
      logEvent('home_joined', parameters: {'home_id': homeId});

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Future<void> logTaskCreated({required String homeId, required String taskId}) =>
      logEvent('task_created', parameters: {
        'home_id': homeId,
        'task_id': taskId,
      });

  Future<void> logTaskCompleted({required String homeId, required String taskId}) =>
      logEvent('task_completed', parameters: {
        'home_id': homeId,
        'task_id': taskId,
      });

  Future<void> logTaskPassed({required String homeId, required String taskId}) =>
      logEvent('task_passed', parameters: {
        'home_id': homeId,
        'task_id': taskId,
      });

  // ─── Reviews ──────────────────────────────────────────────────────────────

  Future<void> logTaskReviewSubmitted({
    required String homeId,
    required String taskEventId,
    required int score,
  }) =>
      logEvent('task_review_submitted', parameters: {
        'home_id': homeId,
        'task_event_id': taskEventId,
        'score': score,
      });

  // ─── Premium ──────────────────────────────────────────────────────────────

  Future<void> logPremiumPurchaseStarted({required String plan}) =>
      logEvent('premium_purchase_started', parameters: {'plan': plan});

  Future<void> logPremiumPurchaseSuccess({required String plan}) =>
      logEvent('premium_purchase_success', parameters: {'plan': plan});

  Future<void> logPremiumRescueOpened({required String homeId}) =>
      logEvent('premium_rescue_opened', parameters: {'home_id': homeId});

  Future<void> logPremiumDowngradeApplied({required String homeId}) =>
      logEvent('premium_downgrade_applied', parameters: {'home_id': homeId});

  // ─── Perfil / Radar ───────────────────────────────────────────────────────

  Future<void> logRadarOpened({required String homeId}) =>
      logEvent('radar_opened', parameters: {'home_id': homeId});

  Future<void> logProfileViewed({required String viewedUid}) =>
      logEvent('profile_viewed', parameters: {'viewed_uid': viewedUid});
}
