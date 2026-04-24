// lib/features/tasks/presentation/skins/create_edit_task_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'create_edit_task_screen_v2.dart';
import 'futurista/create_edit_task_screen_futurista.dart';

/// Punto de entrada de la pantalla Crear/Editar tarea. Delega en [SkinSwitch]
/// para elegir entre la variante v2 (actual) y la variante futurista según el
/// skin activo en `skinModeProvider`. Ambas ramas consumen el mismo
/// `CreateEditTaskViewModel`, sólo cambia la presentación.
class CreateEditTaskScreen extends StatelessWidget {
  const CreateEditTaskScreen({super.key, this.editTaskId});

  final String? editTaskId;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => CreateEditTaskScreenV2(editTaskId: editTaskId),
        futurista: (_) => CreateEditTaskScreenFuturista(editTaskId: editTaskId),
      );
}
