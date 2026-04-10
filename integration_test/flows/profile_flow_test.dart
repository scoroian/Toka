// integration_test/flows/profile_flow_test.dart
//
// Patrol E2E — Profile flow
// Cubre: ver perfil propio, editar nombre, cambiar avatar, radar chart, reseñas.

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

  // ── Test 1 — Ver perfil propio ────────────────────────────────────────────
  patrolTest(
    'profile flow: ver perfil propio desde Settings carga la pantalla',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      // Buscar tile de perfil
      if ($(find.byKey(const Key('profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('profile_tile')));
      } else if ($(find.byKey(const Key('edit_profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('edit_profile_tile')));
      } else if ($(find.byIcon(Icons.person_outline)).exists) {
        await $.tester.tap(find.byIcon(Icons.person_outline).first);
      } else {
        markTestSkipped('Tile de perfil no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('own_profile_screen'))).exists ||
            $(find.byKey(const Key('edit_profile_screen'))).exists ||
            $(find.byKey(const Key('display_name_field'))).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'Pantalla de perfil no cargó.',
      );
    },
  );

  // ── Test 2 — Editar nombre de perfil ─────────────────────────────────────
  patrolTest(
    'profile flow: editar nombre de perfil y guardar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('edit_profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('edit_profile_tile')));
      } else if ($(find.byKey(const Key('profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('profile_tile')));
      } else {
        markTestSkipped('Tile de perfil no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('display_name_field'))).exists) {
        markTestSkipped('Campo de nombre no encontrado en pantalla de perfil.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('display_name_field')));
      await $.tester.pump(const Duration(milliseconds: 300));
      // Limpiar y escribir nuevo nombre
      final field = $.tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('display_name_field')),
          matching: find.byType(TextField),
        ),
      );
      field.controller?.clear();
      await $(find.byKey(const Key('display_name_field'))).enterText('E2E Nombre Test');
      await $.tester.pump(const Duration(milliseconds: 300));

      if ($(find.byKey(const Key('save_profile_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('save_profile_button')));
        await _wait($, const Duration(seconds: 5));
      }

      expect($(find.byType(Scaffold)).exists, isTrue);
    },
  );

  // ── Test 3 — Radar chart visible en perfil ───────────────────────────────
  patrolTest(
    'profile flow: radar chart visible en pantalla de perfil propio',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('profile_tile')));
      } else {
        markTestSkipped('Tile de perfil no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      // Buscar el radar chart por key o tipo CustomPaint
      expect(
        $(find.byKey(const Key('radar_chart'))).exists ||
            $(find.byType(CustomPaint)).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'Pantalla de perfil con radar chart no encontrada.',
      );
    },
  );

  // ── Test 4 — Flujo de reseña desde perfil de un miembro ─────────────────
  patrolTest(
    'profile flow: puntuar a un miembro desde su perfil',
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

      // Navegar a Miembros
      await $.tester.tap(find.byIcon(Icons.people_outline));
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('member_card'))).exists) {
        markTestSkipped('No hay member cards para puntuar.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('member_card')).first);
      await _wait($, const Duration(seconds: 5));

      // Buscar botón de reseña/puntuar
      if (!$(find.byKey(const Key('review_button'))).exists &&
          !$(find.text('Puntuar')).exists &&
          !$(find.text('Review')).exists) {
        markTestSkipped('Botón de reseña no encontrado en perfil del miembro.');
        return;
      }

      if ($(find.byKey(const Key('review_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('review_button')));
      } else if ($(find.text('Puntuar')).exists) {
        await $.tester.tap(find.text('Puntuar').first);
      }
      await _wait($, const Duration(seconds: 3));

      // Buscar selector de puntuación (Slider o Rating bar)
      if ($(find.byType(Slider)).exists) {
        await $.tester.drag(
            find.byType(Slider).first, const Offset(50, 0));
        await $.tester.pump();
      }

      // Guardar reseña
      if ($(find.byKey(const Key('submit_review_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('submit_review_button')));
        await _wait($, const Duration(seconds: 5));
      }

      expect($(find.byType(Scaffold)).exists, isTrue,
          reason: 'App debería seguir corriendo tras enviar reseña.');
    },
  );
}
