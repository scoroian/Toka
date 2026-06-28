import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../homes/application/join_home_error.dart';
import '../../../homes/application/join_home_error_messages.dart';
import '../../../homes/presentation/widgets/join_privacy_notice.dart';

/// Resuelve el código de error del view model (nombre de [JoinHomeError]) al
/// mensaje localizado, usando la MISMA fuente de verdad que el selector
/// multi-hogar (Hallazgo #04). Un código no reconocido —p. ej.
/// `invite_code_length`, validación de longitud del cliente que el propio
/// validador del campo ya muestra inline— cae al genérico.
String _joinErrorText(String code, AppLocalizations l10n) {
  final reason = JoinHomeError.values.asNameMap()[code];
  return reason != null
      ? joinHomeErrorMessage(reason, l10n)
      : l10n.join_error_generic;
}

class HomeJoinForm extends StatefulWidget {
  const HomeJoinForm({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onJoin,
    required this.onBack,
    this.onClearError,
    this.phoneShared = false,
  });

  final bool isLoading;
  final String? error;
  final ValueChanged<String> onJoin;
  final VoidCallback onBack;

  /// Si el teléfono del usuario se compartirá con los miembros (Hallazgo #09).
  /// Gobierna la línea del teléfono del aviso de transparencia.
  final bool phoneShared;

  /// Se invoca al editar el código para limpiar el error de servidor
  /// ("Código de invitación inválido", etc.), que vive en el view model y no
  /// se reevalúa solo al teclear.
  final VoidCallback? onClearError;

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
      // Revalida la longitud del código al teclear tras el primer submit.
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
            onChanged: (_) {
              // Al corregir el código, descarta el error de servidor previo.
              if (widget.error != null) widget.onClearError?.call();
            },
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return l10n.onboarding_invite_code_length_error;
              }
              return null;
            },
          ),
          if (widget.error != null)
            Text(
              _joinErrorText(widget.error!, l10n),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          // Aviso de transparencia (#09): qué verán los demás miembros. En
          // onboarding sin enlace navegable → mención textual.
          JoinPrivacyNotice(phoneShared: widget.phoneShared),
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
