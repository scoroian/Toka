import 'package:flutter/material.dart';

import '../../../../core/constants/free_limits.dart';
import '../../../../core/utils/toka_dates.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../homes/domain/home.dart';
import '../../domain/subscription_dashboard.dart';

/// Bloque principal "Tu suscripción". Resume el plan activo o inactivo del
/// hogar en función del `SubscriptionDashboard` que recibe. La responsabilidad
/// de navegar o disparar acciones queda fuera de este widget — únicamente
/// muestra información estática.
class PlanSummaryCard extends StatelessWidget {
  const PlanSummaryCard({
    super.key,
    required this.data,
    this.currentUserUid,
  });

  final SubscriptionDashboard data;

  /// Si coincide con `data.currentPayerUid` se muestra "tú" en el campo
  /// pagador. Se pasa opcional para poder probar el widget sin auth.
  final String? currentUserUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Card(
      key: const Key('plan_summary_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildContent(context, theme, l10n, locale),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Locale locale,
  ) {
    switch (data.status) {
      case HomePremiumStatus.free:
        return _buildFree(context, theme, l10n);
      case HomePremiumStatus.active:
        return _buildActive(context, theme, l10n, locale);
      case HomePremiumStatus.cancelledPendingEnd:
        return _buildCancelledPendingEnd(context, theme, l10n, locale);
      case HomePremiumStatus.rescue:
        return _buildRescue(context, theme, l10n, locale);
      case HomePremiumStatus.expiredFree:
        return _buildExpiredFree(context, theme, l10n, locale);
      case HomePremiumStatus.restorable:
        return _buildRestorable(context, theme, l10n, locale);
      case HomePremiumStatus.purged:
        return _buildFree(context, theme, l10n);
    }
  }

  Widget _header({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFree(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final pc = data.planCounters;
    return [
      _header(
        theme: theme,
        icon: Icons.workspace_premium_outlined,
        iconColor: theme.colorScheme.onSurfaceVariant,
        title: l10n.subscription_status_free,
      ),
      const SizedBox(height: 16),
      Text(
        l10n.subscription_free_benefits_title,
        style: theme.textTheme.titleSmall,
      ),
      const SizedBox(height: 8),
      _benefit(l10n.paywall_feature_members),
      _benefit(l10n.paywall_feature_smart),
      _benefit(l10n.paywall_feature_vacations),
      _benefit(l10n.paywall_feature_reviews),
      _benefit(l10n.paywall_feature_history),
      _benefit(l10n.paywall_feature_no_ads),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _counterChip(
            context,
            label: l10n.subscription_counter_members(
              pc.activeMembers,
              FreeLimits.maxActiveMembers,
            ),
            overLimit: pc.activeMembers >= FreeLimits.maxActiveMembers,
          ),
          _counterChip(
            context,
            label: l10n.subscription_counter_tasks(
              pc.automaticRecurringTasks,
              FreeLimits.maxAutomaticRecurringTasks,
            ),
            overLimit:
                pc.automaticRecurringTasks >= FreeLimits.maxAutomaticRecurringTasks,
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildActive(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Locale locale,
  ) {
    final renewal = data.endsAt != null
        ? l10n.subscription_next_renewal(
            TokaDates.dateLongFull(data.endsAt!, locale))
        : '';
    return [
      _header(
        theme: theme,
        icon: Icons.workspace_premium,
        iconColor: theme.colorScheme.primary,
        title: l10n.subscription_status_active,
        subtitle: renewal.isEmpty ? null : renewal,
      ),
      if (data.plan != null) ...[
        const SizedBox(height: 12),
        _planRow(theme, l10n, data.plan!),
      ],
      if (data.currentPayerUid != null) ...[
        const SizedBox(height: 8),
        _payerRow(theme, l10n),
      ],
    ];
  }

  List<Widget> _buildCancelledPendingEnd(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Locale locale,
  ) {
    final endsAt = data.endsAt != null
        ? TokaDates.dateLongFull(data.endsAt!, locale)
        : '';
    return [
      _header(
        theme: theme,
        icon: Icons.workspace_premium,
        iconColor: theme.colorScheme.tertiary,
        title: l10n.subscription_premium_until(endsAt),
        subtitle: l10n.subscription_no_auto_renew,
      ),
      if (data.currentPayerUid != null) ...[
        const SizedBox(height: 8),
        _payerRow(theme, l10n),
      ],
    ];
  }

  List<Widget> _buildRescue(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Locale locale,
  ) {
    final warn = l10n.subscription_rescue_warning(data.daysLeft);
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                warn,
                key: const Key('rescue_warning_banner'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      if (data.endsAt != null) ...[
        const SizedBox(height: 12),
        Text(
          l10n.subscription_premium_until(
              TokaDates.dateLongFull(data.endsAt!, locale)),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    ];
  }

  List<Widget> _buildExpiredFree(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Locale locale,
  ) {
    final expired = data.endsAt != null
        ? TokaDates.dateLongFull(data.endsAt!, locale)
        : '';
    return [
      _header(
        theme: theme,
        icon: Icons.history,
        iconColor: theme.colorScheme.onSurfaceVariant,
        title: l10n.subscription_expired_on(expired),
      ),
    ];
  }

  List<Widget> _buildRestorable(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Locale locale,
  ) {
    final restore = data.restoreUntil != null
        ? TokaDates.dateLongFull(data.restoreUntil!, locale)
        : '';
    return [
      _header(
        theme: theme,
        icon: Icons.restore,
        iconColor: theme.colorScheme.primary,
        title: l10n.subscription_restorable_until(restore, data.restoreDaysLeft),
      ),
    ];
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _counterChip(
    BuildContext context, {
    required String label,
    required bool overLimit,
  }) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      backgroundColor: overLimit
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }

  Widget _planRow(ThemeData theme, AppLocalizations l10n, String plan) {
    final label = plan == 'annual'
        ? l10n.subscription_annual
        : plan == 'monthly'
            ? l10n.subscription_monthly
            : plan;
    return Row(
      children: [
        Icon(Icons.credit_card_outlined,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _payerRow(ThemeData theme, AppLocalizations l10n) {
    final isSelf = currentUserUid != null &&
        currentUserUid == data.currentPayerUid;
    final name =
        isSelf ? l10n.subscription_payer_you : l10n.subscription_payer_other;
    return Row(
      children: [
        Icon(Icons.person_outline,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('${l10n.subscription_payer_label}: $name',
            style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
