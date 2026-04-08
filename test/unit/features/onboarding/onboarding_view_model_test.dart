// test/unit/features/onboarding/onboarding_view_model_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/onboarding/application/onboarding_provider.dart';
import 'package:toka/features/onboarding/application/onboarding_state.dart';
import 'package:toka/features/onboarding/application/onboarding_view_model.dart';

/// Fake OnboardingNotifier that avoids touching Firebase / SharedPreferences.
class _FakeOnboarding extends OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  // Expose state setter for tests
  void push(OnboardingState s) => state = s;

  @override
  Future<void> loadSavedProgress() async {}

  @override
  Future<void> saveProfileAndContinue() async {}

  @override
  Future<String?> createHome(String name, String? emoji) async => 'home123';

  @override
  Future<String?> joinHome(String code) async => 'home456';
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');

  @override
  Future<void> initialize(String? uid) async {}

  @override
  Future<void> setLocale(String code, String? uid) async {}
}

ProviderContainer _makeContainer(_FakeOnboarding fakeOnboarding) {
  return ProviderContainer(overrides: [
    onboardingNotifierProvider.overrideWith(() => fakeOnboarding),
    localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
  ]);
}

void main() {
  setUpAll(() {
    // Provide fake SharedPreferences so isCompleted() does not throw
    SharedPreferences.setMockInitialValues({'onboarding_completed': false});
  });

  group('OnboardingViewModel', () {
    late _FakeOnboarding fakeOnboarding;
    late ProviderContainer container;

    setUp(() {
      fakeOnboarding = _FakeOnboarding();
      container = _makeContainer(fakeOnboarding);
    });

    tearDown(() => container.dispose());

    test('isInitialized starts false before async init completes', () {
      final vm = container.read(onboardingViewModelProvider);
      expect(vm.isInitialized, isFalse);
    });

    test('shouldNavigateHome is false initially', () {
      final vm = container.read(onboardingViewModelProvider);
      expect(vm.shouldNavigateHome, isFalse);
    });

    test('isInitialized becomes true after async init completes', () async {
      container.read(onboardingViewModelProvider);
      // Allow the async _initialize() to run
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(
        container.read(onboardingViewModelProvider).isInitialized,
        isTrue,
      );
    });

    test('createHome sets shouldNavigateHome true on success', () async {
      final notifier =
          container.read(onboardingViewModelNotifierProvider.notifier);
      await notifier.createHome('Mi Casa', null);
      expect(notifier.shouldNavigateHome, isTrue);
    });

    test('joinHome sets shouldNavigateHome true on success', () async {
      final notifier =
          container.read(onboardingViewModelNotifierProvider.notifier);
      await notifier.joinHome('ABC123');
      expect(notifier.shouldNavigateHome, isTrue);
    });

    test('delegates setNickname to underlying notifier', () {
      final notifier =
          container.read(onboardingViewModelNotifierProvider.notifier);
      notifier.setNickname('Ana');
      expect(container.read(onboardingNotifierProvider).nickname, 'Ana');
    });

    test('delegates nextStep to underlying notifier', () {
      final notifier =
          container.read(onboardingViewModelNotifierProvider.notifier);
      // Put inner state at step 0 with totalSteps 4
      notifier.nextStep();
      expect(container.read(onboardingNotifierProvider).currentStep, 1);
    });

    test('delegates prevStep to underlying notifier', () {
      final notifier =
          container.read(onboardingViewModelNotifierProvider.notifier);
      // Advance first
      notifier.nextStep();
      notifier.prevStep();
      expect(container.read(onboardingNotifierProvider).currentStep, 0);
    });

    test('exposes currentStep from inner OnboardingState', () {
      final vm = container.read(onboardingViewModelProvider);
      expect(vm.currentStep, 0);
    });

    test('exposes totalSteps from inner OnboardingState', () {
      final vm = container.read(onboardingViewModelProvider);
      expect(vm.totalSteps, 4);
    });
  });
}
