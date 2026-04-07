import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class AssignmentForm extends StatelessWidget {
  const AssignmentForm({
    super.key,
    required this.availableMembers,
    required this.selectedOrder,
    required this.onChanged,
  });

  /// All UIDs of home members.
  final List<String> availableMembers;

  /// Currently selected UIDs in rotation order.
  final List<String> selectedOrder;

  final void Function(List<String> order) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tasks_assignment_members,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...availableMembers.map((uid) {
          final selected = selectedOrder.contains(uid);
          return CheckboxListTile(
            key: Key('assignee_checkbox_$uid'),
            title: Text(uid),
            value: selected,
            onChanged: (v) {
              final updated = v == true
                  ? [...selectedOrder, uid]
                  : selectedOrder.where((u) => u != uid).toList();
              onChanged(updated);
            },
          );
        }),
      ],
    );
  }
}
