// lib/features/subscription/presentation/widgets/premium_state_banner.dart
//
// Banner no cerrable que se renderiza como primer child en Hoy y en
// Ajustes del hogar. Sólo aparece para los estados rescue, cancelled
// pending end, expiredFree y restorable. Para free y active no se
// muestra nada (SizedBox.shrink).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../homes/application/current_home_provider.dart';
import '../../application/days_left.dart';
import '../../application/subscription_provider.dart';
import '../paywall_entry_context.dart';

class PremiumStateBanner extends ConsumerWidget {
  const PremiumStateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionStateProvider);
    final home = ref.watch(currentHomeProvider).valueOrNull;
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return subState.maybeWhen(
      rescue: (_, endsAt, __) {
        if (endsAt == null) return const SizedBox.shrink();
        final days = daysLeftFrom(endsAt);
        final hours = hoursLeftFrom(endsAt);
        final lastDay = days < 1 || hours < 24;
        // Fondo rojo; intensidad más alta en el último día.
        final bg = lastDay
            ? cs.error
            : cs.error.withValues(alpha: 0.8);
        final fg = lastDay ? cs.onError : cs.onError;
        final text = lastDay
            ? l10n.rescue_banner_last_day
            : l10n.rescue_banner_title(days);
        return _BannerShell(
          keyName: 'banner_rescue',
          background: bg,
          foreground: fg,
          icon: Icons.warning_amber_rounded,
          text: text,
          ctaLabel: l10n.rescue_banner_renew,
          onCta: () => context.push(AppRoutes.rescueScreen),
          pulse: lastDay,
        );
      },
      cancelledPendingEnd: (_, endsAt) {
        return _BannerShell(
          keyName: 'banner_cancelled_pending_end',
          background: const Color(0xFFFFB74D), // ámbar
          foreground: Colors.black87,
          icon: Icons.info_outline,
          text: l10n.cancelled_ends_banner_title(_formatDate(endsAt)),
          ctaLabel: l10n.cancelled_ends_banner_cta,
          onCta: () => context.push(AppRoutes.subscription),
        );
      },
      expiredFree: () {
        final expired = home?.premiumEndsAt;
        final date = expired != null ? _formatDate(expired) : '—';
        return _BannerShell(
          keyName: 'banner_expired_free',
          background: cs.surfaceContainerHighest,
          foreground: cs.onSurface,
          icon: Icons.info_outline,
          text: l10n.expired_free_banner_title(date),
          ctaLabel: l10n.expired_free_banner_cta,
          onCta: () => context.push(
            '${AppRoutes.paywall}?ctx=${PaywallEntryContext.fromExpired.name}',
          ),
        );
      },
      restorable: (restoreUntil) {
        return _BannerShell(
          keyName: 'banner_restorable',
          background: const Color(0xFFC8E6C9), // verde claro
          foreground: Colors.black87,
          icon: Icons.restore,
          text: l10n.restorable_banner_title(_formatDate(restoreUntil)),
          ctaLabel: l10n.restorable_banner_cta,
          onCta: () => context.push(
            '${AppRoutes.paywall}?ctx=${PaywallEntryContext.fromRestorable.name}',
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _BannerShell extends StatefulWidget {
  const _BannerShell({
    required this.keyName,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.text,
    required this.ctaLabel,
    required this.onCta,
    this.pulse = false,
  });

  final String keyName;
  final Color background;
  final Color foreground;
  final IconData icon;
  final String text;
  final String ctaLabel;
  final VoidCallback onCta;
  final bool pulse;

  @override
  State<_BannerShell> createState() => _BannerShellState();
}

class _BannerShellState extends State<_BannerShell>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget container = Semantics(
      container: true,
      label: '${widget.text}. ${widget.ctaLabel}',
      child: Material(
        key: Key(widget.keyName),
        color: widget.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.foreground, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.text,
                  key: Key('${widget.keyName}_text'),
                  style: TextStyle(
                    color: widget.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                key: Key('${widget.keyName}_cta'),
                onPressed: widget.onCta,
                child: Text(
                  widget.ctaLabel,
                  style: TextStyle(
                    color: widget.foreground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (_controller != null) {
      container = FadeTransition(
        opacity: Tween<double>(begin: 0.75, end: 1).animate(_controller!),
        child: container,
      );
    }

    return container;
  }
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}
