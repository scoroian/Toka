// lib/features/onboarding/presentation/notification_rationale_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/application/fcm_token_service.dart';
import '../../notifications/application/notification_prefs_provider.dart';

/// Key used in SharedPreferences to avoid showing the rationale screen twice
/// within the same installation.
const kNotifRationaleShownPrefKey = 'notif_rationale_shown_v1';

/// Decide si la pantalla rationale debe aparecer al final del onboarding.
///
/// Se muestra si:
/// - La flag local `notif_rationale_shown_v1` NO está puesta, **o**
/// - El status actual del SO es `notDetermined` (nunca se pidió).
///
/// Si el usuario ya concedió o denegó, no volvemos a insistir en el onboarding.
Future<bool> shouldShowNotificationRationale({
  FirebaseMessaging? messaging,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final alreadyShown = prefs.getBool(kNotifRationaleShownPrefKey) ?? false;
  if (!alreadyShown) return true;

  final settings =
      await (messaging ?? FirebaseMessaging.instance).getNotificationSettings();
  return settings.authorizationStatus == AuthorizationStatus.notDetermined;
}

/// Marca la flag local como mostrada para que no vuelva a aparecer en este
/// install. Safe to call multiple times.
Future<void> markNotificationRationaleShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kNotifRationaleShownPrefKey, true);
}

Future<void> _persistSystemAuthorized(bool authorized) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'notificationPrefs': {
          'systemAuthorized': authorized,
        },
      },
      SetOptions(merge: true),
    );
  } catch (_) {
    // No-critical: el observer de ciclo de vida volverá a intentarlo.
  }
}

class NotificationRationaleScreen extends ConsumerStatefulWidget {
  const NotificationRationaleScreen({super.key});

  @override
  ConsumerState<NotificationRationaleScreen> createState() =>
      _NotificationRationaleScreenState();
}

class _NotificationRationaleScreenState
    extends ConsumerState<NotificationRationaleScreen> {
  bool _busy = false;

  FcmTokenService _service() => FcmTokenService(
        repository: ref.read(notificationPrefsRepositoryProvider),
        messaging: FirebaseMessaging.instance,
      );

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await _service().requestPermission();
      await markNotificationRationaleShown();
      await _persistSystemAuthorized(
        status == NotificationAuthorizationStatus.authorized ||
            status == NotificationAuthorizationStatus.provisional,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        context.go(AppRoutes.home);
      }
    }
  }

  Future<void> _later() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await markNotificationRationaleShown();
      // No tocamos el permiso: dejamos el valor por defecto (null) en Firestore
      // para que el observer de lifecycle lo sincronice al primer resumed.
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.notifications_active,
                size: 96,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.notifRationaleTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _Bullet(text: l10n.notifRationaleBullet1),
              _Bullet(text: l10n.notifRationaleBullet2),
              _Bullet(text: l10n.notifRationaleBullet3),
              const Spacer(),
              FilledButton(
                key: const Key('notif_rationale_enable'),
                onPressed: _busy ? null : _enable,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.notifRationaleCtaEnable),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('notif_rationale_later'),
                onPressed: _busy ? null : _later,
                child: Text(l10n.notifRationaleCtaLater),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

