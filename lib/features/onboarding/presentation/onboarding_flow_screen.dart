// lib/features/onboarding/presentation/onboarding_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../application/onboarding_view_model.dart';
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
  final _pageController = PageController();

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
    final vm = ref.watch(onboardingViewModelProvider);

    ref.listen<OnboardingViewModel>(onboardingViewModelProvider, (_, next) {
      if (next.shouldNavigateHome) context.go(AppRoutes.home);
    });

    ref.listen<OnboardingViewModel>(onboardingViewModelProvider, (prev, next) {
      if (prev?.currentStep != next.currentStep) {
        _goToPage(next.currentStep);
      }
    });

    if (!vm.isInitialized && !vm.shouldNavigateHome) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          OnboardingProgressBar(
            currentStep: vm.currentStep,
            totalSteps: vm.totalSteps,
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
