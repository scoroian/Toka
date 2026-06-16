// lib/features/subscription/presentation/skins/downgrade_planner_screen.dart
//
// Wrapper "skin-aware" que renderiza `DowngradePlannerScreenV2` (única skin
// activa) según el `SkinMode` persistido, consumiendo el mismo
// `downgradePlannerViewModelProvider`.

import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'downgrade_planner_screen_v2.dart';

class DowngradePlannerScreen extends StatelessWidget {
  const DowngradePlannerScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const DowngradePlannerScreenV2(),
      );
}
