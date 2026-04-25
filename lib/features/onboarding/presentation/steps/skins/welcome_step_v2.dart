import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class WelcomeStepV2 extends StatelessWidget {
  const WelcomeStepV2({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.home_rounded, size: 96),
            const SizedBox(height: 32),
            Text(
              l10n.onboarding_welcome_title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboarding_welcome_subtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton(
              key: const Key('start_button'),
              onPressed: onStart,
              child: Text(l10n.onboarding_start),
            ),
          ],
        ),
      ),
    );
  }
}
