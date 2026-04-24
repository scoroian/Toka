// lib/features/onboarding/presentation/onboarding_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../application/onboarding_provider.dart';
import '../application/onboarding_view_model.dart';
import 'notification_rationale_screen.dart';
import 'steps/home_choice_step.dart';
import 'steps/language_step.dart';
import 'steps/profile_step.dart';
import 'steps/welcome_step.dart';
import 'widgets/onboarding_progress_bar.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late final PageController _pageController;
  bool _navigationDispatched = false;

  @override
  void initState() {
    super.initState();
    final step = ref.read(onboardingNotifierProvider).currentStep;
    _pageController = PageController(initialPage: step);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch notifier state directly para que el widget reconstruya cuando cambia.
    // onboardingViewModelProvider devuelve siempre el mismo objeto notifier
    // (misma referencia), por lo que Riverpod no notifica por sí solo.
    final vmState = ref.watch(onboardingViewModelNotifierProvider);
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final vm = ref.watch(onboardingViewModelProvider);

    // Navegar a home en el post-frame para evitar setState durante build.
    // Si el onboarding aún no mostró la rationale de notificaciones o el SO
    // reporta `notDetermined`, la insertamos como último paso antes de home.
    if (vmState.shouldNavigateHome && !_navigationDispatched) {
      _navigationDispatched = true;
      final router = GoRouter.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final showRationale = await shouldShowNotificationRationale();
        if (!mounted) return;
        router.go(
          showRationale ? AppRoutes.notificationRationale : AppRoutes.home,
        );
      });
    }

    // Sincronizar PageController con el paso actual.
    final targetStep = onboardingState.currentStep;
    if (_pageController.hasClients &&
        _pageController.page?.round() != targetStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToPage(targetStep);
      });
    }

    if (!vmState.isInitialized && !vmState.shouldNavigateHome) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          OnboardingProgressBar(
            currentStep: onboardingState.currentStep,
            totalSteps: onboardingState.totalSteps,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 0: Welcome
                WelcomeStep(onStart: vm.nextStep),

                // Step 1: Language
                LanguageStep(
                  selectedLocale: vm.selectedLocale,
                  onLocaleSelected: vm.setLocale,
                  onNext: vm.nextStep,
                  onPrev: vm.prevStep,
                ),

                // Step 2: Profile
                ProfileStep(
                  nickname: vm.nickname,
                  phoneNumber: vm.phoneNumber,
                  phoneVisible: vm.phoneVisible,
                  photoLocalPath: vm.photoLocalPath,
                  isLoading: vm.isLoading,
                  error: vm.error,
                  onNicknameChanged: vm.setNickname,
                  onPhoneChanged: vm.setPhoneNumber,
                  onPhoneVisibleChanged: vm.setPhoneVisible,
                  onPhotoChanged: vm.setPhotoLocalPath,
                  onNext: vm.saveProfileAndContinue,
                  onPrev: vm.prevStep,
                ),

                // Step 3: Home choice
                HomeChoiceStep(
                  isLoading: vm.isLoading,
                  error: vm.error,
                  onCreateHome: (name, emoji) => vm.createHome(name, emoji),
                  onJoinHome: vm.joinHome,
                  onPrev: vm.prevStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
