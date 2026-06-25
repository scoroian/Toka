import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/errors/exceptions.dart';
import 'package:toka/features/homes/application/join_home_error.dart';
import 'package:toka/features/onboarding/application/home_creation_provider.dart';
import 'package:toka/features/onboarding/application/onboarding_provider.dart';
import 'package:toka/features/onboarding/domain/home_creation_repository.dart';
import 'package:toka/features/onboarding/domain/onboarding_repository.dart';

class _MockOnboardingRepo extends Mock implements OnboardingRepository {}

class _MockHomeCreationRepo extends Mock implements HomeCreationRepository {}

ProviderContainer _makeContainer({
  OnboardingRepository? onboardingRepo,
  HomeCreationRepository? homeRepo,
}) {
  return ProviderContainer(
    overrides: [
      if (onboardingRepo != null)
        onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
      if (homeRepo != null)
        homeCreationRepositoryProvider.overrideWithValue(homeRepo),
    ],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('initial state is step 0', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    expect(c.read(onboardingNotifierProvider).currentStep, 0);
  });

  test('nextStep increments currentStep', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    c.read(onboardingNotifierProvider.notifier).nextStep();
    expect(c.read(onboardingNotifierProvider).currentStep, 1);
  });

  test('prevStep decrements currentStep', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    c.read(onboardingNotifierProvider.notifier).nextStep();
    c.read(onboardingNotifierProvider.notifier).nextStep();
    c.read(onboardingNotifierProvider.notifier).prevStep();
    expect(c.read(onboardingNotifierProvider).currentStep, 1);
  });

  test('prevStep does not go below 0', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    c.read(onboardingNotifierProvider.notifier).prevStep();
    expect(c.read(onboardingNotifierProvider).currentStep, 0);
  });

  test('nextStep does not exceed totalSteps - 1', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    for (var i = 0; i < 10; i++) {
      c.read(onboardingNotifierProvider.notifier).nextStep();
    }
    final state = c.read(onboardingNotifierProvider);
    expect(state.currentStep, state.totalSteps - 1);
  });

  test('setLocale updates selectedLocale', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    c.read(onboardingNotifierProvider.notifier).setLocale('en');
    expect(c.read(onboardingNotifierProvider).selectedLocale, 'en');
  });

  test('saveProfileAndContinue with empty nickname sets error and does not advance',
      () async {
    final repo = _MockOnboardingRepo();
    final c = _makeContainer(onboardingRepo: repo);
    addTearDown(c.dispose);

    c.read(onboardingNotifierProvider.notifier).setNickname('');
    await c.read(onboardingNotifierProvider.notifier).saveProfileAndContinue();

    expect(c.read(onboardingNotifierProvider).error, 'nickname_required');
    expect(c.read(onboardingNotifierProvider).currentStep, 0);
    verifyNever(() => repo.saveProfile(
          uid: any(named: 'uid'),
          nickname: any(named: 'nickname'),
          phoneVisible: any(named: 'phoneVisible'),
          locale: any(named: 'locale'),
        ));
  });

  test('saveProfileAndContinue with nickname > 30 chars sets error', () async {
    final repo = _MockOnboardingRepo();
    final c = _makeContainer(onboardingRepo: repo);
    addTearDown(c.dispose);

    c.read(onboardingNotifierProvider.notifier).setNickname('A' * 31);
    await c.read(onboardingNotifierProvider.notifier).saveProfileAndContinue();

    expect(c.read(onboardingNotifierProvider).error, 'nickname_max_length');
  });

  test('createHome with empty name sets error', () async {
    final homeRepo = _MockHomeCreationRepo();
    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).createHome('', null);

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'home_name_required');
    verifyNever(() => homeRepo.createHome(name: any(named: 'name')));
  });

  test('createHome with name > 40 chars sets error', () async {
    final homeRepo = _MockHomeCreationRepo();
    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result = await c
        .read(onboardingNotifierProvider.notifier)
        .createHome('A' * 41, null);

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'home_name_max_length');
  });

  test('joinHome with code length != 6 sets error', () async {
    final homeRepo = _MockHomeCreationRepo();
    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('AB12');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'invite_code_length');
    verifyNever(() => homeRepo.joinHome(code: any(named: 'code')));
  });

  test('createHome sets no_slots error on NoHomeSlotsException', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.createHome(
          name: any(named: 'name'),
          emoji: any(named: 'emoji'),
        )).thenThrow(const NoHomeSlotsException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result = await c
        .read(onboardingNotifierProvider.notifier)
        .createHome('Mi Casa', null);

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'no_slots');
  });

  // Hallazgo #04: el repo real (HomeCreationRepositoryImpl) ya traduce el
  // FirebaseFunctionsException a una excepción de dominio tipada; el provider
  // solo clasifica el motivo canónico y guarda su nombre. Mismo eje que el
  // selector multi-hogar → mismo mensaje en ambas entradas.

  test('joinHome clasifica InvalidInviteCodeException → invalidCode', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(const InvalidInviteCodeException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('ABC123');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error,
        JoinHomeError.invalidCode.name);
  });

  test('joinHome clasifica ExpiredInviteCodeException → expiredCode', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(const ExpiredInviteCodeException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('XYZ789');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error,
        JoinHomeError.expiredCode.name);
  });

  test(
      'joinHome clasifica MaxMembersReachedException → homeFull '
      '(Hallazgo #04: "hogar lleno" ya NO cae en "Algo salió mal")', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(const MaxMembersReachedException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('ABC123');

    expect(result, isNull);
    expect(
        c.read(onboardingNotifierProvider).error, JoinHomeError.homeFull.name);
  });

  test(
      'joinHome clasifica NoAccountSlotsException → noAccountSlots '
      '(Hallazgo #01)', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(const NoAccountSlotsException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('ABC123');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error,
        JoinHomeError.noAccountSlots.name);
  });

  test('joinHome clasifica TooManyAttemptsException → tooManyAttempts',
      () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(const TooManyAttemptsException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('ABC123');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error,
        JoinHomeError.tooManyAttempts.name);
  });

  test('joinHome clasifica SocketException → network', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(const SocketException('No internet'));

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('ABC123');

    expect(result, isNull);
    expect(
        c.read(onboardingNotifierProvider).error, JoinHomeError.network.name);
  });

  test('joinHome clasifica FFE de code desconocido → unexpected', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code'))).thenThrow(
      FirebaseFunctionsException(code: 'internal', message: 'boom'),
    );

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('ABC123');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error,
        JoinHomeError.unexpected.name);
  });

  test('joinHome clasifica excepción genérica → unexpected', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(Exception('Something went wrong'));

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('ABC123');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error,
        JoinHomeError.unexpected.name);
  });
}
