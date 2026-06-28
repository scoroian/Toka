// lib/features/onboarding/presentation/onboarding_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../application/onboarding_provider.dart';
import '../application/onboarding_view_model.dart';
import 'skins/notification_rationale_screen_v2.dart'
    show shouldShowNotificationRationale;
import 'steps/skins/home_choice_step.dart';
import 'steps/skins/language_step.dart';
import 'steps/skins/profile_step.dart';
import 'steps/skins/welcome_step.dart';
import 'widgets/onboarding_progress_bar.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  bool _navigationDispatched = false;

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
            // IndexedStack en vez de PageView(NeverScrollableScrollPhysics): el
            // stepper no es deslizable, y el viewport/gesture-detector del
            // PageView interfería con el hit-testing del botón "Empezar" (no
            // respondía a toques inyectados). IndexedStack preserva el estado de
            // cada paso y no introduce reconocedores de gestos.
            child: IndexedStack(
              index: onboardingState.currentStep.clamp(0, 3),
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
                  // Hallazgo #09: el aviso de transparencia refleja si el
                  // teléfono configurado en el paso de perfil se compartirá.
                  phoneShared: vm.phoneVisible &&
                      (vm.phoneNumber?.trim().isNotEmpty ?? false),
                  onCreateHome: (name, emoji) => vm.createHome(name, emoji),
                  onJoinHome: vm.joinHome,
                  onPrev: vm.prevStep,
                  onClearError: vm.clearError,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
