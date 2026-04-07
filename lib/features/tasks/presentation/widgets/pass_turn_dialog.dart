import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class PassTurnDialog extends StatefulWidget {
  final TaskPreview task;
  final double currentComplianceRate;
  final double estimatedComplianceAfter;
  final String? nextAssigneeName;
  final void Function(String? reason) onConfirm;

  const PassTurnDialog({
    super.key,
    required this.task,
    required this.currentComplianceRate,
    required this.estimatedComplianceAfter,
    required this.nextAssigneeName,
    required this.onConfirm,
  });

  /// Cálculo puro para tests: completed / (completed + passed + 1)
  static double calcEstimatedCompliance({
    required int completedCount,
    required int passedCount,
  }) {
    final total = completedCount + passedCount + 1;
    return (completedCount / total).clamp(0.0, 1.0);
  }

  @override
  State<PassTurnDialog> createState() => _PassTurnDialogState();
}

class _PassTurnDialogState extends State<PassTurnDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final before = (widget.currentComplianceRate * 100).round();
    final after = (widget.estimatedComplianceAfter * 100).round();

    return AlertDialog(
      title: Text(l10n.pass_turn_dialog_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.pass_turn_compliance_warning(
                  before.toString(),
                  after.toString(),
                ),
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.nextAssigneeName != null)
              Text(l10n.pass_turn_next_assignee(widget.nextAssigneeName!))
            else
              Text(
                l10n.pass_turn_no_candidate,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('field_pass_reason'),
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: l10n.pass_turn_reason_hint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('btn_cancel_pass'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          key: const Key('btn_confirm_pass'),
          onPressed: () {
            final reason = _reasonController.text.trim();
            widget.onConfirm(reason.isEmpty ? null : reason);
            Navigator.of(context).pop();
          },
          child: Text(l10n.pass_turn_confirm_btn),
        ),
      ],
    );
  }
}
