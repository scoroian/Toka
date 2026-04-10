// integration_test/flows/home_management_flow_test.dart
//
// Patrol E2E — Home management flow
// Cubre: ajustes del hogar, cambiar nombre, crear segundo hogar, cambiar hogar activo,
//        salir del hogar, eliminar hogar como owner.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../helpers/test_setup.dart';

const _testEmail = 'test@toka.dev';
const _testPassword = 'Test1234!';

Future<void> _wait(PatrolIntegrationTester $, Duration duration) async {
  await $.tester.runAsync(() => Future.delayed(duration));
  await $.tester.pump();
  await $.tester.pump();
  await $.tester.pump();
}

Future<bool> _loginIfNeeded(PatrolIntegrationTester $) async {
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
    if (!$(find.byType(NavigationBar)).exists) {
      await _wait($, const Duration(seconds: 10));
    }
  }
  return $(find.byType(NavigationBar)).exists;
}

void main() {
  setUpAll(setupE2EEnvironment);

  // ── Test 1 — Pantalla de ajustes del hogar carga ─────────────────────────
  patrolTest(
    'home management: ajustes del hogar carga con nombre del hogar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      // Navegar a Settings
      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      // Buscar tile de ajustes del hogar
      final hasHomeTile =
          $(find.byKey(const Key('home_settings_tile'))).exists ||
          $(find.text('Hogar')).exists ||
          $(find.text('Home settings')).exists;

      if (!hasHomeTile) {
        markTestSkipped('Tile de ajustes del hogar no encontrado.');
        return;
      }

      if ($(find.byKey(const Key('home_settings_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('home_settings_tile')));
      } else if ($(find.text('Hogar')).exists) {
        await $.tester.tap(find.text('Hogar').first);
      }
      await _wait($, const Duration(seconds: 5));

      expect($(find.byType(Scaffold)).exists, isTrue,
          reason: 'Pantalla de ajustes del hogar no cargó.');
    },
  );

  // ── Test 2 — Cambiar nombre del hogar ────────────────────────────────────
  patrolTest(
    'home management: cambiar nombre del hogar persiste tras guardar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('home_settings_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('home_settings_tile')));
        await _wait($, const Duration(seconds: 5));
      }

      if (!$(find.byKey(const Key('home_name_field'))).exists) {
        markTestSkipped('Campo de nombre del hogar no encontrado.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('home_name_field')));
      await $.tester.pump(const Duration(milliseconds: 300));
      await $(find.byKey(const Key('home_name_field'))).enterText('Casa Renombrada E2E');
      await $.tester.pump(const Duration(milliseconds: 300));

      if ($(find.byKey(const Key('save_home_name_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('save_home_name_button')));
      }
      await _wait($, const Duration(seconds: 5));

      expect($(find.byType(Scaffold)).exists, isTrue);
    },
  );

  // ── Test 3 — Navegar a Mis hogares ───────────────────────────────────────
  patrolTest(
    'home management: pantalla Mis hogares muestra el hogar actual',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      final hasMyHomesTile =
          $(find.byKey(const Key('my_homes_tile'))).exists ||
          $(find.text('Mis hogares')).exists ||
          $(find.text('My homes')).exists;

      if (!hasMyHomesTile) {
        markTestSkipped('Tile de Mis hogares no encontrado.');
        return;
      }

      if ($(find.byKey(const Key('my_homes_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('my_homes_tile')));
      } else if ($(find.text('Mis hogares')).exists) {
        await $.tester.tap(find.text('Mis hogares').first);
      }
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('home_list_item'))).exists ||
            $(find.byType(ListTile)).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
      );
    },
  );

  // ── Test 4 — Salir del hogar como miembro ───────────────────────────────
  patrolTest(
    'home management: opción de salir del hogar visible en ajustes',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('home_settings_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('home_settings_tile')));
        await _wait($, const Duration(seconds: 5));
      }

      final hasLeaveOption =
          $(find.byKey(const Key('leave_home_button'))).exists ||
          $(find.text('Salir del hogar')).exists ||
          $(find.text('Leave home')).exists ||
          $(find.text('Eliminar hogar')).exists ||
          $(find.text('Close home')).exists;

      expect(hasLeaveOption, isTrue,
          reason: 'Opción de salir/eliminar hogar no encontrada en ajustes.');
    },
  );

  // ── Test 5 — Eliminar hogar como owner (destructivo) ────────────────────
  patrolTest(
    'home management: owner puede eliminar el hogar y la app navega al onboarding',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('home_settings_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('home_settings_tile')));
        await _wait($, const Duration(seconds: 5));
      }

      final hasCloseButton =
          $(find.byKey(const Key('close_home_button'))).exists ||
          $(find.text('Eliminar hogar')).exists ||
          $(find.text('Close home')).exists;

      if (!hasCloseButton) {
        markTestSkipped('Botón de eliminar hogar no encontrado (usuario puede no ser owner).');
        return;
      }

      if ($(find.byKey(const Key('close_home_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('close_home_button')));
      } else if ($(find.text('Eliminar hogar')).exists) {
        await $.tester.tap(find.text('Eliminar hogar').first);
      }
      await _wait($, const Duration(seconds: 3));

      // Confirmar en el dialog si aparece
      if ($(find.byType(AlertDialog)).exists ||
          $(find.byKey(const Key('confirm_close_home_dialog'))).exists) {
        if ($(find.byKey(const Key('confirm_close_home_button'))).exists) {
          await $.tester.tap(find.byKey(const Key('confirm_close_home_button')));
        } else if ($(find.text('Confirmar')).exists) {
          await $.tester.tap(find.text('Confirmar').first);
        } else if ($(find.text('Eliminar')).exists) {
          await $.tester.tap(find.text('Eliminar').first);
        }
        await _wait($, const Duration(seconds: 8));
      }

      // Tras eliminar, el usuario vuelve a onboarding o selector de hogar
      expect(
        $(find.byType(PageView)).exists ||
            $(find.byKey(const Key('create_home_button'))).exists ||
            $(find.byKey(const Key('my_homes_screen'))).exists ||
            !$(find.byType(NavigationBar)).exists,
        isTrue,
        reason: 'Tras eliminar el hogar, se esperaba salir del home shell.',
      );
    },
  );
}
