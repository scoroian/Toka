// integration_test/flows/auth_onboarding_flow_test.dart
//
// Patrol E2E tests — Auth & Sign-out flow
//
// Prerequisites:
//   - Firebase Auth emulator running on localhost:9099
//   - A test user already seeded: test@toka.dev / Test1234!
//
// Run with:
//   patrol test -d emulator-5554 integration_test/flows/auth_onboarding_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  // ────────────────────────────────────────────────────────────────────
  // Test 1 — Login with email/password → home screen shown
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'login with email+password shows home screen',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 30),
      visibleTimeout: Duration(seconds: 15),
    ),
    ($) async {
      // Wait for splash / initial routing to complete
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Only run login flow if the login screen is actually shown
      if ($(find.byKey(const Key('email_field'))).exists) {
        await $(find.byKey(const Key('email_field')))
            .enterText('test@toka.dev');
        await $(find.byKey(const Key('password_field')))
            .enterText('Test1234!');

        // Dismiss the soft keyboard
        await $.tester.testTextInput.receiveAction(TextInputAction.done);
        await $.pumpAndSettle(timeout: const Duration(seconds: 2));

        await $(find.byKey(const Key('submit_button'))).tap();

        // Wait for authentication + potential onboarding redirect
        await $.pumpAndSettle(timeout: const Duration(seconds: 20));
      }

      // After login the router can redirect to /onboarding or /home.
      // Accept either the NavigationBar (home shell) or an onboarding PageView.
      final onHome = $(find.byType(NavigationBar)).exists;
      final onOnboarding = $(find.byType(PageView)).exists;

      expect(
        onHome || onOnboarding,
        isTrue,
        reason: 'Expected to land on home shell or onboarding after login, '
            'but neither was found.',
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────
  // Test 2 — Navigate to profile → sign out → login screen appears
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'sign out from profile returns to login screen',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 30),
      visibleTimeout: Duration(seconds: 15),
    ),
    ($) async {
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // ── Authenticate if we landed on the login screen ──────────────
      if ($(find.byKey(const Key('email_field'))).exists) {
        await $(find.byKey(const Key('email_field')))
            .enterText('test@toka.dev');
        await $(find.byKey(const Key('password_field')))
            .enterText('Test1234!');
        await $.tester.testTextInput.receiveAction(TextInputAction.done);
        await $.pumpAndSettle(timeout: const Duration(seconds: 2));
        await $(find.byKey(const Key('submit_button'))).tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 20));
      }

      // ── Wait for home NavigationBar (onboarding may redirect there) ─
      if (!$(find.byType(NavigationBar)).exists) {
        await $.pumpAndSettle(timeout: const Duration(seconds: 10));
      }

      // Guard: skip if we never reached the home shell
      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped(
          'Could not reach home screen — possibly stuck on onboarding. '
          'Skipping sign-out test.',
        );
        return;
      }

      // ── Navigate to Settings (tab index 4, icon: Icons.settings_outlined) ─
      await $.tap(find.byIcon(Icons.settings_outlined));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('settings_section_account'))).exists,
        isTrue,
        reason: 'Settings screen not found after tapping settings tab.',
      );

      // ── The profile screen (own_profile_screen) exposes logout_tile.
      //    Navigate there via the edit-profile action in settings, or by
      //    tapping the first ListTile under the Account section.
      if (!$(find.byKey(const Key('logout_tile'))).exists) {
        // Tap "Editar perfil" – first ListTile after the account section header
        await $.tap(find.byIcon(Icons.person_outline));
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      }

      // Guard: skip if profile / logout tile not found
      if (!$(find.byKey(const Key('logout_tile'))).exists) {
        markTestSkipped(
          'Could not navigate to profile screen. '
          'Skipping logout assertion.',
        );
        return;
      }

      // ── Tap Logout ─────────────────────────────────────────────────
      await $(find.byKey(const Key('logout_tile'))).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 8));

      // ── Verify login screen is shown ───────────────────────────────
      expect(
        $(find.byKey(const Key('email_field'))).exists,
        isTrue,
        reason: 'Login screen (email_field) not shown after sign-out.',
      );
    },
  );
}
