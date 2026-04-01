import 'package:firebase_analytics/firebase_analytics.dart';
import '../../core/utils/logger.dart';

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

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

  Future<void> setCurrentScreen(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e, st) {
      AppLogger.error('Analytics setCurrentScreen failed', e, st);
    }
  }
}
