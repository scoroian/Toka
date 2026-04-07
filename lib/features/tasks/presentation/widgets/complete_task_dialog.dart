import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';

class CompleteTaskDialog extends StatelessWidget {
  final TaskPreview task;
  final VoidCallback onConfirm;

  const CompleteTaskDialog({
    super.key,
    required this.task,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${task.visualValue} ${task.title}'),
      content: Text(l10n.complete_task_dialog_body),
      actions: [
        TextButton(
          key: const Key('btn_cancel_complete'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          key: const Key('btn_confirm_complete'),
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          child: Text(l10n.complete_task_confirm_btn),
        ),
      ],
    );
  }
}
