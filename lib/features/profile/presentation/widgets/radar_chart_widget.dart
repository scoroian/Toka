// lib/features/profile/presentation/widgets/radar_chart_widget.dart
import 'package:fl_chart/fl_chart.dart' hide RadarEntry;
import 'package:fl_chart/fl_chart.dart' as fl show RadarEntry;
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'strengths_list_widget.dart';

/// Data model for a single task in the radar chart.
class RadarEntry {
  const RadarEntry({
    this.taskId = '',
    required this.taskName,
    required this.avgScore,
  });

  final String taskId;
  final String taskName;
  final double avgScore; // 1-10
}

class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({super.key, required this.entries});

  final List<RadarEntry> entries;

  static const int _maxAxes = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.radar_chart_title,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Center(
            key: const Key('radar_no_data'),
            child: Text(
              l10n.radar_no_data,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      );
    }

    if (entries.length < 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.radar_chart_title,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          StrengthsListWidget(
            key: const Key('radar_text_fallback'),
            entries: entries,
          ),
        ],
      );
    }

    final radarEntries = entries.take(_maxAxes).toList();
    final overflowEntries = entries.skip(_maxAxes).toList();
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.radar_chart_title,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                // Dataset invisible que fuerza la escala 0-10 en todos los ejes.
                RadarDataSet(
                  dataEntries: List.generate(
                    radarEntries.length,
                    (_) => const fl.RadarEntry(value: 10),
                  ),
                  fillColor: Colors.transparent,
                  borderColor: Colors.transparent,
                  borderWidth: 0,
                  entryRadius: 0,
                ),
                RadarDataSet(
                  dataEntries: radarEntries
                      .map((e) => fl.RadarEntry(value: e.avgScore))
                      .toList(),
                  fillColor: primary.withValues(alpha: 0.3),
                  borderColor: primary,
                  borderWidth: 2,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.transparent),
              titlePositionPercentageOffset: 0.2,
              titleTextStyle: Theme.of(context).textTheme.bodySmall,
              getTitle: (index, _) => RadarChartTitle(
                text: radarEntries[index].taskName,
              ),
              tickCount: 5,
              ticksTextStyle: const TextStyle(fontSize: 8, color: Colors.grey),
              tickBorderData: const BorderSide(color: Colors.grey, width: 0.5),
              gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
        ),
        if (overflowEntries.isNotEmpty) ...[
          const SizedBox(height: 16),
          StrengthsListWidget(entries: overflowEntries),
        ],
      ],
    );
  }
}
