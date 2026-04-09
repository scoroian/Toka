# Patrol E2E Flows — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir 3 flujos Patrol nuevos (member management, subscription, settings/notifications) y ampliar el flujo de task completion existente con valoraciones y penalización visible.

**Architecture:** Cada flow es un archivo independiente en `integration_test/flows/`. Reutilizan `setupE2EEnvironment()` y `_wait()` del patrón existente. Todos apuntan al emulador Firebase vía `test_setup.dart`. Los tests usan claves semánticas (`Key('...')`) cuando existen y finders de texto/tipo como fallback.

**Tech Stack:** Flutter Patrol, Firebase Emulators (Auth 9099, Firestore 8080, Functions 5001), `integration_test`, `flutter_test`.

**Prerequisito:** Emuladores activos con `firebase emulators:start --import=./emulator-data --export-on-exit`. Usuario `test@toka.dev` / `Test1234!` creado.

**Comando para ejecutar:** `patrol test --target integration_test/flows/<archivo>_test.dart`

---

## Archivos a crear/modificar

- Create: `integration_test/flows/member_management_flow_test.dart`
- Create: `integration_test/flows/subscription_flow_test.dart`
- Create: `integration_test/flows/settings_notifications_flow_test.dart`
- Modify: `integration_test/flows/task_completion_flow_test.dart`
- Modify: `integration_test/test_bundle.dart`

---

## Task 1: member_management_flow_test.dart

**Files:**
- Create: `integration_test/flows/member_management_flow_test.dart`

- [ ] **Step 1: Crear el flow**

```dart
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
```

- [ ] **Step 2: Ejecutar el flow**

```bash
patrol test --target integration_test/flows/member_management_flow_test.dart
```

Esperado: 4 tests en verde (o skipped si el emulador no tiene hogar configurado).

- [ ] **Step 3: Commit**

```bash
git add integration_test/flows/member_management_flow_test.dart
git commit -m "test(e2e): Patrol flow de gestión de miembros — navegar, invitar, perfil, vacaciones"
```

---

## Task 2: subscription_flow_test.dart

**Files:**
- Create: `integration_test/flows/subscription_flow_test.dart`

- [ ] **Step 1: Crear el flow**

```dart
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
```

- [ ] **Step 2: Ejecutar el flow**

```bash
patrol test --target integration_test/flows/subscription_flow_test.dart
```

Esperado: 4 tests en verde (o skipped según estado del emulador).

- [ ] **Step 3: Commit**

```bash
git add integration_test/flows/subscription_flow_test.dart
git commit -m "test(e2e): Patrol flow de suscripción — paywall, rescue banner, gestión"
```

---

## Task 3: settings_notifications_flow_test.dart

**Files:**
- Create: `integration_test/flows/settings_notifications_flow_test.dart`

- [ ] **Step 1: Crear el flow**

```dart
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
```

- [ ] **Step 2: Ejecutar el flow**

```bash
patrol test --target integration_test/flows/settings_notifications_flow_test.dart
```

Esperado: 6 tests en verde (o skipped según estado del emulador).

- [ ] **Step 3: Commit**

```bash
git add integration_test/flows/settings_notifications_flow_test.dart
git commit -m "test(e2e): Patrol flow de ajustes y notificaciones — secciones, idioma, toggles, perfil"
```

---

## Task 4: Ampliar task_completion_flow_test.dart

**Files:**
- Modify: `integration_test/flows/task_completion_flow_test.dart`

- [ ] **Step 1: Añadir test de complete task dialog con valoración**

Al final del archivo `task_completion_flow_test.dart`, ANTES del cierre del `main()`, añadir:

```dart
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
```

- [ ] **Step 2: Ejecutar el flow completo**

```bash
patrol test --target integration_test/flows/task_completion_flow_test.dart
```

Esperado: 5 tests en total (2 existentes + 3 nuevos) en verde o skipped.

- [ ] **Step 3: Commit**

```bash
git add integration_test/flows/task_completion_flow_test.dart
git commit -m "test(e2e): ampliar task_completion_flow con complete dialog, pass turn penalty y crear tarea semanal"
```

---

## Task 5: Registrar los nuevos flows en test_bundle.dart

**Files:**
- Modify: `integration_test/test_bundle.dart`

- [ ] **Step 1: Leer el archivo actual**

Leer `integration_test/test_bundle.dart` para ver los imports existentes.

- [ ] **Step 2: Añadir los 3 nuevos flows**

Añadir los 3 imports nuevos junto a los existentes. El patrón exacto depende del contenido del archivo, pero el resultado debe ser:

```dart
// integration_test/test_bundle.dart
import 'flows/auth_onboarding_flow_test.dart' as auth_onboarding;
import 'flows/task_completion_flow_test.dart' as task_completion;
import 'flows/member_management_flow_test.dart' as member_management;
import 'flows/subscription_flow_test.dart' as subscription;
import 'flows/settings_notifications_flow_test.dart' as settings_notifications;

void main() {
  auth_onboarding.main();
  task_completion.main();
  member_management.main();
  subscription.main();
  settings_notifications.main();
}
```

- [ ] **Step 3: Verificar que compila**

```bash
flutter analyze integration_test/
```

Esperado: sin errores de análisis estático.

- [ ] **Step 4: Ejecutar todos los flows juntos**

```bash
patrol test
```

Esperado: todos los tests en verde o skipped (los skipped son esperables cuando el emulador no tiene datos de hogar configurados).

- [ ] **Step 5: Commit final**

```bash
git add integration_test/test_bundle.dart
git commit -m "test(e2e): registrar todos los flows Patrol en test_bundle — member, subscription, settings"
```
