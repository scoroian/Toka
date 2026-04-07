// lib/features/notifications/presentation/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/notification_prefs_provider.dart';
import '../domain/notification_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.homeId,
    required this.uid,
  });

  final String homeId;
  final String uid;

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreferences? _prefs;

  bool _isPremium() {
    final sub = ref.watch(subscriptionStateProvider);
    return sub.map(
      free: (_) => false,
      active: (_) => true,
      cancelledPendingEnd: (_) => true,
      rescue: (_) => true,
      expiredFree: (_) => false,
      restorable: (_) => false,
      purged: (_) => false,
    );
  }

  Future<void> _save(NotificationPreferences prefs) async {
    await ref.read(notificationPrefsNotifierProvider.notifier).save(prefs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPremium = _isPremium();

    final prefsAsync = ref.watch(
      notificationPrefsProvider(homeId: widget.homeId, uid: widget.uid),
    );

    prefsAsync.whenData((p) {
      if (!mounted) return;
      if (_prefs == null) setState(() => _prefs = p);
    });

    final prefs = _prefs ?? NotificationPreferences(homeId: widget.homeId, uid: widget.uid);

    final minutesOptions = {
      15: l10n.notification_15min,
      30: l10n.notification_30min,
      60: l10n.notification_1h,
      120: l10n.notification_2h,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notification_settings_title)),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (_) => ListView(
          children: [
            SwitchListTile(
              key: const Key('toggle_on_due'),
              title: Text(l10n.notification_on_due_label),
              value: prefs.notifyOnDue,
              onChanged: (v) {
                final updated = prefs.copyWith(notifyOnDue: v);
                setState(() => _prefs = updated);
                _save(updated);
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
                      final updated = prefs.copyWith(notifyBefore: v);
                      setState(() => _prefs = updated);
                      _save(updated);
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
                    final updated = prefs.copyWith(minutesBefore: v);
                    setState(() => _prefs = updated);
                    _save(updated);
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
                      final updated = prefs.copyWith(dailySummary: v);
                      setState(() => _prefs = updated);
                      _save(updated);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
