// lib/features/tasks/presentation/skins/all_tasks_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'all_tasks_screen_v2.dart';
import 'futurista/all_tasks_screen_futurista.dart';

/// Punto de entrada de la pantalla de Tareas. Delega en [SkinSwitch] para
/// elegir entre la variante v2 (actual) y la variante futurista según el skin
/// activo en `skinModeProvider`.
class AllTasksScreen extends StatelessWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const AllTasksScreenV2(),
        futurista: (_) => const AllTasksScreenFuturista(),
      );
}
