import 'package:flutter/material.dart';

import '../../domain/home_dashboard.dart';

class TodayTaskSection extends StatelessWidget {
  final String recurrenceType;
  final List<TaskPreview> todos;
  final List<DoneTaskPreview> dones;
  final String? currentUid;

  const TodayTaskSection({
    super.key,
    required this.recurrenceType,
    required this.todos,
    required this.dones,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) =>
      const SliverToBoxAdapter(child: SizedBox.shrink());
}
