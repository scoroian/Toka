// lib/features/tasks/presentation/widgets/assignment_form.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/create_edit_task_view_model.dart';

/// Lista de miembros con toggle de asignación y reordenación de los asignados.
class AssignmentForm extends StatelessWidget {
  const AssignmentForm({
    super.key,
    required this.members,
    required this.onToggle,
    required this.onReorder,
  });

  final List<MemberOrderItem> members;
  final void Function(String uid) onToggle;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assigned = members.where((m) => m.isAssigned).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final unassigned = members.where((m) => !m.isAssigned).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tasks_assignment_members,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),

        // Miembros asignados (reordenables)
        if (assigned.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assigned.length,
            onReorder: onReorder,
            itemBuilder: (_, i) {
              final m = assigned[i];
              return ListTile(
                key: Key('assigned_member_${m.uid}'),
                leading: m.photoUrl != null
                    ? CircleAvatar(backgroundImage: NetworkImage(m.photoUrl!))
                    : CircleAvatar(
                        child: Text(m.name.isNotEmpty
                            ? m.name[0].toUpperCase()
                            : '?')),
                title: Text(m.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      key: Key('assignee_checkbox_${m.uid}'),
                      value: true,
                      onChanged: (_) => onToggle(m.uid),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              );
            },
          ),

        // Miembros no asignados
        ...unassigned.map(
          (m) => ListTile(
            key: Key('unassigned_member_${m.uid}'),
            leading: m.photoUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(m.photoUrl!))
                : CircleAvatar(
                    child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?')),
            title: Text(m.name),
            trailing: Checkbox(
              key: Key('assignee_checkbox_${m.uid}'),
              value: false,
              onChanged: (_) => onToggle(m.uid),
            ),
          ),
        ),
      ],
    );
  }
}
