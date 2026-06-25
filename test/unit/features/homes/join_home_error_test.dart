import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/errors/exceptions.dart';
import 'package:toka/features/homes/application/join_home_error.dart';
import 'package:toka/features/homes/application/join_home_error_messages.dart';
import 'package:toka/l10n/app_localizations_en.dart';
import 'package:toka/l10n/app_localizations_es.dart';

FirebaseFunctionsException _ffe(String code, [String message = '']) =>
    FirebaseFunctionsException(code: code, message: message);

void main() {
  group('mapJoinHomeException — code específico → excepción de dominio', () {
    test('not-found → InvalidInviteCodeException', () {
      expect(mapJoinHomeException(_ffe('not-found', 'Invalid invite code')),
          isA<InvalidInviteCodeException>());
    });

    test('deadline-exceeded → ExpiredInviteCodeException', () {
      expect(mapJoinHomeException(_ffe('deadline-exceeded', 'expired')),
          isA<ExpiredInviteCodeException>());
    });

    test('resource-exhausted + no-account-slots → NoAccountSlotsException', () {
      expect(mapJoinHomeException(_ffe('resource-exhausted', 'no-account-slots')),
          isA<NoAccountSlotsException>());
    });

    test('resource-exhausted + too-many-join-attempts → TooManyAttemptsException',
        () {
      expect(
          mapJoinHomeException(
              _ffe('resource-exhausted', 'too-many-join-attempts')),
          isA<TooManyAttemptsException>());
    });

    test('resource-exhausted sin mensaje reconocible → TooManyAttemptsException',
        () {
      // El rate-limit es el único resource-exhausted que NO es no-account-slots.
      expect(mapJoinHomeException(_ffe('resource-exhausted')),
          isA<TooManyAttemptsException>());
    });

    test('failed-precondition + free_limit_members → MaxMembersReachedException',
        () {
      expect(
          mapJoinHomeException(_ffe('failed-precondition', 'free_limit_members')),
          isA<MaxMembersReachedException>());
    });

    test(
        'failed-precondition con otro mensaje NO se mapea a "hogar lleno" '
        '(devuelve el FFE crudo, no miente)', () {
      final e = _ffe('failed-precondition', 'some-other-precondition');
      expect(mapJoinHomeException(e), same(e));
    });

    test('code desconocido devuelve el FFE crudo (caller hace rethrow)', () {
      final e = _ffe('internal', 'boom');
      expect(mapJoinHomeException(e), same(e));
    });
  });

  group('classifyJoinHomeError — excepción → motivo canónico', () {
    test('excepciones de dominio tipadas', () {
      expect(classifyJoinHomeError(const InvalidInviteCodeException()),
          JoinHomeError.invalidCode);
      expect(classifyJoinHomeError(const ExpiredInviteCodeException()),
          JoinHomeError.expiredCode);
      expect(classifyJoinHomeError(const MaxMembersReachedException()),
          JoinHomeError.homeFull);
      expect(classifyJoinHomeError(const NoAccountSlotsException()),
          JoinHomeError.noAccountSlots);
      expect(classifyJoinHomeError(const TooManyAttemptsException()),
          JoinHomeError.tooManyAttempts);
    });

    test('SocketException → network', () {
      expect(classifyJoinHomeError(const SocketException('offline')),
          JoinHomeError.network);
    });

    test('FFE crudo (red de seguridad) se clasifica por code', () {
      expect(classifyJoinHomeError(_ffe('not-found')), JoinHomeError.invalidCode);
      expect(classifyJoinHomeError(_ffe('deadline-exceeded')),
          JoinHomeError.expiredCode);
      expect(classifyJoinHomeError(_ffe('resource-exhausted', 'no-account-slots')),
          JoinHomeError.noAccountSlots);
      expect(
          classifyJoinHomeError(
              _ffe('resource-exhausted', 'too-many-join-attempts')),
          JoinHomeError.tooManyAttempts);
      expect(
          classifyJoinHomeError(_ffe('failed-precondition', 'free_limit_members')),
          JoinHomeError.homeFull);
      expect(classifyJoinHomeError(_ffe('permission-denied')),
          JoinHomeError.permissionDenied);
    });

    test('FFE de code desconocido → unexpected', () {
      expect(classifyJoinHomeError(_ffe('internal')), JoinHomeError.unexpected);
    });

    test('error genérico → unexpected', () {
      expect(classifyJoinHomeError(Exception('boom')), JoinHomeError.unexpected);
    });
  });

  group('joinHomeErrorMessage — fuente de verdad única de textos', () {
    final es = AppLocalizationsEs();
    final en = AppLocalizationsEn();

    test('cada motivo conocido tiene un texto propio (ninguno cae al genérico)',
        () {
      for (final reason in JoinHomeError.values) {
        if (reason == JoinHomeError.unexpected) continue;
        final msg = joinHomeErrorMessage(reason, es);
        expect(msg, isNotEmpty);
        expect(msg, isNot(es.error_generic),
            reason: '$reason no debe mostrar "Algo salió mal"');
      }
    });

    test('mapea cada motivo a su clave join_error_* (es)', () {
      expect(joinHomeErrorMessage(JoinHomeError.invalidCode, es),
          es.join_error_invalid_code);
      expect(joinHomeErrorMessage(JoinHomeError.expiredCode, es),
          es.join_error_expired_code);
      expect(joinHomeErrorMessage(JoinHomeError.homeFull, es),
          es.join_error_home_full);
      expect(joinHomeErrorMessage(JoinHomeError.noAccountSlots, es),
          es.join_error_no_account_slots);
      expect(joinHomeErrorMessage(JoinHomeError.tooManyAttempts, es),
          es.join_error_too_many_attempts);
      expect(joinHomeErrorMessage(JoinHomeError.permissionDenied, es),
          es.join_error_permission_denied);
      expect(joinHomeErrorMessage(JoinHomeError.network, es),
          es.join_error_network);
      expect(joinHomeErrorMessage(JoinHomeError.unexpected, es),
          es.join_error_generic);
    });

    test('home_full usa copy neutral (no menciona "Free" ni "3 miembros")', () {
      final msg = joinHomeErrorMessage(JoinHomeError.homeFull, es);
      expect(msg.toLowerCase(), isNot(contains('free')));
      expect(msg, isNot(contains('3 miembros')));
    });

    test('los textos existen también en inglés', () {
      for (final reason in JoinHomeError.values) {
        expect(joinHomeErrorMessage(reason, en), isNotEmpty);
      }
    });
  });

  group('paridad selector ↔ onboarding (mismo motivo, mismo mensaje)', () {
    final es = AppLocalizationsEs();

    // Cada fila: (excepción de dominio que produce el repo del selector,
    //             FFE crudo que recibe el onboarding en los mocks).
    final scenarios = <String, (Object, Object)>{
      'código inválido': (
        const InvalidInviteCodeException(),
        _ffe('not-found'),
      ),
      'código expirado': (
        const ExpiredInviteCodeException(),
        _ffe('deadline-exceeded'),
      ),
      'hogar lleno': (
        const MaxMembersReachedException(),
        _ffe('failed-precondition', 'free_limit_members'),
      ),
      'sin plazas de cuenta': (
        const NoAccountSlotsException(),
        _ffe('resource-exhausted', 'no-account-slots'),
      ),
      'demasiados intentos': (
        const TooManyAttemptsException(),
        _ffe('resource-exhausted', 'too-many-join-attempts'),
      ),
    };

    scenarios.forEach((name, pair) {
      test('$name: selector y onboarding resuelven el mismo mensaje', () {
        final selectorReason = classifyJoinHomeError(pair.$1);
        final onboardingReason = classifyJoinHomeError(pair.$2);
        expect(selectorReason, onboardingReason);
        expect(joinHomeErrorMessage(selectorReason, es),
            joinHomeErrorMessage(onboardingReason, es));
      });
    });
  });
}
