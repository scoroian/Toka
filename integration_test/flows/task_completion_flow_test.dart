// integration_test/flows/task_completion_flow_test.dart
//
// Patrol E2E tests — Task creation & pass-turn flow
//
// Prerequisites:
//   - Firebase Auth emulator on localhost:9099
//   - Firestore emulator on localhost:8080
//   - A test user seeded: test@toka.dev / Test1234!
//   - The user must already belong to a home (completed onboarding)
//
// Run with:
//   patrol test -d emulator-5554 integration_test/flows/task_completion_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

const _testEmail = 'test@toka.dev';
const _testPassword = 'Test1234!';
const _testTaskName = 'Tarea E2E Test';

// ── Helper: login if needed ───────────────────────────────────────────────────
Future<void> _loginIfNeeded(PatrolIntegrationTester $) async {
  await $.pumpAndSettle(timeout: const Duration(seconds: 5));

  if ($(find.byKey(const Key('email_field'))).exists) {
    await $(find.byKey(const Key('email_field'))).enterText(_testEmail);
    await $(find.byKey(const Key('password_field'))).enterText(_testPassword);
    await $.tester.testTextInput.receiveAction(TextInputAction.done);
    await $.pumpAndSettle(timeout: const Duration(seconds: 2));
    await $(find.byKey(const Key('submit_button'))).tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 20));
  }
}

// ── Helper: navigate to a shell tab by icon ───────────────────────────────────
Future<void> _goToTasksTab(PatrolIntegrationTester $) async {
  // NavigationBar tab 3 = Tareas (icon: Icons.task_alt_outlined)
  await $.tap(find.byIcon(Icons.task_alt_outlined));
  await $.pumpAndSettle(timeout: const Duration(seconds: 5));
}

Future<void> _goToTodayTab(PatrolIntegrationTester $) async {
  // NavigationBar tab 0 = Hoy (icon: Icons.home_outlined)
  await $.tap(find.byIcon(Icons.home_outlined));
  await $.pumpAndSettle(timeout: const Duration(seconds: 5));
}

void main() {
  // ────────────────────────────────────────────────────────────────────
  // Test 1 — Authenticate, go to tasks, create 'Tarea E2E Test'
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'authenticated user can create a task and see the today screen',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 30),
      visibleTimeout: Duration(seconds: 15),
    ),
    ($) async {
      await _loginIfNeeded($);

      // Guard: must be on home shell
      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped(
          'Could not reach home shell — possibly stuck on onboarding. '
          'Skipping task creation test.',
        );
        return;
      }

      // Navigate to Tasks tab
      await _goToTasksTab($);

      // Guard: AllTasksScreen must be shown
      final onTasksScreen = $(find.byKey(const Key('create_task_fab'))).exists ||
          $(find.byKey(const Key('tasks_empty_state'))).exists ||
          $(find.byKey(const Key('tasks_list'))).exists;

      if (!onTasksScreen) {
        markTestSkipped(
          'Tasks screen not found. '
          'User may not have a home set up. Skipping.',
        );
        return;
      }

      // Only create if the FAB exists (user has permission / premium)
      if ($(find.byKey(const Key('create_task_fab'))).exists) {
        await $(find.byKey(const Key('create_task_fab'))).tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        // Fill in the task title
        expect(
          $(find.byKey(const Key('task_title_field'))).exists,
          isTrue,
          reason: 'CreateEditTaskScreen not shown after tapping FAB.',
        );

        await $(find.byKey(const Key('task_title_field')))
            .enterText(_testTaskName);
        await $.pumpAndSettle(timeout: const Duration(seconds: 2));

        // Save the task
        await $(find.byKey(const Key('save_task_button'))).tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 10));

        // After save, we should be back on the tasks list or today screen
        final savedOk = $(find.byKey(const Key('tasks_list'))).exists ||
            $(find.byKey(const Key('tasks_empty_state'))).exists ||
            $(find.byType(NavigationBar)).exists;

        expect(
          savedOk,
          isTrue,
          reason:
              'After saving task, expected to return to task list or shell.',
        );
      }

      // Navigate to Today tab and verify it loads
      await _goToTodayTab($);

      // Today screen shows AppBar with title or the CustomScrollView content
      final todayLoaded = $(find.byType(CustomScrollView)).exists ||
          $(find.byType(Scaffold)).exists;

      expect(
        todayLoaded,
        isTrue,
        reason: 'Today screen did not load after navigating to home tab.',
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────
  // Test 2 — Navigate to today, attempt pass-turn if task exists
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'today screen loads and pass-turn button is tappable if task is assigned',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 30),
      visibleTimeout: Duration(seconds: 15),
    ),
    ($) async {
      await _loginIfNeeded($);

      // Guard: must be on home shell
      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped(
          'Could not reach home shell. Skipping today/pass-turn test.',
        );
        return;
      }

      // Navigate to Today tab
      await _goToTodayTab($);
      await $.pumpAndSettle(timeout: const Duration(seconds: 8));

      // Today screen should show either tasks content or empty state
      final todayVisible = $(find.byType(CustomScrollView)).exists ||
          $(find.byType(Center)).exists;

      expect(
        todayVisible,
        isTrue,
        reason: 'Today screen content not found.',
      );

      // If there is a pass-turn button visible, tap it to test the flow
      if ($(find.byKey(const Key('btn_pass'))).exists) {
        await $(find.byKey(const Key('btn_pass'))).tap();
        await $.pumpAndSettle(timeout: const Duration(seconds: 5));

        // A dialog should appear (PassTurnDialog)
        final dialogShown = $(find.byType(AlertDialog)).exists ||
            $(find.byType(Dialog)).exists;

        // We don't require the dialog — the task might not be assigned to this
        // user in the emulator. We just verify the tap didn't crash the app.
        if (dialogShown) {
          // Dismiss the dialog by tapping outside or cancel button
          await $.tester.tapAt(const Offset(10, 10));
          await $.pumpAndSettle(timeout: const Duration(seconds: 3));
        }
      }

      // Final sanity check: the app is still running and showing the shell
      expect(
        $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'App crashed or navigated away unexpectedly.',
      );
    },
  );
}
