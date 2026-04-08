import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

class HomeJoinForm extends StatefulWidget {
  const HomeJoinForm({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onJoin,
    required this.onBack,
  });

  final bool isLoading;
  final String? error;
  final ValueChanged<String> onJoin;
  final VoidCallback onBack;

  @override
  State<HomeJoinForm> createState() => _HomeJoinFormState();
}

class _HomeJoinFormState extends State<HomeJoinForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
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
            key: const Key('invite_code_field'),
            controller: _codeCtrl,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(6),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.onboarding_invite_code_label,
              hintText: l10n.onboarding_invite_code_hint,
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return l10n.onboarding_invite_code_length_error;
              }
              return null;
            },
          ),
          if (widget.error == 'invalid_invite')
            Text(
              l10n.onboarding_error_invalid_invite,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (widget.error == 'expired_invite')
            Text(
              l10n.onboarding_error_expired_invite,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                key: const Key('join_back_button'),
                onPressed: widget.isLoading ? null : widget.onBack,
                child: Text(l10n.back),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('join_button'),
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            widget.onJoin(
                                _codeCtrl.text.trim().toUpperCase());
                          }
                        },
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.onboarding_join_home_button),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
