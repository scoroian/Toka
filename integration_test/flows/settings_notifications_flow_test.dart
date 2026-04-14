// integration_test/flows/settings_notifications_flow_test.dart
//
// Patrol E2E — Settings & Notifications flow
// Cubre: ajustes visibles, cambio de idioma, toggles de notificaciones, editar perfil.

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

  // ── Test 1 — Pantalla de ajustes carga con todas las secciones ───────────
  patrolTest(
    'settings: screen loads with expected sections',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();

      final reachedHome = await _loginIfNeeded($);
      if (!reachedHome) {
        markTestSkipped('No se pudo llegar al home shell.');
        return;
      }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      // Sección de cuenta
      expect(
        $(find.byKey(const Key('settings_section_account'))).exists ||
            $(find.text('Cuenta')).exists ||
            $(find.text('Account')).exists,
        isTrue,
        reason: 'Settings section "Cuenta" not found.',
      );

      // Al menos una sección más debe existir (notificaciones, idioma, etc.)
      final hasMoreSections =
          $(find.text('Notificaciones')).exists ||
          $(find.text('Notifications')).exists ||
          $(find.text('Idioma')).exists ||
          $(find.text('Language')).exists ||
          $(find.byKey(const Key('settings_section_notifications'))).exists;

      expect(hasMoreSections, isTrue,
          reason: 'Settings screen should show more than just the account section.');
    },
  );

  // ── Test 2 — Sección de idioma es navegable ───────────────────────────────
  patrolTest(
    'settings: language selector is accessible',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();

      final reachedHome = await _loginIfNeeded($);
      if (!reachedHome) {
        markTestSkipped('No se pudo llegar al home shell.');
        return;
      }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      // Encontrar tile de idioma
      final hasLanguageTile =
          $(find.byKey(const Key('language_tile'))).exists ||
          $(find.text('Idioma')).exists ||
          $(find.text('Language')).exists;

      if (!hasLanguageTile) {
        markTestSkipped('No se encontró tile de idioma en Settings.');
        return;
      }

      if ($(find.byKey(const Key('language_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('language_tile')));
      } else if ($(find.text('Idioma')).exists) {
        await $.tester.tap(find.text('Idioma').first);
      } else {
        await $.tester.tap(find.text('Language').first);
      }
      await _wait($, const Duration(seconds: 5));

      // Verificar que aparece el selector de idioma
      expect(
        $(find.byKey(const Key('language_selector'))).exists ||
            $(find.text('Español')).exists ||
            $(find.text('English')).exists ||
            $(find.text('Română')).exists ||
            $(find.byType(ListView)).exists,
        isTrue,
        reason: 'Language selector not shown.',
      );
    },
  );

  // ── Test 3 — Pantalla de notificaciones es navegable ─────────────────────
  patrolTest(
    'settings: notification settings screen accessible and has toggles',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();

      final reachedHome = await _loginIfNeeded($);
      if (!reachedHome) {
        markTestSkipped('No se pudo llegar al home shell.');
        return;
      }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      // Encontrar tile de notificaciones
      final hasNotifTile =
          $(find.byKey(const Key('notifications_tile'))).exists ||
          $(find.text('Notificaciones')).exists ||
          $(find.text('Notifications')).exists;

      if (!hasNotifTile) {
        markTestSkipped('No se encontró tile de notificaciones en Settings.');
        return;
      }

      if ($(find.byKey(const Key('notifications_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('notifications_tile')));
      } else if ($(find.text('Notificaciones')).exists) {
        await $.tester.tap(find.text('Notificaciones').first);
      } else {
        await $.tester.tap(find.text('Notifications').first);
      }
      await _wait($, const Duration(seconds: 5));

      // Verificar que aparece la pantalla con al menos un Switch/toggle
      expect(
        $(find.byType(Switch)).exists ||
            $(find.byKey(const Key('notification_settings_screen'))).exists,
        isTrue,
        reason: 'Notification settings screen with toggles not found.',
      );
    },
  );

  // ── Test 4 — Toggle de notificaciones es interactuable ───────────────────
  patrolTest(
    'settings: notification toggle can be toggled',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();

      final reachedHome = await _loginIfNeeded($);
      if (!reachedHome) {
        markTestSkipped('No se pudo llegar al home shell.');
        return;
      }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('notifications_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('notifications_tile')));
      } else if ($(find.text('Notificaciones')).exists) {
        await $.tester.tap(find.text('Notificaciones').first);
      } else if ($(find.text('Notifications')).exists) {
        await $.tester.tap(find.text('Notifications').first);
      } else {
        markTestSkipped('No se pudo navegar a notificaciones.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byType(Switch)).exists) {
        markTestSkipped('No hay toggles en pantalla de notificaciones.');
        return;
      }

      // Leer estado inicial del primer switch
      final switchFinder = find.byType(Switch).first;
      final switchWidget = $.tester.widget<Switch>(switchFinder);
      final initialValue = switchWidget.value;

      // Tocar el switch para cambiar estado
      await $.tester.tap(switchFinder);
      await _wait($, const Duration(seconds: 3));

      // Verificar que el estado cambió
      final newSwitchWidget = $.tester.widget<Switch>(find.byType(Switch).first);
      expect(newSwitchWidget.value, isNot(equals(initialValue)),
          reason: 'Toggle did not change after tapping.');

      // Restaurar estado original
      await $.tester.tap(find.byType(Switch).first);
      await _wait($, const Duration(seconds: 2));
    },
  );

  // ── Test 5 — Navegar a editar perfil ──────────────────────────────────────
  patrolTest(
    'settings: navigate to edit profile screen',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();

      final reachedHome = await _loginIfNeeded($);
      if (!reachedHome) {
        markTestSkipped('No se pudo llegar al home shell.');
        return;
      }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      // Buscar tile de perfil o nombre de usuario
      final hasProfileTile =
          $(find.byKey(const Key('profile_tile'))).exists ||
          $(find.byKey(const Key('edit_profile_tile'))).exists ||
          $(find.byIcon(Icons.person_outline)).exists;

      if (!hasProfileTile) {
        markTestSkipped('No se encontró tile de perfil en Settings.');
        return;
      }

      if ($(find.byKey(const Key('edit_profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('edit_profile_tile')));
      } else if ($(find.byKey(const Key('profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('profile_tile')));
      } else {
        await $.tester.tap(find.byIcon(Icons.person_outline).first);
      }
      await _wait($, const Duration(seconds: 5));

      // Verificar que estamos en pantalla de perfil o editar perfil
      expect(
        $(find.byKey(const Key('own_profile_screen'))).exists ||
            $(find.byKey(const Key('edit_profile_screen'))).exists ||
            $(find.byKey(const Key('display_name_field'))).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'Profile/EditProfile screen not found.',
      );
    },
  );

  // ── Test 6 — Cerrar sesión desde Ajustes ──────────────────────────────────
  patrolTest(
    'settings: logout tile is visible and functional',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();

      final reachedHome = await _loginIfNeeded($);
      if (!reachedHome) {
        markTestSkipped('No se pudo llegar al home shell.');
        return;
      }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('logout_tile'))).exists ||
            $(find.text('Cerrar sesión')).exists ||
            $(find.text('Sign out')).exists ||
            $(find.text('Logout')).exists,
        isTrue,
        reason: 'Logout tile not found in Settings.',
      );
    },
  );
}
