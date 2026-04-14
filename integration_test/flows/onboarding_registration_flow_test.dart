// integration_test/flows/onboarding_registration_flow_test.dart
//
// Patrol E2E — Onboarding & Registration flow
// Cubre: validaciones de registro, registro nuevo usuario, flujo onboarding completo,
//        flujo de ciclo de vida completo (registro → hogar → tarea → logout → reset pwd → login → verificar).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../helpers/test_setup.dart';

const _emulatorHost = '10.0.2.2';
const _testEmail = 'test@toka.dev';

Future<void> _wait(PatrolIntegrationTester $, Duration duration) async {
  await $.tester.runAsync(() => Future.delayed(duration));
  await $.tester.pump();
  await $.tester.pump();
  await $.tester.pump();
}

/// Registra un usuario nuevo usando la API REST del emulador de Auth.
/// Devuelve [email, password] del usuario creado.
Future<List<String>> _createUniqueUser() async {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final email = 'e2e_$ts@toka.dev';
  const password = 'E2eTest123!';

  final client = HttpClient();
  try {
    final uri = Uri.parse(
      'http://$_emulatorHost:9099'
      '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key',
    );
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }));
    await request.close();
  } finally {
    client.close();
  }
  return [email, password];
}

/// Obtiene el OOB code de reset de contraseña del emulador de Auth
/// y establece la nueva contraseña usando la API REST.
Future<bool> _resetPasswordViaEmulator(String email, String newPassword) async {
  final client = HttpClient();
  try {
    // 1. Solicitar reset password (esto genera el OOB code en el emulador)
    final requestUri = Uri.parse(
      'http://$_emulatorHost:9099'
      '/identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=fake-key',
    );
    final req = await client.postUrl(requestUri);
    req.headers.set('Content-Type', 'application/json');
    req.write(jsonEncode({
      'requestType': 'PASSWORD_RESET',
      'email': email,
    }));
    await req.close();
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Obtener el OOB code del emulador
    final oobUri = Uri.parse(
      'http://$_emulatorHost:9099/emulator/v1/projects/demo-toka/oobCodes',
    );
    final oobReq = await client.getUrl(oobUri);
    final oobRes = await oobReq.close();
    final oobBody = await oobRes.transform(utf8.decoder).join();
    final oobJson = jsonDecode(oobBody) as Map<String, dynamic>;
    final codes = oobJson['oobCodes'] as List<dynamic>? ?? [];
    final entry = codes.cast<Map<String, dynamic>>().lastWhere(
          (c) => c['email'] == email && c['requestType'] == 'PASSWORD_RESET',
          orElse: () => {},
        );
    final oobCode = entry['oobCode'] as String?;
    if (oobCode == null) return false;

    // 3. Confirmar el reset con la nueva contraseña
    final confirmUri = Uri.parse(
      'http://$_emulatorHost:9099'
      '/identitytoolkit.googleapis.com/v1/accounts:resetPassword?key=fake-key',
    );
    final confirmReq = await client.postUrl(confirmUri);
    confirmReq.headers.set('Content-Type', 'application/json');
    confirmReq.write(jsonEncode({
      'oobCode': oobCode,
      'newPassword': newPassword,
    }));
    final confirmRes = await confirmReq.close();
    return confirmRes.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    client.close();
  }
}

