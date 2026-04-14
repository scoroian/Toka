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
      return Center(
        key: const Key('radar_no_data'),
        child: Text(l10n.radar_no_data),
      );
    }

    final radarEntries = entries.take(_maxAxes).toList();
    final overflowEntries = entries.skip(_maxAxes).toList();

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
                RadarDataSet(
                  dataEntries: radarEntries
                      .map((e) => fl.RadarEntry(value: e.avgScore))
                      .toList(),
                  fillColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  borderColor: Theme.of(context).colorScheme.primary,
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
              tickCount: 4,
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
