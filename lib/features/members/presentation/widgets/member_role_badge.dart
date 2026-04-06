import 'package:flutter/material.dart';

import '../../../../features/homes/domain/home_membership.dart';
import '../../../../l10n/app_localizations.dart';

class MemberRoleBadge extends StatelessWidget {
  const MemberRoleBadge({super.key, required this.role});

  final MemberRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (role) {
      MemberRole.owner => (l10n.members_role_badge_owner, Colors.amber.shade700),
      MemberRole.admin => (l10n.members_role_badge_admin, Colors.blue.shade600),
      MemberRole.member => (l10n.members_role_badge_member, Colors.grey.shade600),
      MemberRole.frozen => (l10n.members_role_badge_frozen, Colors.blueGrey),
    };

    return Container(
      key: Key('role_badge_${role.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
