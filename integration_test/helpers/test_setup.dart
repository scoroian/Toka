// integration_test/helpers/test_setup.dart
//
// Shared E2E test setup.
// Must be called from setUpAll() before any patrolTest runs.
//
// What it does:
//   1. Initializes Firebase SDK (with debug App Check, no Crashlytics).
//   2. Redirects the Firebase SDK to the local emulators (10.0.2.2 = host
//      machine as seen from the Android emulator).
//   3. Creates the E2E test user in the Auth emulator if it doesn't exist.

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:toka/app.dart';
import 'package:toka/firebase_options.dart';

export 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
export 'package:toka/app.dart' show TokaApp;

const testEmail = 'test@toka.dev';
const testPassword = 'Test1234!';

// Android emulator maps the host machine to 10.0.2.2.
const _emulatorHost = '10.0.2.2';

/// Call once in setUpAll() before any patrolTest.
Future<void> setupE2EEnvironment() async {
  tz_data.initializeTimeZones();
  await _initFirebase();
  await _connectToEmulators();
  await _ensureTestUser();
}

/// Root widget to pump in each patrolTest.
/// Use: await $.pumpWidgetAndSettle(testApp());
ProviderScope testApp() => const ProviderScope(child: TokaApp());

// ─── Firebase initialization ──────────────────────────────────────────────────

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Use debug App Check provider so tests pass without Play Integrity.
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
    // ignore: avoid_print
    print('[E2E setup] Firebase initialized with debug App Check');
  } catch (e) {
    // ignore: avoid_print
    print('[E2E setup] Warning: Firebase init error (may already be initialized): $e');
  }
}

// ─── Firebase SDK → local emulators ──────────────────────────────────────────

Future<void> _connectToEmulators() async {
  try {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(_emulatorHost, 5001);
    // ignore: avoid_print
    print('[E2E setup] Firebase SDK connected to local emulators at $_emulatorHost');
  } catch (e) {
    // ignore: avoid_print
    print('[E2E setup] Warning: could not redirect Firebase to emulators: $e');
  }
}

// ─── Create test user via Auth emulator REST API ──────────────────────────────

Future<void> _ensureTestUser() async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(
      'http://$_emulatorHost:9099'
      '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key',
    );
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'email': testEmail,
      'password': testPassword,
      'returnSecureToken': true,
    }));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      // ignore: avoid_print
      print('[E2E setup] Test user created: $testEmail');
    } else if (body.contains('EMAIL_EXISTS')) {
      // ignore: avoid_print
      print('[E2E setup] Test user already exists: $testEmail');
    } else {
      // ignore: avoid_print
      print('[E2E setup] Warning: unexpected response ${response.statusCode}: $body');
    }
  } on SocketException catch (e) {
    // ignore: avoid_print
    print('[E2E setup] Could not reach Auth emulator — is "firebase emulators:start" running? $e');
  } catch (e) {
    // ignore: avoid_print
    print('[E2E setup] Unexpected error creating test user: $e');
  } finally {
    client.close();
  }
}

// ─── Home existence helpers ───────────────────────────────────────────────────

/// Navega por el onboarding/creación de hogar si el usuario no tiene
/// un hogar activo todavía. Llama esto al inicio de cualquier test
/// que requiera un hogar existente.
Future<void> ensureHomeExists(PatrolIntegrationTester $) async {
  // Si ya hay NavigationBar, hay hogar activo — nada que hacer.
  if ($(find.byType(NavigationBar)).exists) return;

  // Si estamos en onboarding (PageView de pasos)
  if ($(find.byType(PageView)).exists) {
    await _completeOnboarding($);
    return;
  }

  // Si hay botón directo de crear hogar
  if ($(find.byKey(const Key('create_home_button'))).exists) {
    await _createHomeFromButton($);
    return;
  }
}

Future<void> _completeOnboarding(PatrolIntegrationTester $) async {
  int attempts = 0;
  while (!$(find.byType(NavigationBar)).exists && attempts < 10) {
    attempts++;

    if ($(find.byKey(const Key('onboarding_next_button'))).exists) {
      await $.tester.tap(find.byKey(const Key('onboarding_next_button')));
      await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
      await $.tester.pump();
      continue;
    }

    if ($(find.byKey(const Key('display_name_field'))).exists) {
      await $(find.byKey(const Key('display_name_field'))).enterText('E2E User');
      await $.tester.pump(const Duration(milliseconds: 300));
    }
    if ($(find.byKey(const Key('profile_next_button'))).exists) {
      await $.tester.tap(find.byKey(const Key('profile_next_button')));
      await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
      await $.tester.pump();
      continue;
    }

    if ($(find.byKey(const Key('home_name_field'))).exists) {
      await $(find.byKey(const Key('home_name_field'))).enterText('Casa E2E');
      await $.tester.pump(const Duration(milliseconds: 300));
    }
    if ($(find.byKey(const Key('create_home_confirm_button'))).exists) {
      await $.tester.tap(find.byKey(const Key('create_home_confirm_button')));
      await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
      await $.tester.pump();
      continue;
    }

    await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    await $.tester.pump();
  }
}

Future<void> _createHomeFromButton(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byKey(const Key('create_home_button')));
  await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
  await $.tester.pump();

  if ($(find.byKey(const Key('home_name_field'))).exists) {
    await $(find.byKey(const Key('home_name_field'))).enterText('Casa E2E');
    await $.tester.pump(const Duration(milliseconds: 300));
  }
  if ($(find.byKey(const Key('create_home_confirm_button'))).exists) {
    await $.tester.tap(find.byKey(const Key('create_home_confirm_button')));
    await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await $.tester.pump();
  }
}
