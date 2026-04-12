// lib/features/tasks/presentation/widgets/assignment_form.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../features/members/domain/member.dart';
import '../../../../l10n/app_localizations.dart';

class AssignmentForm extends StatelessWidget {
  const AssignmentForm({
    super.key,
    required this.availableMembers,
    required this.selectedOrder,
    required this.onChanged,
  });

  final List<Member> availableMembers;
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
        ...availableMembers.map((member) {
          final selected = selectedOrder.contains(member.uid);
          return CheckboxListTile(
            key: Key('assignee_checkbox_${member.uid}'),
            secondary: CircleAvatar(
              radius: 18,
              backgroundImage: member.photoUrl != null
                  ? CachedNetworkImageProvider(member.photoUrl!)
                  : null,
              child: member.photoUrl == null
                  ? Text(
                      member.nickname.isNotEmpty
                          ? member.nickname[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            title: Text(member.nickname),
            value: selected,
            onChanged: (v) {
              final updated = v == true
                  ? [...selectedOrder, member.uid]
                  : selectedOrder.where((u) => u != member.uid).toList();
              onChanged(updated);
            },
          );
        }),
      ],
    );
  }
}
