import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/member.dart';
import 'member_role_badge.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.onTap,
    this.pendingTasksCount = 0,
  });

  final Member member;
  final VoidCallback onTap;
  final int pendingTasksCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compliancePercent =
        (member.complianceRate * 100).toStringAsFixed(0);

    return ListTile(
      key: Key('member_card_${member.uid}'),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: member.photoUrl != null
            ? NetworkImage(member.photoUrl!)
            : null,
        child: member.photoUrl == null
            ? Text(member.nickname.isNotEmpty
                ? member.nickname[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.nickname,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          MemberRoleBadge(role: member.role),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.members_compliance(compliancePercent)),
          if (pendingTasksCount > 0)
            Text(
              l10n.members_pending_tasks(pendingTasksCount),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
