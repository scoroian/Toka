import 'package:flutter/material.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      key: const Key('onboarding_progress_bar'),
      value: totalSteps > 0 ? (currentStep + 1) / totalSteps : 0,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      color: Theme.of(context).colorScheme.primary,
      minHeight: 4,
    );
  }
}
