import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class EmailAuthForm extends StatefulWidget {
  const EmailAuthForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.submitLabel,
    this.showPasswordConfirm = false,
    this.minPasswordLength = 8,
  });

  final void Function(String email, String password) onSubmit;
  final bool isLoading;
  final String? submitLabel;
  final bool showPasswordConfirm;
  final int minPasswordLength;

  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<EmailAuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static final _emailRegex = RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-z]{2,}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(_emailCtrl.text.trim(), _passwordCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('email_field'),
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            // BUG-01: neutralizar autocorrector/sugerencias de MIUI, Samsung
            // Keyboard y Gboard, que sustituyen letras al escribir rápido un
            // email.
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.auth_email_label),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.auth_validation_required;
              }
              if (!_emailRegex.hasMatch(v.trim())) {
                return l10n.auth_validation_email_invalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('password_field'),
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.auth_password_label,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                tooltip: _obscurePassword
                    ? l10n.auth_password_show
                    : l10n.auth_password_hide,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return l10n.auth_validation_required;
              if (widget.showPasswordConfirm &&
                  v.length < widget.minPasswordLength) {
                return l10n.auth_validation_password_min_length;
              }
              return null;
            },
          ),
          if (widget.showPasswordConfirm) ...[
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('confirm_password_field'),
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: l10n.auth_confirm_password_label,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  tooltip: _obscureConfirm
                      ? l10n.auth_password_show
                      : l10n.auth_password_hide,
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.auth_validation_required;
                }
                if (v != _passwordCtrl.text) {
                  return l10n.auth_validation_passwords_no_match;
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('submit_button'),
            onPressed: widget.isLoading ? null : _submit,
            style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(widget.submitLabel ?? l10n.auth_login),
          ),
        ],
      ),
    );
  }
}
