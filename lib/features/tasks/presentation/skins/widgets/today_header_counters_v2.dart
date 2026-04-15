// lib/features/tasks/presentation/skins/widgets/today_header_counters_v2.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors_v2.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/home_dashboard.dart';

class TodayHeaderCountersV2 extends StatelessWidget {
  const TodayHeaderCountersV2({super.key, required this.counters});
  final DashboardCounters counters;

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg    = isDark ? AppColorsV2.surfaceDark    : AppColorsV2.surfaceLight;
    final bd    = isDark ? AppColorsV2.borderDark     : AppColorsV2.borderLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(child: _CounterCard(
          key: const Key('counter_due'),
          number: counters.tasksDueToday,
          label: l10n.today_tasks_due(counters.tasksDueToday),
          numberColor: AppColorsV2.primary,
          bg: bg, bd: bd,
        )),
        const SizedBox(width: 8),
        Expanded(child: _CounterCard(
          key: const Key('counter_done'),
          number: counters.tasksDoneToday,
          label: l10n.today_tasks_done_today(counters.tasksDoneToday),
          numberColor: isDark ? AppColorsV2.textPrimaryDark : AppColorsV2.textPrimaryLight,
          bg: bg, bd: bd,
        )),
      ]),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({super.key, required this.number, required this.label,
      required this.numberColor, required this.bg, required this.bd});
  final int number;
  final String label;
  final Color numberColor, bg, bd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$number',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 24, fontWeight: FontWeight.w900, color: numberColor)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 9, fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColorsV2.textSecondaryDark
                    : AppColorsV2.textSecondaryLight)),
      ]),
    );
  }
}
