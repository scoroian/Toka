// lib/features/tasks/presentation/skins/today_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/today_screen_futurista.dart';
import 'today_screen_v2.dart';

/// Punto de entrada de la pantalla "Hoy". Delegar en [SkinSwitch] para elegir
/// entre la variante v2 (actual) y la variante futurista según el skin activo
/// en `skinModeProvider`.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const TodayScreenV2(),
        futurista: (_) => const TodayScreenFuturista(),
      );
}
