import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/task_detail_screen_futurista.dart';
import 'task_detail_screen_v2.dart';

/// Wrapper que elige entre la ficha de tarea v2 y la variante futurista según
/// el `SkinMode` persistido. Ambas variantes consumen el mismo
/// `taskDetailViewModelProvider(taskId)`.
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => TaskDetailScreenV2(taskId: taskId),
        futurista: (_) => TaskDetailScreenFuturista(taskId: taskId),
      );
}
