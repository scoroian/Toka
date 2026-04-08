// lib/features/auth/presentation/verify_email_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/verify_email_view_model.dart';

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(verifyEmailViewModelProvider);
    final isDisabled = vm.isSending || vm.resendCooldownSeconds > 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auth_verify_email_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80),
              const SizedBox(height: 24),
              Text(
                l10n.auth_verify_email_title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.auth_verify_email_body(vm.email),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: isDisabled ? null : vm.resendVerification,
                child: Text(
                  vm.resendCooldownSeconds > 0
                      ? l10n.auth_resend_cooldown(vm.resendCooldownSeconds)
                      : l10n.auth_resend_email,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
