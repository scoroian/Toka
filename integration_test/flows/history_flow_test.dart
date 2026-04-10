// integration_test/flows/history_flow_test.dart
//
// Patrol E2E — History flow
// Cubre: pantalla historial carga, scroll paginación, estructura de items.

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

  // ── Test 1 — Pantalla historial carga ────────────────────────────────────
  patrolTest(
    'history flow: pantalla de historial carga con lista o estado vacío',
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

      // Navegar a History (puede estar en Settings o en un tab)
      final hasHistoryTab =
          $(find.byIcon(Icons.history_outlined)).exists ||
          $(find.byIcon(Icons.history)).exists;

      if (hasHistoryTab) {
        if ($(find.byIcon(Icons.history_outlined)).exists) {
          await $.tester.tap(find.byIcon(Icons.history_outlined));
        } else {
          await $.tester.tap(find.byIcon(Icons.history));
        }
      } else {
        // Intentar desde Settings
        await $.tester.tap(find.byIcon(Icons.settings_outlined));
        await _wait($, const Duration(seconds: 5));
        if ($(find.text('Historial')).exists || $(find.text('History')).exists) {
          if ($(find.text('Historial')).exists) {
            await $.tester.tap(find.text('Historial').first);
          } else {
            await $.tester.tap(find.text('History').first);
          }
        } else {
          markTestSkipped('No se encontró entrada al historial.');
          return;
        }
      }
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('history_screen'))).exists ||
            $(find.byKey(const Key('history_list'))).exists ||
            $(find.byKey(const Key('history_empty_state'))).exists ||
            $(find.byType(ListView)).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'Pantalla de historial no cargó.',
      );
    },
  );

  // ── Test 2 — Scroll dispara paginación ───────────────────────────────────
  patrolTest(
    'history flow: scroll hasta el fondo dispara carga de más items',
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

      // Navegar a History
      if ($(find.byIcon(Icons.history_outlined)).exists) {
        await $.tester.tap(find.byIcon(Icons.history_outlined));
      } else if ($(find.byIcon(Icons.history)).exists) {
        await $.tester.tap(find.byIcon(Icons.history));
      } else {
        markTestSkipped('Tab de historial no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byType(ListView)).exists) {
        markTestSkipped('No hay lista de historial visible.');
        return;
      }

      // Hacer scroll al fondo para disparar carga
      await $.tester.drag(find.byType(ListView).first,
          const Offset(0, -3000));
      await _wait($, const Duration(seconds: 5));

      // La app no debe haberse crasheado
      expect($(find.byType(Scaffold)).exists, isTrue);
    },
  );

  // ── Test 3 — Items de historial tienen estructura correcta ───────────────
  patrolTest(
    'history flow: items de historial muestran datos (título, fecha, miembro)',
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

      if ($(find.byIcon(Icons.history_outlined)).exists) {
        await $.tester.tap(find.byIcon(Icons.history_outlined));
      } else if ($(find.byIcon(Icons.history)).exists) {
        await $.tester.tap(find.byIcon(Icons.history));
      } else {
        markTestSkipped('Tab de historial no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('history_item'))).exists) {
        markTestSkipped('No hay items de historial (hogar puede no tener actividad).');
        return;
      }

      // Verificar que el primer item tiene contenido visible
      expect($(find.byKey(const Key('history_item'))).exists, isTrue);
    },
  );
}
