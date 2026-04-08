// integration_test/helpers/test_setup.dart
//
// Shared E2E test setup.
// Must be called from setUpAll() before any patrolTest runs.
//
// What it does:
//   1. Redirects the Firebase SDK to the local emulators (10.0.2.2 = host
//      machine as seen from the Android emulator).
//   2. Creates the E2E test user in the Auth emulator if it doesn't exist.

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

const testEmail = 'test@toka.dev';
const testPassword = 'Test1234!';

// Android emulator maps the host machine to 10.0.2.2.
const _emulatorHost = '10.0.2.2';

/// Call once in setUpAll() before any patrolTest.
Future<void> setupE2EEnvironment() async {
  await _connectToEmulators();
  await _ensureTestUser();
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