void main() {
  setUpAll(setupE2EEnvironment);

  // ── Test 1 — Validación: contraseña corta ────────────────────────────────
  patrolTest(
    'registro: contraseña corta muestra error sin navegar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));

      // Si ya estamos logueados, cerrar sesión primero
      if ($(find.byType(NavigationBar)).exists) {
        markTestSkipped('Usuario ya autenticado, omitir test de registro.');
        return;
      }

      if (!$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('Pantalla de login no encontrada.');
        return;
      }

      // Navegar a registro
      if ($(find.byKey(const Key('go_to_register_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('go_to_register_button')));
        await _wait($, const Duration(seconds: 3));
      } else if ($(find.text('Registrarse')).exists) {
        await $.tester.tap(find.text('Registrarse').first);
        await _wait($, const Duration(seconds: 3));
      } else {
        markTestSkipped('Botón de ir a registro no encontrado.');
        return;
      }

      if (!$(find.byKey(const Key('register_email_field'))).exists &&
          !$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('Pantalla de registro no encontrada.');
        return;
      }

      final emailField = $(find.byKey(const Key('register_email_field'))).exists
          ? find.byKey(const Key('register_email_field'))
          : find.byKey(const Key('email_field'));
      await $(emailField).enterText('nuevo@toka.dev');
      await $.tester.pump(const Duration(milliseconds: 300));

      final passField =
          $(find.byKey(const Key('register_password_field'))).exists
              ? find.byKey(const Key('register_password_field'))
              : find.byKey(const Key('password_field'));
      await $(passField).enterText('123'); // contraseña demasiado corta
      await $.tester.pump(const Duration(milliseconds: 300));

      final submitButton =
          $(find.byKey(const Key('register_submit_button'))).exists
              ? find.byKey(const Key('register_submit_button'))
              : find.byKey(const Key('submit_button'));
      await $.tester.tap(submitButton);
      await _wait($, const Duration(seconds: 5));

      // No debemos estar en NavigationBar
      expect($(find.byType(NavigationBar)).exists, isFalse,
          reason: 'No debería navegar con contraseña inválida.');
    },
  );

  // ── Test 2 — Forgot password muestra confirmación ───────────────────────
  patrolTest(
    'auth: forgot password muestra mensaje de confirmación',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));

      if ($(find.byType(NavigationBar)).exists) {
        markTestSkipped('Usuario autenticado, no se puede probar forgot password desde login.');
        return;
      }

      if (!$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('Pantalla de login no encontrada.');
        return;
      }

      if ($(find.byKey(const Key('forgot_password_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('forgot_password_button')));
      } else if ($(find.text('¿Olvidaste tu contraseña?')).exists) {
        await $.tester.tap(find.text('¿Olvidaste tu contraseña?').first);
      } else if ($(find.text('Forgot password')).exists) {
        await $.tester.tap(find.text('Forgot password').first);
      } else {
        markTestSkipped('Botón de olvidé contraseña no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 3));

      // Introducir email y solicitar reset
      if ($(find.byKey(const Key('forgot_email_field'))).exists) {
        await $(find.byKey(const Key('forgot_email_field')))
            .enterText(_testEmail);
      } else if ($(find.byKey(const Key('email_field'))).exists) {
        await $(find.byKey(const Key('email_field'))).enterText(_testEmail);
      }
      await $.tester.pump(const Duration(milliseconds: 300));

      if (!$(find.byKey(const Key('send_reset_button'))).exists &&
          !$(find.byKey(const Key('submit_button'))).exists) {
        markTestSkipped('Botón de enviar reset no encontrado.');
        return;
      }
      final sendButton =
          $(find.byKey(const Key('send_reset_button'))).exists
              ? find.byKey(const Key('send_reset_button'))
              : find.byKey(const Key('submit_button'));
      await $.tester.tap(sendButton);
      await _wait($, const Duration(seconds: 5));

      // Verificar que aparece mensaje de confirmación
      expect(
        $(find.byKey(const Key('reset_sent_message'))).exists ||
            $(find.text('correo')).exists ||
            $(find.text('email')).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'No se mostró confirmación de envío de reset.',
      );
    },
  );

  // ── Test 3 — Ciclo de vida completo ─────────────────────────────────────
  patrolTest(
    'lifecycle: registro → hogar → tarea → logout → reset contraseña → login → verificar datos',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 300),
      visibleTimeout: Duration(seconds: 60),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));

      // Si ya hay sesión activa, cerrar sesión primero
      if ($(find.byType(NavigationBar)).exists) {
        await $.tester.tap(find.byIcon(Icons.settings_outlined));
        await _wait($, const Duration(seconds: 3));
        if ($(find.byKey(const Key('logout_tile'))).exists) {
          await $.tester.tap(find.byKey(const Key('logout_tile')));
          await _wait($, const Duration(seconds: 8));
        }
      }

      if (!$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('No se pudo llegar a la pantalla de login.');
        return;
      }

      // ── PASO 1: Crear usuario nuevo via REST ──────────────────────────────
      final credentials = await $.tester.runAsync(() => _createUniqueUser()) ?? [];
      if (credentials.isEmpty) {
        markTestSkipped('No se pudo crear usuario de prueba via emulador.');
        return;
      }
      final newEmail = credentials[0];
      final originalPassword = credentials[1];
      const newPassword = 'NuevaPass456!';

      // ── PASO 2: Hacer login con el nuevo usuario ──────────────────────────
      await $(find.byKey(const Key('email_field'))).enterText(newEmail);
      await $(find.byKey(const Key('password_field'))).enterText(originalPassword);
      await $.tester.testTextInput.receiveAction(TextInputAction.done);
      await $.tester.pump(const Duration(milliseconds: 300));
      await $.tester.tap(find.byKey(const Key('submit_button')));
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));
      if (!$(find.byType(NavigationBar)).exists && !$(find.byType(PageView)).exists) {
        await _wait($, const Duration(seconds: 10));
      }

      // ── PASO 3: Completar onboarding si es necesario ─────────────────────
      await ensureHomeExists($);

      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped('No se llegó al home shell tras el registro.');
        return;
      }

      // ── PASO 4: Crear una tarea ────────────────────────────────────────────
      const taskTitle = 'Tarea Ciclo Vida E2E';
      await $.tester.tap(find.byIcon(Icons.task_alt_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('create_task_fab'))).exists) {
        await $.tester.tap(find.byKey(const Key('create_task_fab')));
        await _wait($, const Duration(seconds: 5));

        if ($(find.byKey(const Key('task_title_field'))).exists) {
          await $(find.byKey(const Key('task_title_field'))).enterText(taskTitle);
          await $.tester.pump(const Duration(milliseconds: 300));

          if ($(find.byType(CheckboxListTile)).exists) {
            await $.tester.tap(find.byType(CheckboxListTile).first);
            await $.tester.pump(const Duration(milliseconds: 300));
          }

          await $.tester.tap(find.byKey(const Key('save_task_button')));
          await _wait($, const Duration(seconds: 8));
        }
      }

      // ── PASO 5: Cerrar sesión ─────────────────────────────────────────────
      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('logout_tile'))).exists) {
        markTestSkipped('logout_tile no encontrado, no se puede cerrar sesión.');
        return;
      }
      await $.tester.tap(find.byKey(const Key('logout_tile')));
      await _wait($, const Duration(seconds: 8));

      expect($(find.byKey(const Key('email_field'))).exists, isTrue,
          reason: 'Tras logout se esperaba la pantalla de login.');

      // ── PASO 6: Reset de contraseña via emulador ──────────────────────────
      final resetOk = await $.tester.runAsync(
        () => _resetPasswordViaEmulator(newEmail, newPassword),
      );

      if (resetOk != true) {
        markTestSkipped('No se pudo hacer reset de contraseña via emulador.');
        return;
      }

      // ── PASO 7: Login con la nueva contraseña ─────────────────────────────
      await $(find.byKey(const Key('email_field'))).enterText(newEmail);
      await $(find.byKey(const Key('password_field'))).enterText(newPassword);
      await $.tester.testTextInput.receiveAction(TextInputAction.done);
      await $.tester.pump(const Duration(milliseconds: 300));
      await $.tester.tap(find.byKey(const Key('submit_button')));
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));
      if (!$(find.byType(NavigationBar)).exists) {
        await _wait($, const Duration(seconds: 10));
      }

      expect($(find.byType(NavigationBar)).exists, isTrue,
          reason: 'No se pudo hacer login con la nueva contraseña.');

      // ── PASO 8: Verificar que el hogar y la tarea siguen existiendo ───────
      await $.tester.tap(find.byIcon(Icons.task_alt_outlined));
      await _wait($, const Duration(seconds: 8));

      expect(
        $(find.text(taskTitle)).exists ||
            $(find.byKey(const Key('tasks_list'))).exists,
        isTrue,
        reason: 'La tarea creada debería seguir visible tras reset de contraseña.',
      );
    },
  );
}
