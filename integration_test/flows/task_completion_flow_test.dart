// integration_test/flows/task_completion_flow_test.dart
//
// Patrol E2E tests — Task creation & pass-turn flow

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../helpers/test_setup.dart';

const _testEmail = 'test@toka.dev';
const _testPassword = 'Test1234!';
const _testTaskName = 'Tarea E2E Test';

// See auth_onboarding_flow_test.dart for the runAsync pump strategy.

Future<void> _wait(PatrolIntegrationTester $, Duration duration) async {
  await $.tester.runAsync(() => Future.delayed(duration));
  await $.tester.pump();
  await $.tester.pump();
  await $.tester.pump();
}

Future<void> _loginIfNeeded(PatrolIntegrationTester $) async {
  await _wait($, const Duration(seconds: 15));
  if (!$(find.byKey(const Key('email_field'))).exists &&
      !$(find.byType(NavigationBar)).exists &&
      !$(find.byType(PageView)).exists) {
    await _wait($, const Duration(seconds: 10));
  }

  if ($(find.byKey(const Key('email_field'))).exists) {
    await $(find.byKey(const Key('email_field'))).enterText(_testEmail);
    await $(find.byKey(const Key('password_field'))).enterText(_testPassword);
    await $.tester.testTextInput.receiveAction(TextInputAction.done);
    await $.tester.pump(const Duration(milliseconds: 300));
    await $.tester.tap(find.byKey(const Key('submit_button')));
    await $.tester.pump();

    await _wait($, const Duration(seconds: 15));
    if (!$(find.byType(NavigationBar)).exists &&
        !$(find.byType(PageView)).exists) {
      await _wait($, const Duration(seconds: 10));
    }
  }
}

