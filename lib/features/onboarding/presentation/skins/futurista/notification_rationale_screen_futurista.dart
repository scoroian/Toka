// lib/features/onboarding/presentation/skins/futurista/notification_rationale_screen_futurista.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../notifications/application/fcm_token_service.dart';
import '../../../../notifications/application/notification_prefs_provider.dart';
import '../notification_rationale_screen_v2.dart';

class NotificationRationaleScreenFuturista extends ConsumerStatefulWidget {
  const NotificationRationaleScreenFuturista({super.key});

  @override
  ConsumerState<NotificationRationaleScreenFuturista> createState() =>
      _NotificationRationaleScreenFuturistaState();
}

class _NotificationRationaleScreenFuturistaState
    extends ConsumerState<NotificationRationaleScreenFuturista> {
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
      // No tocamos el permiso: el observer de lifecycle lo sincronizará.
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        context.go(AppRoutes.home);
      }
    }
  }

  /// Copia local de la función privada del v2 (mismo comportamiento).
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final bullets = <_BulletData>[
      _BulletData(icon: Icons.check, text: l10n.notifRationaleBullet1),
      _BulletData(icon: Icons.access_alarm, text: l10n.notifRationaleBullet2),
      _BulletData(icon: Icons.star_outline, text: l10n.notifRationaleBullet3),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primary.withValues(alpha: 0.19),
                        primary.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.33),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.55),
                        blurRadius: 60,
                        offset: const Offset(0, 30),
                        spreadRadius: -20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.notifications_active,
                      size: 40,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.notifRationaleTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Te avisamos solo cuando importa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < bullets.length; i++) ...[
                _FuturistaBullet(data: bullets[i]),
                if (i < bullets.length - 1) const SizedBox(height: 8),
              ],
              const Spacer(),
              TockaBtn(
                key: const Key('notif_rationale_enable'),
                variant: TockaBtnVariant.glow,
                size: TockaBtnSize.lg,
                fullWidth: true,
                onPressed: _busy ? null : _enable,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.notifRationaleCtaEnable),
              ),
              const SizedBox(height: 8),
              TockaBtn(
                key: const Key('notif_rationale_later'),
                variant: TockaBtnVariant.ghost,
                size: TockaBtnSize.md,
                fullWidth: true,
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

class _BulletData {
  const _BulletData({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _FuturistaBullet extends StatelessWidget {
  const _FuturistaBullet({required this.data});

  final _BulletData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.09),
              border: Border.all(color: primary.withValues(alpha: 0.19)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(data.icon, size: 16, color: primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
