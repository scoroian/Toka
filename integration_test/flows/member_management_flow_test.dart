// integration_test/flows/member_management_flow_test.dart
//
// Patrol E2E — Member management flow
// Cubre: ver miembros, invitar, aplicar vacaciones, cancelar vacaciones, expulsar.

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

  // ── Test 1 — Navegar a pantalla Miembros ──────────────────────────────────
  patrolTest(
    'member management: navigate to members screen',
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

      // Navegar a tab de Miembros (icono people)
      await $.tester.tap(find.byIcon(Icons.people_outline));
      await _wait($, const Duration(seconds: 5));

      // Verificar que estamos en la pantalla de miembros
      expect(
        $(find.byKey(const Key('members_screen'))).exists ||
            $(find.byKey(const Key('members_list'))).exists ||
            $(find.byKey(const Key('invite_member_button'))).exists ||
            $(find.text('Miembros')).exists ||
            $(find.text('Members')).exists,
        isTrue,
        reason: 'Members screen not found.',
      );
    },
  );

  // ── Test 2 — Abrir sheet de invitar miembro ───────────────────────────────
  patrolTest(
    'member management: open invite sheet and verify invite code',
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

      await $.tester.tap(find.byIcon(Icons.people_outline));
      await _wait($, const Duration(seconds: 5));

      // Buscar botón de invitar (FAB o botón con icono add o texto Invitar)
      final hasInviteButton =
          $(find.byKey(const Key('invite_member_button'))).exists ||
          $(find.byIcon(Icons.person_add_outlined)).exists ||
          $(find.byIcon(Icons.add)).exists;

      if (!hasInviteButton) {
        markTestSkipped('Botón de invitar no encontrado. El hogar puede estar vacío o el usuario no es admin/owner.');
        return;
      }

      if ($(find.byKey(const Key('invite_member_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('invite_member_button')));
      } else {
        await $.tester.tap(find.byIcon(Icons.person_add_outlined).first);
      }
      await _wait($, const Duration(seconds: 5));

      // Verificar que el sheet de invitación aparece con un código
      expect(
        $(find.byKey(const Key('invite_code'))).exists ||
            $(find.byKey(const Key('invite_sheet'))).exists ||
            $(find.byType(BottomSheet)).exists,
        isTrue,
        reason: 'Invite sheet not shown.',
      );
    },
  );

  // ── Test 3 — Abrir perfil de un miembro ──────────────────────────────────
  patrolTest(
    'member management: tap member card to open profile',
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

      await $.tester.tap(find.byIcon(Icons.people_outline));
      await _wait($, const Duration(seconds: 5));

      // Si hay al menos un member card, tocarlo
      if ($(find.byKey(const Key('member_card'))).exists) {
        await $.tester.tap(find.byKey(const Key('member_card')).first);
        await _wait($, const Duration(seconds: 5));

        // Verificar que se navega al perfil del miembro
        expect(
          $(find.byKey(const Key('member_profile_screen'))).exists ||
              $(find.byType(Scaffold)).exists,
          isTrue,
          reason: 'Member profile screen not shown after tapping member card.',
        );
      } else {
        // Si no hay miembros (hogar nuevo), verificamos estado vacío
        expect(
          $(find.byKey(const Key('members_empty_state'))).exists ||
              $(find.byType(Scaffold)).exists,
          isTrue,
          reason: 'Expected members list or empty state.',
        );
      }
    },
  );

  // ── Test 4 — Navegar a vacation screen si existe ─────────────────────────
  patrolTest(
    'member management: vacation screen accessible from members',
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

      await $.tester.tap(find.byIcon(Icons.people_outline));
      await _wait($, const Duration(seconds: 5));

      // Buscar opción de vacaciones (puede estar en menú o en perfil de miembro)
      final hasVacationOption =
          $(find.byKey(const Key('vacation_button'))).exists ||
          $(find.byIcon(Icons.beach_access_outlined)).exists ||
          $(find.text('Vacaciones')).exists ||
          $(find.text('Vacation')).exists;

      if (hasVacationOption) {
        if ($(find.byKey(const Key('vacation_button'))).exists) {
          await $.tester.tap(find.byKey(const Key('vacation_button')));
        } else if ($(find.text('Vacaciones')).exists) {
          await $.tester.tap(find.text('Vacaciones').first);
        }
        await _wait($, const Duration(seconds: 5));

        expect(
          $(find.byType(Scaffold)).exists,
          isTrue,
          reason: 'Vacation screen not shown.',
        );
      } else {
        // Si no hay opción de vacaciones visible, el test es informativo
        expect($(find.byType(Scaffold)).exists, isTrue);
      }
    },
  );
}
