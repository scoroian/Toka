import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/my_homes_screen_futurista.dart';
import 'my_homes_screen_v2.dart';

/// Wrapper "skin-aware" para la pantalla "Mis hogares".
///
/// Selecciona la implementación según el skin activo (`AppSkin`):
///   - [AppSkin.v2]        → [MyHomesScreenV2] (skin actual).
///   - [AppSkin.futurista] → [MyHomesScreenFuturista].
class MyHomesScreen extends StatelessWidget {
  const MyHomesScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const MyHomesScreenV2(),
        futurista: (_) => const MyHomesScreenFuturista(),
      );
}
