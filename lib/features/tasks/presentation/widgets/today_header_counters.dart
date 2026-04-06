import 'package:flutter/material.dart';

import '../../domain/home_dashboard.dart';

class TodayHeaderCounters extends StatelessWidget {
  final DashboardCounters counters;

  const TodayHeaderCounters({super.key, required this.counters});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
