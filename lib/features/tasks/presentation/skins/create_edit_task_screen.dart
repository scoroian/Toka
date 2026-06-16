// lib/features/tasks/presentation/skins/create_edit_task_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'create_edit_task_screen_v2.dart';

/// Punto de entrada de la pantalla Crear/Editar tarea. Delega en [SkinSwitch]
/// para renderizar la variante v2 (única skin activa) según el skin activo en
/// `skinModeProvider`, consumiendo el mismo `CreateEditTaskViewModel`.
class CreateEditTaskScreen extends StatelessWidget {
  const CreateEditTaskScreen({super.key, this.editTaskId});

  final String? editTaskId;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => CreateEditTaskScreenV2(editTaskId: editTaskId),
      );
}
