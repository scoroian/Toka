// lib/features/subscription/presentation/skins/downgrade_planner_screen.dart
//
// Wrapper que elige entre `DowngradePlannerScreenV2` y
// `DowngradePlannerScreenFuturista` según el `SkinMode` persistido.
// Ambas variantes consumen el mismo `downgradePlannerViewModelProvider`.

import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'downgrade_planner_screen_v2.dart';
import 'futurista/downgrade_planner_screen_futurista.dart';

class DowngradePlannerScreen extends StatelessWidget {
  const DowngradePlannerScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const DowngradePlannerScreenV2(),
        futurista: (_) => const DowngradePlannerScreenFuturista(),
      );
}
