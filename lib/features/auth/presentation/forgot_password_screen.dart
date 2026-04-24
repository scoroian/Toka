// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/forgot_password_view_model.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  static final _emailRegex = RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-z]{2,}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(forgotPasswordViewModelProvider)
        .sendPasswordReset(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(forgotPasswordViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auth_forgot_password_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: vm.resetSent
              ? _ConfirmationView(l10n: l10n)
              : _FormView(
                  formKey: _formKey,
                  emailCtrl: _emailCtrl,
                  loading: vm.isLoading,
                  onSend: _send,
                  l10n: l10n,
                  emailRegex: _emailRegex,
                ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.loading,
    required this.onSend,
    required this.l10n,
    required this.emailRegex,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSend;
  final AppLocalizations l10n;
  final RegExp emailRegex;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.auth_forgot_password_body),
          const SizedBox(height: 24),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            // BUG-01: neutralizar autocorrector del teclado (MIUI/Gboard).
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.auth_email_label),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.auth_validation_required;
              }
              if (!emailRegex.hasMatch(v.trim())) {
                return l10n.auth_validation_email_invalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading ? null : onSend,
            style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(l10n.auth_send_reset_link),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          l10n.auth_reset_sent,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
