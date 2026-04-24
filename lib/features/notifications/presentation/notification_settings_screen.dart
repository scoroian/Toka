// lib/features/notifications/presentation/notification_settings_screen.dart
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/notification_service.dart';
import '../application/notification_settings_view_model.dart';
import '../domain/notification_preferences.dart';

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
    final viewAsync = ref.watch(notificationSettingsProvider(homeId, uid));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notification_settings_title)),
      body: viewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.error_generic),
          ),
        ),
        data: (view) => _SettingsBody(
          view: view,
          homeId: homeId,
          uid: uid,
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({
    required this.view,
    required this.homeId,
    required this.uid,
  });

  final NotificationSettingsView view;
  final String homeId;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = view.prefs;
    final isPremium = view.isPremium;
    final systemOn = view.systemAuthorized;

    final minutesOptions = {
      15: l10n.notification_15min,
      30: l10n.notification_30min,
      60: l10n.notification_1h,
      120: l10n.notification_2h,
    };

    void save(NotificationPreferences update) {
      ref
          .read(notificationSettingsActionsProvider.notifier)
          .updatePrefs(update);
    }

    return ListView(
      children: [
        if (!systemOn)
          MaterialBanner(
            key: const Key('system_blocked_banner'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            leading: Icon(
              Icons.notifications_off,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            content: Text(
              l10n.notifSystemBlockedBanner,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            actions: [
              TextButton(
                key: const Key('system_blocked_open_settings'),
                onPressed: () => AppSettings.openAppSettings(
                  type: AppSettingsType.notification,
                ),
                child: Text(l10n.notifSystemBlockedAction),
              ),
            ],
          ),
        SwitchListTile(
          key: const Key('toggle_on_due'),
          title: Text(l10n.notification_on_due_label),
          value: prefs.notifyOnDue,
          onChanged: systemOn
              ? (v) => save(prefs.copyWith(notifyOnDue: v))
              : null,
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
          onChanged: (isPremium && systemOn)
              ? (v) => save(prefs.copyWith(notifyBefore: v))
              : null,
        ),
        if (prefs.notifyBefore && isPremium)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              initialValue: minutesOptions.containsKey(prefs.minutesBefore)
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
              onChanged: systemOn
                  ? (v) {
                      if (v == null) return;
                      save(prefs.copyWith(minutesBefore: v));
                    }
                  : null,
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
          onChanged: (isPremium && systemOn)
              ? (v) => save(prefs.copyWith(dailySummary: v))
              : null,
        ),
        if (kDebugMode)
          ..._buildTestSection(context, ref, l10n, homeId: homeId),
      ],
    );
  }

  /// Sección «Probar notificaciones» — solo visible en modo debug. Dispara una
  /// notificación local por cada tipo para poder validar visualmente los
  /// canales, estilos y destinos de deep-link en el emulador.
  List<Widget> _buildTestSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required String homeId,
  }) {
    final service = ref.read(notificationServiceProvider);
    const homeNameSample = 'Casa Lavapiés';
    final samples = <({String label, IconData icon, Key key, Future<void> Function() run})>[
      (
        label: l10n.notifTestDeadline,
        icon: Icons.timer_outlined,
        key: const Key('notif_test_deadline'),
        run: () => service.showDeadline(
          homeId: homeId,
          homeName: homeNameSample,
          taskId: 'demo_task_1',
          taskTitle: 'Sacar la basura',
          minutesLeft: 10,
        ),
      ),
      (
        label: l10n.notifTestAssignment,
        icon: Icons.person_add_alt,
        key: const Key('notif_test_assignment'),
        run: () => service.showAssignment(
          homeId: homeId,
          homeName: homeNameSample,
          taskId: 'demo_task_2',
          taskTitle: 'Limpiar el baño',
          assignerName: 'Ana',
          dueAtLabel: 'viernes 18:00',
        ),
      ),
      (
        label: l10n.notifTestReminder,
        icon: Icons.access_alarm,
        key: const Key('notif_test_reminder'),
        run: () => service.showReminder(
          homeId: homeId,
          homeName: homeNameSample,
          taskId: 'demo_task_3',
          taskTitle: 'Regar las plantas',
          minutesLeft: 30,
          dueAtLabel: '18:00',
        ),
      ),
      (
        label: l10n.notifTestDailySummary,
        icon: Icons.today_outlined,
        key: const Key('notif_test_daily_summary'),
        run: () => service.showDailySummary(
          homeId: homeId,
          homeName: homeNameSample,
          totalToday: 4,
          myToday: 2,
        ),
      ),
      (
        label: l10n.notifTestFeedback,
        icon: Icons.star_outline,
        key: const Key('notif_test_feedback'),
        run: () => service.showFeedback(
          homeId: homeId,
          homeName: homeNameSample,
          feedbackId: 'demo_feedback_1',
          raterName: 'Ana',
          stars: 5,
          taskTitle: 'Preparar cena',
        ),
      ),
      (
        label: l10n.notifTestRotation,
        icon: Icons.autorenew,
        key: const Key('notif_test_rotation'),
        run: () => service.showRotation(
          homeId: homeId,
          homeName: homeNameSample,
          rotationLines: const [
            '🗑️ Basura · te toca a ti',
            '🧺 Lavadora · Ana',
            '🧽 Baño · Marco',
          ],
        ),
      ),
    ];

    return [
      const SizedBox(height: 12),
      const Divider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          l10n.notifTestSectionTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          l10n.notifTestSectionHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      ...samples.map(
        (s) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: OutlinedButton.icon(
            key: s.key,
            icon: Icon(s.icon),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(s.label),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              alignment: Alignment.centerLeft,
            ),
            onPressed: () async {
              await s.run();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.notifTestSent)),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 24),
    ];
  }
}

