import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../i18n/presentation/language_selector_widget.dart';
import '../application/auth_provider.dart';
import '../application/auth_state.dart';
import '../domain/failures/auth_failure.dart';
import 'widgets/email_auth_form.dart';
import 'widgets/social_auth_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final isLoading =
        authState.maybeWhen(loading: () => true, orElse: () => false);

    ref.listen<AuthState>(authProvider, (_, next) {
      next.maybeWhen(
        error: (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_failureMessage(failure, l10n))),
        ),
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (_) => const LanguageSelectorWidget(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                l10n.auth_title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.auth_subtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              SocialAuthButton(
                label: l10n.auth_google,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                isLoading: isLoading,
                onPressed: () =>
                    ref.read(authProvider.notifier).signInWithGoogle(),
              ),
              if (Platform.isIOS || Platform.isMacOS) ...[
                const SizedBox(height: 12),
                SocialAuthButton(
                  key: const Key('apple_button'),
                  label: l10n.auth_apple,
                  icon: const Icon(Icons.apple, size: 24),
                  isLoading: isLoading,
                  onPressed: () =>
                      ref.read(authProvider.notifier).signInWithApple(),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.auth_or_divider,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              EmailAuthForm(
                isLoading: isLoading,
                submitLabel: l10n.auth_login,
                onSubmit: (email, password) => ref
                    .read(authProvider.notifier)
                    .signInWithEmail(email, password),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                child: Text(l10n.auth_forgot_password),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.register),
                child: Text(l10n.auth_no_account),
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
