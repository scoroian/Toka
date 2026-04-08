// lib/features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../application/register_view_model.dart';
import '../domain/failures/auth_failure.dart';
import 'widgets/email_auth_form.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(registerViewModelProvider);

    ref.listen<RegisterViewModel>(registerViewModelProvider, (_, next) {
      if (next.registrationComplete) {
        context.go(AppRoutes.verifyEmail);
        return;
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_failureMessage(next.error!, l10n))),
        );
        next.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auth_register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailAuthForm(
                showPasswordConfirm: true,
                isLoading: vm.isLoading,
                submitLabel: l10n.auth_register,
                onSubmit: (email, password) => vm.register(email, password),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.auth_have_account),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _failureMessage(AuthFailure failure, AppLocalizations l10n) =>
      failure.when(
        networkError: () => l10n.auth_error_network,
        invalidCredentials: () => l10n.auth_error_invalid_credentials,
        emailAlreadyInUse: () => l10n.auth_error_email_in_use,
        userNotFound: () => l10n.auth_error_user_not_found,
        weakPassword: () => l10n.auth_error_weak_password,
        emailNotVerified: () => l10n.error_generic,
        accountExistsWithDifferentCredential: (_, __) => l10n.error_generic,
        tooManyRequests: () => l10n.auth_error_too_many_requests,
        operationCancelled: () => l10n.error_generic,
        unknown: (_) => l10n.error_generic,
      );
}
