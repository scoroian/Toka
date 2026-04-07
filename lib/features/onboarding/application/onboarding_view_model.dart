// lib/features/onboarding/application/onboarding_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../i18n/application/locale_provider.dart';
import 'onboarding_provider.dart';
import 'onboarding_state.dart';

part 'onboarding_view_model.freezed.dart';
part 'onboarding_view_model.g.dart';

// ── 1. CONTRACT ────────────────────────────────────────────────────────────

abstract class OnboardingViewModel {
  bool get isInitialized;
  bool get shouldNavigateHome;
  int get currentStep;
  int get totalSteps;
  String? get selectedLocale;
  String? get nickname;
  String? get phoneNumber;
  bool get phoneVisible;
  String? get photoLocalPath;
  bool get isLoading;
  String? get error;

  void nextStep();
  void prevStep();
  void setLocale(String code);
  void setNickname(String name);
  void setPhoneNumber(String? phone);
  void setPhoneVisible(bool visible);
  void setPhotoLocalPath(String? path);
  Future<void> saveProfileAndContinue();
  Future<void> createHome(String name, String? emoji);
  Future<void> joinHome(String code);
}

// ── 2. INTERNAL STATE ──────────────────────────────────────────────────────

@freezed
class _OnboardingVMState with _$OnboardingVMState {
  const factory _OnboardingVMState({
    @Default(false) bool isInitialized,
    @Default(false) bool shouldNavigateHome,
  }) = __OnboardingVMState;
}

// ── 3. IMPLEMENTATION ──────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class OnboardingViewModelNotifier extends _$OnboardingViewModelNotifier
    implements OnboardingViewModel {
  OnboardingNotifier get _inner =>
      ref.read(onboardingNotifierProvider.notifier);

  @override
  _OnboardingVMState build() {
    _initialize();
    return const _OnboardingVMState();
  }

  Future<void> _initialize() async {
    final done = await OnboardingNotifier.isCompleted();
    if (done) {
      state = state.copyWith(shouldNavigateHome: true);
      return;
    }
    await _inner.loadSavedProgress();
    state = state.copyWith(isInitialized: true);
  }

  OnboardingState get _s => ref.read(onboardingNotifierProvider);

  @override
  bool get isInitialized => state.isInitialized;

  @override
  bool get shouldNavigateHome => state.shouldNavigateHome;

  @override
  int get currentStep => _s.currentStep;

  @override
  int get totalSteps => _s.totalSteps;

  @override
  String? get selectedLocale => _s.selectedLocale;

  @override
  String? get nickname => _s.nickname;

  @override
  String? get phoneNumber => _s.phoneNumber;

  @override
  bool get phoneVisible => _s.phoneVisible;

  @override
  String? get photoLocalPath => _s.photoLocalPath;

  @override
  bool get isLoading => _s.isLoading;

  @override
  String? get error => _s.error;

  @override
  void nextStep() => _inner.nextStep();

  @override
  void prevStep() => _inner.prevStep();

  @override
  void setLocale(String code) {
    _inner.setLocale(code);
    ref.read(localeNotifierProvider.notifier).setLocale(code, null);
  }

  @override
  void setNickname(String name) => _inner.setNickname(name);

  @override
  void setPhoneNumber(String? phone) => _inner.setPhoneNumber(phone);

  @override
  void setPhoneVisible(bool visible) => _inner.setPhoneVisible(visible);

  @override
  void setPhotoLocalPath(String? path) => _inner.setPhotoLocalPath(path);

  @override
  Future<void> saveProfileAndContinue() => _inner.saveProfileAndContinue();

  @override
  Future<void> createHome(String name, String? emoji) async {
    final homeId = await _inner.createHome(name, emoji);
    if (homeId != null) state = state.copyWith(shouldNavigateHome: true);
  }

  @override
  Future<void> joinHome(String code) async {
    final homeId = await _inner.joinHome(code);
    if (homeId != null) state = state.copyWith(shouldNavigateHome: true);
  }
}

// ── 4. TYPED PROVIDER (what screens import) ────────────────────────────────

@Riverpod(keepAlive: true)
OnboardingViewModel onboardingViewModel(OnboardingViewModelRef ref) {
  ref.watch(onboardingViewModelNotifierProvider);
  ref.watch(onboardingNotifierProvider);
  return ref.read(onboardingViewModelNotifierProvider.notifier);
}
