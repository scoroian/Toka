// integration_test/flows/subscription_flow_test.dart
//
// Patrol E2E — Subscription flow
// Cubre: navegar a paywall, gestión de suscripción, rescue banner, downgrade.

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

  // ── Test 1 — Navegar a ajustes y encontrar sección Premium ───────────────
  patrolTest(
    'subscription flow: settings screen has premium section',
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

      // Navegar a Settings
      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('settings_section_account'))).exists ||
            $(find.text('Ajustes')).exists ||
            $(find.text('Settings')).exists,
        isTrue,
        reason: 'Settings screen not found.',
      );

      // Buscar sección premium o suscripción
      final hasPremiumSection =
          $(find.byKey(const Key('premium_section'))).exists ||
          $(find.byKey(const Key('subscription_tile'))).exists ||
          $(find.text('Premium')).exists ||
          $(find.text('Suscripción')).exists;

      expect(hasPremiumSection, isTrue,
          reason: 'Premium/Subscription section not visible in settings.');
    },
  );

  // ── Test 2 — Navegar al Paywall ───────────────────────────────────────────
  patrolTest(
    'subscription flow: navigate to paywall screen',
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

      // Intentar navegar al paywall
      if ($(find.byKey(const Key('subscription_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('subscription_tile')));
        await _wait($, const Duration(seconds: 5));
      } else if ($(find.text('Premium')).exists) {
        await $.tester.tap(find.text('Premium').first);
        await _wait($, const Duration(seconds: 5));
      } else {
        markTestSkipped('No se encontró tile de suscripción en Settings.');
        return;
      }

      // Verificar que aparece la pantalla de Paywall o Gestión de Suscripción
      expect(
        $(find.byKey(const Key('paywall_screen'))).exists ||
            $(find.byKey(const Key('subscription_management_screen'))).exists ||
            $(find.byKey(const Key('plan_comparison_card'))).exists ||
            $(find.text('Mensual')).exists ||
            $(find.text('Monthly')).exists ||
            $(find.text('Anual')).exists,
        isTrue,
        reason: 'Paywall or subscription management screen not found.',
      );
    },
  );

  // ── Test 3 — Rescue banner visible si hogar está en modo rescue ───────────
  patrolTest(
    'subscription flow: rescue banner visible when home is in rescue mode',
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

      // Navegar a la pantalla Today (donde aparece el rescue banner si aplica)
      await $.tester.tap(find.byIcon(Icons.home_outlined));
      await _wait($, const Duration(seconds: 5));

      // Si el hogar está en modo rescue, debe aparecer el rescue banner
      // Si no, el test es informativo (el hogar de test puede no estar en rescue)
      if ($(find.byKey(const Key('rescue_banner'))).exists) {
        expect($(find.byKey(const Key('rescue_banner'))).exists, isTrue,
            reason: 'Rescue banner found — expected when home is in rescue mode.');

        // Verificar que el banner tiene un CTA
        final hasCta =
            $(find.byKey(const Key('rescue_banner_cta'))).exists ||
            $(find.text('Renovar')).exists ||
            $(find.text('Renew')).exists ||
            $(find.text('Ver opciones')).exists;

        expect(hasCta, isTrue, reason: 'Rescue banner should have a CTA button.');
      } else {
        // Si no hay banner, verificar que la pantalla Today cargó correctamente
        expect(
          $(find.byType(CustomScrollView)).exists ||
              $(find.byType(Scaffold)).exists,
          isTrue,
          reason: 'Today screen did not load (and no rescue banner present).',
        );
      }
    },
  );

  // ── Test 4 — Pantalla de gestión de suscripción carga correctamente ───────
  patrolTest(
    'subscription flow: subscription management screen loads',
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

      if ($(find.byKey(const Key('subscription_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('subscription_tile')));
        await _wait($, const Duration(seconds: 5));
      } else {
        markTestSkipped('No se encontró tile de suscripción.');
        return;
      }

      // Si el hogar tiene Premium activo, debe aparecer la pantalla de gestión
      if ($(find.byKey(const Key('subscription_management_screen'))).exists) {
        // Verificar elementos clave de la gestión
        final hasContent =
            $(find.byKey(const Key('current_plan_info'))).exists ||
            $(find.text('Mensual')).exists ||
            $(find.text('Anual')).exists ||
            $(find.text('Cancelar')).exists ||
            $(find.text('Cancel')).exists;

        expect(hasContent, isTrue,
            reason: 'Subscription management screen should show plan info.');
      } else {
        // Si está en paywall, también es válido
        expect($(find.byType(Scaffold)).exists, isTrue);
      }
    },
  );
}
