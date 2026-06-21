import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/home_dashboard.dart';
import '../utils/task_visual_utils.dart';

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
      // Renderiza emoji o icono Material en vez de concatenar el codepoint
      // crudo (que mostraba "57622 <título>" en tareas con icono custom).
      title: Row(
        children: [
          taskVisualWidget(task.visualKind, task.visualValue, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(task.title)),
        ],
      ),
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
