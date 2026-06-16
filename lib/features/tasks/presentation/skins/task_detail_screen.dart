import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'task_detail_screen_v2.dart';

/// Wrapper "skin-aware" que renderiza la ficha de tarea v2 (única skin activa)
/// según el `SkinMode` persistido, consumiendo el mismo
/// `taskDetailViewModelProvider(taskId)`.
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => TaskDetailScreenV2(taskId: taskId),
      );
}
