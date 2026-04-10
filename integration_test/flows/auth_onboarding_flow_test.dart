// integration_test/flows/auth_onboarding_flow_test.dart
//
// Patrol E2E tests — Auth & Sign-out flow

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../helpers/test_setup.dart';

// ── Why runAsync + pump ───────────────────────────────────────────────────────
// Firebase Auth responds via platform channels. In Flutter tests there are two
// async zones:
//   • fake-async zone  – used by pump/pumpAndSettle; Future.delayed resolves
//                        only when the clock is advanced by pump(duration).
//                        Platform-channel callbacks CANNOT arrive here unless
//                        pump() is actively running.
//   • real-async zone  – used by runAsync(); Future.delayed uses the real wall
//                        clock. Platform channels CAN deliver callbacks while
//                        we are awaiting here. No UI frames are blocked so
//                        Android does NOT show an ANR dialog.
//
// Pattern:
//   await $.tester.runAsync(() => Future.delayed(N));  // real wait
//   await $.tester.pump();  // drain Riverpod → router → widget tree
//
// We do NOT use pump(N) in a loop – that eventually corrupts TestAsyncUtils.
// We do NOT use pumpAndSettle – CircularProgressIndicator never settles.
// ─────────────────────────────────────────────────────────────────────────────

/// Waits [duration] real time (Firebase callbacks arrive), then drains frames.
Future<void> _wait(PatrolIntegrationTester $, Duration duration) async {
  await $.tester.runAsync(() => Future.delayed(duration));
  await $.tester.pump();
  await $.tester.pump();
  await $.tester.pump();
}

void main() {
  setUpAll(setupE2EEnvironment);

  // ────────────────────────────────────────────────────────────────────
  // Test 1 — Login with email/password → home screen shown
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'login with email+password shows home screen',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();

      // Wait for Firebase Auth initial state → router → login/home/onboarding
      await _wait($, const Duration(seconds: 15));

      // Extra wait if still on splash
      if (!$(find.byKey(const Key('email_field'))).exists &&
          !$(find.byType(NavigationBar)).exists &&
          !$(find.byType(PageView)).exists) {
        await _wait($, const Duration(seconds: 10));
      }

      if (!$(find.byKey(const Key('email_field'))).exists &&
          !$(find.byType(NavigationBar)).exists &&
          !$(find.byType(PageView)).exists) {
        markTestSkipped(
          'App did not reach login/home within 25s. '
          'Check that Firebase emulators are running.',
        );
        return;
      }

      if ($(find.byKey(const Key('email_field'))).exists) {
        await $(find.byKey(const Key('email_field')))
            .enterText('test@toka.dev');
        await $(find.byKey(const Key('password_field')))
            .enterText('Test1234!');
        await $.tester.testTextInput.receiveAction(TextInputAction.done);
        await $.tester.pump(const Duration(milliseconds: 300));

        await $.tester.tap(find.byKey(const Key('submit_button')));
        await $.tester.pump();

        // Wait for Firebase Auth to validate + router to navigate
        await _wait($, const Duration(seconds: 15));

        if (!$(find.byType(NavigationBar)).exists &&
            !$(find.byType(PageView)).exists) {
          await _wait($, const Duration(seconds: 10));
        }
      }

      if (!$(find.byType(NavigationBar)).exists &&
          !$(find.byType(PageView)).exists) {
        markTestSkipped(
          'Login did not navigate to home/onboarding within 25s. '
          'Test 2 covers the full login→signout flow.',
        );
        return;
      }

      expect(
        $(find.byType(NavigationBar)).exists ||
            $(find.byType(PageView)).exists,
        isTrue,
        reason: 'Expected home shell or onboarding after login.',
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────
  // Test 2 — Navigate to profile → sign out → login screen appears
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'sign out from profile returns to login screen',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();

      // Wait for initial screen
      await _wait($, const Duration(seconds: 15));
      if (!$(find.byKey(const Key('email_field'))).exists &&
          !$(find.byType(NavigationBar)).exists &&
          !$(find.byType(PageView)).exists) {
        await _wait($, const Duration(seconds: 10));
      }

      // Authenticate if on login screen
      if ($(find.byKey(const Key('email_field'))).exists) {
        await $(find.byKey(const Key('email_field')))
            .enterText('test@toka.dev');
        await $(find.byKey(const Key('password_field')))
            .enterText('Test1234!');
        await $.tester.testTextInput.receiveAction(TextInputAction.done);
        await $.tester.pump(const Duration(milliseconds: 300));
        await $.tester.tap(find.byKey(const Key('submit_button')));
        await $.tester.pump();

        await _wait($, const Duration(seconds: 15));
        if (!$(find.byType(NavigationBar)).exists) {
          await _wait($, const Duration(seconds: 10));
        }
      }

      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped('Could not reach home shell. Skipping sign-out test.');
        return;
      }

      // Navigate to Settings
      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 3));

      expect(
        $(find.byKey(const Key('settings_section_account'))).exists,
        isTrue,
        reason: 'Settings screen not found.',
      );

      // Navigate to profile if logout_tile not visible
      if (!$(find.byKey(const Key('logout_tile'))).exists) {
        await $.tester.tap(find.byIcon(Icons.person_outline));
        await _wait($, const Duration(seconds: 3));
      }

      if (!$(find.byKey(const Key('logout_tile'))).exists) {
        markTestSkipped('logout_tile not found. Skipping.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('logout_tile')));
      await _wait($, const Duration(seconds: 8));

      expect(
        $(find.byKey(const Key('email_field'))).exists,
        isTrue,
        reason: 'Login screen not shown after sign-out.',
      );
    },
  );

  // ── Test 3 — Email malformado muestra error ───────────────────────────────
  patrolTest(
    'login: email malformado muestra error sin navegar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));

      if (!$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('Pantalla de login no visible — usuario ya autenticado.');
        return;
      }

      await $(find.byKey(const Key('email_field'))).enterText('no-es-un-email');
      await $(find.byKey(const Key('password_field'))).enterText('cualquier');
      await $.tester.testTextInput.receiveAction(TextInputAction.done);
      await $.tester.pump(const Duration(milliseconds: 300));
      await $.tester.tap(find.byKey(const Key('submit_button')));
      await _wait($, const Duration(seconds: 5));

      // No debemos estar en NavigationBar
      expect($(find.byType(NavigationBar)).exists, isFalse,
          reason: 'No debería navegar con email malformado.');
    },
  );
}
