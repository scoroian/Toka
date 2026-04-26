// lib/features/subscription/presentation/skins/futurista/rescue_screen_futurista.dart
//
// Pantalla "Rescue" en skin futurista. Consume el mismo
// `rescueViewModelProvider` que la variante v2.
//
// Layout (canvas `skin_futurista/screens-meta.jsx`, función `RescueScreen`):
//   1. Header: botón back (chevron_left) + Spacer.
//   2. Pill warning con countdown ("Premium termina en N días" o "Quedan N horas").
//   3. Title display: "Decide qué sigue\nactivo en Free." (28/800).
//   4. Subtitle 13 muted (Text.rich): si no reactivas, downgrade el {date mono}.
//      Resto queda congelado 30 días, restaurable.
//   5. CTAs:
//      - TockaBtn(gold, lg, fullWidth) "Reactivar Premium" -> AppRoutes.paywall.
//      - TockaBtn(ghost, md, fullWidth) "Volver al hogar"  -> context.pop().
//
// Concern documentado: el `rescueViewModelProvider` actual (ver
// `rescue_view_model.dart`) NO expone listas de miembros ni de tareas
// activas, así que no se renderizan las cards "MIEMBROS ACTIVOS" /
// "TAREAS ACTIVAS" del canvas. Se sustituyen por un mensaje informativo
// y los CTAs. Cuando el VM exponga esas colecciones, añadir las cards
// usando el mismo patrón que el canvas (header mono uppercase + counter).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
import '../../../../../shared/widgets/futurista/tocka_btn.dart';
import '../../../../../shared/widgets/futurista/tocka_pill.dart';
import '../../../application/rescue_view_model.dart';

const _warning = Color(0xFFF5B544);

class RescueScreenFuturista extends ConsumerWidget {
  const RescueScreenFuturista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vm = ref.watch(rescueViewModelProvider);

    final countdownLabel = vm.hoursLeft < 24
        ? l10n.rescue_banner_hours_left(vm.hoursLeft)
        : l10n.rescue_banner_text(vm.daysLeft);

    final endsAtFormatted = _formatDate(vm.endsAt) ?? '—';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: adAwareBottomPadding(context, ref, extra: 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header: back button + Spacer.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: () => context.pop()),
                    const Spacer(),
                  ],
                ),
              ),

              // 2. Pill warning con countdown.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TockaPill(
                    color: _warning,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 10),
                        const SizedBox(width: 6),
                        Text(countdownLabel),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Title display 28/800.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(
                  'Decide qué sigue\nactivo en Free.',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.1,
                    color: cs.onSurface,
                  ),
                ),
              ),

              // 4. Subtitle 13 muted con fecha mono.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: cs.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Si no reactivas, tu hogar bajará a Free el ',
                      ),
                      TextSpan(
                        text: endsAtFormatted,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const TextSpan(
                        text:
                            '. El resto quedará congelado 30 días · restaurable.',
                      ),
                    ],
                  ),
                ),
              ),

              // Mensaje informativo (sustituye cards de miembros/tareas
              // que no están en el VM actual).
              if (vm.lastBillingError != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _LastBillingErrorTile(message: vm.lastBillingError!),
                ),
              ],

              // 5. CTAs.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TockaBtn(
                  key: const Key('btn_reactivate_premium'),
                  variant: TockaBtnVariant.gold,
                  size: TockaBtnSize.lg,
                  fullWidth: true,
                  onPressed: vm.isLoading
                      ? null
                      : () => context.push(AppRoutes.paywall),
                  child: Text(l10n.paywall_cta_reactivate),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TockaBtn(
                  key: const Key('btn_back_home'),
                  variant: TockaBtnVariant.ghost,
                  size: TockaBtnSize.md,
                  fullWidth: true,
                  onPressed: () => context.pop(),
                  child: const Text('Volver al hogar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(
            Icons.chevron_left,
            size: 22,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LastBillingErrorTile extends StatelessWidget {
  const _LastBillingErrorTile({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const Key('rescue_last_billing_error_futurista'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rescue_last_billing_error_title,
                  style: TextStyle(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}
