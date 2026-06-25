// lib/features/auth/presentation/verify_email_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/verify_email_view_model.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.enablePolling = true});

  /// Polling suave que comprueba la verificación mientras la pantalla está
  /// visible. Se desactiva en tests de widget (un Timer.periodic vivo cuelga
  /// pumpAndSettle).
  final bool enablePolling;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enablePolling) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => ref.read(verifyEmailViewModelProvider).pollVerification(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver del cliente de correo, reintentar la comprobación.
    if (state == AppLifecycleState.resumed && widget.enablePolling) {
      ref.read(verifyEmailViewModelProvider).pollVerification();
    }
  }

  Future<void> _onContinue() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome =
        await ref.read(verifyEmailViewModelProvider).continueIfVerified();
    if (!mounted) return;
    switch (outcome) {
      case VerifyCheckOutcome.verified:
        break; // el router avanza solo
      case VerifyCheckOutcome.notVerified:
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.auth_verify_email_not_yet)));
      case VerifyCheckOutcome.networkError:
        messenger
            .showSnackBar(SnackBar(content: Text(l10n.auth_error_network)));
      case VerifyCheckOutcome.unknownError:
        messenger.showSnackBar(SnackBar(content: Text(l10n.error_generic)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(verifyEmailViewModelProvider);
    final isResendDisabled = vm.isSending || vm.resendCooldownSeconds > 0;

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
                key: const Key('btn_continue_verification'),
                onPressed: vm.isChecking ? null : _onContinue,
                child: Text(
                  vm.isChecking
                      ? l10n.auth_verify_email_checking
                      : l10n.auth_verify_email_continue,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('btn_resend_verification'),
                onPressed: isResendDisabled ? null : vm.resendVerification,
                child: Text(
                  vm.resendCooldownSeconds > 0
                      ? l10n.auth_resend_cooldown(vm.resendCooldownSeconds)
                      : l10n.auth_resend_email,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('btn_back_verification'),
                onPressed: vm.isChecking ? null : vm.cancelAndSignOut,
                child: Text(l10n.auth_verify_email_back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