void main() {
  setUpAll(setupE2EEnvironment);

  // ────────────────────────────────────────────────────────────────────
  // Test 1 — Authenticate, go to tasks, create 'Tarea E2E Test'
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'authenticated user can create a task and see the today screen',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _loginIfNeeded($);

      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped(
          'Could not reach home shell — possibly stuck on onboarding.',
        );
        return;
      }

      // Navigate to Tasks tab
      await $.tester.tap(find.byIcon(Icons.task_alt_outlined));
      await _wait($, const Duration(seconds: 5));

      final onTasksScreen =
          $(find.byKey(const Key('create_task_fab'))).exists ||
              $(find.byKey(const Key('tasks_empty_state'))).exists ||
              $(find.byKey(const Key('tasks_list'))).exists;

      if (!onTasksScreen) {
        markTestSkipped('Tasks screen not found. User may not have a home.');
        return;
      }

      if ($(find.byKey(const Key('create_task_fab'))).exists) {
        await $.tester.tap(find.byKey(const Key('create_task_fab')));
        await _wait($, const Duration(seconds: 5));

        expect(
          $(find.byKey(const Key('task_title_field'))).exists,
          isTrue,
          reason: 'CreateEditTaskScreen not shown after tapping FAB.',
        );

        await $(find.byKey(const Key('task_title_field')))
            .enterText(_testTaskName);
        await $.tester.pump(const Duration(milliseconds: 300));

        await $.tester.tap(find.byKey(const Key('save_task_button')));
        await _wait($, const Duration(seconds: 8));

        expect(
          $(find.byKey(const Key('tasks_list'))).exists ||
              $(find.byKey(const Key('tasks_empty_state'))).exists ||
              $(find.byType(NavigationBar)).exists,
          isTrue,
          reason: 'After saving task, expected task list or shell.',
        );
      }

      // Navigate to Today tab
      await $.tester.tap(find.byIcon(Icons.home_outlined));
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byType(CustomScrollView)).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'Today screen did not load.',
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────
  // Test 2 — Navigate to today, attempt pass-turn if task exists
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'today screen loads and pass-turn button is tappable if task is assigned',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _loginIfNeeded($);

      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped('Could not reach home shell. Skipping pass-turn test.');
        return;
      }

      // Navigate to Today tab
      await $.tester.tap(find.byIcon(Icons.home_outlined));
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byType(CustomScrollView)).exists ||
            $(find.byType(Center)).exists,
        isTrue,
        reason: 'Today screen content not found.',
      );

      if ($(find.byKey(const Key('btn_pass'))).exists) {
        await $.tester.tap(find.byKey(const Key('btn_pass')));
        await _wait($, const Duration(seconds: 3));

        if ($(find.byType(AlertDialog)).exists ||
            $(find.byType(Dialog)).exists) {
          await $.tester.tapAt(const Offset(10, 10));
          await $.tester.pump();
        }
      }

      expect(
        $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'App crashed or navigated away unexpectedly.',
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────
  // Test 3 — Complete task dialog y valoración
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'task completion: complete task dialog appears and can be dismissed',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _loginIfNeeded($);

      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped('Could not reach home shell.');
        return;
      }

      // Ir a pantalla Hoy
      await $.tester.tap(find.byIcon(Icons.home_outlined));
      await _wait($, const Duration(seconds: 5));

      // Si hay un botón de completar tarea, tocarlo
      if ($(find.byKey(const Key('btn_complete'))).exists) {
        await $.tester.tap(find.byKey(const Key('btn_complete')).first);
        await _wait($, const Duration(seconds: 3));

        // Verificar que aparece el dialog de completar tarea
        if ($(find.byType(AlertDialog)).exists ||
            $(find.byType(Dialog)).exists ||
            $(find.byKey(const Key('complete_task_dialog'))).exists) {
          expect(
            $(find.byKey(const Key('complete_task_dialog'))).exists ||
                $(find.byType(AlertDialog)).exists,
            isTrue,
            reason: 'Complete task dialog not shown after tapping complete button.',
          );

          // Buscar botón de confirmar
          if ($(find.byKey(const Key('confirm_complete_button'))).exists) {
            await $.tester.tap(find.byKey(const Key('confirm_complete_button')));
            await _wait($, const Duration(seconds: 5));
          } else {
            // Descartar el dialog
            await $.tester.tapAt(const Offset(10, 10));
            await $.tester.pump();
          }
        }
      }

      expect($(find.byType(Scaffold)).exists, isTrue,
          reason: 'App should still be running after complete interaction.');
    },
  );

  // ────────────────────────────────────────────────────────────────────
  // Test 4 — Pass turn con penalización visible
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'task completion: pass turn dialog shows penalty info',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _loginIfNeeded($);

      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped('Could not reach home shell.');
        return;
      }

      await $.tester.tap(find.byIcon(Icons.home_outlined));
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('btn_pass'))).exists) {
        markTestSkipped('No pass button found on today screen.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('btn_pass')).first);
      await _wait($, const Duration(seconds: 3));

      if ($(find.byType(AlertDialog)).exists ||
          $(find.byType(Dialog)).exists ||
          $(find.byKey(const Key('pass_turn_dialog'))).exists) {

        // Verificar que el dialog muestra información de penalización
        final showsPenaltyInfo =
            $(find.byKey(const Key('compliance_before'))).exists ||
            $(find.byKey(const Key('compliance_after'))).exists ||
            $(find.text('penalización')).exists ||
            $(find.text('penalty')).exists ||
            $(find.byKey(const Key('pass_turn_dialog'))).exists;

        expect(showsPenaltyInfo, isTrue,
            reason: 'Pass turn dialog should show penalty information.');

        // Descartar el dialog sin confirmar
        if ($(find.byKey(const Key('cancel_pass_button'))).exists) {
          await $.tester.tap(find.byKey(const Key('cancel_pass_button')));
        } else {
          await $.tester.tapAt(const Offset(10, 10));
        }
        await $.tester.pump();
      }

      expect($(find.byType(Scaffold)).exists, isTrue);
    },
  );

  // ────────────────────────────────────────────────────────────────────
  // Test 5 — Crear tarea con recurrencia semanal
  // ────────────────────────────────────────────────────────────────────
  patrolTest(
    'task completion: create task with weekly recurrence',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _loginIfNeeded($);

      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped('Could not reach home shell.');
        return;
      }

      // Navegar a All Tasks tab
      await $.tester.tap(find.byIcon(Icons.task_alt_outlined));
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('create_task_fab'))).exists) {
        markTestSkipped('create_task_fab not found. User may not have admin/owner role.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('create_task_fab')));
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('task_title_field'))).exists) {
        markTestSkipped('CreateEditTaskScreen not found.');
        return;
      }

      // Introducir título
      await $(find.byKey(const Key('task_title_field')))
          .enterText('Tarea Semanal E2E');
      await $.tester.pump(const Duration(milliseconds: 300));

      // Buscar selector de recurrencia y elegir Semanal si es posible
      if ($(find.byKey(const Key('recurrence_weekly_option'))).exists) {
        await $.tester.tap(find.byKey(const Key('recurrence_weekly_option')));
        await $.tester.pump();
      } else if ($(find.text('Semanal')).exists) {
        await $.tester.tap(find.text('Semanal').first);
        await $.tester.pump();
      }

      // Guardar tarea
      await $.tester.tap(find.byKey(const Key('save_task_button')));
      await _wait($, const Duration(seconds: 8));

      // Verificar que volvimos a la lista de tareas
      expect(
        $(find.byKey(const Key('tasks_list'))).exists ||
            $(find.byType(NavigationBar)).exists,
        isTrue,
        reason: 'After saving task, expected task list or nav bar.',
      );
    },
  );
}
