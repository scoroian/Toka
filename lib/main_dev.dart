import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'shared/services/remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Connect to local emulators
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);

  // En dev: inicializar RemoteConfig (usa emuladores si están disponibles)
  final remoteConfigService = RemoteConfigService(FirebaseRemoteConfig.instance);
  await remoteConfigService.init();

  // En dev: log errors locally, no Crashlytics upload
  FlutterError.onError = (errorDetails) {
    debugPrint('FlutterError: ${errorDetails.exceptionAsString()}');
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Unhandled async error: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: TokaApp()));
}
