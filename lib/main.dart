import 'dart:async';

import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'shared/services/crashlytics_service.dart';
import 'shared/services/remote_config_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      tz_data.initializeTimeZones();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await FirebaseAppCheck.instance.activate(
        androidProvider: const bool.fromEnvironment('dart.vm.product')
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
        appleProvider: const bool.fromEnvironment('dart.vm.product')
            ? AppleProvider.deviceCheck
            : AppleProvider.debug,
      );

      if (!const bool.fromEnvironment('dart.vm.product')) {
        try {
          final token = await FirebaseAppCheck.instance.getToken(true);
          debugPrint('🔑 APP CHECK DEBUG TOKEN: $token');
        } catch (e) {
          debugPrint('🔑 APP CHECK TOKEN ERROR: $e');
        }
      }

      final crashlyticsService =
          CrashlyticsService(FirebaseCrashlytics.instance);
      await crashlyticsService.init();

      final remoteConfigService =
          RemoteConfigService(FirebaseRemoteConfig.instance);
      await remoteConfigService.init();

      runApp(const ProviderScope(child: TokaApp()));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
