import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  bool _showScanner = false;
  MobileScannerController? _scannerCtrl;

  @override
  void dispose() {
    _scannerCtrl?.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _openScanner() {
    _scannerCtrl = MobileScannerController();
    setState(() => _showScanner = true);
  }

  void _closeScanner() {
    _scannerCtrl?.dispose();
    _scannerCtrl = null;
    setState(() => _showScanner = false);
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    final cleaned = code.trim().toUpperCase();
    if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(cleaned)) {
      _codeCtrl.text = cleaned;
      _closeScanner();
      if (_formKey.currentState?.validate() ?? false) {
        widget.onJoin(cleaned);
      }
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
          if (_showScanner) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: MobileScanner(
                  key: const Key('qr_scanner'),
                  controller: _scannerCtrl,
                  onDetect: _onDetect,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.invite_sheet_qr_hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('btn_close_scanner'),
              onPressed: _closeScanner,
              child: Text(l10n.cancel),
            ),
            const SizedBox(height: 16),
          ],
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
              suffixIcon: IconButton(
                key: const Key('btn_scan_qr'),
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: l10n.invite_sheet_scan_qr,
                onPressed: widget.isLoading ? null : _openScanner,
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return l10n.onboarding_invite_code_length_error;
              }
              return null;
            },
          ),
          if (widget.error != null)
            Text(
              switch (widget.error!) {
                'invalid_invite' => l10n.onboarding_error_invalid_invite,
                'expired_invite' => l10n.onboarding_error_expired_invite,
                'network_error' => l10n.onboarding_error_network,
                'permission_denied' => l10n.onboarding_error_permission_denied,
                _ => l10n.onboarding_error_unexpected,
              },
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
