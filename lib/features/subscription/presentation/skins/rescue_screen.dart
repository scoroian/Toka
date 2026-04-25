// lib/features/subscription/presentation/skins/rescue_screen.dart
//
// Wrapper que elige entre `RescueScreenV2` y `RescueScreenFuturista`
// según el `SkinMode` persistido. Ambas variantes consumen el mismo
// `rescueViewModelProvider`.

import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/rescue_screen_futurista.dart';
import 'rescue_screen_v2.dart';

class RescueScreen extends StatelessWidget {
  const RescueScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const RescueScreenV2(),
        futurista: (_) => const RescueScreenFuturista(),
      );
}
