import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class AccessManagementSection extends StatelessWidget {
  const AccessManagementSection({
    super.key,
    required this.hasEmailPassword,
    required this.onChangePassword,
    required this.onLogout,
  });

  final bool hasEmailPassword;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasEmailPassword)
          ListTile(
            key: const Key('change_password_tile'),
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.profile_change_password),
            onTap: onChangePassword,
          ),
        ListTile(
          key: const Key('logout_tile'),
          leading: const Icon(Icons.logout),
          title: Text(
            l10n.profile_logout,
            style: const TextStyle(color: Colors.red),
          ),
          onTap: onLogout,
        ),
      ],
    );
  }
}
