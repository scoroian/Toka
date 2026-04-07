import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default(4) int totalSteps,
    String? selectedLocale,
    String? nickname,
    String? phoneNumber,
    @Default(false) bool phoneVisible,
    String? photoLocalPath,
    String? photoUrl,
    @Default(false) bool isLoading,
    String? error,
  }) = _OnboardingState;
}
