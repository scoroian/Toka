import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/skins/main_shell_v2.dart';
import '../../application/member_actions_provider.dart';

class InviteMemberSheet extends ConsumerStatefulWidget {
  const InviteMemberSheet({super.key, required this.homeId});

  final String homeId;

  @override
  ConsumerState<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  bool _showEmail = false;
  final _emailController = TextEditingController();
  String? _generatedCode;
  DateTime? _expiresAt;
  bool _isLoadingCode = false;
  String? _codeError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isExpiringSoon(DateTime expiresAt) {
    return expiresAt.difference(DateTime.now()).inHours < 24;
  }

  Future<void> _generateCode() async {
    setState(() {
      _isLoadingCode = true;
      _codeError = null;
    });
    try {
      final result = await ref
          .read(memberActionsProvider.notifier)
          .generateInviteCode(widget.homeId);
      if (mounted) {
        setState(() {
          _generatedCode = result.code;
          _expiresAt = result.expiresAt;
          _isLoadingCode = false;
        });
      }
    } catch (e, s) {
      debugPrint('🔴 generateInviteCode error: $e\n$s');
      if (mounted) {
        setState(() {
          _isLoadingCode = false;
          _codeError = 'error';
        });
      }
    }
  }

  Future<void> _sendEmailInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    await ref
        .read(memberActionsProvider.notifier)
        .inviteMember(widget.homeId, email);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final mq = MediaQuery.of(context);
    const navBarExtra = MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom;
    final bottomPadding = mq.viewInsets.bottom + mq.viewPadding.bottom + navBarExtra;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPadding + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.invite_sheet_title,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('btn_share_code'),
                  onPressed: _isLoadingCode
                      ? null
                      : () {
                          setState(() => _showEmail = false);
                          _generateCode();
                        },
                  icon: const Icon(Icons.qr_code),
                  label: Text(l10n.invite_sheet_share_code),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('btn_invite_email'),
                  onPressed: () => setState(() => _showEmail = true),
                  icon: const Icon(Icons.email_outlined),
                  label: Text(l10n.invite_sheet_by_email),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingCode)
            const Center(child: CircularProgressIndicator()),
          if (_codeError != null && !_isLoadingCode)
            Text(
              l10n.error_generic,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              key: const Key('invite_code_error'),
            ),
          if (_generatedCode != null && !_showEmail && !_isLoadingCode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(l10n.invite_sheet_code_label,
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: _generatedCode!,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _generatedCode!,
                    key: const Key('invite_code_text'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(letterSpacing: 4),
                  ),
                  if (_expiresAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.invite_code_expires_at(
                        DateFormat('dd MMM yyyy · HH:mm').format(_expiresAt!),
                      ),
                      key: const Key('invite_code_expiry'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _isExpiringSoon(_expiresAt!)
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        key: const Key('btn_copy_code'),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _generatedCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(l10n.invite_sheet_code_copied)),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: Text(l10n.invite_sheet_copy_code),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        key: const Key('btn_regenerate_code'),
                        onPressed: _isLoadingCode ? null : _generateCode,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.invite_code_regenerate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_showEmail) ...[
            TextField(
              key: const Key('email_field'),
              controller: _emailController,
              decoration: InputDecoration(
                hintText: l10n.invite_sheet_email_hint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('btn_send_invite'),
              onPressed: _sendEmailInvite,
              child: Text(l10n.invite_sheet_send),
            ),
          ],
        ],
      ),
    );
  }
}
