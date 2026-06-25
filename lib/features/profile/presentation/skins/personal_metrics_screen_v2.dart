import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../homes/application/current_home_provider.dart';
import '../../../subscription/application/plus_provider.dart';
import '../../application/member_radar_provider.dart';
import '../../application/personal_metrics_view_model.dart';
import '../widgets/radar_chart_widget.dart';

/// Pantalla de métricas personales del usuario (gated por Toka Plus).
class PersonalMetricsScreenV2 extends ConsumerWidget {
  const PersonalMetricsScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasPlus = ref.watch(plusActiveProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.personalMetricsTitle)),
      body: hasPlus ? const _MetricsBody() : const _LockedBody(),
    );
  }
}

class _LockedBody extends StatelessWidget {
  const _LockedBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      key: const Key('metrics_locked'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.personalMetricsLockedTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.personalMetricsLockedBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('metrics_unlock_cta'),
              onPressed: () => context.push(AppRoutes.plusPaywall),
              child: Text(l10n.personalMetricsUnlockCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsBody extends ConsumerWidget {
  const _MetricsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final metricsAsync = ref.watch(personalMetricsViewModelProvider);

    return metricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.error_generic)),
      data: (m) {
        if (!m.hasData) {
          return Center(
            key: const Key('metrics_empty'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.personalMetricsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MetricTile(
              metricKey: 'metric_completed',
              icon: Icons.check_circle_outline,
              label: l10n.member_profile_tasks_completed,
              value: '${m.tasksCompleted}',
            ),
            _MetricTile(
              metricKey: 'metric_streak',
              icon: Icons.local_fire_department_outlined,
              label: l10n.metricCurrentStreak,
              value: '${m.currentStreak}',
            ),
            _MetricTile(
              metricKey: 'metric_punctuality',
              icon: Icons.schedule_outlined,
              label: l10n.metricPunctuality,
              value: '${m.compliancePercent.toStringAsFixed(0)}%',
            ),
            _MetricTile(
              metricKey: 'metric_score',
              icon: Icons.star_outline,
              label: l10n.metricAverageScore,
              value: m.averageScore.toStringAsFixed(1),
            ),
            _MetricTile(
              metricKey: 'metric_passed',
              icon: Icons.skip_next_outlined,
              label: l10n.metricPassedCount,
              value: '${m.passedCount}',
            ),
            _MetricTile(
              metricKey: 'metric_share',
              icon: Icons.pie_chart_outline,
              label: l10n.metricShare,
              value: '${m.sharePercent.toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 24),
            const _RadarSection(),
          ],
        );
      },
    );
  }
}

/// Desglose por tarea (radar), reutilizando la infraestructura existente.
class _RadarSection extends ConsumerWidget {
  const _RadarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
    final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
    if (uid == null || homeId == null) return const SizedBox.shrink();
    final radar =
        ref.watch(memberRadarProvider(homeId: homeId, uid: uid));
    return radar.maybeWhen(
      data: (entries) => RadarChartWidget(entries: entries),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.metricKey,
    required this.icon,
    required this.label,
    required this.value,
  });

  final String metricKey;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: Key(metricKey),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
