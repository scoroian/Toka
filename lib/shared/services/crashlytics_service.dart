// lib/shared/services/crashlytics_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/logger.dart';

class CrashlyticsService {
  CrashlyticsService(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  Future<void> init() async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = (errorDetails) {
        _crashlytics.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e, st) {
      AppLogger.error('Crashlytics init failed', e, st);
    }
  }

  Future<void> setUserId(String? uid) async {
    try {
      await _crashlytics.setUserIdentifier(uid ?? '');
    } catch (e, st) {
      AppLogger.error('Crashlytics setUserId failed', e, st);
    }
  }

  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );
    } catch (e, st) {
      AppLogger.error('Crashlytics recordError failed', e, st);
    }
  }

  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e, st) {
      AppLogger.error('Crashlytics log failed', e, st);
    }
  }
}
