import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'home_settings_screen_v2.dart';

/// Wrapper "skin-aware" para la pantalla de Ajustes del hogar.
///
/// Selecciona la implementación según el skin activo (`AppSkin`):
///   - [AppSkin.v2] → [HomeSettingsScreenV2] (única skin activa por ahora).
class HomeSettingsScreen extends StatelessWidget {
  const HomeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const HomeSettingsScreenV2(),
      );
}
