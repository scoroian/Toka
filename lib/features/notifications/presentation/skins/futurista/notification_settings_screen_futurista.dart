// lib/features/notifications/presentation/skins/futurista/notification_settings_screen_futurista.dart
//
// Pantalla de Ajustes de notificaciones en skin Futurista. Replica el
// comportamiento exacto del v2 (mismo provider/VM, misma lógica premium-gate
// y system-blocked) con el lenguaje visual futurista:
//   - AppBar con título.
//   - Hero card "warning" si !systemAuthorized (en lugar del MaterialBanner).
//   - Secciones agrupadas en tarjeta `surfaceContainerHighest` radius 16 con
//     filas separadas por Divider, label monospaced uppercase letterSpacing
//     1.6 como header.
//   - Sección debug "PROBAR NOTIFICACIONES" solo en kDebugMode con la misma
//     lista de muestras que el v2.
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../application/notification_service.dart';
import '../../../application/notification_settings_view_model.dart';
import '../../../domain/notification_preferences.dart';

class NotificationSettingsScreenFuturista extends ConsumerWidget {
  const NotificationSettingsScreenFuturista({
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
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.error_generic),
          ),
        ),
        data: (view) => _SettingsBodyFuturista(
          view: view,
          homeId: homeId,
          uid: uid,
        ),
      ),
    );
  }
}

class _SettingsBodyFuturista extends ConsumerWidget {
  const _SettingsBodyFuturista({
    required this.view,
    required this.homeId,
    required this.uid,
  });

  final NotificationSettingsView view;
  final String homeId;
  final String uid;

  static const _monoHeader = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final prefs = view.prefs;
    final isPremium = view.isPremium;
    final systemOn = view.systemAuthorized;

    final mutedColor = cs.onSurface.withValues(alpha: 0.6);

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
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        adAwareBottomPadding(context, ref, extra: 16),
      ),
      children: [
        if (!systemOn) ...[
          Container(
            key: const Key('system_blocked_banner'),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.error.withValues(alpha: 0.4),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.notifications_off,
                          color: cs.error,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.notifSystemBlockedBanner,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reabre Ajustes para activarlas',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TockaBtn(
                    key: const Key('system_blocked_open_settings'),
                    variant: TockaBtnVariant.ghost,
                    size: TockaBtnSize.sm,
                    onPressed: () => AppSettings.openAppSettings(
                      type: AppSettingsType.notification,
                    ),
                    child: Text(l10n.notifSystemBlockedAction),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // --- Sección TAREAS ---
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: Text(
            'TAREAS',
            style: _monoHeader.copyWith(color: mutedColor),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              // Avisar al vencer
              _SettingsRow(
                icon: Icons.alarm,
                title: l10n.notification_on_due_label,
                trailing: Switch(
                  key: const Key('toggle_on_due'),
                  value: prefs.notifyOnDue,
                  onChanged: systemOn
                      ? (v) => save(prefs.copyWith(notifyOnDue: v))
                      : null,
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),
              // Avisar antes de vencer + dropdown opcional
              _SettingsRow(
                icon: Icons.access_time,
                title: l10n.notification_before_label,
                subtitle: !isPremium ? l10n.notification_premium_only : null,
                subtitleColor: Colors.orange,
                trailing: Switch(
                  key: const Key('toggle_notify_before'),
                  value: prefs.notifyBefore,
                  onChanged: (isPremium && systemOn)
                      ? (v) => save(prefs.copyWith(notifyBefore: v))
                      : null,
                ),
              ),
              if (prefs.notifyBefore && isPremium) ...[
                Divider(height: 1, color: theme.dividerColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: DropdownButtonFormField<int>(
                    key: const Key('minutes_before_dropdown'),
                    initialValue:
                        minutesOptions.containsKey(prefs.minutesBefore)
                            ? prefs.minutesBefore
                            : 30,
                    decoration: InputDecoration(
                      labelText: l10n.notification_minutes_before_label,
                      border: const OutlineInputBorder(),
                    ),
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
              ],
              Divider(height: 1, color: theme.dividerColor),
              // Resumen diario
              _SettingsRow(
                icon: Icons.summarize,
                title: l10n.notification_daily_summary_label,
                subtitle: !isPremium ? l10n.notification_premium_only : null,
                subtitleColor: Colors.orange,
                trailing: Switch(
                  key: const Key('toggle_daily_summary'),
                  value: prefs.dailySummary,
                  onChanged: (isPremium && systemOn)
                      ? (v) => save(prefs.copyWith(dailySummary: v))
                      : null,
                ),
              ),
            ],
          ),
        ),

        if (kDebugMode) ...[
          const SizedBox(height: 16),
          ..._buildTestSection(context, ref, l10n, homeId: homeId),
        ],
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor = cs.onSurface.withValues(alpha: 0.6);
    final service = ref.read(notificationServiceProvider);
    const homeNameSample = 'Casa Lavapiés';
    final samples = <({String label, IconData icon, Key key, Future<void> Function() run})>[
      (
        label: l10n.notifTestDeadline,
        icon: Icons.timer_outlined,
        key: const Key('notif_test_deadline'),
        run: () => service.showDeadline(
          l10n: l10n,
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
          l10n: l10n,
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
          l10n: l10n,
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
          l10n: l10n,
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
          l10n: l10n,
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
          l10n: l10n,
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
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Text(
          l10n.notifTestSectionTitle.toUpperCase(),
          style: _monoHeader.copyWith(color: mutedColor),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        child: Text(
          l10n.notifTestSectionHint,
          style: TextStyle(fontSize: 12, color: mutedColor),
        ),
      ),
      ...samples.map(
        (s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
      const SizedBox(height: 8),
    ];
  }
}

/// Fila reutilizable para las secciones agrupadas: icon-slot + título +
/// (subtítulo opcional) + trailing widget (típicamente un Switch).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final String title;
  final Widget trailing;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, size: 16, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor ?? cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
