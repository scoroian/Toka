// lib/features/notifications/presentation/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/notification_settings_view_model.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.homeId,
    required this.uid,
  });

  final String homeId;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm =
        ref.watch(notificationSettingsViewModelProvider(homeId, uid));
    final notifier = ref.read(
        notificationSettingsViewModelNotifierProvider(homeId, uid).notifier);

    if (!vm.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notification_settings_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final prefs = vm.prefs;
    final isPremium = vm.isPremium;

    final minutesOptions = {
      15: l10n.notification_15min,
      30: l10n.notification_30min,
      60: l10n.notification_1h,
      120: l10n.notification_2h,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notification_settings_title)),
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key('toggle_on_due'),
            title: Text(l10n.notification_on_due_label),
            value: prefs.notifyOnDue,
            onChanged: (v) {
              notifier.updatePrefs(prefs.copyWith(notifyOnDue: v));
            },
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('toggle_notify_before'),
            title: Text(l10n.notification_before_label),
            subtitle: !isPremium
                ? Text(l10n.notification_premium_only,
                    style: const TextStyle(color: Colors.orange))
                : null,
            value: prefs.notifyBefore,
            onChanged: isPremium
                ? (v) {
                    notifier.updatePrefs(prefs.copyWith(notifyBefore: v));
                  }
                : null,
          ),
          if (prefs.notifyBefore && isPremium)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<int>(
                value: minutesOptions.containsKey(prefs.minutesBefore)
                    ? prefs.minutesBefore
                    : 30,
                decoration: InputDecoration(
                    labelText: l10n.notification_minutes_before_label),
                items: minutesOptions.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  notifier.updatePrefs(prefs.copyWith(minutesBefore: v));
                },
              ),
            ),
          const Divider(),
          SwitchListTile(
            key: const Key('toggle_daily_summary'),
            title: Text(l10n.notification_daily_summary_label),
            subtitle: !isPremium
                ? Text(l10n.notification_premium_only,
                    style: const TextStyle(color: Colors.orange))
                : null,
            value: prefs.dailySummary,
            onChanged: isPremium
                ? (v) {
                    notifier.updatePrefs(prefs.copyWith(dailySummary: v));
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
