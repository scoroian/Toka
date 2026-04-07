import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/crashlytics_service.dart';
import 'shared/services/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  // Inicializar observabilidad antes de runApp
  final crashlyticsService = CrashlyticsService(FirebaseCrashlytics.instance);
  await crashlyticsService.init();

  final remoteConfigService = RemoteConfigService(FirebaseRemoteConfig.instance);
  await remoteConfigService.init();

  // AnalyticsService disponible pero no requiere init async
  final analyticsService = AnalyticsService(FirebaseAnalytics.instance);

  // Capturar errores no manejados de Dart
  runZonedGuarded(
    () => runApp(const ProviderScope(
      child: TokaApp(),
    )),
    (error, stack) {
      analyticsService.logEvent('unhandled_error');
      crashlyticsService.recordError(error, stack, fatal: true);
    },
  );
}
