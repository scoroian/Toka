// integration_test/helpers/test_setup.dart
//
// Shared E2E test setup helpers.
// Creates the test user in the Firebase Auth emulator if it doesn't exist yet.

import 'dart:convert';
import 'dart:io';

const testEmail = 'test@toka.dev';
const testPassword = 'Test1234!';

/// Tries to create the E2E test user in the Auth emulator.
/// Safe to call multiple times — silently ignores EMAIL_EXISTS.
///
/// Must be called from setUpAll() before any patrolTest runs.
/// When running on the Android emulator, the host machine is reachable
/// at 10.0.2.2 (Android emulator loopback to host).
Future<void> ensureTestUser() async {
  // Android emulator → host machine address
  const authEmulatorHost = '10.0.2.2';
  const authEmulatorPort = 9099;

  final client = HttpClient();
  try {
    final uri = Uri.parse(
      'http://$authEmulatorHost:$authEmulatorPort'
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
    print('[E2E setup] Could not reach Auth emulator at $authEmulatorHost:$authEmulatorPort — $e');
    // ignore: avoid_print
    print('[E2E setup] Make sure Firebase emulators are running: firebase emulators:start');
  } catch (e) {
    // ignore: avoid_print
    print('[E2E setup] Unexpected error creating test user: $e');
  } finally {
    client.close();
  }
}
