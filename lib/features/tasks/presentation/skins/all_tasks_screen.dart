// lib/features/tasks/presentation/skins/all_tasks_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'all_tasks_screen_v2.dart';

/// Punto de entrada de la pantalla de Tareas. Delega en [SkinSwitch] para
/// renderizar la variante v2 (única skin activa) según el skin activo en
/// `skinModeProvider`.
class AllTasksScreen extends StatelessWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const AllTasksScreenV2(),
      );
}
